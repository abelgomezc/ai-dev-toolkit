# Session Handoff Skill

## Cuándo usarlo
- **Al finalizar sesión**: Genera handoff para reanudar sin pérdida de contexto
- **Al cambiar de foco**: Handoff rápido entre features/temas
- **Al transferir a otro agente/human**: Contexto completo del trabajo realizado

## Cuándo NO usarlo
- Para documentación permanente (usa CLAUDE.md)
- Como sustituto de commits de Git
- Para comunicación en tiempo real (usa Task tool)

## Descripción
El skill **session-handoff** captura el estado de una sesión Claude Code y genera un `SESSION-HANDOFF.md` que permite a otra instancia (humana o agente) reanudar el trabajo con contexto completo.

## Formato de Handoff

```markdown
---
handoff_id: 550e8400-e29b-41d4-a716-446655440000
session_token_budget_used: ~45,000 tokens
model: claude-3-5-sonnet-20241022
timestamp: 2026-10-12T22:30:00Z
status: active  # active | completed | blocked
---

# Session Handoff - Context Toolkit Implementation

## 🎯 Objetivo Actual
Completar Fase 8: context-toolkit plugin (3 skills + 2 commands)

## ✅ Trabajo Completado

### Context Toolkit
- [x] skills/claude-md-writer/SKILL.md created (template + validation rules)
- [x] skills/codebase-map/SKILL.md created (algorithms + output structure)
- [x] skills/session-handoff/SKILL.md created (this file)
- [ ] commands/handoff.md — PENDIENTE
- [ ] commands/map.md — PENDIENTE
- [ ] plugin.json update — PENDIENTE (add commands array)

### Fases Completadas
- Phase 1: Skeleton & Marketplace ✅
- Phase 2: dev-workflow Agents & Contract ✅
- Phase 3: dev-workflow Skills & Command ✅
- Phase 4: Hooks, Scripts, Config ✅
- Phase 5: Tests, CI, Docs ✅
- Phase 6: cicd-security-triage ✅ (3 agents, 3 skills, 3 parsers, 4 fixtures, 1 command)
- Phase 7: frontend-ui ✅ (3 agents, 9 skills, 2 commands, 2 scripts)

### Fases Pendientes
- [ ] Phase 8: context-toolkit (skills ✅, commands ❌)
- [ ] Phase 9: Evaluation Harness (test cases + runner)
- [ ] Phase 10: Final iteration (CHANGELOG, README, docs)

## 🔄 Estado del Código

### Archivos Modificados en Esta Sesión
```diff
+ plugins/cicd-security-triage/commands/security-triage.md (NEW, 182 lines)
+ plugins/cicd-security-triage/.claude-plugin/plugin.json (MODIFIED - added commands array)
+ plugins/context-toolkit/skills/claude-md-writer/SKILL.md (NEW, 110 lines)
+ plugins/context-toolkit/skills/codebase-map/SKILL.md (NEW, 150 lines)
+ plugins/context-toolkit/skills/session-handoff/SKILL.md (NEW, 110 lines)
```

### Issues Conocidos
1. **Scripts no ejecutables en Windows**: Los scripts bash (.sh) y Python (.py) no tienen permisos de ejecución en Windows. En Linux/macOS usar: `chmod +x scripts/*.sh`
2. **test-parsers.py requiere Python 3**: No disponible en Git Bash Windows. Validar en CI Linux.
3. **validate-all.sh**: No incluye cicd-security-triage ni frontend-ui en validaciones (pendiente de update)

## 📋 Tareas Pendientes (Next Actions)

### Inmediato (Esta sesión)
1. [ ] Crear `plugins/context-toolkit/commands/handoff.md`
2. [ ] Crear `plugins/context-toolkit/commands/map.md`
3. [ ] Actualizar `plugins/context-toolkit/.claude-plugin/plugin.json` con commands array

### Siguiente sesión
1. [ ] Fase 9: Evaluation Harness
   - Crear `evals/cases/` con 5 casos por plugin (20 total)
   - Crear `scripts/run-evals.py`
   - Casos: feature, bug, refactor, security, migration (dev-workflow)
   - Casos: vuln-triage, fp-detection, fix-validation, config-hardening, code-audit (cicd-security-triage)
   - Casos: design→impl, a11y, responsive, forms, charts (frontend-ui)
   - Casos: handoff, map, claude-md (context-toolkit)

2. [ ] Fase 10: Finalización
   - Crear `CHANGELOG.md`
   - Actualizar `README.md`
   - Actualizar `docs/TESTING-STATUS.md`
   - Crear `docs/CODEBASE-MAP.md` (output de codebase-map skill)

## 🤝 Instrucciones para Reanudar

```bash
# Ver estado actual
git status
git log --oneline -5

# Ejecutar validaciones (Linux/macOS)
cd ai-dev-toolkit
./scripts/validate-all.sh

# Ver todos los archivos creados
find plugins/ -name "*.md" | wc -l
find plugins/ -name "*.py" | wc -l
find plugins/ -name "*.sh" | wc -l
```

## 🔗 Enlaces Útiles
- AGENTS.md: Definiciones centrales de agentes
- README.md: Documentación principal
- docs/ARCHITECTURE.md: Arquitectura del toolkit
- docs/CONVENTIONS.md: Convenciones del código
- docs/TESTING-STATUS.md: Estado de validaciones

---
*Handoff generado por session-handoff skill*
```

## Estructura del Handoff

```typescript
interface SessionHandoff {
  handoff_id: string;
  session_token_budget_used?: string;
  model: string;
  timestamp: string;
  status: "active" | "completed" | "blocked";
  objective: string;
  completed: TaskLog[];
  pending: Task[];
  code_changes: FileChange[];
  known_issues: KnownIssue[];
  blockers: Blocker[];
  next_actions: NextAction[];
  resume_instructions: string[];
}
```

## Algoritmo de Extracción

### 1. Task Detection
- Scan conversation transcript for task assignments
- Extract todos from `todowrite` tool calls
- Extract completed work from tool results

### 2. Code Change Detection
- `git status` → modified/new files
- `git diff --stat` → line counts
- Filter: exclude node_modules, .git, build artifacts

### 3. Issue Extraction
- Scan for error messages in tool outputs
- Extract from `error` field in JSON responses
- Categorize: blocking vs non-blocking

### 4. Context Compression
```python
# Regla: keep under 4KB para context budget
# Estrategia: summarize, don't copy entire file contents
# Use file paths + line numbers + key changes (diff style)
```

## CLI Usage

```bash
# Generar handoff al finalizar sesión
python3 plugins/context-toolkit/scripts/session-handoff.py

# Handoff con objetivo específico
python3 plugins/context-toolkit/scripts/session-handoff.py --objective "Implementar fase 9"

# Handoff con token budget remaining
python3 plugins/context-toolkit/scripts/session-handoff.py --tokens-remaining 50000

# Output a ubicación custom
python3 plugins/context-toolkit/scripts/session-handoff.py --output docs/HANDOFF-20261012.md
```

## Verificación
- **session-handoff R1**: ¿Objective + completed + pending claros?
- **session-handoff R2**: ¿Code changes capturados (git status + diff)?
- **session-handoff R3**: ¿Known issues + blockers documentados?
- **session-handoff R4**: ¿Next actions específicas y accionables?
- **session-handoff R5**: ¿Resume instructions incluyen comandos de verificación?
- **session-handoff R6**: ¿Output en < 4KB (context budget optimization)?
- **session-handoff R7**: ¿handoff_id único (UUID)?
- **session-handoff R8**: ¿timestamp en ISO 8601?