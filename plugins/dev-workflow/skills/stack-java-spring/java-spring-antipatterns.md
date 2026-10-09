# Java Spring Antipatrones

## Antipatrón 1: Servicio anémico (Anemic Domain Model)
```java
// MALO - Servicio solo llama a repositorio, sin lógica
@Service
public class OrderService {
    private final OrderRepository repository;

    public Order create(Order order) {
        return repository.save(order);  // Solo delega, sin validaciones ni reglas
    }
}

// BUENO - Servicio contiene reglas de negocio
@Service
public class OrderService {
    private final OrderRepository repository;
    private final InventoryClient inventory;

    public Order create(OrderCreateRequest request) {
        // Validaciones de negocio
        if (request.items().isEmpty()) {
            throw new BusinessException("Pedido sin items");
        }
        request.items().forEach(item -> 
            inventory.reserve(item.productId(), item.quantity())
        );

        Order order = Order.from(request);
        order.calculateTotals();
        return repository.save(order);
    }
}
```

## Antipatrón 2: Repositorio con lógica de negocio
```java
// MALO - Lógica en repository (difícil de testear, acopla JPA)
public interface OrderRepository extends JpaRepository<Order, UUID> {
    @Query("SELECT o FROM Order o WHERE o.customer.id = :customerId AND o.status = 'PENDING'")
    List<Order> findPendingByCustomer(@Param("customerId") UUID customerId);

    @Modifying
    @Query("UPDATE Order o SET o.status = 'CANCELLED' WHERE o.id = :id")
    void cancel(@Param("id") UUID id);
}

// BUENO - Repository solo CRUD + queries simples; lógica en Service
public interface OrderRepository extends JpaRepository<Order, UUID> {
    List<Order> findByCustomerIdAndStatus(UUID customerId, OrderStatus status);
    // Método derivado, sin @Query
}

@Service
public class OrderService {
    public void cancel(UUID orderId) {
        Order order = repository.findById(orderId).orElseThrow();
        order.cancel();  // Lógica en entidad/domain
        repository.save(order);
    }
}
```

## Antipatrón 3: Entidad con lógica de presentación
```java
// MALO - Entidad conoce DTOs/JSON
@Entity
public class Order {
    public OrderResponse toResponse() {  // FALLA: acopla entidad a API
        return new OrderResponse(...);
    }
}

// BUENO - Mapper separado o record factory
public record OrderResponse(...) {
    public static OrderResponse from(Order order) { ... }
}
```

## Antipatrón 4: @Transactional en método que llama a servicio externo
```java
// MALO - Transacción abierta durante llamada HTTP (timeout, locks)
@Service
@Transactional
public class OrderService {
    public Order create(OrderCreateRequest request) {
        Order order = Order.from(request);
        repository.save(order);
        paymentClient.charge(order.getPaymentId());  // HTTP call dentro de transacción
        return order;
    }
}

// BUENO - Separar transacción de llamadas externas
@Service
public class OrderService {
    @Transactional
    public Order create(OrderCreateRequest request) {
        Order order = Order.from(request);
        return repository.save(order);
    }

    @Transactional
    public void processPayment(UUID orderId) {
        Order order = repository.findById(orderId).orElseThrow();
        paymentClient.charge(order.getPaymentId());
        order.markPaid();
        repository.save(order);
    }
}
```

## Antipatrón 5: DTOs mutables con setters
```java
// MALO - Mutable, sin validación en constructor
public class OrderCreateRequest {
    private String customerId;
    private List<OrderItemRequest> items;
    // getters + setters
    // Posible estado inválido: customerId=null, items=null
}

// BUENO - Record inmutable, validado al crear
public record OrderCreateRequest(
    @NotNull UUID customerId,
    @NotEmpty @Valid List<@Valid OrderItemRequest> items
) {
    // Compact constructor para validación adicional
    public OrderCreateRequest {
        if (items.stream().mapToInt(OrderItemRequest::quantity).sum() > 100) {
            throw new IllegalArgumentException("Máximo 100 unidades por pedido");
        }
    }
}
```

## Antipatrón 6: Excepciones genéricas / RuntimeException sin información
```java
// MALO - Información perdida
throw new RuntimeException("Error");  // FALLA: sin contexto, no manejable

// BUENO - Excepciones de dominio tipadas
public class InsufficientStockException extends BusinessException {
    private final UUID productId;
    private final int requested;
    private final int available;

    public InsufficientStockException(UUID productId, int requested, int available) {
        super(String.format("Stock insuficiente para %s: solicitado %d, disponible %d", productId, requested, available));
        this.productId = productId;
        this.requested = requested;
        this.available = available;
    }
}
```

## Antipatrón 7: OpenAPI sin ejemplos ni descripciones
```java
// MALO - Solo annotations vacías
@PostMapping("/orders")
public ResponseEntity<OrderResponse> create(@RequestBody OrderCreateRequest request) { ... }

// BUENO - Documentación completa
@Operation(
    summary = "Crear nuevo pedido",
    description = "Crea un pedido validando stock y calculando totales. Reserva stock temporalmente.",
    responses = {
        @ApiResponse(responseCode = "201", description = "Pedido creado",
            content = @Content(schema = @Schema(implementation = OrderResponse.class))),
        @ApiResponse(responseCode = "400", description = "Datos inválidos",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "409", description = "Stock insuficiente",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    }
)
@PostMapping("/orders")
public ResponseEntity<OrderResponse> create(
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
        description = "Datos del pedido",
        required = true,
        content = @Content(
            schema = @Schema(implementation = OrderCreateRequest.class),
            examples = @ExampleObject(
                name = "Pedido estándar",
                value = """
                    {"customerId":"550e8400-e29b-41d4-a716-446655440000",
                     "items":[{"productId":"prod-1","quantity":2}],
                     "address":{"street":"Calle Mayor 1","city":"Madrid","postalCode":"28001","country":"ES"}}
                    """
            )
        )
    )
    @Valid @RequestBody OrderCreateRequest request
) { ... }
```

## Antipatrón 8: Configuración hardcodeada
```java
// MALO - Valores en código
@Value("${app.external.timeout:30000}")
private int timeout;

// BUENO - ConfigurationProperties tipado
@ConfigurationProperties(prefix = "app.external")
@ConstructorBinding
public record ExternalServiceConfig(
    @DurationUnit(ChronoUnit.MILLIS) Duration timeout,
    @DurationUnit(ChronoUnit.SECONDS) Duration retryInterval,
    int maxRetries
) {}
```

## Antipatrón 9: Tests que dependen de orden/estado compartido
```java
// MALO - @DirtiesContext, tests dependientes
@SpringBootTest
@TestMethodOrder(OrderAnnotation.class)
class OrderTest {
    @Test @Order(1) void create() { ... }
    @Test @Order(2) void find() { ... }  // Depende del test 1
}

// BUENO - Tests aislados, cada uno crea sus datos
@SpringBootTest
@Testcontainers
class OrderControllerTest {
    @Test void create_returns201() { ... }
    @Test void find_returns404_whenNotExists() { ... }  // Independiente
}
```

## Antipatrón 10: Lombok @Data en entidades JPA
```java
// MALO - @Data genera equals/hashCode con campos mutables + toString con lazy loading
@Entity
@Data  // FALLA: equals/hashCode roto con proxies, toString dispara lazy loading
public class Order {
    @OneToMany(mappedBy = "order")
    private List<OrderItem> items;
}

// BUENO - Equals/hashCode solo por ID, toString sin asociaciones
@Entity
@Getter @Setter @ToString(exclude = "items") @EqualsAndHashCode(of = "id")
public class Order {
    @Id @GeneratedValue private UUID id;
    @OneToMany(mappedBy = "order")
    private List<OrderItem> items;
}
```