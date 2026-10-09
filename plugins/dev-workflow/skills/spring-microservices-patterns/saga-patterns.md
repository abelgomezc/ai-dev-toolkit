# Saga Patterns - Orquestada vs Coreografiada

## Cuándo usar cada una

| Criterio | Orquestada | Coreografiada |
|----------|------------|---------------|
| Número de pasos | > 3 | 2-4 |
| Complejidad compensaciones | Alta (diferentes por paso) | Baja (simétricas) |
| Acoplamiento | Centralizado (orchestrator conoce todos) | Descentralizado (eventos) |
| Debugging | Fácil (un lugar) | Difícil (trazas distribuidas) |
| Single point of failure | Orchestrator | Ninguno |
| Latencia | Menor (secuencial controlado) | Mayor (eventual) |

## Saga Orquestada - Implementación completa

### Orchestrator
```java
@Component
@RequiredArgsConstructor
public class OrderSagaOrchestrator {
    private final OrderRepository orderRepository;
    private final InventoryClient inventoryClient;
    private final PaymentClient paymentClient;
    private final ShippingClient shippingClient;
    private final SagaStateRepository sagaStateRepository;

    public Order createOrder(OrderCreateRequest request) {
        // 1. Crear orden en estado PENDING
        Order order = Order.from(request);
        order.setStatus(OrderStatus.PENDING);
        Order saved = orderRepository.save(order);

        // 2. Iniciar saga state
        SagaState saga = SagaState.builder()
            .orderId(saved.getId())
            .currentStep(SagaStep.INVENTORY_RESERVATION)
            .status(SagaStatus.IN_PROGRESS)
            .build();
        sagaStateRepository.save(saga);

        // 3. Ejecutar pasos
        executeSaga(saved);
        return saved;
    }

    private void executeSaga(Order order) {
        try {
            // Paso 1: Inventario
            updateSagaStep(order.getId(), SagaStep.INVENTORY_RESERVATION);
            inventoryClient.reserve(order.getItems());
            order.markInventoryReserved();
            orderRepository.save(order);

            // Paso 2: Pago
            updateSagaStep(order.getId(), SagaStep.PAYMENT_CHARGE);
            paymentClient.charge(order.getPaymentId(), order.getTotal());
            order.markPaymentCompleted();
            orderRepository.save(order);

            // Paso 3: Envío
            updateSagaStep(order.getId(), SagaStep.SHIPPING_SCHEDULE);
            shippingClient.schedule(order.getShippingAddress());
            order.markShippingScheduled();
            orderRepository.save(order);

            // Completado
            order.confirm();
            orderRepository.save(order);
            completeSaga(order.getId());

        } catch (Exception e) {
            compensate(order, e);
        }
    }

    private void compensate(Order order, Exception cause) {
        log.warn("Saga compensation started for order {}", order.getId(), cause);
        
        List<SagaStep> completedSteps = getCompletedSteps(order.getId());
        Collections.reverse(completedSteps);

        for (SagaStep step : completedSteps) {
            try {
                switch (step) {
                    case SHIPPING_SCHEDULE -> shippingClient.cancel(order.getShippingId());
                    case PAYMENT_CHARGE -> paymentClient.refund(order.getPaymentId());
                    case INVENTORY_RESERVATION -> inventoryClient.release(order.getItems());
                }
            } catch (Exception e) {
                log.error("Compensation failed for step {}", step, e);
                // Alertar para intervención manual
                alertService.sendAlert("Saga compensation failed: " + order.getId() + " step " + step);
            }
        }

        order.markCancelled();
        orderRepository.save(order);
        failSaga(order.getId(), cause.getMessage());
    }
}
```

### Saga State Persistence
```java
@Entity
@Table(name = "saga_states")
public class SagaState {
    @Id private UUID orderId;
    
    @Enumerated(EnumType.STRING)
    private SagaStep currentStep;
    
    @Enumerated(EnumType.STRING)
    private SagaStatus status;  // IN_PROGRESS, COMPLETED, FAILED, COMPENSATING
    
    private String errorMessage;
    private Instant startedAt;
    private Instant completedAt;
    
    @ElementCollection
    @CollectionTable(name = "saga_completed_steps", joinColumns = @JoinColumn(name = "order_id"))
    @Column(name = "step")
    @Enumerated(EnumType.STRING)
    private Set<SagaStep> completedSteps = EnumSet.noneOf(SagaStep.class);
}

public enum SagaStep {
    INVENTORY_RESERVATION, PAYMENT_CHARGE, SHIPPING_SCHEDULE
}

public enum SagaStatus {
    IN_PROGRESS, COMPLETED, FAILED, COMPENSATING
}
```

## Saga Coreografiada - Implementación completa

### Eventos de dominio
```java
public record OrderCreatedEvent(
    UUID orderId,
    List<OrderItem> items,
    ShippingAddress address,
    PaymentInfo payment
) {}

public record InventoryReservedEvent(UUID orderId) {}
public record InventoryFailedEvent(UUID orderId, String reason) {}
public record PaymentCompletedEvent(UUID orderId, String transactionId) {}
public record PaymentFailedEvent(UUID orderId, String reason) {}
public record ShippingScheduledEvent(UUID orderId, String trackingNumber) {}
public record ShippingFailedEvent(UUID orderId, String reason) {}
```

### Order Service (emisor inicial)
```java
@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository repository;
    private final EventPublisher eventPublisher;

    public Order create(OrderCreateRequest request) {
        Order order = Order.from(request);
        order.setStatus(OrderStatus.PENDING);
        Order saved = repository.save(order);

        eventPublisher.publish(new OrderCreatedEvent(
            saved.getId(),
            saved.getItems(),
            saved.getShippingAddress(),
            saved.getPaymentInfo()
        ));
        return saved;
    }

    @EventListener
    @Transactional
    public void handle(InventoryReservedEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.setStatus(OrderStatus.INVENTORY_RESERVED);
        repository.save(order);
        
        eventPublisher.publish(new PaymentRequestedEvent(order.getId(), order.getTotal()));
    }

    @EventListener
    @Transactional
    public void handle(InventoryFailedEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancellationReason("Inventory: " + event.reason());
        repository.save(order);
    }

    @EventListener
    @Transactional
    public void handle(PaymentCompletedEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.setStatus(OrderStatus.PAYMENT_COMPLETED);
        order.setPaymentTransactionId(event.transactionId());
        repository.save(order);
        
        eventPublisher.publish(new ShippingRequestedEvent(order.getId(), order.getShippingAddress()));
    }

    @EventListener
    @Transactional
    public void handle(PaymentFailedEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancellationReason("Payment: " + event.reason());
        repository.save(order);
        
        // Compensación: liberar inventario
        eventPublisher.publish(new InventoryReleaseRequestedEvent(order.getId(), order.getItems()));
    }

    @EventListener
    @Transactional
    public void handle(ShippingScheduledEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.setStatus(OrderStatus.CONFIRMED);
        order.setTrackingNumber(event.trackingNumber());
        repository.save(order);
    }
}
```

### Inventory Service (consumidor)
```java
@Service
@RequiredArgsConstructor
public class InventoryEventHandler {
    private final InventoryService inventoryService;
    private final EventPublisher eventPublisher;
    private final ProcessedEventRepository processedEvents;

    @EventListener
    @Transactional
    public void handle(OrderCreatedEvent event) {
        // Idempotencia
        if (processedEvents.existsByEventId(event.orderId().toString())) return;

        try {
            inventoryService.reserve(event.items());
            eventPublisher.publish(new InventoryReservedEvent(event.orderId()));
        } catch (InsufficientStockException e) {
            eventPublisher.publish(new InventoryFailedEvent(event.orderId(), e.getMessage()));
        } finally {
            processedEvents.save(new ProcessedEvent(event.orderId().toString(), Instant.now()));
        }
    }

    @EventListener
    @Transactional
    public void handle(InventoryReleaseRequestedEvent event) {
        inventoryService.release(event.items());
    }
}
```

## Testing Sagas

### Test Orquestada
```java
@SpringBootTest
@Testcontainers
class OrderSagaOrchestratorIntegrationTest {

    @Autowired OrderSagaOrchestrator orchestrator;
    @MockBean InventoryClient inventoryClient;
    @MockBean PaymentClient paymentClient;
    @MockBean ShippingClient shippingClient;

    @Test
    void createOrder_success_completesAllSteps() {
        // Given
        OrderCreateRequest request = new OrderCreateRequest(...);
        when(inventoryClient.reserve(any())).thenReturn(ReservationResult.success());
        when(paymentClient.charge(any(), any())).thenReturn(ChargeResult.success("txn-123"));
        when(shippingClient.schedule(any())).thenReturn(ShippingResult.success("TRACK-123"));

        // When
        Order order = orchestrator.createOrder(request);

        // Then
        assertThat(order.getStatus()).isEqualTo(OrderStatus.CONFIRMED);
        verify(inventoryClient).reserve(any());
        verify(paymentClient).charge(any(), any());
        verify(shippingClient).schedule(any());
    }

    @Test
    void createOrder_paymentFails_compensatesInventory() {
        // Given
        when(inventoryClient.reserve(any())).thenReturn(ReservationResult.success());
        when(paymentClient.charge(any(), any())).thenThrow(new PaymentDeclinedException());

        // When/Then
        assertThatThrownBy(() -> orchestrator.createOrder(request))
            .isInstanceOf(SagaFailedException.class);

        verify(inventoryClient).release(any());  // Compensación ejecutada
        verify(shippingClient, never()).schedule(any());
    }
}
```

### Test Coreografiada
```java
@SpringBootTest
@Testcontainers
class OrderSagaChoreographyIntegrationTest {

    @Autowired OrderService orderService;
    @Autowired EventPublisher eventPublisher;
    @MockBean InventoryClient inventoryClient;

    @Test
    void orderCreated_triggersInventoryReservation() {
        // Given
        when(inventoryClient.reserve(any())).thenReturn(ReservationResult.success());

        // When
        Order order = orderService.create(new OrderCreateRequest(...));

        // Then - Verificar evento publicado
        ArgumentCaptor<OrderCreatedEvent> captor = ArgumentCaptor.forClass(OrderCreatedEvent.class);
        verify(eventPublisher).publish(captor.capture());
        assertThat(captor.getValue().orderId()).isEqualTo(order.getId());

        // Simular respuesta de Inventory
        eventPublisher.publish(new InventoryReservedEvent(order.getId()));

        // Verificar estado final
        Order updated = orderRepository.findById(order.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(OrderStatus.INVENTORY_RESERVED);
    }
}
```