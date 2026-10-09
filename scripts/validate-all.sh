#!/usr/bin/env bash
# validate-all.sh - Ejecuta todas las validaciones del repositorio
# Uso: ./validate-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
}

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local script="$2"
    
    log "=== Ejecutando: ${name} ==="
    if [[ -f "${REPO_ROOT}/${script}" && -x "${REPO_ROOT}/${script}" ]]; then
        if "${REPO_ROOT}/${script}"; then
            log "✓ ${name} PASÓ"
            PASS=$((PASS + 1))
        else
            error "✗ ${name} FALLÓ"
            FAIL=$((FAIL + 1))
        fi
    elif [[ -f "${REPO_ROOT}/${script}" ]]; then
        error "✗ ${name}: script no ejecutable (${script})"
        FAIL=$((FAIL + 1))
    else
        error "✗ ${name}: script no encontrado (${script})"
        FAIL=$((FAIL + 1))
    fi
    echo
}

# Validate JSON files
validate_json_files() {
    log "=== Validando archivos JSON ==="
    local json_files=(
        ".claude-plugin/marketplace.json"
        "plugins/dev-workflow/.claude-plugin/plugin.json"
        "plugins/cicd-security-triage/.claude-plugin/plugin.json"
        "plugins/frontend-ui/.claude-plugin/plugin.json"
        "plugins/context-toolkit/.claude-plugin/plugin.json"
        "plugins/dev-workflow/config/stacks.json"
        "plugins/dev-workflow/config/sensitive-patterns.json"
        "plugins/dev-workflow/hooks/hooks.json"
        "plugins/dev-workflow/skills/stack-detector/supported-stacks.json"
        "plugins/dev-workflow/skills/workflow-contract/workflow-contract-schema.json"
        "plugins/dev-workflow/skills/workflow-contract/workflow-contract-example.json"
    )
    
    for file in "${json_files[@]}"; do
        if [[ -f "${REPO_ROOT}/${file}" ]]; then
            if command -v jq >/dev/null 2>&1; then
                if jq empty "${REPO_ROOT}/${file}" 2>/dev/null; then
                    log "✓ ${file} (JSON válido)"
                    PASS=$((PASS + 1))
                else
                    error "✗ ${file} (JSON INVÁLIDO)"
                    FAIL=$((FAIL + 1))
                fi
            elif command -v python3 >/dev/null 2>&1; then
                if python3 -m json.tool "${REPO_ROOT}/${file}" >/dev/null 2>&1; then
                    log "✓ ${file} (JSON válido)"
                    PASS=$((PASS + 1))
                else
                    error "✗ ${file} (JSON INVÁLIDO)"
                    FAIL=$((FAIL + 1))
                fi
            else
                log "? ${file} (sin validador)"
                PASS=$((PASS + 1))
            fi
        else
            error "✗ ${file} (NO ENCONTRADO)"
            FAIL=$((FAIL + 1))
        fi
    done
    echo
}

# Validate YAML frontmatter
validate_frontmatter() {
    log "=== Validando frontmatter YAML ==="
    local md_files=(
        "plugins/dev-workflow/agents/architect.md"
        "plugins/dev-workflow/agents/implementer.md"
        "plugins/dev-workflow/agents/reviewer.md"
        "plugins/dev-workflow/agents/qa.md"
        "plugins/dev-workflow/commands/feature.md"
    )
    
    for file in "${md_files[@]}"; do
        if [[ -f "${REPO_ROOT}/${file}" ]]; then
            if head -1 "${REPO_ROOT}/${file}" | grep -q "^---$"; then
                log "✓ ${file} (frontmatter presente)"
                PASS=$((PASS + 1))
            else
                error "✗ ${file} (sin frontmatter ---)"
                FAIL=$((FAIL + 1))
            fi
        else
            error "✗ ${file} (NO ENCONTRADO)"
            FAIL=$((FAIL + 1))
        fi
    done
    echo
}

# Validate scripts executable
validate_scripts_executable() {
    log "=== Validando scripts ejecutables ==="
    local scripts=(
        "plugins/dev-workflow/scripts/detect-stack.sh"
        "plugins/dev-workflow/scripts/run-checks.sh"
        "plugins/dev-workflow/scripts/guard-sensitive.sh"
        "plugins/dev-workflow/scripts/validate-contract.sh"
        "plugins/dev-workflow/tests/test-plugin-structure.sh"
        "plugins/dev-workflow/tests/test-hooks.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "${REPO_ROOT}/${script}" && -x "${REPO_ROOT}/${script}" ]]; then
            log "✓ ${script} (ejecutable)"
            PASS=$((PASS + 1))
        elif [[ -f "${REPO_ROOT}/${script}" ]]; then
            error "✗ ${script} (NO ejecutable)"
            FAIL=$((FAIL + 1))
        else
            error "✗ ${script} (NO ENCONTRADO)"
            FAIL=$((FAIL + 1))
        fi
    done
    echo
}

# Main
log "=== VALIDACIÓN COMPLETA DEL REPOSITORIO ==="
log "Directorio: ${REPO_ROOT}"
echo

validate_json_files
validate_frontmatter
validate_scripts_executable

# Run test scripts
run_test "test-plugin-structure.sh" "plugins/dev-workflow/tests/test-plugin-structure.sh"
run_test "test-hooks.sh" "plugins/dev-workflow/tests/test-hooks.sh"

log "=== RESUMEN FINAL ==="
log "Pruebas pasadas: ${PASS}"
log "Pruebas fallidas: ${FAIL}"

if [[ ${FAIL} -eq 0 ]]; then
    log "✓✓✓ TODAS LAS VALIDACIONES PASARON ✓✓✓"
    exit 0
else
    error "✗✗✗ ALGUNAS VALIDACIONES FALLARON ✗✗✗"
    exit 1
fi