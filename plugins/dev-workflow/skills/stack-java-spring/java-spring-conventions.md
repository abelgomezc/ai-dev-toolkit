# Java Spring Conventions - Código Bueno vs Malo

## Inyección de dependencias

### ✅ BUENO: Constructor injection
```java
@Service
@RequiredArgsConstructor  // Lombok genera constructor con final fields
public class OrderService {
    private final OrderRepository orderRepository;
    private final PaymentClient paymentClient;
    private final EventPublisher eventPublisher;

    public Order create(OrderCreateRequest request) {
        Order order = Order.from(request);
        orderRepository.save(order);
        paymentClient.charge(order.getPaymentId());
        eventPublisher.publish(new OrderCreatedEvent(order.getId()));
        return order;
    }
}
```

### ❌ MALO: Field injection
```java
@Service
public class OrderService {
    @Autowired private OrderRepository orderRepository;
    @Autowired private PaymentClient paymentClient;
    @Autowired private EventPublisher eventPublisher;
    // Problemas: no testable sin Spring context, inmutabilidad rota, dependencias ocultas
}
```

### ❌ MALO: Setter injection
```java
@Service
public class OrderService {
    private OrderRepository orderRepository;
    private PaymentClient paymentClient;

    @Autowired
    public void setOrderRepository(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }
    // Problemas: objeto en estado inválido tras construcción, mutabilidad innecesaria
}
```

## DTOs vs Entidades

### ✅ BUENO: Records para DTOs, Entidades solo en repositorio
```java
// Request DTO - validado en entrada
public record OrderCreateRequest(
    @NotNull @Valid CustomerRef customer,
    @NotEmpty @Valid List<@Valid OrderItemRequest> items,
    @NotNull @Valid ShippingAddress address
) {}

// Response DTO - forma la API
public record OrderResponse(
    UUID id,
    String orderNumber,
    OrderStatus status,
    BigDecimal total,
    Instant createdAt,
    List<OrderItemResponse> items
) {
    public static OrderResponse from(Order order) {
        return new OrderResponse(
            order.getId(),
            order.getOrderNumber(),
            order.getStatus(),
            order.getTotal(),
            order.getCreatedAt(),
            order.getItems().stream().map(OrderItemResponse::from).toList()
        );
    }
}

// Entidad JPA - package-private, solo en capa repository
@Entity
@Table(name = "orders")
class Order {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(unique = true, nullable = false)
    private String orderNumber;

    @Enumerated(EnumType.STRING)
    private OrderStatus status;

    @Embedded
    private MonetaryAmount total;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    // Package-private factory
    static Order from(OrderCreateRequest request) { ... }
}
```

### ❌ MALO: Entidad expuesta en API
```java
@RestController
public class OrderController {
    @GetMapping("/orders/{id}")
    public ResponseEntity<Order> get(@PathVariable UUID id) {  // FALLA: expone JPA
        return repository.findById(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }
}
// Problemas: lazy loading en serialización, ciclos bidireccionales, over-fetching, acoplamiento API-BD
```

## Manejo de errores

### ✅ BUENO: @RestControllerAdvice + RFC 7807
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        List<ErrorResponse.FieldError> fields = ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> new ErrorResponse.FieldError(fe.getField(), fe.getDefaultMessage()))
            .toList();
        ErrorResponse body = new ErrorResponse("VALIDATION_ERROR", "Datos de entrada inválidos", fields);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(EntityNotFoundException ex) {
        ErrorResponse body = new ErrorResponse("NOT_FOUND", ex.getMessage(), List.of());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
    }

    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ResponseEntity<ErrorResponse> handleConcurrency(OptimisticLockingFailureException ex) {
        ErrorResponse body = new ErrorResponse("CONFLICT", "El recurso fue modificado por otro usuario", List.of());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body);
    }
}

// Error response RFC 7807 compatible
public record ErrorResponse(
    String type,
    String title,
    List<FieldError> fields
) {
    public record FieldError(String field, String message) {}
}
```

### ❌ MALO: Try-catch disperso
```java
@RestController
public class OrderController {
    @PostMapping("/orders")
    public ResponseEntity<?> create(@RequestBody OrderCreateRequest request) {
        try {
            Order order = service.create(request);
            return ResponseEntity.ok(order);
        } catch (ValidationException e) {
            return ResponseEntity.badRequest().body(e.getMessage());  // String, no estructurado
        } catch (NotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error interno");  // Sin detalles, no loggeado
        }
    }
}
```

## Estructura de paquetes

### ✅ BUENO: Package by feature (microservicio)
```text
com.example.orders
├── OrderController.java
├── OrderService.java
├── OrderRepository.java
├── dto/
│   ├── OrderCreateRequest.java
│   ├── OrderResponse.java
│   ├── OrderItemRequest.java
│   └── OrderItemResponse.java
├── entity/
│   ├── Order.java
│   └── OrderItem.java
├── event/
│   ├── OrderCreatedEvent.java
│   └── OrderEventPublisher.java
└── exception/
    ├── OrderNotFoundException.java
    └── InsufficientStockException.java
```

### ✅ BUENO: Package by layer (monolito modular)
```text
com.example
├── controller/
│   ├── OrderController.java
│   └── CustomerController.java
├── service/
│   ├── OrderService.java
│   └── CustomerService.java
├── repository/
│   ├── OrderRepository.java
│   └── CustomerRepository.java
├── dto/
│   ├── OrderCreateRequest.java
│   └── CustomerCreateRequest.java
├── entity/
│   ├── Order.java
│   └── Customer.java
├── config/
│   ├── SecurityConfig.java
│   └── OpenApiConfig.java
└── exception/
    ├── GlobalExceptionHandler.java
    └── BusinessException.java
```

## Tests

### ✅ BUENO: Testcontainers para integración, Mockito para unidad
```java
@SpringBootTest
@Testcontainers
class OrderControllerIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @Autowired
    private MockMvc mockMvc;

    @Test
    void createOrder_returns201_withLocation() throws Exception {
        String body = """
            {"customer":{"id":"123"},"items":[{"productId":"p1","quantity":2}],"address":{"street":"Calle 1","city":"Madrid"}}
            """;

        mockMvc.perform(post("/api/v1/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
            .andExpect(status().isCreated())
            .andExpect(header().exists("Location"))
            .andExpect(jsonPath("$.id").exists());
    }
}

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock private OrderRepository repository;
    @Mock private PaymentClient paymentClient;
    @Mock private EventPublisher eventPublisher;

    @InjectMocks private OrderService service;

    @Test
    void create_publishesEvent() {
        OrderCreateRequest request = new OrderCreateRequest(...);
        Order saved = Order.from(request);
        when(repository.save(any())).thenReturn(saved);

        OrderResponse response = service.create(request);

        verify(eventPublisher).publish(argThat(e -> e.orderId().equals(saved.getId())));
        assertThat(response.id()).isEqualTo(saved.getId());
    }
}
```

### ❌ MALO: Solo tests de integración lentos, sin tests unitarios
```java
@SpringBootTest  // Carga todo el contexto Spring para cada test
class OrderServiceTest {
    @Autowired OrderService service;  // Lento, frágil, no aísla lógica

    @Test
    void create_works() { ... }  // Tarda 10s+ por test
}
```

## Configuración Maven (pom.xml) - Mínimo viable

```xml
<project>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.3</version>
  </parent>

  <properties>
    <java.version>21</java.version>
    <checkstyle.version>10.17.0</checkstyle.version>
    <spotbugs.version>4.8.6</spotbugs.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>2.3.0</version>
    </dependency>
    <dependency>
      <groupId>org.projectlombok</groupId>
      <artifactId>lombok</artifactId>
      <optional>true</optional>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>junit-jupiter</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>postgresql</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-checkstyle-plugin</artifactId>
        <version>${checkstyle.version}</version>
        <configuration>
          <configLocation>checkstyle.xml</configLocation>
        </configuration>
      </plugin>
      <plugin>
        <groupId>com.github.spotbugs</groupId>
        <artifactId>spotbugs-maven-plugin</artifactId>
        <version>${spotbugs.version}</version>
      </plugin>
      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <version>0.8.11</version>
        <executions>
          <execution>
            <goals><goal>prepare-agent</goal></goals>
          </execution>
          <execution>
            <id>report</id>
            <phase>verify</phase>
            <goals><goal>report</goal></goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```