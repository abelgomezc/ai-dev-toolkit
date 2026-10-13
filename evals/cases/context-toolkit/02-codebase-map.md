# Eval Case: Codebase Map - Architecture Discovery

## Plugin
context-toolkit

## Escenario
Un nuevo miembro del equipo se une al proyecto y necesita entender la arquitectura rápidamente. El `/map` command debe generar un mapa que le permita navegar en <2 minutos.

## Input (Prompt)
```
/map --depth=3 --check-duplicates --check-dead-code

Proyecto: ai-dev-toolkit
Estructura: Monorepo con 4 plugins (dev-workflow, cicd-security-triage, frontend-ui, context-toolkit)
Tecnologías: Markdown, Python scripts, Bash scripts, JSON configs
Entry points: AGENTS.md, plugins/*/commands/*.md, scripts/validate-all.sh
```

## Métricas de Evaluación

| Métrica | CON Plugin | SIN Plugin (manual) |
|---------|-----------|---------------------|
| Entry points identified | ✅ AGENTS.md, 4 command files, validate-all.sh | ⚠️ solo AGENTS.md |
| Module boundaries | ✅ 4 plugins con conteos precisos | ⚠️ agrupación genérica |
| Hotspots identified | ✅ AGENTS.md (409 lines), analyst.md (~79) | ⚠️ solo AGENTS.md |
| Duplicates detected | ✅ `set -euo pipefail` pattern (intencional) | ❌ |
| Dead code found | ✅ evals/ vacío, TESTING-STATUS referencias obsoletas | ⚠️ solo "todo OK" |
| Total counts accurate | ✅ files/lines/plugins/agents/skills/commands | ⚠️ estimados |
| Compactness (< 4KB) | ✅ 3.2KB | N/A |
| Time to understand | < 2 minutos | 5-10 minutos |

## Expected Outcome
- **CON Plugin**: Mapa con 5 entry points identificados, 4 módulos con conteos (dev-workflow: 12 files/4 agents, cicd-security-triage: 15 files/3 agents, etc.), AGENTS.md como hotspot principal, duplicates reportados (boilerplate excluidos), dead code detectado (evals empty dir, TESTING-STATUS líneas obsoletas), counts totales precisos, output 3.2KB.
- **SIN Plugin**: Lista de directorios genérica, conteos aproximados, sin hotspots/duplicates/dead code analysis.

## Difficulty: Medium
## Est. Tokens: 15,000 (CON) vs 10,000 (SIN)

## Skill References
- codebase-map R1-R8 (entry points, tree depth, hotspots, duplicates, dead code, size)
- claude-md-writer R2 (estructura de directorios)