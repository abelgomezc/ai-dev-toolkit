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
        "plugins/cicd-security-triage/agents/analyst.md"
        "plugins/cicd-security-triage/agents/fixer.md"
        "plugins/cicd-security-triage/agents/qa.md"
        "plugins/cicd-security-triage/commands/security-triage.md"
        "plugins/frontend-ui/agents/ui-designer.md"
        "plugins/frontend-ui/agents/ui-implementer.md"
        "plugins/frontend-ui/agents/ui-reviewer.md"
        "plugins/frontend-ui/commands/ui.md"
        "plugins/context-toolkit/commands/handoff.md"
        "plugins/context-toolkit/commands/map.md"
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

# Validate scripts exist
validate_scripts_exist() {
    log "=== Validando scripts ==="
    local scripts=(
        "plugins/dev-workflow/scripts/detect-stack.sh"
        "plugins/dev-workflow/scripts/run-checks.sh"
        "plugins/dev-workflow/scripts/guard-sensitive.sh"
        "plugins/dev-workflow/scripts/validate-contract.sh"
        "plugins/dev-workflow/tests/test-plugin-structure.sh"
        "plugins/dev-workflow/tests/test-hooks.sh"
        "plugins/cicd-security-triage/scripts/parse-grype.py"
        "plugins/cicd-security-triage/scripts/parse-sonar.py"
        "plugins/cicd-security-triage/scripts/parse-stackhawk.py"
        "plugins/frontend-ui/scripts/check-a11y.sh"
        "plugins/frontend-ui/scripts/check-bundle.sh"
        "evals/run-evals.py"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "${REPO_ROOT}/${script}" ]]; then
            log "✓ ${script} existe"
            PASS=$((PASS + 1))
        else
            error "✗ ${script} (NO ENCONTRADO)"
            FAIL=$((FAIL + 1))
        fi
    done
    echo
}

# Validate skills exist
validate_skills_exist() {
    log "=== Validando skills ==="
    local skill_files=(
        "plugins/dev-workflow/skills/stack-detector/SKILL.md"
        "plugins/dev-workflow/skills/stack-java-spring/SKILL.md"
        "plugins/dev-workflow/skills/stack-python-fastapi/SKILL.md"
        "plugins/dev-workflow/skills/review-checklist/SKILL.md"
        "plugins/dev-workflow/skills/test-strategy/SKILL.md"
        "plugins/dev-workflow/skills/spring-microservices-patterns/SKILL.md"
        "plugins/dev-workflow/skills/api-design-review/SKILL.md"
        "plugins/dev-workflow/skills/security-review-owasp/SKILL.md"
        "plugins/dev-workflow/skills/db-migration-review/SKILL.md"
        "plugins/dev-workflow/skills/workflow-contract/SKILL.md"
        "plugins/cicd-security-triage/skills/severity-rules/SKILL.md"
        "plugins/cicd-security-triage/skills/false-positive-triage/SKILL.md"
        "plugins/cicd-security-triage/skills/report-formats/SKILL.md"
        "plugins/frontend-ui/skills/accessibility-wcag/SKILL.md"
        "plugins/frontend-ui/skills/responsive-and-performance/SKILL.md"
        "plugins/frontend-ui/skills/ui-review-checklist/SKILL.md"
        "plugins/frontend-ui/skills/design-system-foundations/SKILL.md"
        "plugins/frontend-ui/skills/react-component-patterns/SKILL.md"
        "plugins/frontend-ui/skills/tailwind-shadcn-stack/SKILL.md"
        "plugins/frontend-ui/skills/forms-and-validation/SKILL.md"
        "plugins/frontend-ui/skills/data-display-and-charts/SKILL.md"
        "plugins/frontend-ui/skills/angular-ui-patterns/SKILL.md"
        "plugins/context-toolkit/skills/claude-md-writer/SKILL.md"
        "plugins/context-toolkit/skills/codebase-map/SKILL.md"
        "plugins/context-toolkit/skills/session-handoff/SKILL.md"
    )
    
    for skill in "${skill_files[@]}"; do
        if [[ -f "${REPO_ROOT}/${skill}" ]]; then
            log "✓ ${skill}"
            PASS=$((PASS + 1))
        else
            error "✗ ${skill} (NO ENCONTRADO)"
            FAIL=$((FAIL + 1))
        fi
    done
    echo
}

# Validate eval cases
validate_eval_cases() {
    log "=== Validando casos de evaluación ==="
    local expected_cases=20
    local actual_cases=$(find "${REPO_ROOT}/evals/cases" -name "*.md" -type f 2>/dev/null | wc -l)
    
    if [[ ${actual_cases} -eq ${expected_cases} ]]; then
        log "✓ ${actual_cases}/${expected_cases} casos de evaluación encontrados"
        PASS=$((PASS + 1))
    else
        error "✗ ${actual_cases}/${expected_cases} casos (se esperaban ${expected_cases})"
        FAIL=$((FAIL + 1))
    fi
    echo
}

# Main
log "=== VALIDACIÓN COMPLETA DEL REPOSITORIO ==="
log "Directorio: ${REPO_ROOT}"
echo

validate_json_files
validate_frontmatter
validate_scripts_exist
validate_skills_exist
validate_eval_cases

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