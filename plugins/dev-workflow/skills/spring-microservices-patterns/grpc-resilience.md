# gRPC Resilience - Timeouts, Retries, Circuit Breaker

## Problema
Llamadas gRPC síncronas entre microservicios: fallos en cascada, timeouts infinitos, recursos agotados.

## Solución: Configuración por método + Circuit Breaker

### Timeouts por método
```java
@GrpcClient("inventory-service")
private InventoryServiceGrpc.InventoryServiceBlockingStub inventoryStub;

public InventoryResponse checkStock(UUID productId, int quantity) {
    // Timeout TOTAL: 3 segundos (deadline)
    return inventoryStub
        .withDeadlineAfter(3, TimeUnit.SECONDS)
        // Espera si canal en TRANSIENT_FAILURE (reconexión)
        .withWaitForReady()
        .checkStock(CheckStockRequest.newBuilder()
            .setProductId(productId.toString())
            .setQuantity(quantity)
            .build());
}

public InventoryResponse reserveStock(UUID productId, int quantity) {
    // Timeout MÁS LARGO para operaciones de escritura
    return inventoryStub
        .withDeadlineAfter(10, TimeUnit.SECONDS)
        .withWaitForReady()
        .reserveStock(ReserveStockRequest.newBuilder()
            .setProductId(productId.toString())
            .setQuantity(quantity)
            .build());
}
```

### Retry Policy (Spring Cloud LoadBalancer / gRPC config)
```java
@Configuration
public class GrpcClientConfig {

    @Bean
    public GrpcClientConfigurer inventoryClientConfigurer() {
        return configurer -> configurer
            .service("inventory-service")
            // Retry para consultas (idempotentes)
            .method("CheckStock", methodConfig -> methodConfig
                .retryPolicy(RetryPolicy.newBuilder()
                    .setMaxAttempts(3)
                    .setInitialBackoff(Duration.ofMillis(100))
                    .setMaxBackoff(Duration.ofSeconds(1))
                    .setBackoffMultiplier(2.0)
                    .setRetryableStatusCodes(
                        Status.Code.UNAVAILABLE,
                        Status.Code.DEADLINE_EXCEEDED,
                        Status.Code.RESOURCE_EXHAUSTED
                    )
                    .build())
                .build())
            // NO retry para escrituras (no idempotentes sin idempotency key)
            .method("ReserveStock", methodConfig -> methodConfig
                .retryPolicy(RetryPolicy.newBuilder()
                    .setMaxAttempts(1)  // Sin retry
                    .build())
                .build())
            // Timeout global por método
            .method("CheckStock", methodConfig -> methodConfig
                .timeout(Duration.ofSeconds(3))
                .build())
            .method("ReserveStock", methodConfig -> methodConfig
                .timeout(Duration.ofSeconds(10))
                .build());
    }
}
```

### Circuit Breaker (Resilience4j + gRPC)
```java
@Configuration
public class GrpcCircuitBreakerConfig {

    @Bean
    public Registry<CircuitBreaker> circuitBreakerRegistry() {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom()
            .failureRateThreshold(50)                    // Abrir si 50% fallos
            .waitDurationInOpenState(Duration.ofSeconds(30))  // Esperar 30s antes de half-open
            .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
            .slidingWindowSize(10)                       // Últimas 10 llamadas
            .minimumNumberOfCalls(5)                     // Mínimo 5 llamadas para evaluar
            .permittedNumberOfCallsInHalfOpenState(3)    // 3 llamadas en half-open
            .recordExceptions(StatusRuntimeException.class)  // Solo gRPC errors
            .build();

        return CircuitBreakerRegistry.of(config);
    }
}
```

```java
@Service
@RequiredArgsConstructor
public class InventoryClient {
    private final InventoryServiceGrpc.InventoryServiceBlockingStub stub;
    private final CircuitBreaker circuitBreaker;

    public InventoryResponse checkStock(UUID productId, int quantity) {
        return circuitBreaker.executeSupplier(() -> 
            stub.withDeadlineAfter(3, TimeUnit.SECONDS)
                .withWaitForReady()
                .checkStock(CheckStockRequest.newBuilder()
                    .setProductId(productId.toString())
                    .setQuantity(quantity)
                    .build())
        );
    }
}
```

### Interceptor para métricas y logging
```java
@GrpcGlobalInterceptor
@Component
@RequiredArgsConstructor
public class GrpcMetricsInterceptor implements ServerInterceptor, ClientInterceptor {

    private final MeterRegistry meterRegistry;

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            ServerCall<ReqT, RespT> call, Metadata headers, ServerCallHandler<ReqT, RespT> next) {
        
        Timer.Sample sample = Timer.start(meterRegistry);
        String method = call.getMethodDescriptor().getFullMethodName();

        return new ForwardingServerCallListener.SimpleForwardingServerCallListener<ReqT>(
            next.startCall(new ForwardingServerCall.SimpleForwardingServerCall<ReqT, RespT>(call) {
                @Override
                public void close(Status status, Metadata trailers) {
                    sample.stop(Timer.builder("grpc.server.duration")
                        .tag("method", method)
                        .tag("status", status.getCode().name())
                        .register(meterRegistry));
                    super.close(status, trailers);
                }
            }), headers);
    }

    @Override
    public <ReqT, RespT> ClientCall<ReqT, RespT> interceptCall(
            MethodDescriptor<ReqT, RespT> method, CallOptions callOptions, Channel next) {
        
        Timer.Sample sample = Timer.start(meterRegistry);
        String methodName = method.getFullMethodName();

        return new ForwardingClientCall.SimpleForwardingClientCall<ReqT, RespT>(
            next.newCall(method, callOptions)) {
            @Override
            public void start(Listener<RespT> responseListener, Metadata headers) {
                super.start(new ForwardingClientCallListener.SimpleForwardingClientCallListener<RespT>(
                    responseListener) {
                    @Override
                    public void onClose(Status status, Metadata trailers) {
                        sample.stop(Timer.builder("grpc.client.duration")
                            .tag("method", methodName)
                            .tag("status", status.getCode().name())
                            .register(meterRegistry));
                        super.onClose(status, trailers);
                    }
                }, headers);
            }
        };
    }
}
```

### Health Check gRPC
```java
@Component
@RequiredArgsConstructor
public class GrpcHealthIndicator implements HealthIndicator {

    private final ManagedChannel inventoryChannel;
    private final ManagedChannel paymentChannel;

    @Override
    public Health health() {
        Health.Builder builder = Health.up();
        
        // Check inventory service
        Health inventoryHealth = checkChannel("inventory-service", inventoryChannel);
        builder.withDetail("inventory", inventoryHealth.getDetails());
        if (inventoryHealth.getStatus() != Status.UP) {
            builder.down();
        }

        // Check payment service
        Health paymentHealth = checkChannel("payment-service", paymentChannel);
        builder.withDetail("payment", paymentHealth.getDetails());
        if (paymentHealth.getStatus() != Status.UP) {
            builder.down();
        }

        return builder.build();
    }

    private Health checkChannel(String name, ManagedChannel channel) {
        try {
            // gRPC Health Checking Protocol
            HealthGrpc.HealthBlockingStub stub = HealthGrpc.newBlockingStub(channel);
            HealthCheckResponse response = stub.withDeadlineAfter(2, TimeUnit.SECONDS)
                .check(HealthCheckRequest.getDefaultInstance());
            
            if (response.getStatus() == HealthCheckResponse.ServingStatus.SERVING) {
                return Health.up().build();
            }
            return Health.down().withDetail("status", response.getStatus().name()).build();
        } catch (StatusRuntimeException e) {
            return Health.down(e).withDetail("error", e.getStatus().getCode().name()).build();
        }
    }
}
```

## Verificación en Review
- **gRPC-1**: ¿Todos los stubs usan `withDeadlineAfter()`?
- **gRPC-2**: ¿Retry policy configurada SOLO para métodos idempotentes?
- **gRPC-3**: ¿Circuit breaker en clientes críticos?
- **gRPC-4**: ¿Health check implementado para cada downstream?
- **gRPC-5**: ¿Métricas de latencia p50/p95/p99 expuestas?
- **gRPC-6**: ¿`withWaitForReady()` en stubs para manejar reconexión?