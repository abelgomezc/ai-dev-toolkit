# Eval Case: Migration - Spring Boot 2.x → 3.x

## Plugin
dev-workflow

## Escenario
Migrar aplicación Spring Boot 2.7.x a Spring Boot 3.2.x (Java 17). Incluye cambio de paquetes (javax → jakarta), actualización de dependencias y migración de consultas JPA.

## Input (Prompt)
```
Migrate Spring Boot 2.7.18 (Java 11) → Spring Boot 3.2.2 (Java 17):
1. Update pom.xml: Spring Boot 3.2.2, Spring Dependency Management 1.1.5
2. Replace javax.* → jakarta.* imports (persistence, servlet, validation)
3. Update Hibernate 5 → Hibernate 6 (query syntax changes)
4. Update Flyway migrations if schema changes needed
5. Update tests (MockitoInjector → MockitoSettings)
6. Verify: application starts, 100% tests pass, no deprecated warnings
7. Generate migration report (breaking changes addressed, known issues)
```

## Métricas de Evaluación

| Métrica | CON Plugin | SIN Plugin (baseline) |
|---------|-----------|----------------------|
| Jakarta migration completeness | ✅ 100% imports updated | ⚠️ 80-90% (some missed) |
| Hibernate 6 compatibility | ✅ queries updated (String concatenation → Criteria) | ⚠️ tests fallan |
| Build succeeds (Maven) | ✅ clean compile | ⚠️ warnings o errors |
| Tests pass (100%) | ✅ | 70-90% |
| Migration report | ✅ detalla breaking changes | ⚠️ superficial |
| Schema migration (Flyway) | ✅ versioned SQL | ⚠️ puede faltar |
| DB migration review (db-migration-review skill) | ✅ applied | N/A |

## Expected Outcome
- **CON Plugin**: pom.xml actualizado, todos imports javax→jakarta, consultas compatibles Hibernate 6, 100% tests passing, migration report detallado
- **SIN Plugin**: Build exitoso pero tests fallando, imports faltantes, reporte incompleto

## Difficulty: Hard
## Est. Tokens: 50,000 (CON) vs 35,000 (SIN)

## Skill References
- stack-java-spring (migration guide references)
- db-migration-review (Flyway best practices)
- api-design-review (breaking changes impact)