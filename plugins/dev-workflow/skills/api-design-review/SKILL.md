# API Design Review Skill

## Cuándo usarlo
- **Architect**: Define contratos API en el plan (acceptance_criteria)
- **Implementer**: Implementa endpoints siguiendo estas reglas
- **Reviewer**: Verifica cada regla numerada ("falla api-design-review regla 3")
- **QA**: Tests de contrato validan estas reglas

## Cuándo NO usarlo
- APIs internas no HTTP (gRPC, messaging)
- GraphQL (tiene sus propias convenciones)
- Legacy SOAP/XML APIs

## Descripción
Reglas verificables para diseño de APIs REST: versionado, formato errores, paginación, idempotencia, códigos HTTP, naming, filtering, versionado.

## Archivos de referencia
- `api-conventions.md` — Convenciones completas con ejemplos
- `error-format.md` — RFC 7807 Problem Details implementation
- `versioning-strategy.md` — URL versioning vs header versioning

## Reglas verificables

### Regla 1: Versionado en URL obligatorio
```
/api/v1/users
/api/v2/users
```
- **NUNCA** en header (`Accept: application/vnd.myapp.v1+json`) para APIs públicas
- **NUNCA** sin versionado
- **Verificación**: `grep -r "@RequestMapping\|@GetMapping\|router\." --include="*.java" --include="*.py" | grep -v "v[0-9]+"`

### Regla 2: Formato de error RFC 7807 (Problem Details)
```json
// BUENO - Estructura consistente
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation failed",
  "status": 400,
  "detail": "One or more fields are invalid",
  "instance": "/api/v1/users",
  "errors": [
    { "field": "email", "message": "must be a valid email" },
    { "field": "password", "message": "must be at least 8 characters" }
  ]
}

// MALO - Inconsistente
{ "error": "Validation failed", "message": "Invalid email" }
{ "code": 400, "msg": "Bad request" }
```
- **Verificación**: Todos los `@ExceptionHandler` / `register_exception_handlers` devuelven esta estructura

### Regla 3: Códigos HTTP correctos
| Situación | Código | Headers/Body |
|-----------|--------|--------------|
| GET éxito | 200 | Body con recurso |
| POST éxito (creación) | 201 | `Location: /api/v1/users/{id}`, body con recurso |
| PUT/PATCH éxito | 200 | Body con recurso actualizado |
| DELETE éxito | 204 | Sin body |
| Validación fallida | 400 | Problem Details |
| No autenticado | 401 | `WWW-Authenticate` header |
| No autorizado | 403 | Problem Details |
| No encontrado | 404 | Problem Details |
| Conflicto (duplicado, concurrencia) | 409 | Problem Details |
| Rate limited | 429 | `Retry-After` header |
| Error servidor | 500 | Problem Details (sin stack trace) |

### Regla 4: Paginación obligatoria en colecciones
```http
# Request
GET /api/v1/users?limit=20&offset=0
GET /api/v1/users?limit=20&cursor=eyJpZCI6MTIzfQ==

# Response
{
  "items": [...],
  "total": 150,
  "limit": 20,
  "offset": 0,
  "next_cursor": "eyJpZCI6MTQzfQ=="
}
```
- `limit` máximo 100, default 20
- `offset` O `cursor` (no ambos)
- `total` opcional si costoso (pero recomendado)
- **Verificación**: Todos los `GET /plural` tienen paginación

### Regla 5: Idempotency-Key en POST no-idempotentes
```http
# Cliente envía
POST /api/v1/orders
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{ "items": [...], "shipping": {...} }

# Respuesta idéntica para misma key (incluso si error)
HTTP/1.1 201 Created
Location: /api/v1/orders/123
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
```
- Aplicar a: creación de recursos, pagos, envíos, emails
- Guardar `(idempotency_key, response)` con TTL 24h
- **Verificación**: Buscar `Idempotency-Key` en controllers de POST

### Regla 6: Naming conventions
| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Recursos (colecciones) | plural, kebab-case | `/api/v1/users`, `/api/v1/order-items` |
| Recursos (individual) | singular por ID | `/api/v1/users/{userId}` |
| Sub-recursos | anidados | `/api/v1/users/{userId}/orders` |
| Acciones no-CRUD | verb + noun (sub-recurso) | `/api/v1/users/{userId}/activate` |
| Query params | camelCase | `?firstName=John&lastName=Doe` |
| Headers | kebab-case | `Idempotency-Key`, `X-Request-ID` |

### Regla 7: Filtering, Sorting, Field Selection
```http
# Filtering
GET /api/v1/users?email=john@example.com&status=active

# Sorting
GET /api/v1/users?sort=createdAt,desc&sort=email,asc

# Field Selection (opcional)
GET /api/v1/users?fields=id,email,fullName
```
- **Verificación**: Controllers usan `Pageable` + `@RequestParam` para filtros

### Regla 8: Content Negotiation
```http
# Request
Accept: application/json
Content-Type: application/json

# Response
Content-Type: application/json; charset=utf-8
```
- **SOLO** `application/json` (no XML, no HTML)
- `charset=utf-8` siempre
- **Verificación**: `produces = "application/json"` / `media_type="application/json"`

### Regla 9: HATEOAS / Links (opcional pero recomendado)
```json
{
  "id": "123",
  "email": "john@example.com",
  "_links": {
    "self": { "href": "/api/v1/users/123" },
    "orders": { "href": "/api/v1/users/123/orders" },
    "deactivate": { "href": "/api/v1/users/123/deactivate", "method": "POST" }
  }
}
```

### Regla 10: OpenAPI/Swagger Documentation
- Todos los endpoints documentados con `@Operation`, `@ApiResponse`, `@Parameter`
- Ejemplos de request/response en `@io.swagger.v3.oas.annotations.parameters.RequestBody` y `@ApiResponse`
- Schemas generados desde código (no manuales)
- **Verificación**: `/v3/api-docs` válido, Swagger UI accesible en dev

### Regla 11: Rate Limiting Headers
```http
# Response headers
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1699900000
Retry-After: 60  # Solo en 429
```

### Regla 12: Correlation ID Propagation
```http
# Request
X-Correlation-ID: 550e8400-e29b-41d4-a716-446655440000

# Response
X-Correlation-ID: 550e8400-e29b-41d4-a716-446655440000
```
- Generar si no viene en request
- Propagar a todos los downstream (HTTP headers, Kafka headers, gRPC metadata)
- Incluir en todos los logs

## Verificación en Review
- **api-design-review-1**: ¿Versionado en URL (`/api/v1/`)?
- **api-design-review-2**: ¿Errores RFC 7807 en TODOS los exception handlers?
- **api-design-review-3**: ¿Códigos HTTP correctos por situación?
- **api-design-review-4**: ¿Paginación en TODOS los listados?
- **api-design-review-5**: ¿Idempotency-Key en POST no-idempotentes?
- **api-design-review-6**: ¿Naming conventions (plural, kebab-case)?
- **api-design-review-7**: ¿Filtering/sorting/fields en listados?
- **api-design-review-8**: ¿Solo application/json + charset=utf-8?
- **api-design-review-10**: ¿OpenAPI docs completas con ejemplos?
- **api-design-review-11**: ¿Rate limit headers?
- **api-design-review-12**: ¿Correlation ID propagado?