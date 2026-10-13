# Evaluaciones (Evil Harness) - ai-dev-toolkit

## Visión General

El evaluation harness valida el impacto de los plugins de ai-dev-toolkit comparando resultados **CON** el plugin activado vs **SIN** el plugin (baseline manual). Los casos están diseñados para ser ejecutados con Claude Code real (Task tool) o simulados para validación preliminar.

## Estructura

```
evals/
├── cases/
│   ├── dev-workflow/           # 5 casos (feature, bug, refactor, security, migration)
│   ├── cicd-security-triage/   # 5 casos (vuln triage, FP detection, fix validation, config hardening, code audit)
│   ├── frontend-ui/            # 5 casos (dashboard, accessibility form, responsive table, forms, charts)
│   └── context-toolkit/        # 5 casos (handoff, codebase-map, claude-md, token savings, error recovery)
├── results/                     # Output de ejecuciones (eval-results-{timestamp}.md)
├── run-evals.py                 # Runner script
└── README.md                    # Este archivo
```

## Casos de Evaluación por Plugin

### dev-workflow (5 casos)

| Caso | ID | Dificultad | Est. Tokens CON / SIN |
|------|----|------------|-----------------------|
| New API Endpoint | `01-feature-new-endpoint` | Medium | 45K / 35K |
| Nullpointer Fix | `02-bug-nullpointer-fix` | Easy | 25K / 20K |
| Clean Architecture Refactor | `03-refactor-clean-architecture` | Hard | 65K / 50K |
| Security Hardening | `04-security-hardening` | Hard | 55K / 40K |
| Spring 3 Migration | `05-migration-spring-3` | Hard | 50K / 35K |

### cicd-security-triage (5 casos)

| Caso | ID | Dificultad | Est. Tokens CON / SIN |
|------|----|------------|-----------------------|
| Vulnerability Triage | `01-vuln-triage-grype` | Medium | 18K / 12K |
| False Positive Detection | `02-false-positive-detection` | Hard | 22K / 15K |
| Fix Validation | `03-fix-validation-upgrade` | Medium | 19K / 14K |
| Config Hardening | `04-config-hardening-dockerfile` | Medium | 20K / 15K |
| SQL Injection Audit | `05-code-audit-sql-injection` | Hard | 25K / 18K |

### frontend-ui (5 casos)

| Caso | ID | Dificultad | Est. Tokens CON / SIN |
|------|----|------------|-----------------------|
| Dashboard Implementation | `01-design-to-dashboard` | Medium | 38K / 28K |
| Accessibility Form | `02-accessibility-form` | Hard | 35K / 25K |
| Responsive Data Table | `03-responsive-data-table` | Hard | 42K / 30K |
| Multi-step Checkout | `04-forms-checkout` | Hard | 45K / 32K |
| Analytics Charts | `05-data-charts-analytics` | Hard | 48K / 35K |

### context-toolkit (5 casos)

| Caso | ID | Dificultad | Est. Tokens CON / SIN |
|------|----|------------|-----------------------|
| Session Handoff | `01-handoff-session-continuity` | Medium | 8K / 6K |
| Codebase Map | `02-codebase-map` | Medium | 15K / 10K |
| Claude MD Writer | `03-claude-md-writer` | Easy | 12K / 18K |
| Token Savings | `04-token-savings-optimization` | Medium | 2K / 50K |
| Error Recovery | `05-error-recovery-resume` | Hard | 3K / 4.8K |

## Ejecución

### Simulación (preliminar)
```bash
# Ejecutar todos los casos (simulación basada en expected values)
python3 evals/run-evals.py

# Solo un plugin
python3 evals/run-evals.py --plugin frontend-ui

# Output JSON
python3 evals/run-evals.py --format json
```

### Real (requiere Claude Code runtime)
```bash
# Los casos están diseñados para ejecutarse con Claude Code real
# usando el feature command (/feature) o directamente con agentes

# Para cada caso, comparar:
# CON: /feature "prompt del caso" → medir resultados
# SIN: Claude Code base sin plugins → medir resultados
# Guardar diffs en evals/results/

# TODO: Integrar con Claude Code Task tool para ejecución automática
```

## Métricas Medidos

| Categoría | Métricas |
|-----------|----------|
| **Calidad** | review_findings (blocker/major), axe violations, schema_valid, tests passing |
| **Tokens** | con_tokens, sin_tokens, token_savings_pct |
| **Tiempo estimado** | con_time_min, sin_time_min |
| **Compleción** | metrics_verified, files_created, todos_completed |
| **Security** | security_findings, omissions |

## Score Calculation

```
Score = Σ(metric_value / expected_value × weight) / Σ(weights) × 10

- CON score: con_metric / con_expected (higher is better)
- SIN score: sin_metric / sin_expected (higher is better)
- For token metrics: expected / actual (lower is better)

Final score range: 0.0 - 10.0
Improvement = CON score - SIN score
```

## Limitaciones

1. **Simulación vs Real**: El `run-evals.py` actual usa valores simulados. Para resultados precisos, ejecutar con Claude Code runtime.
2. **Token counting**: Los tokens estimados son basados en tamaño de output esperado, no medición directa.
3. **No runtime access**: No se puede validar ejecución real de agentes en este entorno.
4. **Subjectivity**: Algunas métricas (code quality, architecture) requieren juicio humano.
5. **Time variance**: Los tiempos estimados varían según hardware y latencia de API.

## Metodología CON vs SIN

| Aspecto | CON (con plugins) | SIN (baseline) |
|---------|-------------------|----------------|
| Prompt inicial | `/feature "..."` o prompt del caso | Prompt directo a Claude Code |
| Contexto inicial | Plugin + CLAUDE.md + skills cargados | Solo AGENTS.md |
| Agentes disponibles | 10 agentes especializados | Claude Code base (sin subagentes) |
| Skills disponibles | 24 skills especializados | Sin skills |
| Hooks activos | validate-contract, guard-sensitive, etc. | Sin hooks |
| Output esperado | Código estructurado, tests, validaciones | Código funcional básico |