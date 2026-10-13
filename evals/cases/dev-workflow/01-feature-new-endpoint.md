# Eval Case: Feature - New API Endpoint

## Plugin
dev-workflow

## Escenario
Un equipo de desarrollo necesita un nuevo endpoint REST para crear usuarios en una aplicación Spring Boot 3.2.x existente con Spring Security, Spring Data JPA y PostgreSQL.

## Input (Prompt)
```
Crear endpoint POST /api/v1/users para registrar usuarios con:
- Email único (validación de base de datos)
- Password hash con bcrypt (12 rounds)
- Validación: email format, password min 8 chars, name required
- Respuesta 201 Created con Location header
- Tests unitarios (JUnit 5 + Mockito) y tests de integración (Spring Boot Test)
- Migración de base de datos con Flyway
- Documentación OpenAPI 3.0
```

## Métricas de Evaluación

| Métrica | CON Plugin | SIN Plugin (baseline) |
|---------|-----------|----------------------|
| Archivos creados | 6+ (controller, service, dto, entity, mapper, migration, tests) | 4-6 (menos estructurados) |
| Tests (unit + integration) | 8+ con cobertura >85% | 4-6 con cobertura ~60-70% |
| Códigos de aceptación verificables | 4/4 | 2-3/4 |
| Security practices (OWASP) | ✅ bcrypt 12 rounds, @Transactional, DTOs | ⚠️ puede omitir |
| Spring patterns (Service, Repository, Mapper) | ✅ arquitectura hexagonal | ⚠️ monolithic controller |
| Review findings (blocker/major) | 0/0 | 1-2/2-4 |

## Expected Outcome
- **CON Plugin**: 6 archivos creados (UserController, UserService, UserDTO, User, UserMapper, V1__create_users_table.sql), 8+ tests, 0 review findings, 201 response, bcrypt hashing, Location header
- **SIN Plugin**: 4-5 archivos, tests incompletos, posible missing security practices

## Difficulty: Medium
## Est. Tokens: 45,000 (CON) vs 35,000 (SIN)