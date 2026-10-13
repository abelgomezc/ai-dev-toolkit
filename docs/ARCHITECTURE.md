# Arquitectura del ai-dev-toolkit

## Visión General

El `ai-dev-toolkit` es un marketplace de plugins para Claude Code que proporciona agentes y skills de nivel experto para flujos de desarrollo profesional. Cada plugin es independiente pero sigue convenciones compartidas.

## Principios de Diseño

### 1. Experto, no Genérico
- Cada skill/agent contiene decisiones concretas y con opinión
- Antipatrones con código malo/bueno verificable
- Criterios citables ("falla regla 7") no comentarios vagos
- Si Claude ya lo hace por defecto, no va en el skill

### 2. Ahorro de Contexto y Tokens
- `SKILL.md` corto y enfocado; detalle en archivos referenciados
- Descripciones precisas: cuándo usar y cuándo NO usar
- Subagentes de solo lectura devuelven resúmenes estructurados
- Scripts deterministas para parsing, linting, blocking
- `CLAUDE.md` mínimos en plugins

### 3. Honestidad sobre Validación
- `docs/TESTING-STATUS.md` clasifica: verificado / parcialmente verificado / no verificado
- No afirmar ahorros de tokens no medidos
- Documentar limitaciones en `evals/README.md`

## Arquitectura de Plugins

### Estructura Común
```
plugin-name/
├── .claude-plugin/plugin.json     # Manifiesto del plugin
├── agents/                        # Subagentes (frontmatter + markdown)
├── skills/                        # Skills (SKILL.md + refs)
├── commands/                      # Comandos slash (frontmatter + markdown)
├── hooks/                         # hooks.json + scripts
├── scripts/                       # Scripts bash deterministas
├── config/                        # JSON de configuración
├── tests/                         # Tests de estructura/hooks
├── CLAUDE.md                      # Contexto mínimo para el plugin
├── README.md                      # Documentación del plugin
└── CHANGELOG.md                   # Historial de cambios
```

### Marketplace
```
.claude-plugin/marketplace.json    # Declara todos los plugins
```

## Flujo Multiagente (dev-workflow)

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────┐
│  Architect  │────▶│ Implementer  │────▶│  Reviewer   │────▶│ QA  │
│  (read)     │     │  (write)     │     │  (read)     │     │(run)│
└─────────────┘     └──────────────┘     └─────────────┘     └─────┘
       │                    │                    │               │
       ▼                    ▼                    ▼               ▼
  Plan + AC           Code + tests         Findings          Approve/
  workflow-contract   workflow-contract    workflow-contract  Reject
       │                    │                    │               │
       └────────────────────┴────────────────────┴───────────────┘
                                    │
                                    ▼
                          workflow-contract.json
                          (estado compartido)
```

### Contrato de Flujo (workflow-contract)
- Archivo JSON único por tarea: `.claude-workflow/contracts/{task_id}.json`
- Esquema fijo (JSON Schema Draft 2020-12)
- Campos por etapa: architect → implementer → reviewer → qa
- Inmutabilidad: cada etapa solo agrega, no modifica campos previos
- Validación automática contra schema

### Agentes

| Agente | Permisos | Responsabilidad |
|--------|----------|-----------------|
| Architect | Read, Glob, Grep, WebFetch, WebSearch | Análisis, plan, criterios de aceptación |
| Implementer | Read, Write, Edit, MultiEdit, Glob, Grep, Bash, Task | Implementación, tests, run-checks.sh |
| Reviewer | Read, Glob, Grep, WebFetch, WebSearch | Review con checklist, hallazgos clasificados |
| QA | Read, Bash, Glob, Grep | Ejecuta tests, verifica AC, decide approve/reject |

### Ciclos de Retroalimentación
- **Reviewer → Implementer**: Máx 3 ciclos si hay blockers/majors
- **QA → Implementer**: Máx 3 ciclos totales si rejected
- Al superar límite: reporte final al usuario, no loop infinito

## Skills de Dominio

### Stack Detection
- `stack-detector`: Detecta stack por evidencia en archivos de config (pesos)
- `supported-stacks.json`: Configuración de stacks soportados y comandos

### Stack Conventions
- `stack-java-spring`: 10 reglas verificables (Java 21, constructor injection, records, etc.)
- `stack-python-fastapi`: 10 reglas (Python 3.11+, tipado estricto, Depends, async, etc.)

### Domain Patterns
- `spring-microservices-patterns`: Saga, Outbox, Idempotencia, DLQ, gRPC resilience, Consistencia eventual
- `api-design-review`: 12 reglas (versionado, RFC 7807, HTTP codes, paginación, idempotency-key, etc.)
- `security-review-owasp`: 27 reglas mapeadas a OWASP Top 10 2021 + ASVS Level 2
- `db-migration-review`: 12 reglas (versionado, rollback, expand/contract, zero-downtime, PL/SQL)

### Quality
- `review-checklist`: 28 reglas en 6 secciones (Correctness, Arquitectura, API, BD, Testing, Observabilidad)
- `test-strategy`: Pirámide testing, verification methods, thresholds, Testcontainers
- `workflow-contract`: Esquema JSON + ejemplo + script validación

## Hooks y Automatización

### Hooks del dev-workflow
1. **run-checks-post-edit** (post_edit): Ejecuta lint/typecheck/tests tras editar código
2. **guard-sensitive-pre-edit** (pre_edit): Bloquea edición de .env, claves, credenciales

### Scripts Deterministas
- `detect-stack.sh`: Devuelve JSON con stack detectado
- `run-checks.sh`: Ejecuta pipeline completo según stack/herramienta
- `guard-sensitive.sh`: Bloquea archivos/contenido sensible
- `validate-contract.sh`: Valida contrato contra JSON Schema

## Otros Plugins

### cicd-security-triage
- Parsers Python normalizan reportes Grype/SonarQube/StackHawk ANTES de que el modelo los lea
- Agentes: analyst (clasifica, descarta FP), fixer (propone fix mínimo), qa (valida fix)
- Fixtures anonimizados + tests de parsers
- 3 skills: severity-rules (R1-R10), false-positive-triage (R1-R7), report-formats (schema v1.0, R1-R8)
- Command: /security-triage (entry point con parser detection + auto-fix)

### frontend-ui
- Agentes: ui-designer (read), ui-implementer (write), ui-reviewer (read)
- Stack principal: React 18 + TS + Tailwind + shadcn/ui + React Hook Form + Zod + TanStack Query + Recharts
- Stack alterno: Angular 17+ (Material/PrimeNG)
- Skills: design-system, component-patterns, a11y (WCAG-1 through WCAG-9), responsive (RAP-1 through RAP-14), forms, charts, review-checklist (41 rules R1-R41)
- Scripts: check-a11y.sh, check-bundle.sh

### context-toolkit
- Skills: claude-md-writer (R1-R6), codebase-map (R1-R8), session-handoff (R1-R8)
- Comandos: handoff.md, map.md
- Enfoque: continuidad entre sesiones, ahorro de tokens (output < 4KB)

## Evaluaciones (evals)

```
evals/
├── cases/              # ≥5 casos por plugin principal
│   ├── dev-workflow/
│   ├── cicd-security-triage/
│   ├── frontend-ui/
│   └── context-toolkit/
├── run-evals.py        # Ejecuta casos, puntúa, compara CON/SIN plugin
└── README.md           # Documentación y limitaciones
```

### Criterios de Evaluación
- Entrada → Salida esperada → Criterio de puntuación
- Comparación: misma tarea CON plugin vs SIN plugin
- Resultados registrados en `TESTING-STATUS.md` tal cual (aunque no favorables)
- 20 casos totales (5 por plugin), run-evals.py con modo simulación + metodología CON vs SIN

## CI/CD

### Pipeline (`.github/workflows/validate.yml`)
1. **validate**: JSON, frontmatter, shellcheck, test-plugin-structure, test-hooks, schema, scripts, skills validation
2. **validate-marketplace**: marketplace.json estructura + 4 plugins
3. **validate-plugins**: Cada plugin individual (matrix)

### Validación Local
```bash
./scripts/validate-all.sh
# Validates: 11 JSON files, 15 frontmatter files, 12 scripts, 25 skills
# Runs: test-plugin-structure.sh, test-hooks.sh
```

## Limitaciones Conocidas

1. **Frontmatter de agentes/comandos**: Basado en convenciones asumidas, no validado contra spec oficial de Claude Code
2. **Hooks**: Esquema `hooks.json` asumido; variables `${plugin_root}`, `${file_path}` son placeholders
3. **Integración subagentes**: Mecanismo real de invocación (Task tool?) no confirmado
4. **Persistencia de contrato**: Ubicación `.claude-workflow/contracts/` asumida
5. **Bash en Windows**: Scripts requieren WSL/Git Bash; no hay versiones .ps1
6. **Dependencias**: `jq`, `python3`, `jsonschema` requeridos para validación completa
7. **Versiones librerías**: Spring Boot 3.2.x, FastAPI 0.109+, etc. - verificar al usar
8. **Python no disponible**: Parsers y run-evals.py no ejecutables en Git Bash Windows
9. **Token savings no medidos**: Los ahorros en evals son estimados, no medidos en runtime real

## Decisiones de Diseño Clave

| Decisión | Razón |
|----------|-------|
| JSON Schema para contrato | Validación automática, tipado, documentación |
| Scripts bash deterministas | Ahorro tokens, reproducibilidad, no depende del modelo |
| Skills con archivos de referencia | SKILL.md corto, carga perezosa de detalle |
| Reglas numeradas citables | Reviewer objetivo, automatizable |
| Máx 3 ciclos retroalimentación | Evita loops infinitos, fuerza resolución |
| Marketplace.json en raíz | Descubrimiento estándar, un solo archivo |
| TESTING-STATUS.md honesto | Confianza, portfolio realista |