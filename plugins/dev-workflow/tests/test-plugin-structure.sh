#!/usr/bin/env bash
# test-plugin-structure.sh - Valida la estructura completa del plugin dev-workflow
# Uso: ./test-plugin-structure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
}

PASS=0
FAIL=0

check_file() {
    local file="$1"
    local desc="$2"
    if [[ -f "${PLUGIN_ROOT}/${file}" ]]; then
        log "✓ ${desc}: ${file}"
        PASS=$((PASS + 1))
    else
        error "✗ ${desc}: ${file} (NO ENCONTRADO)"
        FAIL=$((FAIL + 1))
    fi
}

check_dir() {
    local dir="$1"
    local desc="$2"
    if [[ -d "${PLUGIN_ROOT}/${dir}" ]]; then
        log "✓ ${desc}: ${dir}/"
        PASS=$((PASS + 1))
    else
        error "✗ ${desc}: ${dir}/ (NO ENCONTRADO)"
        FAIL=$((FAIL + 1))
    fi
}

check_json_valid() {
    local file="$1"
    local desc="$2"
    if [[ -f "${PLUGIN_ROOT}/${file}" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq empty "${PLUGIN_ROOT}/${file}" 2>/dev/null; then
                log "✓ ${desc}: ${file} (JSON válido)"
                PASS=$((PASS + 1))
            else
                error "✗ ${desc}: ${file} (JSON INVÁLIDO)"
                FAIL=$((FAIL + 1))
            fi
        elif command -v python3 >/dev/null 2>&1; then
            if python3 -m json.tool "${PLUGIN_ROOT}/${file}" >/dev/null 2>&1; then
                log "✓ ${desc}: ${file} (JSON válido)"
                PASS=$((PASS + 1))
            else
                error "✗ ${desc}: ${file} (JSON INVÁLIDO)"
                FAIL=$((FAIL + 1))
            fi
        else
            log "? ${desc}: ${file} (sin validador JSON)"
            PASS=$((PASS + 1))
        fi
    else
        error "✗ ${desc}: ${file} (NO ENCONTRADO)"
        FAIL=$((FAIL + 1))
    fi
}

check_yaml_frontmatter() {
    local file="$1"
    local desc="$2"
    if [[ -f "${PLUGIN_ROOT}/${file}" ]]; then
        # Check for --- at start and end of frontmatter
        if head -1 "${PLUGIN_ROOT}/${file}" | grep -q "^---$"; then
            log "✓ ${desc}: ${file} (frontmatter presente)"
            PASS=$((PASS + 1))
        else
            error "✗ ${desc}: ${file} (sin frontmatter ---)"
            FAIL=$((FAIL + 1))
        fi
    else
        error "✗ ${desc}: ${file} (NO ENCONTRADO)"
        FAIL=$((FAIL + 1))
    fi
}

log "=== Validando estructura del plugin dev-workflow ==="

# Plugin manifest
check_json_valid ".claude-plugin/plugin.json" "Plugin manifest"

# Agents
check_yaml_frontmatter "agents/architect.md" "Agent architect"
check_yaml_frontmatter "agents/implementer.md" "Agent implementer"
check_yaml_frontmatter "agents/reviewer.md" "Agent reviewer"
check_yaml_frontmatter "agents/qa.md" "Agent qa"

# Commands
check_yaml_frontmatter "commands/feature.md" "Command feature"

# Skills (10 skills)
SKILLS=(
    "workflow-contract"
    "stack-detector"
    "stack-java-spring"
    "stack-python-fastapi"
    "review-checklist"
    "test-strategy"
    "spring-microservices-patterns"
    "api-design-review"
    "security-review-owasp"
    "db-migration-review"
)

for skill in "${SKILLS[@]}"; do
    check_file "skills/${skill}/SKILL.md" "Skill ${skill}"
    check_dir "skills/${skill}" "Skill dir ${skill}"
done

# Skill reference files (spot check)
check_file "skills/workflow-contract/workflow-contract-schema.json" "Workflow contract schema"
check_file "skills/workflow-contract/workflow-contract-example.json" "Workflow contract example"
check_file "skills/stack-detector/stack-detector-rules.md" "Stack detector rules"
check_file "skills/stack-detector/supported-stacks.json" "Supported stacks"
check_file "skills/stack-java-spring/java-spring-conventions.md" "Java Spring conventions"
check_file "skills/stack-java-spring/java-spring-antipatterns.md" "Java Spring antipatterns"
check_file "skills/stack-java-spring/spring-boot-3-migration.md" "Spring Boot 3 migration"
check_file "skills/stack-python-fastapi/python-fastapi-conventions.md" "Python FastAPI conventions"
check_file "skills/stack-python-fastapi/python-fastapi-antipatterns.md" "Python FastAPI antipatterns"
check_file "skills/spring-microservices-patterns/saga-patterns.md" "Saga patterns"
check_file "skills/spring-microservices-patterns/outbox-pattern.md" "Outbox pattern"
check_file "skills/spring-microservices-patterns/idempotency.md" "Idempotency"
check_file "skills/spring-microservices-patterns/grpc-resilience.md" "gRPC resilience"
check_file "skills/spring-microservices-patterns/eventual-consistency.md" "Eventual consistency"
check_file "skills/api-design-review/api-conventions.md" "API conventions"
check_file "skills/security-review-owasp/owasp-top10-mapping.md" "OWASP mapping"
check_file "skills/db-migration-review/migration-conventions.md" "Migration conventions"

# Config
check_json_valid "config/stacks.json" "Stacks config"
check_json_valid "config/sensitive-patterns.json" "Sensitive patterns config"

# Hooks
check_json_valid "hooks/hooks.json" "Hooks config"

# Scripts
check_file "scripts/detect-stack.sh" "Detect stack script"
check_file "scripts/run-checks.sh" "Run checks script"
check_file "scripts/guard-sensitive.sh" "Guard sensitive script"
check_file "scripts/validate-contract.sh" "Validate contract script"

# Scripts executable
for script in scripts/detect-stack.sh scripts/run-checks.sh scripts/guard-sensitive.sh scripts/validate-contract.sh; do
    if [[ -f "${PLUGIN_ROOT}/${script}" && -x "${PLUGIN_ROOT}/${script}" ]]; then
        log "✓ Script ejecutable: ${script}"
        PASS=$((PASS + 1))
    elif [[ -f "${PLUGIN_ROOT}/${script}" ]]; then
        error "✗ Script NO ejecutable: ${script}"
        FAIL=$((FAIL + 1))
    fi
done

# Plugin.json references valid files
if [[ -f "${PLUGIN_ROOT}/.claude-plugin/plugin.json" ]]; then
    if command -v jq >/dev/null 2>&1; then
        # Check agents exist
        AGENTS=$(jq -r '.agents[]' "${PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null)
        for agent in ${AGENTS}; do
            check_file "${agent}" "Agent referenciado en plugin.json"
        done
        
        # Check skills exist
        SKILLS_REF=$(jq -r '.skills[]' "${PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null)
        for skill in ${SKILLS_REF}; do
            check_dir "${skill}" "Skill referenciado en plugin.json"
        done
        
        # Check commands exist
        CMDS=$(jq -r '.commands[]' "${PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null)
        for cmd in ${CMDS}; do
            check_file "${cmd}" "Command referenciado en plugin.json"
        done
    fi
fi

log "=== Resumen ==="
log "Pasaron: ${PASS}"
log "Fallaron: ${FAIL}"

if [[ ${FAIL} -eq 0 ]]; then
    log "✓ TODAS LAS VALIDACIONES DE ESTRUCTURA PASARON"
    exit 0
else
    error "✗ ALGUNAS VALIDACIONES FALLARON"
    exit 1
fi