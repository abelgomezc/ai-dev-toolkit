#!/usr/bin/env bash
# run-checks.sh - Ejecuta lint, typecheck y tests según stack detectado
# Uso: ./run-checks.sh [--dry-run] [--stack <stack_name>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${PLUGIN_ROOT}/config/stacks.json"
DETECT_SCRIPT="${PLUGIN_ROOT}/scripts/detect-stack.sh"

DRY_RUN=false
FORCE_STACK=""

# Parse arguments
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
            echo "Uso: $0 [--dry-run] [--stack <stack_name>]" >&2
            exit 1
            ;;
    esac
done

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
}

# Detect stack if not forced
if [[ -n "${FORCE_STACK}" ]]; then
    STACK="${FORCE_STACK}"
    log "Stack forzado: ${STACK}"
else
    if [[ -f "${DETECT_SCRIPT}" ]]; then
        log "Detectando stack..."
        DETECT_OUTPUT=$("${DETECT_SCRIPT}" 2>/dev/null || echo '{"stack":"unknown","confidence":0}')
        STACK=$(echo "${DETECT_OUTPUT}" | grep -o '"stack"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        CONFIDENCE=$(echo "${DETECT_OUTPUT}" | grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9]*' | cut -d':' -f2)
        log "Stack detectado: ${STACK} (confianza: ${CONFIDENCE}%)"
    else
        error "Script de detección no encontrado: ${DETECT_SCRIPT}"
        exit 1
    fi
fi

if [[ "${STACK}" == "unknown" || -z "${STACK}" ]]; then
    error "No se pudo detectar el stack. Use --stack para forzar."
    exit 1
fi

# Load stack config
if [[ ! -f "${CONFIG_FILE}" ]]; then
    error "Archivo de configuración no encontrado: ${CONFIG_FILE}"
    exit 1
fi

# Extract commands for stack using jq or python
get_stack_config() {
    local key="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -r ".stacks.\"${STACK}\".${key} // empty" "${CONFIG_FILE}"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json, sys
with open('${CONFIG_FILE}') as f:
    config = json.load(f)
stack = config.get('stacks', {}).get('${STACK}', {})
keys = '${key}'.split('.')
val = stack
for k in keys:
    if isinstance(val, dict):
        val = val.get(k, {})
    else:
        val = {}
        break
if isinstance(val, (dict, list)):
    print(json.dumps(val))
elif val:
    print(val)
"
    else
        echo ""
    fi
}

# Detect build tool / package manager
detect_tool() {
    local stack="$1"
    local tools_json=$(get_stack_config "build_tools // package_managers")
    
    if [[ -z "${tools_json}" || "${tools_json}" == "null" ]]; then
        echo ""
        return
    fi
    
    # Find first tool with detect_files present
    if command -v jq >/dev/null 2>&1; then
        echo "${tools_json}" | jq -r 'to_entries[] | select(.value.detect_files[] as $f | (input | test($f))) | .key' 2>/dev/null | head -1
    else
        # Fallback: check common files
        case "${stack}" in
            java-spring)
                [[ -f "pom.xml" ]] && echo "maven" || [[ -f "build.gradle" ]] && echo "gradle" || echo ""
                ;;
            python-fastapi)
                [[ -f "uv.lock" ]] && echo "uv" || [[ -f "poetry.lock" ]] && echo "poetry" || echo "pip"
                ;;
            node-react|angular)
                [[ -f "pnpm-lock.yaml" ]] && echo "pnpm" || [[ -f "yarn.lock" ]] && echo "yarn" || echo "npm"
                ;;
            *) echo "" ;;
        esac
    fi
}

TOOL=$(detect_tool "${STACK}")
if [[ -z "${TOOL}" ]]; then
    error "No se pudo detectar herramienta de build para stack: ${STACK}"
    exit 1
fi
log "Herramienta detectada: ${TOOL}"

# Get commands
get_command() {
    local phase="$1"
    local key=""
    case "${STACK}" in
        java-spring)
            key="build_tools.${TOOL}.${phase}_command"
            ;;
        python-fastapi|node-react|angular)
            key="package_managers.${TOOL}.${phase}_command"
            ;;
    esac
    get_stack_config "${key}"
}

run_phase() {
    local name="$1"
    local cmd="$2"
    local required="${3:-true}"
    
    if [[ -z "${cmd}" || "${cmd}" == "null" ]]; then
        if [[ "${required}" == "true" ]]; then
            log "${name}: No configurado para ${STACK}/${TOOL}"
            return 1
        else
            log "${name}: Opcional, omitido"
            return 0
        fi
    fi
    
    log "${name}: ${cmd}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "  [DRY-RUN] Se ejecutaría: ${cmd}"
        return 0
    fi
    
    # Run command
    if eval "${cmd}"; then
        log "${name}: ✓ PASSED"
        return 0
    else
        error "${name}: ✗ FAILED"
        return 1
    fi
}

# Main execution
log "=== Iniciando verificaciones para ${STACK} (${TOOL}) ==="

FAILED=0

# Compile/Typecheck first
run_phase "Compile/Typecheck" "$(get_command "compile")" false || FAILED=1
run_phase "Typecheck" "$(get_command "typecheck")" false || FAILED=1

# Lint
run_phase "Lint" "$(get_command "lint")" true || FAILED=1

# Tests with coverage
run_phase "Tests" "$(get_command "test")" true || FAILED=1

# Build (optional)
run_phase "Build" "$(get_command "build")" false || FAILED=1

log "=== Verificaciones completadas ==="
if [[ ${FAILED} -eq 0 ]]; then
    log "✓ TODAS LAS VERIFICACIONES PASARON"
    exit 0
else
    error "✗ ALGUNAS VERIFICACIONES FALLARON"
    exit 1
fi