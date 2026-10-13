---
name: handoff
description: Genera resumen de sesión para continuidad entre sesiones. Captura trabajo completado, pendientes, issues, y next actions. Output < 4KB para context budget optimization.
tools: [Read, Write, Glob, Grep, Bash]
---

# Handoff Command - Session Continuity Tool

## Uso
```
/handoff [opciones]
```

## Opciones
| Flag | Descripción | Por defecto |
|------|-------------|-------------|
| `--objective="<texto>"` | Objetivo específico del handoff | Detectado del conversation summary |
| `--scope=<all\|changed\|tasks>` | Alcance: todo / solo archivos cambiados / solo tasks | all |
| `--output=<path>` | Path del output file | `SESSION-HANDOFF.md` |
| `--tokens-remaining=<n>` | Tokens restantes (context budget) | Auto-detectado |
| `--status=<active\|completed\|blocked>` | Estado del handoff | active |
| `--verbose` | Incluir diffs completos | false |

## Qué captura

### 1. Trabajo completado
- Archivos creados/modificados (via `git status` + `git diff --name-only`)
- Todos desde `todowrite` tool (completed items)
- Cambios significativos detectados en tool outputs

### 2. Tareas pendientes
- Todos desde `todowrite` (pending + in_progress)
- Próximos pasos inferidos del conversation context
- Prioridad: crítica → alta → media → baja

### 3. Issues conocidos
- Errores en tool outputs (`error:`, `Error:`, `Exception`)
- Warnings que requieren atención
- Limitaciones detectadas durante sesión

### 4. Next actions
- Acciones específicas para siguiente sesión
- Comandos de verificación
- Tests pendientes

## Output Format

```markdown
---
handoff_id: <UUID v4>
timestamp: <ISO 8601 UTC>
status: <active|completed|blocked>
tokens_remaining: <approximate>
---

# Session Handoff - <Objective>

## ✅ Trabajo Completado
| Archivo | Acción | Líneas |
|---------|--------|--------|
| `plugins/...` | created/modified | +N/-M |
| ... | ... | ... |

## 🔄 Tareas Pendientes
1. [prioridad] Acción específica (#related-file)
2. ...

## 🚨 Issues Conocidos
- **Blocker**: [descripción] (evidencia)
- **Warning**: [descripción] (evidencia)

## 📋 Next Actions (Siguiente Sesión)
```bash
# 1. Ver estado actual
git status

# 2. Continuar con pendiente
<command específico>

# 3. Validar
<validation command>
```

## 🤝 Instrucciones para Reanudar
1. Leer `SESSION-HANDOFF.md` completo
2. Revisar archivos en tabla de "Trabajo Completado"
3. Ejecutar next actions en orden
4. Marcar tareas completadas en todolist

---
*Generado por /handoff command - context-toolkit plugin*
```

## Implementación

```python
# Pseudocódigo de la command
def generate_handoff(context: dict) -> str:
    """
    Genera SESSION-HANDOFF.md desde el contexto actual
    
    context incluye:
    - conversation_summary (string)
    - todos (list de {status, text, priority})
    - git_status (dict de {file, status, diff_stat})
    - tool_outputs (list de outputs con errores)
    - token_budget_remaining (int)
    """
    
    handoff_id = generate_uuid()
    
    # 1. Extract completed work
    completed = extract_completed_work(context)
    
    # 2. Extract pending tasks
    pending = extract_pending_tasks(context)
    
    # 3. Extract issues
    issues = extract_issues(context)
    
    # 4. Generate next actions
    next_actions = generate_next_actions(completed, pending, issues)
    
    # 5. Render template (keep < 4KB)
    markdown = render_handoff_template(
        handoff_id, completed, pending, issues, next_actions
    )
    
    # 6. Write file
    write_file("SESSION-HANDOFF.md", markdown)
    
    # 7. Return summary (para display al usuario)
    return {
        "handoff_id": handoff_id,
        "file": "SESSION-HANDOFF.md",
        "completed_count": len(completed),
        "pending_count": len(pending),
        "issues_count": len(issues),
        "size_bytes": len(markdown),
        "next_action": next_actions[0] if next_actions else None,
    }


def extract_completed_work(context: dict) -> list:
    """Extrae trabajo completado"""
    import subprocess
    
    # Get git changes
    result = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=AM"], 
        capture_output=True, text=True
    )
    changed_files = result.stdout.strip().split("\n")
    
    # Get todo completed items
    completed_todos = [t for t in context.get("todos", []) if t["status"] == "completed"]
    
    # Combine
    return [
        {
            "file": f,
            "action": "created/modified",
            "summary": find_todo_summary(f, completed_todos)
        }
        for f in changed_files if f
    ]


def extract_pending_tasks(context: dict) -> list:
    """Extrae tareas pendientes"""
    todos = context.get("todos", [])
    pending = [t for t in todos if t["status"] in ("pending", "in_progress")]
    
    # Sort by priority
    priority_map = {"high": 0, "medium": 1, "low": 2}
    pending.sort(key=lambda t: priority_map.get(t.get("priority", "medium"), 1))
    
    return pending


def extract_issues(context: dict) -> list:
    """Extrae issues/errores del conversation context"""
    issues = []
    
    for output in context.get("tool_outputs", []):
        if "error" in str(output).lower():
            issues.append({
                "type": "error",
                "description": extract_error_message(output),
                "context": extract_error_context(output),
            })
    
    return issues
```

## Skill que usa
- `session-handoff` (este skill)
- `codebase-map` (para contexto de archivo changes)
- `claude-md-writer` (para reference a CLAUDE.md)

## Validación Previa
```bash
# Verificar git status disponible
git rev-parse --is-inside-work-tree

# Verificar context-toolkit plugin existe
ls plugins/context-toolkit/.claude-plugin/plugin.json
ls plugins/context-toolkit/skills/session-handoff/SKILL.md

# Verificar espacio en disco para output
df -h . | awk 'NR==2 {print $4 " available"}'
```

## Ejemplo de Output
```
✅ Handoff ID: 550e8400-e29b-41d4-a716-446655440000
✅ Trabajo completado: 7 archivos (5 created, 2 modified)
✅ Tareas pendientes: 3 (1 high, 2 medium)
✅ Issues conocidos: 2 (1 warning, 1 blocker menor)
✅ Next action: Completar Fase 9 - Evaluation Harness

📄 Output: SESSION-HANDOFF.md (2.4KB)
```

## Límites
- Output máximo 4KB (context budget optimization)
- Máximo 20 archivos en tabla (usar `--scope=changed` para reducir)
- Máximo 10 tareas pendientes (priorizar las críticas)
- Errores truncados a 200 chars