# Spring Microservices Patterns Skill

## Cuándo usarlo
- Arquitectura de microservicios con Spring Boot 3.x + Kafka + gRPC
- Diseño de nuevas funcionalidades distribuidas
- Revisión de implementaciones existentes (Reviewer cita reglas)

## Cuándo NO usarlo
- Monolitos modulares (usar stack-java-spring)
- Serverless functions / FaaS
- Stacks no-Java

## Descripción
Patrones de nivel experto para microservicios con Spring: Saga (orquestada/coreografiada), Outbox, Idempotencia, Dead Letter, gRPC timeouts/retry, Consistencia eventual. Cada patrón incluye antipatrón y código verificable.

## Archivos de referencia
- `saga-patterns.md` — Saga orquestada vs coreografiada con código
- `outbox-pattern.md` — Transactional Outbox con Kafka
- `idempotency.md` — Idempotencia en consumidores Kafka
- `grpc-resilience.md` — Timeouts, retries, circuit breaker en gRPC
- `eventual-consistency.md` — Patrones y verificaciones

## Reglas verificables

### Regla 1: Saga para transacciones distribuidas (no 2PC)
**Orquestada** (preferida para flujos complejos, >3 pasos, compensaciones complejas):
```java
// BUENO - Orchestrator coordina, cada paso tiene compensación
@Component
public class OrderSagaOrchestrator {
    private final OrderService orderService;
    private final PaymentClient paymentClient;
    private final InventoryClient inventoryClient;
    private final ShippingClient shippingClient;

    public Order createOrder(OrderCreateRequest request) {
        Order order = orderService.createPending(request);
        try {
            // Paso 1: Reservar inventario
            inventoryClient.reserve(order.getItems());
            order.markInventoryReserved();

            // Paso 2: Cobrar pago
            paymentClient.charge(order.getPaymentId(), order.getTotal());
            order.markPaymentCompleted();

            // Paso 3: Confirmar envío
            shippingClient.schedule(order.getShippingAddress());
            order.markShippingScheduled();

            order.confirm();
            return orderService.save(order);
        } catch (Exception e) {
            compensate(order);  // Ejecuta compensaciones en orden inverso
            throw new SagaFailedException("Order saga failed", e);
        }
    }

    private void compensate(Order order) {
        if (order.isShippingScheduled()) shippingClient.cancel(order.getShippingId());
        if (order.isPaymentCompleted()) paymentClient.refund(order.getPaymentId());
        if (order.isInventoryReserved()) inventoryClient.release(order.getItems());
        order.markCancelled();
        orderService.save(order);
    }
}
```

**Coreografiada** (eventos, pocos pasos, compensaciones simples):
```java
// BUENO - Eventos de dominio, cada servicio reacciona
@Service
public class OrderService {
    public Order create(OrderCreateRequest request) {
        Order order = Order.from(request);
        order.markPending();
        Order saved = repository.save(order);
        eventPublisher.publish(new OrderCreatedEvent(saved.getId(), saved.getItems()));
        return saved;
    }

    @EventListener
    public void handle(InventoryReservedEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.markInventoryReserved();
        repository.save(order);
        eventPublisher.publish(new PaymentRequestedEvent(order.getId(), order.getTotal()));
    }

    @EventListener
    public void handle(PaymentCompletedEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.markPaymentCompleted();
        repository.save(order);
        eventPublisher.publish(new ShippingRequestedEvent(order.getId(), order.getAddress()));
    }

    @EventListener
    public void handle(InventoryFailedEvent event) {
        Order order = repository.findById(event.orderId()).orElseThrow();
        order.markCancelled("Inventory unavailable");
        repository.save(order);
    }
}
```

**Antipatrón: 2PC / Distributed Transactions**
```java
// MALO - Two-Phase Commit (no soportado bien en microservicios, blocking, single point of failure)
@Transactional
public Order create(OrderCreateRequest request) {
    Order order = repository.save(Order.from(request));
    inventoryClient.reserve(order.getItems());  // Llamada remota EN transacción
    paymentClient.charge(order.getPaymentId()); // Llamada remota EN transacción
    return order;
    // Problemas: locks distribuidos, timeout cascada, no escalable
}
```

### Regla 2: Transactional Outbox para eventos confiables
```java
// BUENO - Outbox table en misma transacción que entidad
@Entity
@Table(name = "orders")
public class Order {
    // ... campos ...
    
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
    private List<OutboxEvent> outboxEvents = new ArrayList<>();
}

@Entity
@Table(name = "outbox_events")
public class OutboxEvent {
    @Id @GeneratedValue private UUID id;
    private String aggregateType;
    private String aggregateId;
    private String eventType;
    private String payload;  // JSON
    private Instant createdAt;
    private Instant publishedAt;  // null = pendiente
    @ManyToOne private Order order;
}

// Publisher separado (polling o CDC Debezium)
@Component
@RequiredArgsConstructor
public class OutboxEventPublisher {
    private final OutboxEventRepository outboxRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;

    @Scheduled(fixedDelay = 1000)
    @Transactional
    public void publishPending() {
        List<OutboxEvent> pending = outboxRepository.findTop100ByPublishedAtIsNullOrderByCreatedAtAsc();
        for (OutboxEvent event : pending) {
            kafkaTemplate.send(event.getEventType(), event.getAggregateId(), event.getPayload())
                .whenComplete((result, ex) -> {
                    if (ex == null) {
                        event.setPublishedAt(Instant.now());
                        outboxRepository.save(event);
                    }
                });
        }
    }
}
```

**Antipatrón: Publicar evento AFUERA de transacción**
```java
// MALO - Evento publicado tras commit, si falla → inconsistencia
@Transactional
public Order create(OrderCreateRequest request) {
    Order order = repository.save(Order.from(request));
    // commit ocurre aquí
    eventPublisher.publish(new OrderCreatedEvent(order.getId()));  // FALLA: si esto falla, no hay evento
    return order;
}
```

### Regla 3: Idempotencia en consumidores Kafka
```java
// BUENO - Deduplicación por business key + estado
@Component
@RequiredArgsConstructor
public class OrderEventConsumer {
    private final OrderService orderService;
    private final ProcessedEventRepository processedEventRepository;

    @KafkaListener(topics = "order-events", groupId = "order-service")
    public void consume(ConsumerRecord<String, OrderEvent> record) {
        String eventId = record.key();  // Business key: orderId
        
        // Verificar si ya procesado (idempotency key)
        if (processedEventRepository.existsByEventId(eventId)) {
            log.info("Event {} already processed, skipping", eventId);
            return;
        }

        try {
            OrderEvent event = record.value();
            orderService.handleEvent(event);
            
            // Marcar como procesado EN MISMA TRANSACCIÓN que la lógica de negocio
            processedEventRepository.save(new ProcessedEvent(eventId, Instant.now()));
        } catch (Exception e) {
            log.error("Failed to process event {}", eventId, e);
            throw e;  // Requeue / DLQ
        }
    }
}
```

**Antipatrón: Sin idempotencia**
```java
// MALO - Procesa duplicados, efectos secundarios múltiples
@KafkaListener(topics = "order-events")
public void consume(OrderEvent event) {
    orderService.chargePayment(event.getOrderId());  // Cobra doble si reintento
    orderService.reserveInventory(event.getItems()); // Reserva doble
}
```

### Regla 4: Dead Letter Queue (DLQ) para mensajes fallidos
```yaml
# application.yml - Configuración Kafka con DLQ
spring:
  kafka:
    consumer:
      bootstrap-servers: localhost:9092
      group-id: order-service
      auto-offset-reset: earliest
      enable-auto-commit: false  # Manual commit tras procesar OK
      properties:
        spring.json.trusted.packages: "*"
    listener:
      ack-mode: manual_immediate
      missing-topics-fatal: false
```

```java
// BUENO - Error handler envía a DLQ, no reintenta infinitamente
@Component
@RequiredArgsConstructor
public class KafkaErrorHandler {
    private final KafkaTemplate<String, String> dlqTemplate;

    @Bean
    public CommonErrorHandler errorHandler() {
        return new CommonErrorHandler() {
            @Override
            public void handleRemaining(Exception thrownException, List<ConsumerRecord<?, ?>> records, 
                                        Consumer<?, ?> consumer, MessageListenerContainer container) {
                for (ConsumerRecord<?, ?> record : records) {
                    // Enviar a DLQ con headers de error
                    dlqTemplate.send("order-events.DLQ", record.key(), record.value())
                        .whenComplete((r, ex) -> {
                            if (ex != null) log.error("Failed to send to DLQ", ex);
                        });
                }
            }
        };
    }
}
```

### Regla 5: gRPC Resilience (timeouts, retries, circuit breaker)
```java
// BUENO - Configuración resiliente por método
@GrpcClient("inventory-service")
private InventoryServiceGrpc.InventoryServiceBlockingStub inventoryStub;

public InventoryResponse checkStock(UUID productId, int quantity) {
    return inventoryStub
        .withDeadlineAfter(3, TimeUnit.SECONDS)  // Timeout total
        .withWaitForReady()                      // Espera si canal en TRANSIENT_FAILURE
        .checkStock(CheckStockRequest.newBuilder()
            .setProductId(productId.toString())
            .setQuantity(quantity)
            .build());
}

// Retry policy por método (GrpcClientConfigurer o Spring Cloud LoadBalancer)
@Configuration
public class GrpcClientConfig {
    @Bean
    public GrpcClientConfigurer inventoryClientConfigurer() {
        return configurer -> configurer
            .service("inventory-service")
            .method("CheckStock", methodConfig -> methodConfig
                .retryPolicy(RetryPolicy.newBuilder()
                    .setMaxAttempts(3)
                    .setInitialBackoff(Duration.ofMillis(100))
                    .setMaxBackoff(Duration.ofSeconds(1))
                    .setBackoffMultiplier(2.0)
                    .setRetryableStatusCodes(Status.UNAVAILABLE, Status.DEADLINE_EXCEEDED)
                    .build())
                .build());
    }
}
```

**Antipatrón: Sin timeouts / retries infinitos**
```java
// MALO - Bloqueo indefinido si servicio downstream caído
public InventoryResponse checkStock(UUID productId, int quantity) {
    return inventoryStub.checkStock(request);  // Sin deadline, sin retry policy
}
```

### Regla 6: Consistencia eventual - Verificación y compensación
```java
// BUENO - Reconciliation job periódico
@Scheduled(cron = "0 */15 * * * *")  // Cada 15 min
public void reconcileOrders() {
    List<Order> pending = orderRepository.findByStatusIn(
        OrderStatus.PENDING, OrderStatus.INVENTORY_RESERVED
    );
    
    for (Order order : pending) {
        // Verificar estado real en servicios downstream
        boolean inventoryOk = inventoryClient.verifyReservation(order.getItems());
        boolean paymentOk = paymentClient.verifyCharge(order.getPaymentId());
        
        if (!inventoryOk || !paymentOk) {
            // Compensar o alertar
            alertService.sendAlert("Order " + order.getId() + " inconsistent");
        }
    }
}
```

## Verificación en Review
- **Regla 1**: ¿Saga orquestada/coreografiada usada? ¿Compensaciones implementadas?
- **Regla 2**: ¿Outbox table + publisher? ¿Eventos en misma transacción?
- **Regla 3**: ¿Consumidor verifica `ProcessedEventRepository` antes de procesar?
- **Regla 4**: ¿DLQ configurado? ¿`enable-auto-commit: false` + manual ack?
- **Regla 5**: ¿gRPC stubs con `withDeadlineAfter`? ¿Retry policy configurada?
- **Regla 6**: ¿Reconciliation job existe para consistencia eventual?