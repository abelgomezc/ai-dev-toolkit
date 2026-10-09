# Outbox Pattern - Eventos Confiables

## Problema
Publicar evento tras commit de transacción → si falla publicación, sistema inconsistente (entidad guardada, evento no publicado).

## Solución: Transactional Outbox
Escribir evento en tabla `outbox_events` EN LA MISMA TRANSACCIÓN que la entidad de negocio. Publisher separado lee outbox y publica a Kafka.

## Implementación

### Entidad OutboxEvent
```java
@Entity
@Table(name = "outbox_events", indexes = {
    @Index(name = "idx_outbox_unpublished", columnList = "published_at", where = "published_at IS NULL"),
    @Index(name = "idx_outbox_aggregate", columnList = "aggregate_type, aggregate_id")
})
public class OutboxEvent {
    @Id @GeneratedValue private UUID id;

    @Column(nullable = false, length = 100)
    private String aggregateType;  // "Order", "Payment", etc.

    @Column(nullable = false, length = 100)
    private String aggregateId;    // UUID del agregado

    @Column(nullable = false, length = 100)
    private String eventType;      // "OrderCreated", "PaymentCompleted"

    @Column(nullable = false, columnDefinition = "jsonb")
    private String payload;        // JSON serializado

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    private Instant publishedAt;   // null = pendiente

    @Column(length = 500)
    private String errorMessage;   // Para debugging reintentos fallidos

    @Version private Long version; // Optimistic locking
}
```

### Escritura en Outbox (en Service)
```java
@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;
    private final OutboxEventRepository outboxRepository;

    @Transactional
    public Order create(OrderCreateRequest request) {
        Order order = Order.from(request);
        Order saved = orderRepository.save(order);

        // Escribir evento en OUTBOX (misma transacción)
        OutboxEvent event = OutboxEvent.builder()
            .aggregateType("Order")
            .aggregateId(saved.getId().toString())
            .eventType("OrderCreated")
            .payload(toJson(new OrderCreatedEvent(saved.getId(), saved.getItems(), ...)))
            .build();
        outboxRepository.save(event);

        return saved;
    }

    @Transactional
    public void cancel(UUID orderId, String reason) {
        Order order = orderRepository.findById(orderId).orElseThrow();
        order.markCancelled(reason);
        orderRepository.save(order);

        outboxRepository.save(OutboxEvent.builder()
            .aggregateType("Order")
            .aggregateId(orderId.toString())
            .eventType("OrderCancelled")
            .payload(toJson(new OrderCancelledEvent(orderId, reason)))
            .build());
    }
}
```

### Publisher (Polling)
```java
@Component
@RequiredArgsConstructor
public class OutboxEventPublisher {
    private final OutboxEventRepository outboxRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Scheduled(fixedDelay = 1000, initialDelay = 5000)
    @Transactional
    public void publishPendingEvents() {
        List<OutboxEvent> pending = outboxRepository
            .findTop100ByPublishedAtIsNullOrderByCreatedAtAsc();

        for (OutboxEvent event : pending) {
            try {
                // Publicar a Kafka
                kafkaTemplate.send(
                    event.getEventType().toLowerCase(),  // topic
                    event.getAggregateId(),              // key para partición
                    event.getPayload()
                ).get(5, TimeUnit.SECONDS);  // Blocking wait para simplicidad

                // Marcar como publicado
                event.setPublishedAt(Instant.now());
                outboxRepository.save(event);

            } catch (Exception e) {
                log.error("Failed to publish outbox event {}", event.getId(), e);
                event.setErrorMessage(e.getMessage());
                outboxRepository.save(event);
                // No relanzar: continuar con siguiente evento
            }
        }
    }
}
```

### Alternativa: CDC con Debezium (Producción)
```yaml
# docker-compose.yml para Debezium
services:
  debezium:
    image: debezium/connect:2.5
    environment:
      BOOTSTRAP_SERVERS: kafka:9092
      GROUP_ID: debezium-connect
      CONFIG_STORAGE_TOPIC: debezium-configs
      OFFSET_STORAGE_TOPIC: debezium-offsets
      STATUS_STORAGE_TOPIC: debezium-status
      DATABASE_HOSTNAME: postgres
      DATABASE_PORT: 5432
      DATABASE_USER: postgres
      DATABASE_PASSWORD: postgres
      DATABASE_NAME: appdb
      DATABASE_INCLUDE_LIST: public.outbox_events
      TABLE_INCLUDE_LIST: public.outbox_events
      TRANSFORMS: outbox
      TRANSFORMS.OUTBOX.TYPE: io.debezium.transforms.outbox.EventRouter
      TRANSFORMS.OUTBOX.TABLE_FIELDS_ADDITIONAL_PLACEMENT: type:header:eventType
```

## Ventajas vs Desventajas

| Aspecto | Polling | Debezium CDC |
|---------|---------|--------------|
| Latencia | ~1s (configurable) | ~100ms |
| Complejidad | Baja (código propio) | Alta (infra extra) |
| Ordenamiento | Por createdAt | Por LSN (exacto) |
| Escalabilidad | Una instancia publisher | Distribuido |
| Dependencias | Solo Spring/Kafka | Debezium, Kafka Connect |

## Verificación en Review
- **Regla Outbox-1**: ¿Evento escrito en outbox EN MISMA TRANSACCIÓN que entidad?
- **Regla Outbox-2**: ¿Publisher marca `publishedAt` tras confirmar Kafka ACK?
- **Regla Outbox-3**: ¿Índice en `published_at IS NULL` para query eficiente?
- **Regla Outbox-4**: ¿Manejo de errores: `errorMessage` + reintento automático?
- **Regla Outbox-5**: ¿Idempotencia en consumidor (processed_events table)?