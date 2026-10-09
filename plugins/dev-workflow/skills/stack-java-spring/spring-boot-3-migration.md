# Spring Boot 3.x Migration Guide

## Cambios críticos (breaking changes)

### 1. Java 17+ obligatorio (Java 21 recomendado)
```xml
<!-- pom.xml -->
<properties>
  <java.version>21</java.version>
</properties>
```

### 2. Jakarta EE 9+ (javax.* → jakarta.*)
```java
// ANTES (Spring Boot 2.x)
import javax.persistence.Entity;
import javax.validation.constraints.NotNull;
import javax.servlet.http.HttpServletRequest;

// DESPUÉS (Spring Boot 3.x)
import jakarta.persistence.Entity;
import jakarta.validation.constraints.NotNull;
import jakarta.servlet.http.HttpServletRequest;
```
**Migración**: `find/replace` global `javax.` → `jakarta.` + actualizar dependencias

### 3. Spring Framework 6.x
- `WebMvcConfigurer` métodos con `default` → implementación obligatoria
- `HandlerInterceptor` firma cambiada
- `RequestMappingHandlerMapping` cambios internos

### 4. Hibernate 6.x
- `hibernate.dialect` → `hibernate.dialect` (nueva nomenclatura)
- `GenerationType.AUTO` comportamiento cambiado
- `@Type` deprecado → `@JdbcTypeCode` o `@JavaType`

### 5. Spring Security 6.x
```java
// ANTES
http.authorizeRequests().antMatchers("/public/**").permitAll()

// DESPUÉS
http.authorizeHttpRequests(auth -> auth.requestMatchers("/public/**").permitAll())
```
- `WebSecurityConfigurerAdapter` **eliminado** → `SecurityFilterChain` beans
- `antMatchers` → `requestMatchers`
- CSRF activado por defecto en APIs (configurar `csrf().disable()` si stateless)

### 6. Spring Data JPA 3.x
- `findById` devuelve `Optional` (ya era así, pero más estricto)
- `deleteById` lanza `EmptyResultDataAccessException` si no existe
- `Pageable` cambios en sorting

### 7. Actuator / Micrometer
- Métricas renombradas (ej: `jvm.memory.used` → `jvm.memory.used`)
- Endpoints requieren exposición explícita
- `management.endpoints.web.exposure.include=health,info,metrics,prometheus`

## Dependencias clave actualizadas

| Antes (2.x) | Después (3.x) |
|-------------|---------------|
| `spring-boot-starter-parent` 2.7.x | 3.2.x |
| `spring-boot-starter-data-jpa` | igual (transitivo Hibernate 6) |
| `spring-boot-starter-security` | igual (transitivo Spring Security 6) |
| `spring-boot-starter-web` | igual (transitivo Spring Web 6) |
| `springdoc-openapi-ui` 1.x | `springdoc-openapi-starter-webmvc-ui` 2.x |
| `testcontainers` 1.x | 1.19+ (compatible) |

## Checklist de migración

- [ ] Java 21 instalado y configurado en CI/CD
- [ ] `javax.*` → `jakarta.*` en todo el código (buscar: `import javax.`)
- [ ] `WebSecurityConfigurerAdapter` → `SecurityFilterChain` beans
- [ ] `antMatchers` → `requestMatchers` en Security config
- [ ] `springdoc-openapi-ui` → `springdoc-openapi-starter-webmvc-ui`
- [ ] `@Type` de Hibernate → `@JdbcTypeCode` / `@JavaType`
- [ ] Dialecto Hibernate actualizado (ej: `PostgreSQLDialect` → `PostgreSQLDialect` paquete cambiado)
- [ ] Tests con `@SpringBootTest` funcionan (Testcontainers compatible)
- [ ] Checkstyle/SpotBugs config actualizado para Java 21
- [ ] OpenAPI genera spec correcta (`/v3/api-docs`)
- [ ] Métricas Actuator expuestas y Prometheus scrapea
- [ ] Build pasa: `./mvnw clean verify`

## Problemas comunes post-migración

### Error: "Cannot resolve jakarta.persistence"
```xml
<!-- Añadir si no transitivo -->
<dependency>
  <groupId>jakarta.persistence</groupId>
  <artifactId>jakarta.persistence-api</artifactId>
  <version>3.1.0</version>
</dependency>
```

### Error: "No converter found for type"
```java
// Hibernate 6 requiere converter explícito para enums
@Enumerated(EnumType.STRING)
@JdbcTypeCode(SqlTypes.VARCHAR)  // Nuevo en Hibernate 6
private OrderStatus status;
```

### Testcontainers: "Could not find a valid Docker environment"
- CI/CD debe tener Docker disponible
- GitHub Actions: `services: docker:` o `setup-docker` action

### SpotBugs: "Null pointer dereference" en código generado por Lombok
```xml
<!-- Excluir código Lombok generado -->
<plugin>
  <groupId>com.github.spotbugs</groupId>
  <artifactId>spotbugs-maven-plugin</artifactId>
  <configuration>
    <excludeFilterFile>spotbugs-exclude.xml</excludeFilterFile>
  </configuration>
</plugin>
```
```xml
<!-- spotbugs-exclude.xml -->
<FindBugsFilter>
  <Match>
    <Class pattern=".*\$.*"/>  <!-- Clases sintéticas Lombok -->
  </Match>
</FindBugsFilter>
```

## Recursos oficiales
- [Spring Boot 3.2 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.2-Migration-Guide)
- [Spring Framework 6 Migration](https://github.com/spring-projects/spring-framework/wiki/Migration-to-Spring-Framework-6.x)
- [Jakarta EE 9 Migration](https://jakarta.ee/specifications/platform/9/apidocs/)