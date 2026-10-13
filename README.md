# ai-dev-toolkit

Marketplace de plugins para Claude Code con agentes y skills de nivel experto para flujos de desarrollo profesional.

## Plugins

| Plugin | Descripción | Estado | Agents | Skills | Commands | Tests |
|--------|-------------|--------|--------|--------|----------|-------|
| **dev-workflow** | Flujo multiagente (arquitecto, implementador, revisor, QA) con skills de dominio profundos (Spring, FastAPI, OWASP, DB migrations) | ✅ Completado | 4 | 10 | 1 | 2 |
| **cicd-security-triage** | Triage de reportes de seguridad CI/CD (Grype, SonarQube, StackHawk) con parsers normalizados, clasificación + FP descarte + priorización | ✅ Completado | 3 | 3 | 1 | 1 |
| **frontend-ui** | Diseño e implementación de interfaces con React/TypeScript, Tailwind, shadcn/ui + auditoría de accesibilidad y performance | ✅ Completado | 3 | 9 | 1 | 0 |
| **context-toolkit** | Ahorro de contexto: CLAUDE.md writer, codebase map, session handoff | ✅ Completado | 0 | 3 | 2 | 0 |

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
│   │   ├── agents/ (4: architect, implementer, reviewer, qa)
│   │   ├── skills/ (10 skills de dominio)
│   │   ├── commands/feature.md
│   │   ├── hooks/hooks.json
│   │   ├── scripts/ (detect-stack, run-checks, guard-sensitive, validate-contract)
│   │   ├── config/ (stacks.json, sensitive-patterns.json)
│   │   └── tests/ (test-plugin-structure.sh, test-hooks.sh)
│   ├── cicd-security-triage/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/ (3: Analyst, Fixer, QA Security)
│   │   ├── skills/ (3: severity-rules, false-positive-triage, report-formats)
│   │   ├── commands/security-triage.md
│   │   ├── scripts/ (parse-grype.py, parse-sonar.py, parse-stackhawk.py)
│   │   └── tests/ (test-parsers.py + fixtures/)
│   ├── frontend-ui/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/ (3: ui-designer, ui-implementer, ui-reviewer)
│   │   ├── skills/ (9: accessibility-wcag, responsive-and-performance, ui-review-checklist, design-system-foundations, react-component-patterns, tailwind-shadcn-stack, forms-and-validation, data-display-and-charts, angular-ui-patterns)
│   │   ├── commands/ui.md
│   │   └── scripts/ (check-a11y.sh, check-bundle.sh)
│   └── context-toolkit/
│       ├── .claude-plugin/plugin.json
│       ├── skills/ (3: claude-md-writer, codebase-map, session-handoff)
│       └── commands/ (handoff.md, map.md)
├── evals/
│   ├── cases/ (20 casos: 5 por plugin)
│   ├── results/ (output de ejecuciones)
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

## Uso Rápido - cicd-security-triage

```bash
# Triage completo de reporte de seguridad
/security-triage reports/grype-production.json

# Auto-fix después de triage
/security-triage reports/sonar-issues.json --auto-fix

# Solo priorizar (sin fix)
/security-triage reports/stackhawk-scan.json --priority-only
```

**Flujo**: Detecta parser → Normaliza reporte → Analyst (clasifica + descarta FP) → Fixer (propone fix mínimo) → QA Security (valida)

## Uso Rápido - frontend-ui

```bash
# Diseñar e implementar pantalla
/ui "Dashboard de usuario con sidebar navegación, grid de métricas (4 widgets), tabla de actividad con paginación y filtros"
```

**Flujo**: UI Designer → UI Implementer → UI Reviewer (41 reglas de accesibilidad, responsive, consistencia, performance)

```bash
# Validar accesibilidad localmente
./plugins/frontend-ui/scripts/check-a11y.sh

# Validar bundle size
./plugins/frontend-ui/scripts/check-bundle.sh --budget=500
```

## Uso Rápido - context-toolkit

```bash
# Mapear codebase
/map

# Generar mapa con profundidad personalizada
/map --depth=4 --dir=plugins/frontend-ui

# Generar resumen de sesión para handoff
/handoff --objective="Implementar fase 9" --scope=changed
```

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

Validación local (Linux/macOS):
```bash
./scripts/validate-all.sh
# 11 JSON files + 15 frontmatter + 12 scripts + 25 skills + 20 eval cases
```

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

## Evaluaciones (Fase 9 - Completada)

```
evals/
├── cases/
│   ├── dev-workflow/ (5 casos: feature, bug, refactor, security, migration)
│   ├── cicd-security-triage/ (5 casos: triage, FP, fix validation, config, audit)
│   ├── frontend-ui/ (5 casos: dashboard, accessibility, responsive, forms, charts)
│   └── context-toolkit/ (5 casos: handoff, map, claude-md, tokens, recovery)
├── results/ (output de ejecuciones)
├── run-evals.py (ejecuta, puntúa, compara CON vs SIN plugin)
└── README.md (metodología, métricas, limitaciones)
```

```bash
# Ejecutar todas las evaluaciones
python3 evals/run-evals.py

# Solo un plugin
python3 evals/run-evals.py --plugin frontend-ui

# Output JSON
python3 evals/run-evals.py --format json
```

## Licencia

MIT License - ver [LICENSE](LICENSE)

## Autor

Abel Gomez - Backend/Fullstack Developer  
Java 21, Spring Boot, Kafka, gRPC, Oracle PL/SQL, React, Angular, Python

---

## Estado Actual (Fase 10 Completada)

✅ **Completado** (10 fases):
- **Fase 1**: Marketplace con 4 plugins declarados
- **Fase 2**: dev-workflow: 4 agentes, workflow-contract skill + schema
- **Fase 3**: dev-workflow: 10 skills + feature.md command
- **Fase 4**: Hooks, scripts, config (stacks.json, sensitive-patterns.json, hooks.json)
- **Fase 5**: Tests, CI/CD, docs (validate-all.sh, GitHub Actions)
- **Fase 6**: cicd-security-triage: 3 agents, 3 skills, 3 parsers, 4 fixtures, 1 command, 1 test
- **Fase 7**: frontend-ui: 3 agents, 9 skills, 1 command, 2 scripts (check-a11y, check-bundle)
- **Fase 8**: context-toolkit: 3 skills, 2 commands (handoff, map)
- **Fase 9**: Evaluation Harness: 20 casos (5/plugin), run-evals.py, README.md
- **Fase 10**: CHANGELOG.md, README final, TESTING-STATUS actualizado

🚧 **Pendiente** (por limitaciones del entorno):
- Validación de hooks/frontmatter contra spec oficial de Claude Code (no disponible en este entorno)
- Ejecución real de parsers Python (Python no disponible en Git Bash Windows)
- Ejecución real de flujos multiagentes (requiere Claude Code runtime)
- Versión .ps1 de scripts para Windows nativo

## Honestidad sobre Validación

Ver `docs/TESTING-STATUS.md` para clasificación detallada:
- ✅ **verificado**: Ejecutado y pasado
- 🟡 **parcialmente verificado**: Parcialmente ejecutado o con caveats
- ❌ **no verificado**: No ejecutado, solo asumido/planificado

**No se afirman ahorros de tokens no medidos**. La ganancia del flujo multiagente está en contexto principal limpio y calidad, no en menor coste.