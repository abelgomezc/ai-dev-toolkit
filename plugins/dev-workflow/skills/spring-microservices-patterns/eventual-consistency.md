# Eventual Consistency Patterns

## Problema
En microservicios, consistencia fuerte (ACID) no es posible entre servicios. Se acepta consistencia eventual con garantías de convergencia.

## Patrones y Verificaciones

### 1. Event Sourcing + CQRS (para agregados complejos)
```java
// Command Side - Escribe eventos
@Entity
public class Order {
    @Id private UUID id;
    private List<DomainEvent> uncommittedEvents = new ArrayList<>();

    public void create(OrderCreateRequest request) {
        // Validaciones de negocio
        if (request.items().isEmpty()) throw new DomainException("Empty order");
        
        // Aplicar evento (mutación de estado)
        apply(new OrderCreatedEvent(id, request.items(), request.address(), request.payment()));
    }

    public void cancel(String reason) {
        if (status == OrderStatus.CONFIRMED) throw new DomainException("Cannot cancel confirmed order");
        apply(new OrderCancelledEvent(id, reason));
    }

    private void apply(DomainEvent event) {
        // Mutar estado basado en evento
        when(event);
        uncommittedEvents.add(event);
    }

    private void when(OrderCreatedEvent e) { this.status = OrderStatus.PENDING; this.items = e.items(); }
    private void when(OrderCancelledEvent e) { this.status = OrderStatus.CANCELLED; }

    public List<DomainEvent> getUncommittedEvents() { return uncommittedEvents; }
    public void markEventsCommitted() { uncommittedEvents.clear(); }
}

// Repository guarda eventos
@Repository
public class OrderEventStore {
    public void save(Order order) {
        for (DomainEvent event : order.getUncommittedEvents()) {
            eventStore.append(event);
        }
        order.markEventsCommitted();
    }
}

// Query Side - Proyecciones read-only
@Entity
@Table(name = "order_views")
public class OrderView {
    @Id private UUID id;
    private String customerEmail;
    private OrderStatus status;
    private BigDecimal total;
    private Instant createdAt;
    // Optimizado para queries: sin joins, denormalizado
}
```

### 2. Read Model Projections (Event Handlers)
```java
@Component
@RequiredArgsConstructor
public class OrderProjectionHandler {
    private final OrderViewRepository viewRepository;

    @EventListener
    @Transactional
    public void handle(OrderCreatedEvent event) {
        OrderView view = OrderView.builder()
            .id(event.orderId())
            .customerEmail(event.customerEmail())
            .status(OrderStatus.PENDING)
            .total(event.total())
            .createdAt(Instant.now())
            .build();
        viewRepository.save(view);
    }

    @EventListener
    @Transactional
    public void handle(OrderConfirmedEvent event) {
        OrderView view = viewRepository.findById(event.orderId()).orElseThrow();
        view.setStatus(OrderStatus.CONFIRMED);
        view.setConfirmedAt(Instant.now());
        viewRepository.save(view);
    }

    @EventListener
    @Transactional
    public void handle(OrderCancelledEvent event) {
        OrderView view = viewRepository.findById(event.orderId()).orElseThrow();
        view.setStatus(OrderStatus.CANCELLED);
        view.setCancelledAt(Instant.now());
        viewRepository.save(view);
    }
}
```

### 3. Reconciliation Jobs (Detección de deriva)
```java
@Component
@RequiredArgsConstructor
public class OrderReconciliationJob {
    private final OrderRepository orderRepository;
    private final InventoryClient inventoryClient;
    private final PaymentClient paymentClient;
    private final AlertService alertService;

    @Scheduled(cron = "0 */15 * * * *")  // Cada 15 min
    public void reconcilePendingOrders() {
        List<Order> pending = orderRepository.findByStatusIn(
            OrderStatus.PENDING, OrderStatus.INVENTORY_RESERVED, OrderStatus.PAYMENT_COMPLETED
        );

        for (Order order : pending) {
            reconcileOrder(order);
        }
    }

    private void reconcileOrder(Order order) {
        List<ReconciliationIssue> issues = new ArrayList<>();

        // Verificar inventario
        if (order.getStatus() == OrderStatus.INVENTORY_RESERVED) {
            boolean reserved = inventoryClient.verifyReservation(order.getItems());
            if (!reserved) {
                issues.add(new ReconciliationIssue("INVENTORY_RELEASED", "Reservation lost"));
            }
        }

        // Verificar pago
        if (order.getStatus() == OrderStatus.PAYMENT_COMPLETED) {
            boolean charged = paymentClient.verifyCharge(order.getPaymentId());
            if (!charged) {
                issues.add(new ReconciliationIssue("PAYMENT_FAILED", "Charge not found"));
            }
        }

        if (!issues.isEmpty()) {
            alertService.sendAlert(ReconciliationAlert.builder()
                .orderId(order.getId())
                .issues(issues)
                .severity(issues.size() > 1 ? AlertSeverity.CRITICAL : AlertSeverity.WARNING)
                .build());
        }
    }
}
```

### 4. Versionado Optimista para Concurrencia
```java
@Entity
public class Order {
    @Version private Long version;  // Optimistic locking

    public void confirm() {
        if (status != OrderStatus.PAYMENT_COMPLETED) {
            throw new IllegalStateException("Order not ready for confirmation");
        }
        this.status = OrderStatus.CONFIRMED;
    }
}

// Service maneja conflicto
@Service
public class OrderService {
    @Transactional
    public void confirm(UUID orderId) {
        try {
            Order order = repository.findById(orderId).orElseThrow();
            order.confirm();
            repository.save(order);  // Lanza OptimisticLockingFailureException si version cambió
        } catch (OptimisticLockingFailureException e) {
            throw new ConcurrencyException("Order modified concurrently, please retry");
        }
    }
}
```

### 5. Saga State Machine (Verificación de estado)
```java
public enum SagaState {
    STARTED,
    INVENTORY_RESERVED,
    PAYMENT_COMPLETED,
    SHIPPING_SCHEDULED,
    COMPLETED,
    COMPENSATING,
    FAILED
}

@Entity
public class OrderSaga {
    @Id private UUID orderId;
    @Enumerated(EnumType.STRING) private SagaState state;
    private Set<SagaState> completedSteps = EnumSet.noneOf(SagaState.class);
    private String failureReason;

    public void recordStep(SagaState step) {
        if (!canTransitionTo(step)) {
            throw new IllegalStateException("Invalid transition: " + state + " -> " + step);
        }
        completedSteps.add(step);
        this.state = step;
    }

    public void startCompensation(String reason) {
        this.state = SagaState.COMPENSATING;
        this.failureReason = reason;
    }

    public void markFailed() {
        this.state = SagaState.FAILED;
    }

    private boolean canTransitionTo(SagaState next) {
        return switch (state) {
            case STARTED -> next == SagaState.INVENTORY_RESERVED;
            case INVENTORY_RESERVED -> next == SagaState.PAYMENT_COMPLETED;
            case PAYMENT_COMPLETED -> next == SagaState.SHIPPING_SCHEDULED;
            case SHIPPING_SCHEDULED -> next == SagaState.COMPLETED;
            case COMPLETED -> false;
            case COMPENSATING, FAILED -> false;
        };
    }
}
```

## Verificación de Consistencia Eventual

### Métricas a Exponer
```java
@Component
public class ConsistencyMetrics {
    private final MeterRegistry registry;
    private final OrderRepository orderRepository;

    @Scheduled(fixedDelay = 60000)
    public void recordConsistencyMetrics() {
        long pending = orderRepository.countByStatus(OrderStatus.PENDING);
        long stuck = orderRepository.countStaleOrders(Duration.ofHours(1));  // >1h sin avanzar
        
        Gauge.builder("orders.pending", pending).register(registry);
        Gauge.builder("orders.stuck", stuck).register(registry);
        
        if (stuck > 0) {
            // Alertar: órdenes atascadas en estado intermedio
        }
    }
}
```

### Tests de Consistencia
```java
@SpringBootTest
@Testcontainers
class EventualConsistencyIntegrationTest {

    @Autowired OrderService orderService;
    @Autowired OrderViewRepository viewRepository;
    @Autowired EventPublisher eventPublisher;

    @Test
    void orderCreated_viewProjectionEventuallyConsistent() {
        // Given
        Order order = orderService.create(new OrderCreateRequest(...));

        // When - Publicar evento (simula async processing)
        eventPublisher.publish(new OrderCreatedEvent(order.getId(), ...));

        // Then - Eventualmente consistente (polling)
        Awaitility.await()
            .atMost(5, TimeUnit.SECONDS)
            .pollInterval(100, TimeUnit.MILLISECONDS)
            .untilAsserted(() -> {
                OrderView view = viewRepository.findById(order.getId()).orElseThrow();
                assertThat(view.getStatus()).isEqualTo(OrderStatus.PENDING);
            });
    }

    @Test
    void concurrentUpdates_optimisticLockingPreventsLostUpdates() {
        // Given
        Order order = orderService.create(...);
        
        // When - Dos hilos intentan confirmar simultáneamente
        ExecutorService executor = Executors.newFixedThreadPool(2);
        List<Future<Void>> futures = List.of(
            executor.submit(() -> { orderService.confirm(order.getId()); return null; }),
            executor.submit(() -> { orderService.confirm(order.getId()); return null; })
        );

        // Then - Uno falla con ConcurrencyException
        long successCount = futures.stream()
            .map(f -> { try { f.get(); return true; } catch (Exception e) { return false; } })
            .filter(b -> b).count();
        
        assertThat(successCount).isEqualTo(1);
    }
}
```

## Verificación en Review
- **EC-1**: ¿Proyecciones read-only actualizadas via event handlers?
- **EC-2**: ¿Reconciliation job periódico para detectar deriva?
- **EC-3**: ¿Optimistic locking (`@Version`) en agregados con concurrencia?
- **EC-4**: ¿Saga state machine con transiciones válidas?
- **EC-5**: ¿Métricas de órdenes "atascadas" expuestas y alertadas?
- **EC-6**: ¿Tests de consistencia eventual con Awaitility/polling?