# Security Review OWASP Skill

## Cuándo usarlo
- **Reviewer**: Verifica cada regla numerada en revisión de código
- **Architect**: Identifica riesgos de seguridad en diseño
- **Implementer**: Aplica controles desde el inicio
- **QA**: Tests de seguridad validan reglas críticas

## Cuándo NO usarlo
- Como sustituto de SAST/DAST/SCA tools (SonarQube, OWASP ZAP, dependency-check)
- Para compliance completo (PCI-DSS, GDPR, etc.) - requiere auditoría experta

## Descripción
Checklist verificable basado en OWASP Top 10 2021 + ASVS Level 2. Cada regla es objetiva: pasa/no pasa. Citable en reviews ("falla security-review-owasp regla 7").

## Archivos de referencia
- `owasp-top10-mapping.md` — Mapeo regla skill → OWASP Top 10 categoría
- `asvs-checklist.md` — ASVS Level 2 checklist condensado
- `secure-headers.md` — Headers HTTP de seguridad obligatorios

## Reglas verificables

### A01: Broken Access Control

**R1. Autorización en TODOS los endpoints protegidos**
- Endpoints que leen/escriben datos de usuario verifican ownership/roles
- `@PreAuthorize("hasRole('ADMIN')")` / `@PreAuthorize("#userId == authentication.principal.id")`
- **Verificación**: `grep -r "@PreAuthorize\|@Secured\|Depends(get_current_user)" --include="*.java" --include="*.py" | grep -v test`

**R2. No IDOR (Insecure Direct Object References)**
- Nunca exponer IDs secuenciales predecibles en URLs sin autorización
- Usar UUIDs o verificar ownership antes de acceder
- **Verificación**: `grep -r "/users/{id}\|/orders/{id}" --include="*.java" --include="*.py" | grep -v "@PreAuthorize"`

**R3. CORS configurado restrictivamente**
- `allowedOrigins` = lista explícita (no `*`)
- `allowedMethods` = solo necesarios
- `allowCredentials = true` solo si origins de confianza
- **Verificación**: Revisar `CorsConfiguration` / `CORSMiddleware`

### A02: Cryptographic Failures

**R4. HTTPS obligatorio en producción**
- `server.ssl.enabled=true` / `uvicorn --ssl-keyfile --ssl-certfile`
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- **Verificación**: `curl -I https://app | grep -i strict-transport-security`

**R5. Secrets NUNCA en código/config/Docker**
- Variables de entorno / Vault / AWS Secrets Manager / HashiCorp Vault
- `.env` en `.gitignore`
- **Verificación**: `grep -r "password\|secret\|api_key\|token" --include="*.java" --include="*.py" --include="*.yml" --include="*.yaml" --include="Dockerfile" | grep -v test | grep -v example | grep -v ".gitignore"`

**R6. Contraseñas hasheadas con bcrypt/Argon2 (NO MD5/SHA)**
- Java: `BCryptPasswordEncoder(12)` / `Pbkdf2PasswordEncoder`
- Python: `passlib.hash.bcrypt` / `argon2`
- Cost factor ≥ 12 (bcrypt) / Argon2id
- **Verificación**: `grep -r "BCryptPasswordEncoder\|bcrypt\|argon2" --include="*.java" --include="*.py"`

**R7. Datos sensibles encriptados en reposo (PII, tokens, claves)**
- AES-256-GCM para campos sensibles en BD
- JPA `@Convert` con AttributeConverter / SQLAlchemy `TypeDecorator`
- **Verificación**: Buscar `@Convert` / `TypeDecorator` en entidades con PII

### A03: Injection

**R8. SQL Injection: Solo queries parametrizadas / ORM**
- JPA CriteriaQuery, Spring Data JPA derived queries, `@Query` con parámetros
- SQLAlchemy ORM / text() con bindparams
- **NUNCA** concatenación de strings
- **Verificación**: `grep -r "f\"SELECT\|+.*WHERE\|format.*SELECT\|\.format.*SELECT" --include="*.java" --include="*.py"`

**R9. NoSQL Injection: Validación estricta de input**
- MongoDB: `$where` deshabilitado, validar ObjectId
- Redis: validar keys
- **Verificación**: `grep -r "\\$where\|\\$eval" --include="*.java" --include="*.py"`

**R10. Command Injection: No `Runtime.exec` / `ProcessBuilder` / `subprocess` con input usuario**
- Si necesario: allowlist de comandos, `ProcessBuilder` sin shell
- **Verificación**: `grep -r "Runtime.getRuntime().exec\|ProcessBuilder\|subprocess.run\|subprocess.Popen" --include="*.java" --include="*.py"`

**R11. LDAP Injection: Escape de input en filtros LDAP**
- `LdapUtils.encodeFilterValue()`
- **Verificación**: `grep -r "LdapTemplate\|DirContext" --include="*.java"`

### A04: Insecure Design

**R12. Rate Limiting en endpoints públicos de escritura**
- Login, register, password reset, contact, payment initiation
- Sliding window / token bucket
- **Verificación**: Buscar `RateLimiter`, `bucket4j`, `slowapi`, `@RateLimit`

**R13. Idempotency en operaciones críticas (pagos, emails, envíos)**
- `Idempotency-Key` header + deduplicación
- **Verificación**: `grep -r "Idempotency-Key" --include="*.java" --include="*.py"`

**R14. Validación de archivo subido (tipo, tamaño, contenido)**
- Whitelist MIME types + extensión
- Max size configurable
- Escaneo antivirus (ClamAV) en async
- Almacenamiento fuera de webroot / bucket privado
- **Verificación**: `grep -r "MultipartFile\|UploadFile" --include="*.java" --include="*.py" | grep -v test`

### A05: Security Misconfiguration

**R15. Headers de seguridad HTTP obligatorios**
```
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
```
- **Verificación**: `curl -I https://app | grep -E "Content-Security-Policy|X-Frame-Options|X-Content-Type-Options|Referrer-Policy|Permissions-Policy|Cross-Origin"`

**R16. Debug/Dev endpoints deshabilitados en prod**
- `/actuator/*` solo `health,info` expuestos
- Swagger UI solo en non-prod
- H2 console deshabilitado
- **Verificación**: `management.endpoints.web.exposure.include=health,info` en prod

**R17. Versiones de dependencias sin vulnerabilidades conocidas**
- OWASP Dependency Check / `safety` / `pip-audit` en CI
- Fail build si CVE ≥ HIGH
- **Verificación**: Pipeline CI ejecuta dependency check

### A06: Vulnerable and Outdated Components

**R18. Dependency scanning en CI/CD**
- Maven: `org.owasp:dependency-check-maven`
- Gradle: `org.owasp.dependencycheck`
- Python: `safety check` / `pip-audit`
- **Verificación**: Pipeline falla si vulnerabilidad CRITICAL/HIGH

### A07: Identification and Authentication Failures

**R19. MFA para cuentas admin / operaciones sensibles**
- TOTP / WebAuthn / SMS (menos seguro)
- **Verificación**: Buscar `TotpService`, `WebAuthn`, `MfaService`

**R20. Password policy mínima**
- Mínimo 12 chars, sin complejidad obligatoria (NIST 800-63B)
- Check against breached passwords (HaveIBeenPwned API)
- **Verificación**: `grep -r "PasswordValidator\|password.*policy" --include="*.java" --include="*.py"`

**R21. Account lockout / brute force protection**
- Fallos consecutivos → lockout temporal + notificación
- Capcha tras N fallos
- **Verificación**: Buscar `FailedAttempts`, `AccountLockout`, `brute.force`

**R22. Session management seguro**
- `Secure`, `HttpOnly`, `SameSite=Strict` en cookies
- Timeout inactividad ≤ 30 min
- Rotación de session ID tras login
- **Verificación**: `server.servlet.session.cookie.secure=true`, `http-only=true`, `same-site=strict`

### A08: Software and Data Integrity Failures

**R23. Integridad de dependencias (SBOM + verificación checksums)**
- `dependency-check` genera SBOM (CycloneDX/SPDX)
- Verificar checksums en build reproducible
- **Verificación**: `dependency-check` configurado

**R24. CI/CD pipeline seguro**
- Secrets solo en vault, no en pipeline vars
- Signed commits / SLSA provenance
- Imágenes base actualizadas y escaneadas (Trivy/Gryype)
- **Verificación**: Pipeline usa vault, Trivy en build

### A09: Security Logging and Monitoring Failures

**R25. Logging de eventos de seguridad (sin PII)**
- Login success/failed, password change, permission change, admin actions
- Structured JSON con `event_type`, `user_id`, `ip`, `timestamp`, `result`
- **NO** loggear passwords, tokens, PII
- **Verificación**: `grep -r "log.*login\|log.*auth\|security.*event" --include="*.java" --include="*.py"`

**R26. Alertas en anomalías**
- Múltiples login fallidos → alerta
- Acceso admin fuera de horario → alerta
- Cambio permisos críticos → alerta
- **Verificación**: Buscar `AlertService`, `security.*alert`, `monitoring`

### A10: Server-Side Request Forgery (SSRF)

**R27. Validación de URLs en peticiones salientes**
- Allowlist de dominios/IPs permitidos
- Bloquear IPs privadas (10.x, 172.16-31.x, 192.168.x, 169.254.x, 127.x)
- Timeout y size limit en HTTP clients
- **Verificación**: `grep -r "HttpClient\|WebClient\|httpx.AsyncClient" --include="*.java" --include="*.py" | grep -v test`

## Verificación en Review
- **security-review-owasp-1**: ¿AuthZ en todos endpoints protegidos?
- **security-review-owasp-2**: ¿Sin IDOR (verifica ownership)?
- **security-review-owasp-4**: ¿HTTPS + HSTS en prod?
- **security-review-owasp-5**: ¿Sin secrets en código?
- **security-review-owasp-6**: ¿Bcrypt/Argon2 cost ≥ 12?
- **security-review-owasp-8**: ¿Solo queries parametrizadas/ORM?
- **security-review-owasp-12**: ¿Rate limiting en endpoints públicos?
- **security-review-owasp-13**: ¿Idempotency en pagos/emails?
- **security-review-owasp-15**: ¿Headers seguridad HTTP?
- **security-review-owasp-17**: ¿Dependency check en CI?
- **security-review-owasp-19**: ¿MFA para admins?
- **security-review-owasp-22**: ¿Session cookies Secure/HttpOnly/SameSite?
- **security-review-owasp-25**: ¿Logging seguridad estructurado sin PII?
- **security-review-owasp-27**: ¿SSRF protection (allowlist + block private IPs)?