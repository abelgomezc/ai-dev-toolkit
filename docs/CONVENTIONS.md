# Convenciones del ai-dev-toolkit

## Nomenclatura

### Archivos y Directorios
- **Archivos**: kebab-case (`run-checks.sh`, `workflow-contract-schema.json`)
- **Directorios**: kebab-case (`spring-microservices-patterns`, `stack-java-spring`)
- **Scripts**: kebab-case con sufijo `.sh` (`detect-stack.sh`, `guard-sensitive.sh`)
- **Skills**: kebab-case (`review-checklist`, `api-design-review`)
- **Agentes**: kebab-case (`architect.md`, `implementer.md`)
- **Comandos**: kebab-case (`feature.md`)

### JSON
- **Claves**: camelCase (`taskId`, `stackDetected`, `acceptanceCriteria`)
- **Enums**: kebab-case (`java-spring`, `python-fastapi`, `blocker`, `major`, `minor`)
- **Rutas**: relativas con forward slash (`src/main/java/...`)

### Markdown Frontmatter
```yaml
---
name: agent-name
description: Descripción breve (cuándo usar y cuándo NO)
tools: [Read, Write, Glob, Grep, Bash, Task, WebFetch, WebSearch]
---
```

### Código en Documentación
- **Bueno**: `// BUENO` o `✅ BUENO`
- **Malo**: `// MALO` o `❌ MALO` o `// FALLA REGLA X`
- **Comentarios explicativos**: En español
- **Código**: En inglés (nombres de variables, clases, métodos)

## Estructura de Skills

Cada skill sigue esta estructura:

```
skill-name/
├── SKILL.md                    # Principal: cuándo usar, reglas verificables
├── reference-file-1.md         # Detalle: convenciones, ejemplos bueno/malo
├── reference-file-2.md         # Antipatrones, migraciones, etc.
└── reference-file-N.json       # Configuración, esquemas, datos
```

### SKILL.md - Secciones Obligatorias
1. **Cuándo usarlo** - Contexto de activación
2. **Cuándo NO usarlo** - Límites claros
3. **Descripción** - Qué hace, nivel experto
4. **Archivos de referencia** - Lista con propósito
5. **Reglas verificables** - Numeradas, citables, con código bueno/malo
6. **Verificación** - Cómo validar automáticamente

### Reglas Verificables - Formato
```markdown
### Regla N: Nombre descriptivo
- Descripción criterio objetivo
- **Verificación**: comando o patrón de búsqueda

```java
// BUENO
correctCode();

// MALO - FALLA REGLA N
wrongCode();
```
```

## Estructura de Agentes

```markdown
---
name: agent-name
description: Descripción precisa: qué hace, qué NO hace, herramientas
tools: [Tool1, Tool2, ...]
---

# Agent Name

## Rol
Una línea.

## Responsabilidades
Lista numerada.

## Flujo de trabajo
Pasos numerados.

## Restricciones
- Qué NO hace
- Límites de permisos
```

### Tools Permitidos (Claude Code)
- `Read`, `Write`, `Edit`, `MultiEdit`
- `Glob`, `Grep`
- `Bash`, `Task`
- `WebFetch`, `WebSearch`
- **Solo lectura**: Read, Glob, Grep, WebFetch, WebSearch
- **Escritura**: Write, Edit, MultiEdit, Bash, Task

## Estructura de Comandos

```markdown
---
name: command-name
description: Qué hace, punto de entrada
tools: [Task, Read, Write, ...]
---

# Command Name

## Uso
`/command-name "argumentos"`

## Flujo
Pasos numerados.

## Implementación (pseudocódigo)
Código que el agente ejecuta.
```

## Scripts Bash

### Encabezado Obligatorio
```bash
#!/usr/bin/env bash
# script-name.sh - Descripción breve
# Uso: ./script-name.sh [opciones]

set -euo pipefail
```

### Funciones Comunes
```bash
log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
}
```

### Manejo de Argumentos
```bash
DRY_RUN=false
FORCE_STACK=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --stack)
            FORCE_STACK="$2"
            shift 2
            ;;
        *)
            echo "Uso: $0 [--dry-run] [--stack <name>]" >&2
            exit 1
            ;;
    esac
done
```

### Salida
- **Exit 0**: Éxito
- **Exit 1**: Error (con mensaje en stderr)
- **Logs**: Timestamp + mensaje
- **Dry-run**: Simula sin ejecutar comandos reales

## JSON Schema

- **Draft**: 2020-12
- **$id**: URL del repositorio + path
- **required**: Campos mínimos obligatorios
- **Enums**: Valores permitidos explícitos
- **Validación**: `validate-contract.sh` usa python3+jsonschema o jq

## Git y Commits

### Conventional Commits
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Documentación
- `test`: Tests
- `chore`: Mantenimiento, scripts, config
- `refactor`: Refactor sin cambio funcional
- `style`: Formato, sin lógica
- `perf`: Performance

### Scopes
- `dev-workflow`, `cicd-security-triage`, `frontend-ui`, `context-toolkit`
- `marketplace`, `arch`, `docs`, `ci`, `scripts`

### Ejemplos
```
feat(dev-workflow): add spring-microservices-patterns skill
fix(scripts): guard-sensitive.sh false positive on test files
docs(arch): add decision log for workflow contract
test(evals): add 5 dev-workflow eval cases
chore(ci): add shellcheck to validate workflow
```

## Validación

### Pre-commit (recomendado)
```bash
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: validate-all
        name: Validate all
        entry: ./scripts/validate-all.sh
        language: system
        pass_filenames: false
```

### CI
- GitHub Actions: `.github/workflows/validate.yml`
- Ejecuta: JSON, frontmatter, shellcheck, test-plugin-structure, test-hooks, scripts

## Documentación

### README.md por Plugin
1. **Descripción** - Qué hace, para quién
2. **Instalación** - Cómo agregar al marketplace
3. **Uso** - Comandos, agentes, skills
4. **Configuración** - Archivos config, variables
5. **Validación** - Cómo testear
6. **Estado** - Link a TESTING-STATUS.md

### CHANGELOG.md
- Formato: Keep a Changelog
- Secciones: Added, Changed, Deprecated, Removed, Fixed, Security
- Versiones: SemVer (MAJOR.MINOR.PATCH)

### TESTING-STATUS.md
Clasificación por afirmación:
- **verificado**: Ejecutado y pasado
- **parcialmente verificado**: Parcialmente ejecutado o con caveats
- **no verificado**: No ejecutado, solo asumido

Formato:
```markdown
## Plugin: dev-workflow

| Afirmación | Estado | Evidencia |
|------------|--------|-----------|
| Estructura válida | verificado | test-plugin-structure.sh passed |
| Hooks funcionan | parcialmente verificado | test-hooks.sh passed, dry-run only |
| Flujo multiagente | no verificado | Requiere Claude Code runtime |
```

## Variables de Entorno

### Estándar
- `PLUGIN_ROOT`: Raíz del plugin (para scripts)
- `CONFIG_FILE`: Path a archivo de config JSON

### Plugin-specific
- `CLAUDE_PROJECT_DIR`: Raíz del proyecto usuario (proporcionado por Claude Code)

## Patrones de Código Comunes

### Error Handling en Scripts
```bash
# Fallar rápido con mensaje claro
if [[ ! -f "$REQUIRED_FILE" ]]; then
    error "Archivo requerido no encontrado: $REQUIRED_FILE"
    exit 1
fi
```

### JSON Parsing Portátil
```bash
# Preferir jq, fallback python3
if command -v jq >/dev/null 2>&1; then
    jq -r '.key' file.json
elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; print(json.load(open('file.json'))['key'])"
fi
```

### Dry-run Pattern
```bash
if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY-RUN] Ejecutaría: $COMMAND"
else
    eval "$COMMAND"
fi
```

## Referencias

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/)