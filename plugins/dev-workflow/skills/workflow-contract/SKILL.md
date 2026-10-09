# Workflow Contract Skill

## Cuándo usarlo
**Siempre**. Es el formato obligatorio de entrega entre los 4 agentes del dev-workflow. Todos los agentes (architect, implementer, reviewer, qa) deben leer y escribir este contrato.

## Cuándo NO usarlo
Fuera del flujo dev-workflow. No es un formato de propósito general.

## Descripción
Define el esquema JSON fijo para el traspaso de estado entre agentes. Garantiza que cada agente recibe la información mínima necesaria y produce la salida esperada por el siguiente.

## Archivos de referencia
- `workflow-contract-schema.json` — Esquema JSON Schema (Draft 2020-12) para validación
- `workflow-contract-example.json` — Ejemplo completo con todos los campos

## Campos mínimos obligatorios
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `task_id` | string | UUID único de la tarea (generado al inicio) |
| `stage` | enum | "architect" \| "implementer" \| "reviewer" \| "qa" |
| `status` | enum | "pending" \| "in_progress" \| "completed" \| "blocked" \| "rejected" |
| `summary` | string | Resumen ejecutivo de lo hecho en esta etapa |
| `artifacts` | array | Archivos creados/modificados: `{path, purpose, status}` |
| `findings` | array | Hallazgos, riesgos, decisiones, debt técnico |
| `next_action` | enum | "implement" \| "review" \| "qa" \| "replan" \| "done" |

## Campos por etapa

### Architect (`stage: "architect"`)
- `acceptance_criteria`: array de `{id, description, verification_method, verified: false}`
- `stack_detected`: string (ej: "java-spring", "python-fastapi")
- `skills_applicable`: array de skill names referenciados
- `risk_assessment`: array de riesgos identificados

### Implementer (`stage: "implementer"`)
- `steps_completed`: array de step IDs del plan
- `deviations`: array de desviaciones del plan original con justificación
- `local_verification`: resultado de `run-checks.sh` (passed/failed + output)

### Reviewer (`stage: "reviewer"`)
- `findings`: array de `{severity, rule, file, line, description, suggestion}`
- `blockers_count`, `majors_count`, `minors_count`: contadores

### QA (`stage: "qa"`)
- `decision`: `{decision: "approved|rejected", cycle, verified_criteria[], failed_criteria[], reviewer_findings_resolved: boolean, test_results, notes}`
- `cycle`: número de ciclo (1-3)

## Reglas de uso
1. **Un solo archivo de contrato por tarea**: se actualiza in-place (append-only para findings/artifacts)
2. **Ubicación**: `.claude-workflow/contracts/{task_id}.json` en la raíz del proyecto
3. **Validación**: cada agente valida el contrato contra el schema antes de leer/escribir
4. **Inmutabilidad de campos previos**: un agente NO modifica campos escritos por agentes anteriores (solo agrega a `artifacts`, `findings`, y escribe sus propios campos de etapa)

## Antipatrón: contrato incompleto
```json
// MALO - campos mínimos faltantes
{"task_id": "abc", "stage": "implementer"}

// BUENO - contrato completo mínimo
{
  "task_id": "abc",
  "stage": "implementer",
  "status": "in_progress",
  "summary": "Implementando endpoint POST /users",
  "artifacts": [],
  "findings": [],
  "next_action": "review"
}
```

## Verificación
- `scripts/validate-contract.sh` valida contra el schema (ver scripts del plugin)