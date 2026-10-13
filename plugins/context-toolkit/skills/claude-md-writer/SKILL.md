# Claude MD Writer Skill

## Cuándo usarlo
- **Al iniciar sesión en un proyecto nuevo**: Genera CLAUDE.md baseline
- **Después de cambios significativos**: Actualiza CLAUDE.md con nuevas convenciones
- **Antes de handoff**: Asegura que CLAUDE.md refleje el estado actual del repo

## Cuándo NO usarlo
- Para versiones de código (usa Git tags/branches)
- Como sustituto de README oficial
- Para documentación de usuario final

## Descripción
El skill **claude-md-writer** analiza el codebase y genera un `CLAUDE.md` que sirve como contexto persistente para agentes Claude Code. Documenta arquitectura, stack, comandos de build/test, convenciones, y patterns críticos.

## Template de CLAUDE.md

### 1. Stack Detectado
```markdown
# CLAUDE.md - ai-dev-toolkit

## Stack Detectado
- **Language**: TypeScript + Python
- **Framework**: Next.js 15 (React 18, App Router)
- **UI**: TailwindCSS 3.4, shadcn/ui (Radix)
- **Testing**: Jest, Vitest, Cypress, Playwright
- **Build**: pnpm workspaces (monorepo)
- **CI/CD**: GitHub Actions
- **Package Manager**: pnpm 9.x
```

### 2. Estructura de Directorios
```markdown
## Estructura del Proyecto
\`\`\`
ai-dev-toolkit/
├── plugins/                    # Plugin marketplace
│   ├── dev-workflow/           # Multi-agent dev flow
│   ├── cicd-security-triage/   # Security report normalization + triage
│   ├── frontend-ui/            # UI design → implementation → review
│   └── context-toolkit/        # CLAUDE.md, codebase map, session handoff
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md
│   ├── CONVENTIONS.md
│   └── TESTING-STATUS.md
├── evals/                      # Evaluation harness (Phase 9)
│   ├── cases/                  # Test cases (5 per plugin)
│   └── results/                # Eval outputs
├── scripts/                    # Repo-level scripts
│   └── validate-all.sh
└── AGENTS.md                   # Central agent definitions
\`\`\`
```

### 3. Comandos de Build y Test
```markdown
## Comandos de Build y Test
\`\`\`bash
# Validación
./scripts/validate-all.sh          # Ejecuta todas las validaciones

# Tests
python3 plugins/dev-workflow/tests/test-plugin-structure.sh
python3 plugins/cicd-security-triage/tests/test-parsers.py

# Seguridad
python3 plugins/cicd-security-triage/scripts/parse-grype.py <input> <output>

# Frontend
./plugins/frontend-ui/scripts/check-a11y.sh
./plugins/frontend-ui/scripts/check-bundle.sh --budget=500
\`\`\`
```

### 4. Convenciones del Código
```markdown
## Convenciones

### Formato de archivos
- **Agentes**: Frontmatter YAML (`---`), seguido de markdown estructurado
- **Skills**: `SKILL.md` con frontmatter, reglas verificables, ejemplos de código
- **Scripts**: `set -euo pipefail` (bash) o `#!/usr/bin/env python3` (Python)
- **JSON**: 2-space indent, sin trailing commas
- **Tests**: Fixtures en `tests/fixtures/`, tests en `tests/`

### Nombres
- **Agentes**: kebab-case (ej. `ui-implementer`)
- **Skills**: kebab-case (ej. `react-component-patterns`)
- **Comandos**: kebab-case (ej. `security-triage`)
- **Scripts**: kebab-case (ej. `parse-grype.py`)

### Permisos de agentes
| Tipo | Permisos | Uso |
|------|----------|-----|
| Read-only | `Read, Glob, Grep, WebFetch, WebSearch` | Analyst, Reviewer, Architect, UI Designer |
| Write | `Read, Write, Edit, MultiEdit, Glob, Grep, Bash, Task` | Implementer, Fixer, UI Implementer |
| QA | `Read, Bash, Glob, Grep` | QA, QA Security |

### Principios
- Un solo agente con write per flow (evita conflictos)
- workflow-contract como single source of truth (dev-workflow)
- Normalized reports como single source of truth (cicd-security-triage)
```

### 5. Patterns Clave
```markdown
## Patterns Clave

### Dev Workflow
- Architect: Analiza → diseña → planifica (read-only)
- Implementer: Implementa plan + tests (write)
- Reviewer: Revisa contra checklist + domain rules (read-only)
- QA: Ejecuta tests + verifica criterios (bash)

### Security Triage
- Grype (image/SBOM) → parse-grype.py → normalized JSON
- SonarQube (SAST) → parse-sonar.py → normalized JSON
- StackHawk (DAST) → parse-stackhawk.py → normalized JSON
- Analyst: Clasifica + descarta FP + prioriza
- Fixer: Propone fix mínimo (upgrade/config/code)
- QA Security: Valida fix + re-scan + regression tests

### Frontend UI
- UI Designer: Propone estructura, componentes, estados
- UI Implementer: Implementa con React/TS/Tailwind/shadcn/ui
- UI Reviewer: Accesibilidad + responsive + consistencia + performance
```

### 6. Hooks y Validaciones
```markdown
## Hooks y Validaciones
- Hooks: `.claude/hooks/` (on_hook_compact_for, post_tool_use)
- Validación sensibles: `plugins/dev-workflow/scripts/guard-sensitive.sh`
- Workflow contract: `plugins/dev-workflow/scripts/validate-contract.sh`
```

## Generación Automática

```python
# claude-md-writer.py (pseudocódigo)
def generate_claude_md(project_root: str) -> str:
    """Genera CLAUDE.md analizando el codebase"""
    
    # 1. Detect stack
    stack = detect_stack(project_root)
    
    # 2. Extract structure
    structure = extract_directory_structure(project_root, max_depth=3)
    
    # 3. Extract commands
    commands = extract_package_json_scripts(project_root)
    
    # 4. Extract conventions
    conventions = extract_conventions(project_root)
    
    # 5. Generate markdown
    claude_md = render_template(stack, structure, commands, conventions)
    
    # 6. Write (no sobrescribir si existe y --force no especificado)
    write_if_different(f"{project_root}/CLAUDE.md", claude_md)
    
    return claude_md
```

## Reglas de Actualización
1. **Preservar**: Comentarios manuales (marcos `<!-- MANUAL: ... -->`)
2. **Merge**: No overwrites completos, merge inteligente
3. **Versionar**: Siempre crear backup antes de sobrescribir
4. **Timestamp**: Incluir `Last updated: YYYY-MM-DD`

## Verificación
- **claude-md-writer R1**: ¿CLAUDE.md existe en root del repo?
- **claude-md-writer R2**: ¿Stack detectado correctamente (language, framework, tools)?
- **claude-md-writer R3**: ¿Estructura de directorios actualizada (máx depth 3)?
- **claude-md-writer R4**: ¿Comandos de build/test funcionan como documented?
- **claude-md-writer R5**: ¿Convenciones reflejan el código real (patterns, permisos)?
- **claude-md-writer R6**: ¿Last updated timestamp presente y reciente (< 7 días)?