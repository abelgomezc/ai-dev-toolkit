#!/usr/bin/env bash
# guard-sensitive.sh - Bloquea edición de archivos sensibles (.env, claves, credenciales)
# Uso: ./guard-sensitive.sh <archivo_a_editar> [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${PLUGIN_ROOT}/config/sensitive-patterns.json"

FILE_TO_CHECK="${1:-}"
DRY_RUN=false

if [[ "$2" == "--dry-run" ]]; then
    DRY_RUN=true
fi

if [[ -z "${FILE_TO_CHECK}" ]]; then
    echo "Uso: $0 <archivo_a_editar> [--dry-run]" >&2
    exit 1
fi

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
}

# Default patterns if config not found
DEFAULT_PATTERNS=(
    '\.env(\.local)?$'
    '\.env\..*'
    'id_rsa$'
    'id_ed25519$'
    '\.pem$'
    '\.key$'
    '\.crt$'
    '\.p12$'
    '\.pfx$'
    'secrets\.ya?ml$'
    'credentials\.ya?ml$'
    '.*\.secret$'
    '.*_secret$'
    '.*-secret$'
    'AWS_SECRET_ACCESS_KEY'
    'AWS_ACCESS_KEY_ID'
    'DATABASE_PASSWORD'
    'DB_PASSWORD'
    'JWT_SECRET'
    'SECRET_KEY'
    'API_KEY'
    'PRIVATE_KEY'
    'BEGIN (RSA|EC|OPENSSH) PRIVATE KEY'
    'password\s*[=:]\s*["\x27][^"\x27]{8,}["\x27]'
    'token\s*[=:]\s*["\x27][^"\x27]{16,}["\x27]'
)

# Load patterns from config
load_patterns() {
    local patterns=()
    
    if [[ -f "${CONFIG_FILE}" ]]; then
        if command -v jq >/dev/null 2>&1; then
            mapfile -t patterns < <(jq -r '.patterns[]' "${CONFIG_FILE}" 2>/dev/null)
        elif command -v python3 >/dev/null 2>&1; then
            mapfile -t patterns < <(python3 -c "
import json, sys
with open('${CONFIG_FILE}') as f:
    config = json.load(f)
for p in config.get('patterns', []):
    print(p)
" 2>/dev/null)
        fi
    fi
    
    # Fallback to defaults if config loading failed
    if [[ ${#patterns[@]} -eq 0 ]]; then
        patterns=("${DEFAULT_PATTERNS[@]}")
    fi
    
    printf '%s\n' "${patterns[@]}"
}

# Check if file path matches sensitive patterns
check_file_path() {
    local file="$1"
    local patterns=()
    mapfile -t patterns < <(load_patterns)
    
    local basename_file=$(basename "${file}")
    local dirname_file=$(dirname "${file}")
    
    for pattern in "${patterns[@]}"; do
        # Check basename
        if [[ "${basename_file}" =~ ${pattern} ]]; then
            echo "Coincide patrón de archivo sensible: ${pattern}"
            return 1
        fi
        # Check full path
        if [[ "${file}" =~ ${pattern} ]]; then
            echo "Coincide patrón en ruta: ${pattern}"
            return 1
        fi
    done
    
    return 0
}

# Check file content for sensitive patterns
check_file_content() {
    local file="$1"
    local patterns=()
    mapfile -t patterns < <(load_patterns)
    
    if [[ ! -f "${file}" ]]; then
        return 0  # File doesn't exist yet, can't check content
    fi
    
    local content
    content=$(cat "${file}" 2>/dev/null || echo "")
    
    for pattern in "${patterns[@]}"; do
        if echo "${content}" | grep -qiE "${pattern}"; then
            echo "Contenido sensible detectado (patrón: ${pattern})"
            return 1
        fi
    done
    
    return 0
}

# Main
log "Verificando archivo: ${FILE_TO_CHECK}"

# Check file path
if ! check_file_path "${FILE_TO_CHECK}"; then
    error "BLOQUEADO: El archivo coincide con patrones de archivos sensibles"
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "[DRY-RUN] Se bloquearía la edición"
    fi
    exit 1
fi

# Check file content (if exists)
if ! check_file_content "${FILE_TO_CHECK}"; then
    error "BLOQUEADO: El archivo contiene patrones sensibles"
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "[DRY-RUN] Se bloquearía la edición"
    fi
    exit 1
fi

log "✓ Archivo verificado, no se detectaron patrones sensibles"
exit 0