# OWASP Top 10 2021 Mapping

| Skill Rule | OWASP Category | Description |
|------------|----------------|-------------|
| R1, R2, R3 | A01: Broken Access Control | AuthZ en endpoints, no IDOR, CORS restrictivo |
| R4, R5, R6, R7 | A02: Cryptographic Failures | HTTPS/HSTS, secrets management, bcrypt/Argon2, encryption at rest |
| R8, R9, R10, R11 | A03: Injection | SQL/NoSQL/Command/LDAP injection prevention |
| R12, R13, R14 | A04: Insecure Design | Rate limiting, idempotency, file upload validation |
| R15, R16, R17 | A05: Security Misconfiguration | Security headers, debug endpoints, dependency versions |
| R18 | A06: Vulnerable Components | Dependency scanning en CI |
| R19, R20, R21, R22 | A07: Auth Failures | MFA, password policy, account lockout, session management |
| R23, R24 | A08: Integrity Failures | SBOM, CI/CD security, signed artifacts |
| R25, R26 | A09: Logging/Monitoring Failures | Security event logging, anomaly alerts |
| R27 | A10: SSRF | URL validation, private IP blocking |

## ASVS Level 2 Checklist (Condensado)

### V1: Architecture
- [ ] 1.1.1 Security requirements documented
- [ ] 1.2.1 Threat model for high-value features
- [ ] 1.3.1 Security architecture review

### V2: Authentication
- [ ] 2.1.1 Password policy (NIST 800-63B)
- [ ] 2.2.1 MFA for admin/high-value
- [ ] 2.3.1 Secure password storage (bcrypt/Argon2)
- [ ] 2.4.1 Account lockout
- [ ] 2.5.1 Session management (Secure/HttpOnly/SameSite)

### V3: Session Management
- [ ] 3.1.1 Secure session cookies
- [ ] 3.2.1 Session timeout ≤ 30 min
- [ ] 3.3.1 Session rotation on login
- [ ] 3.4.1 Concurrent session limits

### V4: Access Control
- [ ] 4.1.1 Deny by default
- [ ] 4.2.1 Authorization checks on every request
- [ ] 4.3.1 No IDOR
- [ ] 4.4.1 RBAC/ABAC implemented

### V5: Validation
- [ ] 5.1.1 Input validation allowlist
- [ ] 5.2.1 Output encoding
- [ ] 5.3.1 SQL injection prevention (parametrized)
- [ ] 5.4.1 XSS prevention (CSP, encoding)

### V7: Error Handling
- [ ] 7.1.1 No stack traces to client
- [ ] 7.2.1 Generic error messages
- [ ] 7.3.1 Security logging (no PII)

### V8: Data Protection
- [ ] 8.1.1 TLS 1.2+ everywhere
- [ ] 8.2.1 Encryption at rest for PII
- [ ] 8.3.1 Key management (Vault/KMS)
- [ ] 8.4.1 No secrets in code

### V9: Communications
- [ ] 9.1.1 HSTS
- [ ] 9.2.1 Certificate validation
- [ ] 9.3.1 Secure headers (CSP, X-Frame-Options, etc.)

### V10: HTTP Security
- [ ] 10.1.1 CORS restrictive
- [ ] 10.2.1 CSRF protection (SameSite + tokens)
- [ ] 10.3.1 Clickjacking protection (X-Frame-Options)
- [ ] 10.4.1 MIME sniffing protection (X-Content-Type-Options)

### V11: Files
- [ ] 11.1.1 File type validation
- [ ] 11.2.1 Size limits
- [ ] 11.3.1 Antivirus scan
- [ ] 11.4.1 Storage outside webroot

### V12: API Security
- [ ] 12.1.1 Rate limiting
- [ ] 12.2.1 Auth on all endpoints
- [ ] 12.3.1 Input validation
- [ ] 12.4.1 Versioning

### V13: Configuration
- [ ] 13.1.1 Debug disabled in prod
- [ ] 13.2.1 Dependency scanning
- [ ] 13.3.1 Secure defaults
- [ ] 13.4.1 Secrets management

## Security Headers Obligatorios

| Header | Valor Recomendado | Propósito |
|--------|-------------------|-----------|
| `Content-Security-Policy` | `default-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'` | XSS, injection, clickjacking |
| `X-Frame-Options` | `DENY` | Clickjacking (legacy) |
| `X-Content-Type-Options` | `nosniff` | MIME sniffing |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Information leakage |
| `Permissions-Policy` | `geolocation=(), microphone=(), camera=(), payment=()` | Feature policy |
| `Cross-Origin-Opener-Policy` | `same-origin` | Cross-origin isolation |
| `Cross-Origin-Resource-Policy` | `same-origin` | Resource isolation |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | HTTPS enforcement |

### Java Spring Config
```java
@Configuration
@EnableWebSecurity
public class SecurityHeadersConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.headers(headers -> headers
            .contentSecurityPolicy(csp -> csp.policyDirectives(
                "default-src 'self'; script-src 'self'; object-src 'none'; " +
                "frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
            ))
            .frameOptions(frame -> frame.sameOrigin())  // DENY via CSP
            .contentTypeOptions(contentType -> {})
            .referrerPolicy(referrer -> referrer.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN))
            .permissionsPolicy(permissions -> permissions.policy(
                "geolocation=(), microphone=(), camera=(), payment=()"
            ))
            .crossOriginOpenerPolicy(corp -> corp.sameOrigin())
            .crossOriginResourcePolicy(corp -> corp.sameOrigin())
            .httpStrictTransportSecurity(hsts -> hsts
                .includeSubDomains(true)
                .maxAgeInSeconds(31536000)
                .preload(true)
            )
        );
        return http.build();
    }
}
```

### Python FastAPI Middleware
```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; script-src 'self'; object-src 'none'; "
            "frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
        )
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=(), payment=()"
        response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
        response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
        
        # HSTS solo en HTTPS
        if request.url.scheme == "https":
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
        
        return response
```