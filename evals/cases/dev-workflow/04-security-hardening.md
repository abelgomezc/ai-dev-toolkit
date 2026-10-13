# Eval Case: Security - Rate Limiting & Input Sanitization

## Plugin
dev-workflow

## Escenario
Una API Spring Boot expuesta al internet necesita protección contra brute force, rate limiting y XSS/SQL injection en inputs. El security architect solicitó estas mejoras de seguridad.

## Input (Prompt)
```
Add security hardening to Spring Boot 3.2.x API:
1. Rate limiting: 100 requests/min per IP (Bucket4j o Resilience4j)
2. Input sanitization: sanitize all string inputs to prevent XSS
3. SQL injection prevention: already using JPA (verify no string concatenation)
4. Security headers (HSTS, CSP, X-Content-Type-Options)
5. Add OWASP security tests (OWASP ZAP o testcontainers)
6. Document security assumptions in CLAUDE.md
7. Update workflow-contract con security checklist
```

## Métricas de Evaluación

| Métrica | CON Plugin | SIN Plugin (baseline) |
|---------|-----------|----------------------|
| Rate limiting implementado | ✅ Bucket4j + Redis o in-memory | ⚠️ Resilience4j sin configuración |
| Security headers | ✅ todas configuradas correctamente | ⚠️ algunas omitidas |
| XSS sanitization | ✅ InputSanitizer con OWASP ESAPI | ⚠️ regex simple |
| Security tests | 3+ (rate limit, XSS, SQLi patterns) | 0-1 |
| Security review findings | 0 blockers, 0 majors | 1-3 majors |
| Security documentation | ✅ CLAUDE.md + workflow-contract | ⚠️ omitido |

## Expected Outcome
- **CON Plugin**: Bucket4jRateLimiter, SecurityHeadersFilter, XssSanitizer, 3 security tests, security section in CLAUDE.md
- **SIN Plugin**: Implementación parcial, tests faltantes, security debt documented como "future work"

## Difficulty: Hard
## Est. Tokens: 55,000 (CON) vs 40,000 (SIN)

## Skill References
- security-review-owasp (rules 1-10)
- api-design-review (input validation rules)
- review-checklist (security section)