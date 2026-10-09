#!/usr/bin/env bash
# validate-contract.sh - Valida un workflow-contract contra el schema JSON
# Uso: ./validate-contract.sh <archivo_contrato.json>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCHEMA_FILE="${PLUGIN_ROOT}/skills/workflow-contract/workflow-contract-schema.json"

CONTRACT_FILE="${1:-}"

if [[ -z "${CONTRACT_FILE}" ]]; then
    echo "Uso: $0 <archivo_contrato.json>" >&2
    exit 1
fi

if [[ ! -f "${CONTRACT_FILE}" ]]; then
    echo "Error: Archivo de contrato no encontrado: ${CONTRACT_FILE}" >&2
    exit 1
fi

if [[ ! -f "${SCHEMA_FILE}" ]]; then
    echo "Error: Schema no encontrado: ${SCHEMA_FILE}" >&2
    exit 1
fi

# Verificar si python3 está disponible para validación JSON Schema
if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
import sys
try:
    import jsonschema
except ImportError:
    print('ERROR: jsonschema no instalado. pip install jsonschema', file=sys.stderr)
    sys.exit(1)

with open('${SCHEMA_FILE}') as f:
    schema = json.load(f)
with open('${CONTRACT_FILE}') as f:
    contract = json.load(f)

try:
    jsonschema.validate(instance=contract, schema=schema)
    print('✓ Contrato válido según schema')
    sys.exit(0)
except jsonschema.exceptions.ValidationError as e:
    print(f'✗ Contrato INVÁLIDO: {e.message}', file=sys.stderr)
    print(f'  Ruta: {\".\".join(str(x) for x in e.path)}', file=sys.stderr)
    sys.exit(1)
"
else
    echo "Advertencia: python3 no disponible, validación básicaのみ" >&2
    # Validación básica con jq si está disponible
    if command -v jq >/dev/null 2>&1; then
        if jq -e '.task_id and .stage and .status and .summary and .artifacts and .findings and .next_action' "${CONTRACT_FILE}" >/dev/null; then
            echo "✓ Campos obligatorios presentes (validación básica)"
            exit 0
        else
            echo "✗ Faltan campos obligatorios" >&2
            exit 1
        fi
    else
        echo "Error: Ni python3 ni jq disponibles para validación" >&2
        exit 1
    fi
fi