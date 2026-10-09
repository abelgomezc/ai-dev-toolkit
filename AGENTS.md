# Agents - ai-dev-toolkit

## Visión General

Este documento describe todos los agentes (subagentes) disponibles en el marketplace `ai-dev-toolkit`, organizados por plugin. Cada agente tiene un rol específico, permisos definidos (herramientas) y restricciones claras.

## Convenciones de Agentes

### Frontmatter Estándar
```yaml
---
name: agent-name
description: Descripción precisa: qué hace, cuándo usarlo, cuándo NO, herramientas
tools: [Tool1, Tool2, ...]
---
```

### Permisos por Tipo
- **Solo lectura**: `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`
- **Escritura**: `Write`, `Edit`, `MultiEdit`, `Bash`, `Task`
- **Todos**: Combinación de ambos

### Principio: Separación de Responsabilidades
- **Un solo agente con escritura** por flujo (Implementer / UI Implementer / Fixer)
- **Agentes de revisión son solo lectura** (Reviewer / QA / Analyst / UI Reviewer)
- **Arquitectos/Diseñadores son solo lectura** (Architect / UI Designer)

---

## Plugin: dev-workflow

### 1. Architect (architect.md)
**Rol**: Arquitecto de software. Analiza requerimientos, diseña solución técnica, produce plan ejecutable.

**Herramientas**: `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch` (solo lectura)

**Responsabilidades**:
1. Análisis de la tarea y detección de stack (`stack-detector`)
2. Diseño de arquitectura, patrones, contratos API, modelo de datos
3. Plan de implementación: pasos numerados con criterios de aceptación verificables
4. Identificación de riesgos, decisiones críticas, deuda técnica

**Restricciones**:
- ❌ NO escribe código
- ❌ NO modifica archivos
- ✅ Solo lee y analiza
- ✅ Salida: `workflow-contract` con `stage: "architect"`, `acceptance_criteria`, `next_action: "implement"`

**Skills que usa**: `stack-detector`, `workflow-contract`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review`

---

### 2. Implementer (implementer.md)
**Rol**: Implementador único. Ejecuta el plan del Architect paso a paso.

**Herramientas**: `Read`, `Write`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `Bash`, `Task` (lectura + escritura)

**Responsabilidades**:
1. Leer `workflow-contract` del Architect (`stage: "architect"`)
2. Implementar cada paso en orden, sin saltarse ninguno
3. Aplicar convenciones del stack (`stack-java-spring` / `stack-python-fastapi`)
4. Aplicar patterns de dominio (`spring-microservices-patterns`, `api-design-review`, etc.)
5. Escribir tests según `test-strategy`
6. Ejecutar `run-checks.sh` localmente antes de entregar

**Restricciones**:
- ✅ **ÚNICO agente con permisos de escritura** en el flujo
- ❌ NO amplía el alcance (solo lo que está en el plan)
- ❌ NO toma decisiones arquitectónicas nuevas
- ❌ NO salta pasos del plan
- Si paso falla → `next_action: "replan"` (vuelve al Architect)

**Salida**: `workflow-contract` actualizado con `stage: "implementer"`, `artifacts`, `local_verification`, `next_action: "review"`

**Skills que usa**: `stack-java-spring` / `stack-python-fastapi`, `test-strategy`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review`

---

### 3. Reviewer (reviewer.md)
**Rol**: Revisor de código. Evalúa implementación contra plan, checklist y skills de dominio.

**Herramientas**: `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch` (solo lectura)

**Responsabilidades**:
1. Leer `workflow-contract` del Implementer (`stage: "implementer"`)
2. Leer todos los archivos en `artifacts`
3. Aplicar `review-checklist` (28 reglas en 6 secciones)
4. Aplicar skills de dominio según stack detectado
5. Clasificar hallazgos: **Blocker** / **Major** / **Minor** / **Info**
6. Citar regla exacta: `"spring-microservices-patterns regla 3"`, `"security-review-owasp regla 7"`

**Restricciones**:
- ❌ NO sugiere código alternativo
- ❌ NO opina sin fundamento (cada hallazgo = regla numerada)
- ✅ Solo lectura
- Si **blockers** → `next_action: "implement"` (vuelve a Implementer)
- Si **solo majors/minors** → `next_action: "qa"` (pasa a QA)

**Salida**: `workflow-contract` con `stage: "reviewer"`, `findings[]`, `blockers_count`, `majors_count`, `minors_count`

**Skills que usa**: `review-checklist`, `stack-java-spring` / `stack-python-fastapi`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review`

---

### 4. QA (qa.md)
**Rol**: Quality Assurance. Valida criterios de aceptación y ejecuta tests.

**Herramientas**: `Read`, `Bash`, `Glob`, `Grep` (lectura + ejecución tests)

**Responsabilidades**:
1. Leer `workflow-contract` del Reviewer (`stage: "reviewer"`)
2. Leer `acceptance_criteria` del plan original (Architect)
3. Determinar comandos de prueba según stack (`config/stacks.json`)
4. Ejecutar suite: unitarias, integración, contrato, E2E
5. Verificar cada criterio de aceptación (evidencia ejecutable)
6. Revisar hallazgos del Reviewer: confirmar blockers/majors resueltos
7. Decidir: **Approved** / **Rejected** con motivos concretos

**Restricciones**:
- ❌ NO modifica código de producción
- ❌ NO crea tests nuevos (trabajo del Implementer)
- ✅ Decisión binaria: approved / rejected
- ✅ Motivos concretos: cita criterio fallido o hallazgo no resuelto
- ✅ Máximo **3 ciclos de rechazo** total

**Ciclos**:
- Ciclo 1: Rejected → `next_action: "implement"` con `decision` detallada
- Ciclo 2: Rejected → `next_action: "implement"` con `decision` detallada
- Ciclo 3: Rejected → `next_action: "done"`, `status: "rejected_max_cycles"`, reporte final

**Salida**: `workflow-contract` con `stage: "qa"`, `decision: {decision, cycle, verified_criteria[], failed_criteria[], reviewer_findings_resolved, test_results}`

**Skills que usa**: `test-strategy`, `config/stacks.json`

---

## Plugin: cicd-security-triage

### 5. Analyst (analyst.md)
**Rol**: Analista de seguridad. Clasifica hallazgos, descarta falsos positivos, prioriza.

**Herramientas**: `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch` (solo lectura)

**Responsabilidades**:
1. Leer reportes normalizados (output de parsers Python)
2. Clasificar cada hallazgo usando `severity-rules` (explotabilidad, exposición, fix disponible)
3. Descartar falsos positivos **justificando cada descarte**
4. Priorizar: Crítico > Alto > Medio > Bajo (no solo CVSS)
5. Producir lista priorizada con razonamiento

**Restricciones**:
- ❌ NO propone fixes (eso es Fixer)
- ✅ Solo lectura y análisis

---

### 6. Fixer (fixer.md)
**Rol**: Propone correcciones mínimas para hallazgos priorizados.

**Herramientas**: `Read`, `Write`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `Bash` (lectura + escritura)

**Responsabilidades**:
1. Recibir hallazgos priorizados del Analyst
2. Proponer corrección mínima: actualizar dependencia, cambiar config, parche de código
3. Explicar riesgo del cambio (breaking changes, compatibilidad)
4. Crear PR/borrador con el fix

**Restricciones**:
- ✅ Único con escritura en este plugin
- ❌ NO cambia alcance más allá del hallazgo

---

### 7. QA Security (qa.md)
**Rol**: Valida que la corrección resuelve el hallazgo y no rompe tests.

**Herramientas**: `Read`, `Bash`, `Glob`, `Grep`

**Responsabilidades**:
1. Aplicar fix propuesto por Fixer
2. Ejecutar tests de regresión
3. Verificar que hallazgo original ya no aparece (re-scan)
4. Confirmar no nuevos hallazgos introducidos
5. Aprobar / Rechazar fix

---

## Plugin: frontend-ui

### 8. UI Designer (ui-designer.md)
**Rol**: Diseñador de interfaces. Propone estructura, jerarquía, componentes, estados.

**Herramientas**: `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch` (solo lectura)

**Responsabilidades**:
1. Analizar requerimiento de UI/UX
2. Proponer: estructura de pantalla, jerarquía visual, componentes a usar
3. Definir estados: carga, vacío, error, éxito
4. Decisiones de diseño justificadas (accesibilidad, responsive, performance)
5. Referenciar `design-system-foundations`, `accessibility-wcag`, `responsive-and-performance`

**Restricciones**:
- ❌ NO implementa código
- ✅ Solo lectura y diseño

---

### 9. UI Implementer (ui-implementer.md)
**Rol**: Implementador de UI. Único con escritura en este plugin.

**Herramientas**: `Read`, `Write`, `Edit`, `MultiEdit`, `Glob`, `Grep`, `Bash`, `Task`

**Responsabilidades**:
1. Recibir diseño del UI Designer
2. Implementar siguiendo design system y skills de stack
3. Stack principal: React 18 + TypeScript + Tailwind + shadcn/ui (Radix) + React Hook Form + Zod + TanStack Query + Recharts
4. Stack alterno: Angular 17+ (Material/PrimeNG) via `angular-ui-patterns`
5. Ejecutar `check-a11y.sh` y `check-bundle.sh`

**Restricciones**:
- ✅ **ÚNICO con escritura** en frontend-ui
- ❌ NO se desvía del diseño aprobado

---

### 10. UI Reviewer (ui-reviewer.md)
**Rol**: Revisor de UI. Accesibilidad, responsividad, consistencia, performance.

**Herramientas**: `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch` (solo lectura)

**Responsabilidades**:
1. Revisar implementación contra diseño y skills
2. Verificar: `accessibility-wcag` (contraste, foco, teclado, ARIA), `responsive-and-performance` (mobile-first, breakpoints, lazy load, bundle size)
3. Verificar consistencia visual con `design-system-foundations`
4. Verificar estados faltantes (carga, vacío, error)
5. Citar reglas de `ui-review-checklist`

**Restricciones**:
- ❌ NO modifica código
- ✅ Solo lectura

---

## Plugin: context-toolkit

### Sin agentes dedicados
Este plugin solo provee **skills** y **comandos**:
- `claude-md-writer`: Genera/maintains CLAUDE.md
- `codebase-map`: Mapa compacto del repo
- `session-handoff`: Resumen de sesión para continuidad
- Comandos: `/handoff`, `/map`

---

## Matriz de Permisos

| Agente | Plugin | Read | Write | Edit | MultiEdit | Bash | Task | WebFetch | WebSearch | Glob | Grep |
|--------|--------|------|-------|------|-----------|------|------|----------|-----------|------|------|
| Architect | dev-workflow | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Implementer | dev-workflow | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| Reviewer | dev-workflow | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| QA | dev-workflow | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Analyst | cicd-security-triage | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Fixer | cicd-security-triage | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |
| QA Security | cicd-security-triage | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ |
| UI Designer | frontend-ui | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| UI Implementer | frontend-ui | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| UI Reviewer | frontend-ui | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |

---

## Flujo de Trabajo por Plugin

### dev-workflow: Feature Development
```
/feature "descripción"
    │
    ▼
┌─────────────────────────────────────┐
│  Architect (read)                   │
│  → workflow-contract (plan + AC)    │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Implementer (write)                │
│  → code + tests + run-checks.sh     │
│  → workflow-contract (artifacts)    │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Reviewer (read)                    │
│  → review-checklist + domain skills │
│  → findings (blocker/major/minor)   │
│  → workflow-contract (findings)     │
└─────────────────────────────────────┘
    │
    ├─ blockers/majors ──▶ Implementer (max 3 ciclos)
    │
    ▼
┌─────────────────────────────────────┐
│  QA (read + bash)                   │
│  → tests + verify AC                │
│  → decision: approved/rejected      │
│  → workflow-contract (decision)     │
└─────────────────────────────────────┘
    │
    ├─ rejected ──▶ Implementer (max 3 ciclos totales)
    │
    ▼
┌─────────────────────────────────────┐
│  DONE / REPORT TO USER              │
└─────────────────────────────────────┘
```

### cicd-security-triage: Security Triage
```
/security-triage <reporte>
    │
    ▼
┌─────────────────────────────────────┐
│  Parser (script)                    │
│  → reporte normalizado JSON         │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Analyst (read)                     │
│  → clasificación + FP justificados  │
│  → priorización severity-rules      │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  Fixer (write)                      │
│  → fix mínimo + riesgo explicado    │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  QA Security (read + bash)          │
│  → valida fix + no regresiones      │
└─────────────────────────────────────┘
```

### frontend-ui: UI Development
```
/ui "descripción pantalla"
    │
    ▼
┌─────────────────────────────────────┐
│  UI Designer (read)                 │
│  → propuesta diseño + justificación │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  UI Implementer (write)             │
│  → código + check-a11y + check-bundle│
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│  UI Reviewer (read)                 │
│  → a11y + responsive + consistency  │
│  → ui-review-checklist              │
└─────────────────────────────────────┘
```

---

## Referencias Rápidas

### Comandos de Entrada
| Plugin | Comando | Descripción |
|--------|---------|-------------|
| dev-workflow | `/feature` | Lanza flujo multiagente completo |
| cicd-security-triage | `/security-triage` | Lanza triage de reporte seguridad |
| frontend-ui | `/ui` | Lanza flujo diseño→implementación→review |
| context-toolkit | `/handoff` | Genera resumen de sesión |
| context-toolkit | `/map` | Genera mapa del codebase |

### Skills Clave por Agente
| Agente | Skills Principales |
|--------|-------------------|
| Architect | `stack-detector`, `workflow-contract`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review` |
| Implementer | `stack-java-spring`/`stack-python-fastapi`, `test-strategy`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review` |
| Reviewer | `review-checklist`, `stack-java-spring`/`stack-python-fastapi`, `spring-microservices-patterns`, `api-design-review`, `security-review-owasp`, `db-migration-review` |
| QA | `test-strategy`, `config/stacks.json` |
| Analyst | `severity-rules`, `false-positive-triage`, `report-formats` |
| Fixer | `severity-rules`, `report-formats` |
| UI Designer | `design-system-foundations`, `accessibility-wcag`, `responsive-and-performance` |
| UI Implementer | `react-component-patterns`, `tailwind-shadcn-stack`, `forms-and-validation`, `data-display-and-charts` |
| UI Reviewer | `accessibility-wcag`, `responsive-and-performance`, `ui-review-checklist` |

---

## Notas de Implementación

1. **Frontmatter `tools`**: Lista exacta de herramientas permitidas. Claude Code valida esto al invocar el agente.

2. **Agentes de solo lectura**: Nunca deben tener `Write`, `Edit`, `MultiEdit`, `Bash`, `Task` en su lista de tools.

3. **Agente único con escritura**: Por flujo, solo un agente tiene permisos de escritura para evitar conflictos y mantener trazabilidad.

4. **Contrato compartido**: `workflow-contract` es el único mecanismo de paso de estado entre agentes en dev-workflow.

5. **Máximo 3 ciclos**: Hard limit para evitar loops infinitos. Al superar, reporte final al usuario.