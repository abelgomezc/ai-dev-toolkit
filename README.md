# ai-dev-toolkit

Marketplace de plugins para Claude Code con agentes y skills de nivel experto para flujos de desarrollo profesional.

## Plugins

| Plugin | Descripción | Estado |
|--------|-------------|--------|
| **dev-workflow** | Flujo multiagente (arquitecto, implementador, revisor, QA) independiente del lenguaje con skills de dominio profundos | ✅ Fases 1-5 completadas |
| **cicd-security-triage** | Triage de reportes de seguridad de CI/CD (Grype, SonarQube, StackHawk) | 🚧 Fase 6 pendiente |
| **frontend-ui** | Diseño e implementación de interfaces profesionales con React/TypeScript, Tailwind, shadcn/ui | 🚧 Fase 7 pendiente |
| **context-toolkit** | Ahorro de contexto y tokens, continuidad entre sesiones | 🚧 Fase 8 pendiente |

## Instalación

```bash
# Agregar el marketplace
claude plugin marketplace add https://github.com/abelgomez/ai-dev-toolkit

# Instalar plugins individuales
claude plugin install dev-workflow
claude plugin install cicd-security-triage
claude plugin install frontend-ui
claude plugin install context-toolkit
```

## Estructura del Repositorio

```
ai-dev-toolkit/
├── .claude-plugin/marketplace.json
├── plugins/
│   ├── dev-workflow/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/ (architect, implementer, reviewer, qa)
│   │   ├── skills/ (10 skills de dominio)
│   │   ├── commands/feature.md
│   │   ├── hooks/hooks.json
│   │   ├── scripts/ (detect-stack, run-checks, guard-sensitive, validate-contract)
│   │   ├── config/ (stacks.json, sensitive-patterns.json)
│   │   ├── tests/ (test-plugin-structure.sh, test-hooks.sh)
│   │   └── CLAUDE.md, README.md, CHANGELOG.md
│   ├── cicd-security-triage/
│   ├── frontend-ui/
│   └── context-toolkit/
├── evals/
│   ├── cases/ (casos de evaluación por plugin)
│   ├── run-evals.py
│   └── README.md
├── scripts/validate-all.sh
├── docs/
│   ├── ARCHITECTURE.md
│   ├── CONVENTIONS.md
│   └── TESTING-STATUS.md
├── .github/workflows/validate.yml
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── LICENSE (MIT)
└── .gitignore
```

## Uso Rápido - dev-workflow

### Comando Principal
```bash
/feature "Crear endpoint POST /api/v1/users con validación email único, password bcrypt, respuesta 201 Location"
```

### Flujo Automático
1. **Architect** → Analiza, detecta stack, crea plan con criterios de aceptación
2. **Implementer** → Implementa código + tests, ejecuta `run-checks.sh`
3. **Reviewer** → Revisa con 28 reglas (review-checklist) + skills dominio
4. **QA** → Ejecuta tests, verifica criterios, decide Approved/Rejected

### Contrato Compartido
- Archivo: `.claude-workflow/contracts/{task_id}.json`
- Esquema: `skills/workflow-contract/workflow-contract-schema.json`
- Ejemplo: `skills/workflow-contract/workflow-contract-example.json`

## Validación Local

```bash
# Validar todo el repositorio
./scripts/validate-all.sh

# Solo estructura del plugin dev-workflow
./plugins/dev-workflow/tests/test-plugin-structure.sh

# Solo hooks y scripts
./plugins/dev-workflow/tests/test-hooks.sh

# Ver estado de pruebas
cat docs/TESTING-STATUS.md
```

## CI/CD

GitHub Actions workflow en `.github/workflows/validate.yml`:
- Valida JSON, frontmatter, shellcheck
- Ejecuta test-plugin-structure.sh y test-hooks.sh
- Valida marketplace.json y cada plugin.json
- Matrix strategy para validar 4 plugins en paralelo

## Skills de Dominio (dev-workflow)

| Skill | Descripción | Reglas Verificables |
|-------|-------------|---------------------|
| `stack-detector` | Detecta stack por evidencia en config files | Pesos por archivo/patrón |
| `stack-java-spring` | Convenciones Java 21 + Spring Boot 3.x | 10 reglas (injection, records, DTOs, etc.) |
| `stack-python-fastapi` | Convenciones Python 3.11+ + FastAPI | 10 reglas (tipado, Depends, async, Pydantic) |
| `review-checklist` | Checklist 28 reglas en 6 secciones | Correctness, Arquitectura, API, BD, Testing, Observabilidad |
| `test-strategy` | Pirámide testing, thresholds, Testcontainers | Coverage ≥80%, branch ≥70% |
| `spring-microservices-patterns` | Saga, Outbox, Idempotencia, DLQ, gRPC, Consistencia eventual | 6 patrones con antipatrones |
| `api-design-review` | REST contracts, versionado, RFC 7807, paginación, idempotencia | 12 reglas |
| `security-review-owasp` | OWASP Top 10 2021 + ASVS Level 2 | 27 reglas mapeadas |
| `db-migration-review` | Migraciones SQL/PLSQL seguras, zero-downtime | 12 reglas |
| `workflow-contract` | Esquema JSON + validación + ejemplo | Schema Draft 2020-12 |

## Scripts Deterministas (dev-workflow)

| Script | Propósito |
|--------|-----------|
| `detect-stack.sh` | Detecta stack → JSON {stack, confidence, evidence} |
| `run-checks.sh` | Ejecuta compile/lint/tests según stack/herramienta |
| `guard-sensitive.sh` | Bloquea edición de .env, claves, credenciales |
| `validate-contract.sh` | Valida workflow-contract contra JSON Schema |

## Hooks (dev-workflow)

| Hook | Tipo | Trigger | Acción |
|------|------|---------|--------|
| `run-checks-post-edit` | post_edit | Editar código/config | Ejecuta run-checks.sh |
| `guard-sensitive-pre-edit` | pre_edit | Editar cualquier archivo | Bloquea si sensible (on_failure: block) |

## Documentación

- [Arquitectura](docs/ARCHITECTURE.md) - Decisiones de diseño, flujos, limitaciones
- [Convenciones](docs/CONVENTIONS.md) - Nomenclatura, estructura, commits, validación
- [Estado de Pruebas](docs/TESTING-STATUS.md) - Qué está verificado y qué no, con evidencia
- [Agentes](AGENTS.md) - Detalle de 10 agentes, permisos, flujos, matriz

## Evaluaciones (Fase 9 - Pendiente)

```
evals/
├── cases/
│   ├── dev-workflow/ (5+ casos)
│   ├── cicd-security-triage/ (5+ casos)
│   ├── frontend-ui/ (5+ casos)
│   └── context-toolkit/ (5+ casos)
├── run-evals.py (ejecuta, puntúa, compara CON vs SIN plugin)
└── README.md (limitaciones documentadas)
```

## Licencia

MIT License - ver [LICENSE](LICENSE)

## Autor

Abel Gomez - Backend/Fullstack Developer  
Java 21, Spring Boot, Kafka, gRPC, Oracle PL/SQL, React, Angular, Python

---

## Estado Actual (Fase 5 Completada)

✅ **Completado**:
- Marketplace con 4 plugins declarados
- dev-workflow: 4 agentes, 10 skills, 1 comando, 4 scripts, 2 hooks, 2 configs, 2 tests
- Validación completa: `./scripts/validate-all.sh` → 0 fallos
- CI/CD workflow configurado
- Documentación base: ARCHITECTURE.md, CONVENTIONS.md, TESTING-STATUS.md, AGENTS.md

🚧 **Pendiente**:
- Fase 6: cicd-security-triage completo (parsers, fixtures, agentes, tests)
- Fase 7: frontend-ui completo (agentes, skills, comandos, scripts)
- Fase 8: context-toolkit completo (skills, comandos)
- Fase 9: Evals (5 casos/plugin, run-evals.py, comparativa CON/SIN)
- Fase 10: Iteración, CHANGELOG, README final

## Honestidad sobre Validación

Ver `docs/TESTING-STATUS.md` para clasificación detallada:
- ✅ **verificado**: Ejecutado y pasado
- 🟡 **parcialmente verificado**: Parcialmente ejecutado o con caveats
- ❌ **no verificado**: No ejecutado, solo asumido/planificado

**No se afirman ahorros de tokens no medidos**. La ganancia del flujo multiagente está en contexto principal limpio y calidad, no en menor coste.