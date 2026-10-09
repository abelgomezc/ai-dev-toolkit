# Stack Java Spring Skill

## Cuándo usarlo
- Stack detectado: `java-spring` (Java 21, Spring Boot 3.x)
- Cualquier tarea de implementación, revisión o testing en proyectos Spring Boot
- Migraciones de Spring Boot 2.x → 3.x

## Cuándo NO usarlo
- Proyectos Spring Framework sin Spring Boot
- Proyectos Java con Quarkus, Micronaut, Helidon
- Proyectos legacy Java 8/11 sin Spring Boot 3.x

## Descripción
Convenciones obligatorias, patrones recomendados y antipatrones para Java 21 + Spring Boot 3.x. Cada regla es verificable y citable en reviews ("falla stack-java-spring regla 3").

## Archivos de referencia
- `java-spring-conventions.md` — Convenciones detalladas con código bueno/malo
- `java-spring-antipatterns.md` — Antipatrones comunes con ejemplos
- `spring-boot-3-migration.md` — Guía de migración 2.x → 3.x

## Reglas verificables (número = cita en reviews)

### Regla 1: Java 21 + Spring Boot 3.x obligatorio
- `pom.xml`: `<java.version>21</java.version>` + `spring-boot-starter-parent` 3.2+
- `build.gradle`: `java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }` + Spring Boot 3.2+
- **Verificación**: `./mvnw -v` muestra Java 21; `./mvnw dependency:tree | grep spring-boot-starter-parent`

### Regla 2: Inyección por constructor (no @Autowired en campos)
```java
// BUENO
@Service
public class UserService {
    private final UserRepository repository;
    private final EmailService emailService;

    public UserService(UserRepository repository, EmailService emailService) {
        this.repository = repository;
        this.emailService = emailService;
    }
}

// MALO - Inyección por campo (difícil de testear, implícito)
@Service
public class UserService {
    @Autowired private UserRepository repository;  // FALLA REGLA 2
    @Autowired private EmailService emailService;
}
```

### Regla 3: DTOs como records (Java 16+)
```java
// BUENO - Record inmutable, serializable, con equals/hashCode/toString
public record UserCreateRequest(
    @Email @NotBlank String email,
    @NotBlank @Size(min = 8) String password,
    @NotBlank String fullName
) {}

// MALO - Clase mutable con setters, expone entidad JPA
public class UserCreateRequest {
    private String email;
    private String password;
    // getters/setters...  // FALLA REGLA 3
}
```

### Regla 4: NO exponer entidades JPA en API
```java
// BUENO - Controller devuelve DTO/Record
@PostMapping("/users")
public ResponseEntity<UserResponse> create(@Valid @RequestBody UserCreateRequest request) {
    User user = service.create(request);
    return ResponseEntity.created(uri).body(UserResponse.from(user));
}

// MALO - Expone entidad JPA directamente (lazy loading, ciclos, over-fetching)
@PostMapping("/users")
public ResponseEntity<User> create(@RequestBody User user) {  // FALLA REGLA 4
    return ResponseEntity.ok(repository.save(user));
}
```

### Regla 5: Manejo global de errores con @RestControllerAdvice
```java
// BUENO - Formato de error consistente (RFC 7807)
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        List<FieldError> errors = ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> new FieldError(fe.getField(), fe.getDefaultMessage()))
            .toList();
        return ResponseEntity.badRequest().body(new ErrorResponse("VALIDATION_ERROR", errors));
    }
}

// MALO - Try-catch en cada controller, formatos inconsistentes
@PostMapping("/users")
public ResponseEntity<?> create(@RequestBody UserCreateRequest request) {
    try {
        return ResponseEntity.ok(service.create(request));
    } catch (Exception e) {  // FALLA REGLA 5
        return ResponseEntity.badRequest().body(e.getMessage());
    }
}
```

### Regla 6: Estructura por capas (package by layer o feature)
```text
// Package by layer (recomendado para equipos grandes)
com.example
├── controller/     // @RestController, solo HTTP mapping
├── service/        // @Service, lógica de negocio, transaccional
├── repository/     // @Repository, JPA repositories
├── dto/            // Records para request/response
├── entity/         // @Entity JPA (package-private si posible)
├── config/         // @Configuration, security, openapi
└── exception/      // Excepciones de dominio + handler

// Package by feature (recomendado para microservicios pequeños)
com.example.user
├── UserController.java
├── UserService.java
├── UserRepository.java
├── dto/
│   ├── UserCreateRequest.java
│   └── UserResponse.java
└── entity/
    └── User.java
```

### Regla 7: Validación en DTOs con Bean Validation (JSR 380)
```java
// BUENO - Validación declarativa en record
public record UserCreateRequest(
    @Email(message = "Email inválido")
    @NotBlank(message = "Email obligatorio") String email,

    @NotBlank(message = "Contraseña obligatoria")
    @Size(min = 8, message = "Mínimo 8 caracteres") String password,

    @NotBlank(message = "Nombre obligatorio")
    @Size(max = 100, message = "Máximo 100 caracteres") String fullName
) {}

// MALO - Validación manual en service
public User create(UserCreateRequest request) {
    if (request.email() == null || !request.email().contains("@")) {  // FALLA REGLA 7
        throw new IllegalArgumentException("Email inválido");
    }
    // ...
}
```

### Regla 8: Transaccional en Service, NO en Controller/Repository
```java
// BUENO
@Service
@Transactional(readOnly = true)
public class UserService {
    @Transactional(readOnly = false)
    public UserResponse create(UserCreateRequest request) { ... }
}

// MALO - @Transactional en controller (manejo HTTP en transacción)
@RestController
@Transactional  // FALLA REGLA 8
public class UserController { ... }
```

### Regla 9: Paginación obligatoria en listados
```java
// BUENO - Pageable nativo Spring Data
@GetMapping("/users")
public ResponseEntity<Page<UserResponse>> list(
    @PageableDefault(size = 20, maxSize = 100) Pageable pageable
) {
    return ResponseEntity.ok(service.findAll(pageable).map(UserResponse::from));
}

// MALO - Sin paginación (OOM risk)
@GetMapping("/users")
public ResponseEntity<List<UserResponse>> list() {  // FALLA REGLA 9
    return ResponseEntity.ok(service.findAll().stream().map(UserResponse::from).toList());
}
```

### Regla 10: OpenAPI/Swagger obligatorio
- `springdoc-openapi-starter-webmvc-ui` en dependencias
- `@Operation`, `@ApiResponses`, `@Parameter` en controllers
- **Verificación**: `./mvnw spring-boot:run` → `http://localhost:8080/swagger-ui.html` accesible

## Verificación automática
```bash
# Checkstyle + SpotBugs (config en pom.xml/build.gradle)
./mvnw checkstyle:check spotbugs:check

# Tests + cobertura
./mvnw verify
# JaCoCo report en target/site/jacoco/index.html
```