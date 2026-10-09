# Review Checklist Skill

## Cuándo usarlo
- **Reviewer agent** lo usa en cada revisión
- **Implementer** puede usarlo como autoverificación antes de entregar
- **QA** verifica que hallazgos blocker/major fueron resueltos

## Cuándo NO usarlo
- Como sustituto de tests automatizados
- Para decisiones arquitectónicas (eso es trabajo del Architect)

## Descripción
Checklist numerado y verificable para revisiones de código. Cada regla tiene criterio objetivo: pasa/no pasa. El Reviewer cita el número exacto ("falla review-checklist regla 7").

## Reglas verificables

### Sección 1: Correctness y Seguridad

**R1. Validación de entrada en boundary**
- Todos los endpoints públicos validan input con DTOs/schema
- Rechazan campos extra (`extra="forbid"` / `@Valid` + DTO estricto)
- **Verificación**: `grep -r "extra.*forbid\|@Valid" --include="*.py" --include="*.java"`

**R2. Autenticación y autorización en endpoints protegidos**
- Endpoints que modifican datos requieren auth
- Autorización verifica ownership/roles antes de actuar
- **Verificación**: Buscar `@PreAuthorize`, `Depends(get_current_user)`, `@RolesAllowed`

**R3. No exposición de información sensible en errores**
- Stack traces no llegan al cliente
- Error messages no revelan detalles internos (SQL, paths, configs)
- **Verificación**: `grep -r "stacktrace\|traceback\|print_stack" --include="*.py" --include="*.java"` debe estar vacío en prod

**R4. Protección contra inyección (SQL, NoSQL, Command, LDAP)**
- Queries parametrizadas / ORM / query builders
- No concatenación de strings en queries
- **Verificación**: `grep -r "f\"SELECT\|+.*WHERE\|format.*SELECT" --include="*.py" --include="*.java"`

**R5. Rate limiting en endpoints públicos de escritura**
- Login, register, password reset, contact forms tienen rate limit
- **Verificación**: Buscar `@RateLimiter`, `slowapi`, `bucket4j`, middleware de rate limit

**R6. Headers de seguridad HTTP**
- `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`
- HSTS en producción
- **Verificación**: `curl -I https://app` o revisar config de Spring Security / FastAPI middleware

**R7. Secrets management**
- No secrets en código, config files, Docker images, logs
- Variables de entorno / vault / secret manager
- **Verificación**: `grep -r "password\|secret\|api_key\|token" --include="*.py" --include="*.java" --include="*.yml" --include="*.yaml" | grep -v test | grep -v example`

### Sección 2: Arquitectura y Patrones

**R8. Separación de capas respetada**
- Controllers solo HTTP mapping → Service
- Services contienen lógica de negocio → Repository
- Repositories solo data access
- **Verificación**: Revisar imports entre capas (controller no importa repository, service no importa controller)

**R9. Transacciones en Service layer (no Controller/Repository)**
- `@Transactional` / `async with session.begin()` en Service
- No transacciones abiertas durante llamadas HTTP externas
- **Verificación**: `grep -r "@Transactional\|async with.*begin" --include="*.java" --include="*.py" | grep -v test`

**R10. Entidades JPA/SQLAlchemy no expuestas en API**
- DTOs/Records/Pydantic models para request/response
- Mappers/factories para conversión
- **Verificación**: `grep -r "ResponseEntity.*Entity\|response_model.*Model" --include="*.java" --include="*.py"`

**R11. Inyección por constructor (no field/setter)**
- Java: `final` fields + constructor (Lombok `@RequiredArgsConstructor`)
- Python: `Depends()` en parámetros
- **Verificación**: `grep -r "@Autowired.*private\|@Inject.*private" --include="*.java"` debe estar vacío

**R12. DTOs inmutables (Records / Pydantic frozen / dataclasses frozen)**
- Java: `record` o `@Value` / `@Data` con `final`
- Python: `model_config = ConfigDict(frozen=True)` o `BaseModel` (inmutable por defecto en v2)
- **Verificación**: Buscar `setter`, `set_`, `.email =` en DTOs

### Sección 3: API Design

**R13. Versionado en URL (`/api/v1/...`)**
- Todos los endpoints bajo `/api/vN/`
- No breaking changes sin nueva versión
- **Verificación**: `grep -r "@RequestMapping\|@GetMapping\|@router\." --include="*.java" --include="*.py" | grep -v "v1\|v2\|v3"`

**R14. Formato de error consistente (RFC 7807 / Problem Details)**
- `type`, `title`, `status`, `detail`, `instance`
- Campos de validación: `field`, `message`
- **Verificación**: Revisar `GlobalExceptionHandler` / `register_exception_handlers`

**R15. Códigos HTTP correctos**
- 201 Created + Location header en POST exitoso
- 204 No Content en DELETE/PATCH exitoso sin body
- 400 Bad Request en validación fallida
- 404 Not Found en recurso inexistente
- 409 Conflict en conflictos de negocio (duplicados, concurrencia)
- 422 Unprocessable Entity en validación semántica (FastAPI default)
- **Verificación**: Revisar tests de integración que aserten status codes

**R16. Idempotency-Key en POST no-idempotentes**
- Endpoints de creación/pago aceptan `Idempotency-Key` header
- Respuesta idéntica para misma key
- **Verificación**: Buscar `Idempotency-Key`, `idempotency` en controllers

**R17. Paginación obligatoria en listados**
- `limit` (max 100), `offset` o cursor
- Respuesta incluye `total`, `limit`, `offset`/`next_cursor`
- **Verificación**: `grep -r "Pageable\|PageParams\|limit.*offset" --include="*.java" --include="*.py"`

### Sección 4: Base de Datos

**R18. Migraciones versionadas, reversibles, con rollback**
- Cada cambio DDL/DML en archivo de migración separado
- `down` / `downgrade` probado
- No migraciones destructivas sin estrategia (rename → add new → copy → drop old)
- **Verificación**: `ls db/migration/ | wc -l` > 0, revisar `down` en cada archivo

**R19. Índices en claves foráneas y columnas de filtro frecuente**
- FK columns indexadas
- Columnas en WHERE/JOIN/ORDER BY indexadas
- **Verificación**: `grep -r "INDEX\|@Index\|create_index" --include="*.sql" --include="*.java" --include="*.py"`

**R20. Sin `SELECT *` en producción**
- Columns explícitas en queries
- Proyecciones en ORM (`select(User.id, User.email)`)
- **Verificación**: `grep -r "SELECT \*" --include="*.sql" --include="*.java" --include="*.py" | grep -v test`

**R21. Soft delete preferido sobre hard delete**
- Columna `deleted_at` / `is_deleted` + filtro global
- Hard delete solo en GDPR/retention jobs
- **Verificación**: Buscar `deleted_at`, `is_deleted`, `@Where(clause = "deleted_at IS NULL")`

### Sección 5: Testing y Calidad

**R22. Cobertura mínima 80% (líneas) / 70% (branches)**
- JaCoCo / pytest-cov en CI
- Fallo si baja del threshold
- **Verificación**: `./mvnw verify` / `pytest --cov-fail-under=80`

**R23. Tests de integración para todos los endpoints públicos**
- Happy path + validación + auth + not found + conflict
- Testcontainers / Testcontainers-python para DB real
- **Verificación**: `find tests -name "*IntegrationTest*\|*integration*" -type f | wc -l`

**R24. Tests unitarios para lógica de negocio compleja**
- Services con mocks, sin BD
- Casos edge: límites, vacíos, nulos, concurrencia
- **Verificación**: `find tests -name "*Test*.py\|*Test*.java" -path "*/unit/*" | wc -l`

**R25. Sin tests frágiles (flaky, dependientes de orden, tiempo, estado global)**
- Fixtures con cleanup
- No `@DirtiesContext` / `pytest.mark.order` salvo justificado
- **Verificación**: Correr suite 3x seguidas, 0 fallos intermitentes

### Sección 6: Observabilidad

**R26. Logging estructurado (JSON) con correlation ID**
- `trace_id`, `span_id`, `user_id` en todos los logs
- Niveles apropiados (DEBUG/INFO/WARN/ERROR)
- No PII en logs
- **Verificación**: `grep -r "log\.\|logger\." --include="*.java" --include="*.py" | head -20`

**R27. Métricas de negocio y técnicos expuestas**
- Latencia p50/p95/p99, error rate, throughput
- Business metrics: orders_created, users_registered, etc.
- **Verificación**: `/actuator/prometheus` / `/metrics` endpoint accesible

**R28. Health checks (liveness + readiness)**
- Liveness: proceso vivo
- Readiness: DB conectada, dependencias accesibles
- **Verificación**: `curl /health/live && curl /health/ready`

## Uso en Review
```markdown
## Hallazgos

### Blocker
- **review-checklist R3**: Stack trace expuesto en `/api/v1/users` (line 45 UserController.java)
- **review-checklist R4**: Concatenación SQL en UserRepository.java:78

### Major
- **review-checklist R11**: Inyección por campo en OrderService.java:22
- **review-checklist R17**: Listado `/api/v1/orders` sin paginación

### Minor
- **review-checklist R26**: Log sin correlation ID en PaymentService.java
```