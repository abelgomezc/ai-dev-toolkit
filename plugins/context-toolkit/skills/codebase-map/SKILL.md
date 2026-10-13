# Codebase Map Skill

## Cuándo usarlo
- **Al iniciar exploración de un repo grande**: Genera mapa de alto nivel
- **Antes de implementar un cambio**: Identifica entry points y dependencias
- **Para optimización**: Identifica archivos duplicados, imports ciclados, código muerto

## Cuándo NO usarlo
- Para navegar archivos individuales (usa Glob/Grep)
- Como sustitututo de IDE navigación
- Para proyectos < 50 archivos

## Descripción
El skill **codebase-map** produce un mapa compacto del codebase analizando:
1. Entry points (package.json, main.ts, App.tsx, index.js)
2. Módulos y boundaries (archivos, imports, exports)
3. Dependencias externas vs internas
4. Hotspots de complejidad (functions > 50 lines, archivos > 500 lines)
5. Duplicados (strings > 50 chars repetidos)
6. Código muerto (exports no usados, imports muertos)

## Output Format

### Mapa de Alto Nivel
```markdown
## Codebase Map - ai-dev-toolkit

### Entry Points
- `AGENTS.md` — Central agent definitions (409 lines)
- `.claude-plugin/marketplace.json` — Plugin marketplace manifest
- `plugins/dev-workflow/agents/` — 4 agent definitions
- `plugins/cicd-security-triage/agents/` — 3 agent definitions
- `plugins/frontend-ui/agents/` — 3 agent definitions
- `scripts/validate-all.sh` — Validation entry point

### Módulos y Boundaries
```
ai-dev-toolkit/
├── dev-workflow/ (12 archivos, 4 agents, 10 skills, 4 scripts)
├── cicd-security-triage/ (13 archivos, 3 agents, 3 skills, 3 scripts, 1 command)
├── frontend-ui/ (22 archivos, 3 agents, 9 skills, 2 scripts, 1 command)
├── context-toolkit/ (1 archivo, 3 skills, 2 commands - PENDIENTES)
├── docs/ (3 archivos: ARCHITECTURE, CONVENTIONS, TESTING-STATUS)
├── evals/ (estructura vacía - Fase 9)
├── scripts/ (1 archivo: validate-all.sh)
└── AGENTS.md (definitions centrales)
```

### Dependencias Externas (Top 10)
| Package | Plugin | Uso | Versión |
|---------|--------|-----|---------|
| `jsonschema` | dev-workflow | Validate workflow-contract | (runtime) |
| `@axe-core/react` | frontend-ui | Accessibility testing | dev-dependency |
| `@next/bundle-analyzer` | frontend-ui | Bundle analysis | dev-dependency |

### Hotspots de Complejidad
| File | Lines | Complejidad | Notas |
|------|-------|-------------|-------|
| `AGENTS.md` | 409 | alta | Central definitions, matices de permisos |
| `plugins/dev-workflow/agents/implementer.md` | ~80 | media | Multi-step implementation workflow |
| `plugins/cicd-security-triage/agents/analyst.md` | ~79 | media | Classification + FP triage logic |

### Código Potencialmente Duplicado
- `set -euo pipefail` patrón en todos los scripts bash (intencional, convención)
- `SEVERITY_MAP` en parse-grype.py, parse-sonar.py, parse-stackhawk.py (intencional, diferente mapping)

### Código Potencialmente Morto
- `docs/TESTING-STATUS.md` líneas 50-63: referencias a archivos no creados (Fase 6) - ACTUALIZAR
```

## Generación Automática

```python
# codebase-map.py (pseudocódigo)
def generate_codebase_map(project_root: str, options: dict) -> str:
    """Genera mapa compacto del codebase"""
    
    max_depth = options.get("depth", 3)
    include_externals = options.get("externals", True)
    
    # 1. Entry points
    entry_points = find_entry_points(project_root)
    
    # 2. Directory tree (compacto)
    tree = build_compact_tree(project_root, max_depth)
    
    # 3. Dependencies
    deps = extract_dependencies(project_root)
    externals = filter_externals(deps)
    
    # 4. Hotspots (files > 500 lines, functions > 50 lines)
    hotspots = find_hotspots(project_root)
    
    # 5. Duplicates
    duplicates = find_duplicates(project_root)
    
    # 6. Dead code
    dead_code = find_dead_code(project_root)
    
    return render_map(entry_points, tree, externals, hotspots, duplicates, dead_code)
```

## Algoritmos

### Compact Tree
```
# Regla: max_depth configurable (default 3)
# Formato: name/ (count archivos, count subdirs)
# Ej: plugins/ (22 archivos, 4 subdirs)
```

### Hotspot Detection
- **File complexity**: lines > 500 → 🔴 alta, 200-500 → 🟡 media, < 200 → verde
- **Function complexity**: lines > 50 → flag, considerar refactoring
- **Import cycles**: usar dependency-graph para detectar

### Duplicate Detection
- Hash de strings > 50 chars
- Threshold: 3+ ocurrencias idénticas
- Excluir: boilerplate (shebangs, `set -euo pipefail`, import statements)

## CLI Usage

```bash
# Generar mapa del repo actual
python3 plugins/context-toolkit/scripts/codebase-map.py

# Mapa con profundidad específica
python3 plugins/context-toolkit/scripts/codebase-map.py --depth 4

# Mapa solo de un plugin
python3 plugins/context-toolkit/scripts/codebase-map.py --dir plugins/frontend-ui

# Output a archivo
python3 plugins/context-toolkit/scripts/codebase-map.py --output docs/CODEBASE-MAP.md
```

## Output Structure

```typescript
interface CodebaseMap {
  projectName: string;
  generated_at: string;
  entry_points: Array<{
    path: string;
    type: "agent" | "command" | "script" | "config" | "hook";
    lang: string;
  }>;
  modules: ModuleNode;
  dependencies: {
    external: Dependency[];
    internal: Dependency[];
  };
  hotspots: Hotspot[];
  duplicates: Duplicate[];
  dead_code: DeadCodeItem[];
  total_files: number;
  total_lines: number;
}
```

## Verificación
- **codebase-map R1**: ¿Entry points identificados correctamente (package.json, agentes, scripts)?
- **codebase-map R2**: ¿Tree estructura respeta max_depth (default 3)?
- **codebase-map R3**: ¿Dependencies separadas (external vs internal)?
- **codebase-map R4**: ¿Hotspots identificados (files > 500 lines, functions > 50 lines)?
- **codebase-map R5**: ¿Duplicates detectados (strings > 50 chars, 3+ ocurrencias)?
- **codebase-map R6**: ¿Dead code identificado (exports/imports no usados)?
- **codebase-map R7**: ¿Total files/lines counters accurate?
- **codebase-map R8**: ¿Output en < 4KB para context budget optimization?