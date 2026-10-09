# API Conventions - Ejemplos Completos

## Error Response (RFC 7807)

### Java Spring - GlobalExceptionHandler
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Validation failed");
        problem.setType(URI.create("https://api.example.com/errors/validation-error"));
        problem.setTitle("Validation failed");
        problem.setInstance(URI.create("/api/v1/users"));
        problem.setProperty("errors", ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> Map.of("field", fe.getField(), "message", fe.getDefaultMessage()))
            .toList());
        return ResponseEntity.badRequest().body(problem);
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(EntityNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setType(URI.create("https://api.example.com/errors/not-found"));
        problem.setTitle("Resource not found");
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(problem);
    }

    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ResponseEntity<ProblemDetail> handleConcurrency(OptimisticLockingFailureException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, "Resource was modified by another user");
        problem.setType(URI.create("https://api.example.com/errors/concurrency-conflict"));
        problem.setTitle("Concurrency conflict");
        return ResponseEntity.status(HttpStatus.CONFLICT).body(problem);
    }
}
```

### Python FastAPI - Exception Handlers
```python
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError

app = FastAPI()

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = [
        {"field": ".".join(str(loc) for loc in error["loc"][1:]), "message": error["msg"]}
        for error in exc.errors()
    ]
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "type": "https://api.example.com/errors/validation-error",
            "title": "Validation failed",
            "status": 422,
            "detail": "One or more fields are invalid",
            "instance": str(request.url),
            "errors": errors
        }
    )

@app.exception_handler(EntityNotFoundException)
async def not_found_handler(request: Request, exc: EntityNotFoundException):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "type": "https://api.example.com/errors/not-found",
            "title": "Resource not found",
            "status": 404,
            "detail": str(exc),
            "instance": str(request.url)
        }
    )
```

## Paginación Response

### Java Spring
```java
@GetMapping("/users")
public ResponseEntity<PageResponse<UserResponse>> listUsers(
    @PageableDefault(size = 20, maxSize = 100) Pageable pageable
) {
    Page<User> page = userService.findAll(pageable);
    PageResponse<UserResponse> response = PageResponse.of(
        page.getContent().stream().map(UserResponse::from).toList(),
        page.getTotalElements(),
        page.getNumber(),
        page.getSize()
    );
    return ResponseEntity.ok(response);
}

public record PageResponse<T>(
    List<T> items,
    long total,
    int page,
    int size,
    int totalPages,
    boolean first,
    boolean last
) {
    public static <T> PageResponse<T> of(List<T> items, long total, int page, int size) {
        int totalPages = (int) Math.ceil((double) total / size);
        return new PageResponse<>(items, total, page, size, totalPages, page == 0, page >= totalPages - 1);
    }
}
```

### Python FastAPI
```python
from pydantic import BaseModel, Field
from typing import Generic, TypeVar, List

T = TypeVar('T')

class PageParams(BaseModel):
    limit: int = Field(ge=1, le=100, default=20)
    offset: int = Field(ge=0, default=0)

class PageResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    limit: int
    offset: int

@router.get("/users", response_model=PageResponse[UserResponse])
async def list_users(params: PageParams = Depends(), db: AsyncSession = Depends(get_db)):
    total, users = await user_service.list(db, params.limit, params.offset)
    return PageResponse(items=[UserResponse.model_validate(u) for u in users], total=total, limit=params.limit, offset=params.offset)
```

## Idempotency Implementation

### Java Spring
```java
@Component
public class IdempotencyFilter implements Filter {

    private final RedisTemplate<String, String> redis;

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        
        String key = request.getHeader("Idempotency-Key");
        if (key != null && "POST".equals(request.getMethod())) {
            String cached = redis.opsForValue().get("idempotency:" + key);
            if (cached != null) {
                response.setStatus(HttpServletResponse.SC_OK);
                response.setContentType("application/json");
                response.getWriter().write(cached);
                return;
            }
            
            // Wrapper para capturar response
            CachedBodyHttpServletResponse wrapper = new CachedBodyHttpServletResponse(response);
            chain.doFilter(request, wrapper);
            
            if (wrapper.getStatus() < 400) {
                redis.opsForValue().set("idempotency:" + key, wrapper.getBody(), Duration.ofHours(24));
            }
        } else {
            chain.doFilter(request, response);
        }
    }
}
```

### Python FastAPI
```python
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import redis.asyncio as redis

class IdempotencyMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, redis_client: redis.Redis):
        super().__init__(app)
        self.redis = redis_client

    async def dispatch(self, request: Request, call_next):
        key = request.headers.get("Idempotency-Key")
        if key and request.method == "POST":
            cached = await self.redis.get(f"idempotency:{key}")
            if cached:
                return Response(content=cached, media_type="application/json", status_code=200)
            
            response = await call_next(request)
            
            if response.status_code < 400:
                body = b""
                async for chunk in response.body_iterator:
                    body += chunk
                await self.redis.setex(f"idempotency:{key}", 86400, body)
                return Response(content=body, status_code=response.status_code, headers=dict(response.headers), media_type="application/json")
            return response
        
        return await call_next(request)
```

## Versioning Strategy

### URL Versioning (Requerido)
```
/api/v1/users
/api/v1/users/{id}
/api/v1/users/{id}/orders
/api/v2/users          # Breaking changes only
```

### Deprecation Headers
```http
# Response para v1 cuando v2 existe
Deprecation: true
Sunset: Sat, 01 Jan 2025 00:00:00 GMT
Link: </api/v2/users>; rel="successor-version"
```

### OpenAPI Versioning
```yaml
openapi: 3.0.3
info:
  title: User API
  version: "1.0"
servers:
  - url: https://api.example.com/api/v1
    description: Production API v1
  - url: https://api.example.com/api/v2
    description: Production API v2
paths:
  /users:
    get:
      summary: List users
      deprecated: false  # true para v1 cuando v2 existe
      responses:
        '200':
          description: OK
          headers:
            Deprecation:
              schema: { type: string }
            Sunset:
              schema: { type: string, format: date-time }
            Link:
              schema: { type: string }
```