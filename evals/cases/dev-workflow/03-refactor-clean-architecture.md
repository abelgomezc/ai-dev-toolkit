# Eval Case: Refactor - Extract Service Pattern

## Plugin
dev-workflow

## Escenario
Un controller monolítico en Spring Boot 3.x tiene 400+ líneas y mezcla lógica de negocio, validación y persistencia. El equipo solicita refactor a arquitectura limpia (hexagonal/clean architecture).

## Input (Prompt)
```
Refactor: OrderController.java tiene 432 líneas con lógica de negocio mezclada.

Extract pattern:
1. Create OrderService (business logic), OrderMapper (DTO ↔ Entity), OrderValidator (validation)
2. Controller becomes thin: delegate to Service, return ResponseEntity
3. Apply Spring patterns: @Service, @Component, dependency injection
4. No cambios en behavior (behavior-preserving refactor)
5. Add unit tests for new Service and Validator
6. Migration strategy if API changes

Current file: OrderController.java (432 lines) - contains 5 endpoints, validation inline, repository calls.
```

## Métricas de Evaluación

| Métrica | CON Plugin | SIN Plugin (baseline) |
|---------|-----------|----------------------|
| Architecture (Clean Hexagonal) | ✅ separa Service/Mapper/Validator | ⚠️ refactorización parcial |
| Behavior preservation | ✅ tests existentes pasan | ⚠️ posible breaking changes |
| Tests unitarios nuevos | 5+ para Service + Validator | 2-3 |
| Review findings (major) | 0-1 | 2-5 |
| Cobertura de líneas extraídas | 100% | 60-80% |
| Documentation (migration strategy) | ✅ incluye | ⚠️ omitido |

## Expected Outcome
- **CON Plugin**: OrderController (thin), OrderService (business logic), OrderMapper (MapStruct o manual), OrderValidator, 7+ tests, migration strategy documented
- **SIN Plugin**: Refactor incompleto, tests faltantes, posible breaking changes

## Difficulty: Hard
## Est. Tokens: 65,000 (CON) vs 50,000 (SIN)