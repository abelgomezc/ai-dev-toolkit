# Eval Case: Bug - NullPointerException in Spring Service

## Plugin
dev-workflow

## Escenario
En una aplicación Spring Boot existente, un servicio lanza `NullPointerException` cuando se procesa una orden sin cliente asociado. El bug fue detectado en producción y necesita fixing urgente.

## Input (Prompt)
```
Bug: OrderService.processOrder() lanza NullPointerException cuando order.getCustomer() es null.
Stack trace:
  at com.example.order.OrderService.processOrder(OrderService.java:78)
  at com.example.order.OrderController.createOrder(OrderController.java:45)

Código actual:
```java
public Order processOrder(Order order) {
    String customerName = order.getCustomer().getName();  // Line 78 - NPE aquí
    order.setProcessedBy(customerName);
    return orderRepository.save(order);
}
```

Fix: Handle null customer gracefully, log warning, set processedBy to "SYSTEM".
Mantener test de regresión que verifique el fix.
```

## Métricas de Evaluación

| Métrica | CON Plugin | SIN Plugin (baseline) |
|---------|-----------|----------------------|
| Root cause analysis | ✅ identifica NPE en línea 78 | ⚠️ puede fix superficial |
| Fix quality | ✅ null check + logging + fallback | ⚠️ solo null check |
| Test de regresión | ✅ test que verifica null customer path | ⚠️ test pueden ser incompletos |
| Review findings | 0/0 | 0-1/1-3 |
| Code quality (clean code) | ✅ Optional, early return, logging | ⚠️ puede ser menos limpio |
| Tiempo estimado | 3-5 min | 5-10 min |

## Expected Outcome
- **CON Plugin**: Fix con null check explícito, logging con SLF4J, fallback "SYSTEM", test con @Test void processOrder_nullCustomer_setsSystemUser()
- **SIN Plugin**: Fix rápido pero posiblemente sin logging, test incompleto

## Difficulty: Easy
## Est. Tokens: 25,000 (CON) vs 20,000 (SIN)