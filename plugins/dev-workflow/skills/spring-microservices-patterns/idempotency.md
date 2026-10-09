# Idempotency in Kafka Consumers

## Problema
Kafka garantiza *at-least-once* delivery. Consumidores pueden recibir el mismo mensaje múltiples veces (rebalance, retry, crash tras procesar pero antes de commit).

## Solución: Deduplicación por Business Key

### Tabla de eventos procesados
```java
@Entity
@Table(name = "processed_events", indexes = {
    @Index(name = "idx_processed_event_id", columnList = "event_id", unique = true)
})
public class ProcessedEvent {
    @Id @GeneratedValue private Long id;

    @Column(nullable = false, length = 255, unique = true)
    private String eventId;  // Business key: orderId, paymentId, etc.

    @Column(nullable = false)
    private Instant processedAt = Instant.now();

    private String eventType;  // Para debugging
}
```

### Consumer Idempotente
```java
@Component
@RequiredArgsConstructor
public class OrderEventConsumer {
    private final OrderService orderService;
    private final ProcessedEventRepository processedEventRepository;

    @KafkaListener(
        topics = "order-events",
        groupId = "order-service",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void consume(ConsumerRecord<String, OrderEvent> record) {
        String eventId = record.key();  // Business key (orderId)
        OrderEvent event = record.value();

        // 1. Verificar si ya procesado (rápido, índice único)
        if (processedEventRepository.existsByEventId(eventId)) {
            log.debug("Event {} already processed, skipping", eventId);
            return;  // Ack automático (manual_immediate)
        }

        // 2. Procesar EN TRANSACCIÓN con marca de procesado
        try {
            processEvent(event);
            
            // 3. Marcar como procesado (misma transacción que lógica de negocio)
            processedEventRepository.save(new ProcessedEvent(eventId, event.getClass().getSimpleName()));
            
        } catch (Exception e) {
            log.error("Failed to process event {}", eventId, e);
            throw e;  // No ack → requeue / DLQ
        }
    }

    @Transactional
    protected void processEvent(OrderEvent event) {
        switch (event) {
            case OrderCreatedEvent e -> orderService.handleCreated(e);
            case OrderCancelledEvent e -> orderService.handleCancelled(e);
            // ...
        }
    }
}
```

### Configuración Kafka para Idempotencia
```yaml
spring:
  kafka:
    consumer:
      bootstrap-servers: localhost:9092
      group-id: order-service
      auto-offset-reset: earliest
      enable-auto-commit: false  # CRÍTICO: commit manual tras procesar OK
      isolation-level: read_committed  # Solo leer transacciones completadas
      properties:
        spring.json.trusted.packages: "*"
    listener:
      ack-mode: manual_immediate  # Ack tras return sin excepción
      missing-topics-fatal: false
    producer:
      transaction-id-prefix: order-service-tx  # Para transacciones Kafka
      properties:
        enable.idempotence: true  # Productor idempotente
```

### Factory para Container con Transacciones
```java
@Configuration
@EnableKafka
@RequiredArgsConstructor
public class KafkaConsumerConfig {
    private final KafkaProperties kafkaProperties;

    @Bean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, Object>> 
            kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, Object> factory = 
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.MANUAL_IMMEDIATE);
        factory.setBatchListener(false);
        return factory;
    }

    @Bean
    public ConsumerFactory<String, Object> consumerFactory() {
        return new DefaultKafkaConsumerFactory<>(kafkaProperties.buildConsumerProperties());
    }

    @Bean
    public KafkaTransactionManager<String, Object> kafkaTransactionManager() {
        return new KafkaTransactionManager<>(producerFactory());
    }

    @Bean
    public ProducerFactory<String, Object> producerFactory() {
        Map<String, Object> props = kafkaProperties.buildProducerProperties();
        props.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, "order-service-tx");
        props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        return new DefaultKafkaProducerFactory<>(props);
    }
}
```

## Idempotencia en Productores (Outbox Publisher)
```java
@Component
@RequiredArgsConstructor
public class OutboxEventPublisher {
    private final KafkaTemplate<String, String> kafkaTemplate;

    @Transactional("kafkaTransactionManager")
    @Scheduled(fixedDelay = 1000)
    public void publishPending() {
        List<OutboxEvent> pending = outboxRepository.findTop100ByPublishedAtIsNull();
        
        for (OutboxEvent event : pending) {
            // send() en transacción Kafka = exactly-once semantics
            kafkaTemplate.send(event.getEventType(), event.getAggregateId(), event.getPayload());
            
            event.setPublishedAt(Instant.now());
            outboxRepository.save(event);
        }
    }
}
```

## Patrones de Business Key

| Evento | Business Key (record.key()) | Por qué |
|--------|----------------------------|---------|
| OrderCreated | `orderId` | Una orden = un evento de creación |
| PaymentCompleted | `paymentId` | Un pago = una confirmación |
| InventoryReserved | `reservationId` | Una reserva = un evento |
| ShippingScheduled | `shipmentId` | Un envío = un evento |
| UserRegistered | `userId` | Un usuario = un registro |

**NOTA**: Si un mismo agregado genera múltiples eventos del mismo tipo (ej: `OrderStatusChanged`), usar `eventId = aggregateId + ":" + sequenceNumber` o UUID del evento.

## Testing Idempotencia
```java
@SpringBootTest
@Testcontainers
class OrderEventConsumerIdempotencyTest {

    @Autowired OrderEventConsumer consumer;
    @Autowired ProcessedEventRepository processedEvents;
    @MockBean OrderService orderService;

    @Test
    void consume_sameEventTwice_processesOnlyOnce() {
        // Given
        String eventId = "order-123";
        OrderEvent event = new OrderCreatedEvent(UUID.fromString(eventId), ...);
        ConsumerRecord<String, OrderEvent> record = new ConsumerRecord<>("topic", 0, 0, eventId, event);

        // When - Primera vez
        consumer.consume(record);
        
        // When - Segunda vez (duplicado)
        consumer.consume(record);

        // Then
        verify(orderService, times(1)).handleCreated(any());
        assertThat(processedEvents.count()).isEqualTo(1);
    }
}
```

## Verificación en Review
- **Idempotency-1**: ¿`enable-auto-commit: false` + `ack-mode: manual_immediate`?
- **Idempotency-2**: ¿`processed_events` table con índice único en `event_id`?
- **Idempotency-3**: ¿Verificación `existsByEventId` ANTES de procesar?
- **Idempotency-4**: ¿Marca de procesado EN MISMA TRANSACCIÓN que lógica de negocio?
- **Idempotency-5**: ¿Productor con `enable.idempotence: true` + `transactional.id`?