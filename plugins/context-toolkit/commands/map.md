---
name: map
description: Genera mapa compacto del codebase para ahorro de contexto. Identifica entry points, módulos, dependencias, hotspots de complejidad y código potencialmente muerto. Output < 4KB.
tools: [Read, Glob, Grep, Bash]
---

# Map Command - Codebase Mapping Tool

## Uso
```
/map [opciones]
```

## Opciones
| Flag | Descripción | Por defecto |
|------|-------------|-------------|
| `--depth=<n>` | Profundidad del árbol de directorios | 3 |
| `--dir=<path>` | Directorio específico a mapear | `.` (repo root) |
| `--include-source` | Incluir source code snippets (hotspots) | false |
| `--check-duplicates` | Buscar código duplicado | false |
| `--check-dead-code` | Detectar código muerto (imports/exports no usados) | false |
| `--output=<path>` | Output a archivo | stdout |
| `--json` | Output en formato JSON | false |

## Qué mapea

### 1. Entry Points
- `AGENTS.md`, `CLAUDE.md`, `README.md`
- `package.json` (scripts), `pyproject.toml`, `requirements.txt`
- `plugins/*/agents/*.md` (409 líneas en dev-workflow)
- `plugins/*/commands/*.md`
- `scripts/*.sh`, `plugins/*/scripts/*.sh`

### 2. Módulos y Boundaries
- Tree de directorios con conteos (archivos/subdirs)
- Separación clara de responsabilidades
- Cross-plugin dependencies (si existen imports)

### 3. Hotspots de Complejidad
- Archivos > 500 líneas (🔴 alta complejidad)
- Funciones > 50 líneas (refactoring candidate)
- Archivos con mayor número de exports

### 4. Duplicados (opcional)
- Strings > 50 chars repetidos 3+ veces
- Exclusiones: boilerplate, imports estándar, comentarios

### 5. Código Muerto (opcional)
- Imports declarados pero no usados
- Exports definidos pero no importados
- Requires muertos

## Output Format

### Texto (default)
```markdown
## Codebase Map - ai-dev-toolkit

### Entry Points
- `AGENTS.md` — Agent definitions (409 lines)
- `.claude-plugin/marketplace.json` — Plugin marketplace
- `plugins/dev-workflow/commands/feature.md` — Dev workflow entry point
- `plugins/cicd-security-triage/commands/security-triage.md` — Security triage
- `plugins/frontend-ui/commands/ui.md` — UI design flow
- `scripts/validate-all.sh` — All-in-one validation

### Módulos
\`\`\`
.
├── plugins/
│   ├── dev-workflow/ (12 files, 4 agents, 10 skills, 1 command, 4 scripts, 2 tests)
│   ├── cicd-security-triage/ (15 files, 3 agents, 3 skills, 1 command, 3 scripts, 5 fixtures, 1 test)
│   ├── frontend-ui/ (22 files, 3 agents, 9 skills, 1 command, 2 scripts)
│   └── context-toolkit/ (TBD - 3 skills, 2 commands in progress)
├── docs/ (3 files: ARCHITECTURE, CONVENTIONS, TESTING-STATUS)
├── evals/ (estructura vacía - Phase 9)
└── scripts/ (1 file: validate-all.sh)
\`\`\`

### Hotspots
| File | Lines | Severity | Notes |
|------|-------|----------|-------|
| AGENTS.md | 409 | 🟡 med | Central agent definitions |
| plugins/.../analyst.md | ~79 | 🟡 med | Security classification logic |

### Summary
- Total files: ~40 (markdown, json, scripts)
- Total lines: ~1200
- Plugins: 4
- Agents: 10 (4 dev-workflow, 3 security, 3 ui)
- Skills: 13 (10 dev-workflow + context-toolkit)
- Commands: 4 (1 dev-workflow + 1 security + 1 ui + 1 context)
```

### JSON (con --json)
```json
{
  "schema_version": "1.0",
  "project": "ai-dev-toolkit",
  "generated_at": "2026-10-12T22:30:00Z",
  "entry_points": {
    "agents": ["plugins/dev-workflow/agents/architect.md", ...],
    "commands": ["plugins/dev-workflow/commands/feature.md", ...],
    "scripts": ["scripts/validate-all.sh", ...]
  },
  "modules": {
    "dev-workflow": {"files": 12, "agents": 4, "skills": 10, "commands": 1, "scripts": 4, "tests": 2},
    "cicd-security-triage": {"files": 15, "agents": 3, "skills": 3, "commands": 1, "scripts": 3, "tests": 1},
    ...
  },
  "hotspots": [
    {"file": "AGENTS.md", "lines": 409, "severity": "medium"},
    ...
  ],
  "summary": {
    "files": 40,
    "lines": 1200,
    "plugins": 4,
    "agents": 10,
    "skills": 13,
    "commands": 4
  }
}
```

## Implementación

```python
# Pseudocódigo
def generate_map(root: str, options: dict) -> str:
    """Genera mapa del codebase"""
    
    depth = options.get("depth", 3)
    directory = options.get("dir", ".")
    
    # 1. Entry points
    entries = find_entries(root)
    
    # 2. Directory tree (compacto)
    tree = compact_tree(root, depth)
    
    # 3. Module stats (per plugin)
    modules = extract_module_stats(root)
    
    # 4. Hotspots
    hotspots = find_hotspots(root)
    
    # 5. Optional: duplicates
    if options.get("check_duplicates"):
        duplicates = find_duplicates(root)
    
    # 6. Optional: dead code
    if options.get("check_dead_code"):
        dead = find_dead_code(root)
    
    # 7. Keep output < 4KB
    render = render_compact(entries, tree, modules, hotspots, duplicates, dead)
    
    if len(render) > 4096:
        render = truncate_or_compact(render)
    
    return render


def compact_tree(root: str, max_depth: int) -> str:
    """Genera tree compacto con conteos"""
    # Walk directory, group by plugin
    # Count files, subdir in each group
    # Return formatted string
    pass


def find_entries(root: str) -> dict:
    """Encuentra entry points del codebase"""
    entries = {
        "agents": glob("plugins/*/agents/*.md"),
        "commands": glob("plugins/*/commands/*.md"),
        "scripts": glob("plugins/*/scripts/*") + glob("scripts/*.sh"),
        "configs": glob("plugins/*/config/*.json"),
        "skills": glob("plugins/*/skills/*/SKILL.md"),
        "tests": glob("plugins/*/tests/*.sh") + glob("plugins/*/tests/*.py"),
    }
    return entries


def find_hotspots(root: str) -> list:
    """Encuentra hotspots de complejidad"""
    hotspots = []
    # Find all files, count lines
    for file in find_files(root, extensions=[".md", ".py", ".sh", ".json", ".ts", ".tsx"]):
        lines = count_lines(file)
        if lines > 500:
            hotspots.append({"file": file, "lines": lines, "severity": "high"})
        elif lines > 200:
            hotspots.append({"file": file, "lines": lines, "severity": "medium"})
    return sorted(hotspots, key=lambda x: x["lines"], reverse=True)
```

## Skill que usa
- `codebase-map` (este skill)
- `claude-md-writer` (para reference)
- `session-handoff` (para handoff output)

## Validación Previa
```bash
# Verificar plugin structure exists
ls plugins/*/plugins/*/commands/*.md
ls plugins/*/agents/*.md
ls plugins/*/scripts/*

# Verificar conteos
find plugins/ -name "*.md" | wc -l
find plugins/ -name "*.py" | wc -l
```

## Ejemplo de Uso

```
/map
```

Salida esperada:
```
📊 Codebase Map - ai-dev-toolkit
   Total files: ~40
   Plugins: 4 (dev-workflow, cicd-security-triage, frontend-ui, context-toolkit)
   Agents: 10 | Skills: 13 | Commands: 4 | Scripts: 8
   
📋 Hotspots (3 archivos > 200 líneas)
   🔴 AGENTS.md (409 lines)
   🟡 plugins/.../analyst.md (~79 lines)
   🟡 plugins/.../implementer.md (~80 lines)
   
📦 Entry Points
   - /feature → dev-workflow multi-agent
   - /security-triage → security report triage
   - /ui → UI design→impl→review flow
   - /handoff → session handoff
   - /map → codebase mapping

📄 Output: CODEBASE-MAP.md
```

## Límites
- Output máximo 4KB (context budget optimization)
- Tree depth máximo: 5 niveles (truncar con `...`)
- Max 20 hotspots (priorizar por líneas)
- Max 10 archivos en duplicates (priorizar matches)
- File counts: usar `find ... | wc -l` en lugar de leer archivos