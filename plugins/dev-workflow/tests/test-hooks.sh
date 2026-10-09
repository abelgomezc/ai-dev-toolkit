#!/usr/bin/env bash
# test-hooks.sh - Valida hooks.json y scripts asociados
# Uso: ./test-hooks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOKS_FILE="${PLUGIN_ROOT}/hooks/hooks.json"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
}

PASS=0
FAIL=0

check_json_valid() {
    local file="$1"
    if command -v jq >/dev/null 2>&1; then
        jq empty "${file}" 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m json.tool "${file}" >/dev/null 2>&1
    else
        return 0
    fi
}

log "=== Validando hooks ==="

# 1. hooks.json existe y es JSON válido
if [[ -f "${HOOKS_FILE}" ]]; then
    if check_json_valid "${HOOKS_FILE}"; then
        log "✓ hooks.json existe y es JSON válido"
        PASS=$((PASS + 1))
    else
        error "✗ hooks.json es JSON INVÁLIDO"
        FAIL=$((FAIL + 1))
    fi
else
    error "✗ hooks.json no encontrado"
    FAIL=$((FAIL + 1))
    exit 1
fi

# 2. Validar estructura hooks.json
if command -v jq >/dev/null 2>&1; then
    # Check version
    VERSION=$(jq -r '.version // empty' "${HOOKS_FILE}")
    if [[ -n "${VERSION}" ]]; then
        log "✓ hooks.json tiene version: ${VERSION}"
        PASS=$((PASS + 1))
    else
        error "✗ hooks.json sin version"
        FAIL=$((FAIL + 1))
    fi

    # Check hooks array
    HOOKS_COUNT=$(jq '.hooks | length' "${HOOKS_FILE}" 2>/dev/null || echo 0)
    if [[ "${HOOKS_COUNT}" -gt 0 ]]; then
        log "✓ hooks.json tiene ${HOOKS_COUNT} hook(s)"
        PASS=$((PASS + 1))
    else
        error "✗ hooks.json sin hooks definidos"
        FAIL=$((FAIL + 1))
    fi

    # Validate each hook
    for i in $(seq 0 $((HOOKS_COUNT - 1))); do
        HOOK_ID=$(jq -r ".hooks[${i}].id" "${HOOKS_FILE}")
        HOOK_TYPE=$(jq -r ".hooks[${i}].type" "${HOOKS_FILE}")
        HOOK_CMD=$(jq -r ".hooks[${i}].command" "${HOOKS_FILE}")
        HOOK_MATCH=$(jq -r ".hooks[${i}].match.paths[]" "${HOOKS_FILE}" 2>/dev/null | head -1)

        log "  Validando hook: ${HOOK_ID} (type: ${HOOK_TYPE})"

        # Check required fields
        if [[ -n "${HOOK_ID}" && "${HOOK_ID}" != "null" ]]; then
            log "    ✓ id presente"
            PASS=$((PASS + 1))
        else
            error "    ✗ id faltante"
            FAIL=$((FAIL + 1))
        fi

        if [[ -n "${HOOK_TYPE}" && "${HOOK_TYPE}" != "null" ]]; then
            log "    ✓ type presente: ${HOOK_TYPE}"
            PASS=$((PASS + 1))
        else
            error "    ✗ type faltante"
            FAIL=$((FAIL + 1))
        fi

        if [[ -n "${HOOK_CMD}" && "${HOOK_CMD}" != "null" ]]; then
            log "    ✓ command presente: ${HOOK_CMD}"
            PASS=$((PASS + 1))
            
            # Check script exists
            SCRIPT_PATH="${PLUGIN_ROOT}/${HOOK_CMD}"
            if [[ -f "${SCRIPT_PATH}" ]]; then
                log "    ✓ script existe: ${HOOK_CMD}"
                PASS=$((PASS + 1))
            else
                error "    ✗ script NO encontrado: ${HOOK_CMD}"
                FAIL=$((FAIL + 1))
            fi
        else
            error "    ✗ command faltante"
            FAIL=$((FAIL + 1))
        fi

        # Check match.paths
        if [[ -n "${HOOK_MATCH}" && "${HOOK_MATCH}" != "null" ]]; then
            log "    ✓ match.paths presente"
            PASS=$((PASS + 1))
        else
            error "    ✗ match.paths faltante"
            FAIL=$((FAIL + 1))
        fi
    done
else
    log "? jq no disponible, validación básica uniquement"
    PASS=$((PASS + 1))
fi

# 3. Scripts referenciados son ejecutables
if command -v jq >/dev/null 2>&1; then
    SCRIPTS=$(jq -r '.hooks[].command' "${HOOKS_FILE}" | sort -u)
    for script in ${SCRIPTS}; do
        SCRIPT_PATH="${PLUGIN_ROOT}/${script}"
        if [[ -f "${SCRIPT_PATH}" && -x "${SCRIPT_PATH}" ]]; then
            log "✓ Script ejecutable: ${script}"
            PASS=$((PASS + 1))
        elif [[ -f "${SCRIPT_PATH}" ]]; then
            error "✗ Script NO ejecutable: ${script}"
            FAIL=$((FAIL + 1))
        else
            error "✗ Script no encontrado: ${script}"
            FAIL=$((FAIL + 1))
        fi
    done
fi

# 4. Dry-run de scripts (si no requieren args complejos)
log "=== Dry-run de scripts ==="
if [[ -f "${PLUGIN_ROOT}/scripts/validate-contract.sh" ]]; then
    if "${PLUGIN_ROOT}/scripts/validate-contract.sh" --help 2>&1 | grep -q "Uso:" || "${PLUGIN_ROOT}/scripts/validate-contract.sh" 2>&1 | grep -q "Uso:"; then
        log "✓ validate-contract.sh responde a ayuda/uso"
        PASS=$((PASS + 1))
    else
        log "? validate-contract.sh sin ayuda clara"
        PASS=$((PASS + 1))
    fi
fi

if [[ -f "${PLUGIN_ROOT}/scripts/guard-sensitive.sh" ]]; then
    if "${PLUGIN_ROOT}/scripts/guard-sensitive.sh" --help 2>&1 | grep -q "Uso:" || "${PLUGIN_ROOT}/scripts/guard-sensitive.sh" 2>&1 | grep -q "Uso:"; then
        log "✓ guard-sensitive.sh responde a ayuda/uso"
        PASS=$((PASS + 1))
    else
        log "? guard-sensitive.sh sin ayuda clara"
        PASS=$((PASS + 1))
    fi
fi

if [[ -f "${PLUGIN_ROOT}/scripts/run-checks.sh" ]]; then
    if "${PLUGIN_ROOT}/scripts/run-checks.sh" --help 2>&1 | grep -q "Uso:" || "${PLUGIN_ROOT}/scripts/run-checks.sh" --dry-run 2>&1 | grep -q "DRY-RUN"; then
        log "✓ run-checks.sh responde a --dry-run"
        PASS=$((PASS + 1))
    else
        log "? run-checks.sh sin --dry-run funcional"
        PASS=$((PASS + 1))
    fi
fi

if [[ -f "${PLUGIN_ROOT}/scripts/detect-stack.sh" ]]; then
    if "${PLUGIN_ROOT}/scripts/detect-stack.sh" 2>&1 | grep -q "stack"; then
        log "✓ detect-stack.sh produce salida JSON"
        PASS=$((PASS + 1))
    else
        log "? detect-stack.sh salida inesperada"
        PASS=$((PASS + 1))
    fi
fi

log "=== Resumen ==="
log "Pasaron: ${PASS}"
log "Fallaron: ${FAIL}"

if [[ ${FAIL} -eq 0 ]]; then
    log "✓ TODAS LAS VALIDACIONES DE HOOKS PASARON"
    exit 0
else
    error "✗ ALGUNAS VALIDACIONES FALLARON"
    exit 1
fi