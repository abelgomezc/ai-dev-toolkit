#!/usr/bin/env bash
# detect-stack.sh - Detecta el stack tecnológico del proyecto
# Output: JSON con stack detectado, confianza y evidencia

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_FILE="${PLUGIN_ROOT}/skills/stack-detector/stack-detector-rules.md"
SUPPORTED_STACKS_FILE="${PLUGIN_ROOT}/skills/stack-detector/supported-stacks.json"

log() {
    echo "[$(date '+%H:%M:%S')] $*" >&2
}

# Initialize scores
declare -A SCORES
SCORES["java-spring"]=0
SCORES["python-fastapi"]=0
SCORES["node-react"]=0
SCORES["angular"]=0

declare -A EVIDENCE

add_evidence() {
    local stack="$1"
    local file="$2"
    local pattern="$3"
    local weight="$4"
    EVIDENCE["${stack}"]+="{\"file\":\"${file}\",\"pattern\":\"${pattern}\",\"weight\":${weight}},"
}

# Check file exists and contains pattern
check_file_pattern() {
    local file="$1"
    local pattern="$2"
    [[ -f "${file}" ]] && grep -qE "${pattern}" "${file}" 2>/dev/null
}

# Java/Spring detection
if check_file_pattern "pom.xml" "spring-boot-starter-parent"; then
    SCORES["java-spring"]=$((SCORES["java-spring"] + 100))
    add_evidence "java-spring" "pom.xml" "spring-boot-starter-parent" 100
fi

if check_file_pattern "build.gradle" "org.springframework.boot"; then
    SCORES["java-spring"]=$((SCORES["java-spring"] + 100))
    add_evidence "java-spring" "build.gradle" "org.springframework.boot" 100
fi

if check_file_pattern "pom.xml" "spring-boot-starter-web"; then
    SCORES["java-spring"]=$((SCORES["java-spring"] + 80))
    add_evidence "java-spring" "pom.xml" "spring-boot-starter-web" 80
fi

if check_file_pattern "build.gradle" "spring-boot-starter-web"; then
    SCORES["java-spring"]=$((SCORES["java-spring"] + 80))
    add_evidence "java-spring" "build.gradle" "spring-boot-starter-web" 80
fi

if find . -name "*.java" -exec grep -l "@SpringBootApplication" {} \; 2>/dev/null | head -1 | grep -q .; then
    SCORES["java-spring"]=$((SCORES["java-spring"] + 60))
    add_evidence "java-spring" "*.java" "@SpringBootApplication" 60
fi

# Detect build tool for java-spring
if [[ -f "pom.xml" ]]; then
    EVIDENCE["java-spring"]+="{\"file\":\"pom.xml\",\"pattern\":\"maven\",\"weight\":10},"
elif [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
    EVIDENCE["java-spring"]+="{\"file\":\"build.gradle*\",\"pattern\":\"gradle\",\"weight\":10},"
fi

# Detect Java version
if check_file_pattern "pom.xml" "java.version[^>]*21"; then
    EVIDENCE["java-spring"]+="{\"file\":\"pom.xml\",\"pattern\":\"java 21\",\"weight\":5},"
elif check_file_pattern "build.gradle" "languageVersion = JavaLanguageVersion.of(21)"; then
    EVIDENCE["java-spring"]+="{\"file\":\"build.gradle\",\"pattern\":\"java 21\",\"weight\":5},"
fi

# Python/FastAPI detection
if check_file_pattern "pyproject.toml" "fastapi"; then
    SCORES["python-fastapi"]=$((SCORES["python-fastapi"] + 100))
    add_evidence "python-fastapi" "pyproject.toml" "fastapi" 100
fi

if check_file_pattern "requirements.txt" "fastapi"; then
    SCORES["python-fastapi"]=$((SCORES["python-fastapi"] + 90))
    add_evidence "python-fastapi" "requirements.txt" "fastapi" 90
fi

if check_file_pattern "pyproject.toml" "uvicorn"; then
    SCORES["python-fastapi"]=$((SCORES["python-fastapi"] + 70))
    add_evidence "python-fastapi" "pyproject.toml" "uvicorn" 70
fi

if find . -name "*.py" -exec grep -l "from fastapi import FastAPI" {} \; 2>/dev/null | head -1 | grep -q .; then
    SCORES["python-fastapi"]=$((SCORES["python-fastapi"] + 60))
    add_evidence "python-fastapi" "*.py" "from fastapi import FastAPI" 60
fi

# Detect package manager
if [[ -f "uv.lock" ]]; then
    EVIDENCE["python-fastapi"]+="{\"file\":\"uv.lock\",\"pattern\":\"uv\",\"weight\":10},"
elif [[ -f "poetry.lock" ]]; then
    EVIDENCE["python-fastapi"]+="{\"file\":\"poetry.lock\",\"pattern\":\"poetry\",\"weight\":10},"
elif [[ -f "Pipfile" ]]; then
    EVIDENCE["python-fastapi"]+="{\"file\":\"Pipfile\",\"pattern\":\"pipenv\",\"weight\":10},"
else
    EVIDENCE["python-fastapi"]+="{\"file\":\"requirements.txt\",\"pattern\":\"pip\",\"weight\":10},"
fi

# Node/React detection
if check_file_pattern "package.json" "react"; then
    if check_file_pattern "package.json" "next"; then
        SCORES["node-react"]=$((SCORES["node-react"] + 90))
        add_evidence "node-react" "package.json" "next" 90
    elif check_file_pattern "package.json" "vite"; then
        SCORES["node-react"]=$((SCORES["node-react"] + 80))
        add_evidence "node-react" "package.json" "vite" 80
    else
        SCORES["node-react"]=$((SCORES["node-react"] + 100))
        add_evidence "node-react" "package.json" "react + react-dom" 100
    fi
fi

if check_file_pattern "tsconfig.json" "react-jsx"; then
    SCORES["node-react"]=$((SCORES["node-react"] + 60))
    add_evidence "node-react" "tsconfig.json" "react-jsx" 60
fi

# Angular detection
if check_file_pattern "package.json" "@angular/core"; then
    SCORES["angular"]=$((SCORES["angular"] + 100))
    add_evidence "angular" "package.json" "@angular/core" 100
fi

if [[ -f "angular.json" ]]; then
    SCORES["angular"]=$((SCORES["angular"] + 90))
    add_evidence "angular" "angular.json" "exists" 90
fi

# Find max score
MAX_STACK=""
MAX_SCORE=0
for stack in "${!SCORES[@]}"; do
    if [[ ${SCORES[$stack]} -gt ${MAX_SCORE} ]]; then
        MAX_SCORE=${SCORES[$stack]}
        MAX_STACK=$stack
    fi
done

# Check monorepo
MONOREPO_COUNT=0
for stack in "${!SCORES[@]}"; do
    if [[ ${SCORES[$stack]} -ge 80 ]]; then
        MONOREPO_COUNT=$((MONOREPO_COUNT + 1))
    fi
done

if [[ ${MONOREPO_COUNT} -gt 1 ]]; then
    MAX_STACK="monorepo"
    MAX_SCORE=100
fi

# Minimum confidence threshold
MIN_CONFIDENCE=60
if [[ -f "${SUPPORTED_STACKS_FILE}" ]]; then
    if command -v jq >/dev/null 2>&1; then
        MIN_CONFIDENCE=$(jq -r '.detection.min_confidence // 60' "${SUPPORTED_STACKS_FILE}")
    fi
fi

if [[ ${MAX_SCORE} -lt ${MIN_CONFIDENCE} ]]; then
    MAX_STACK="unknown"
    MAX_SCORE=0
fi

# Build evidence JSON
EVIDENCE_JSON="["
for stack in "${!EVIDENCE[@]}"; do
    if [[ -n "${EVIDENCE[$stack]}" ]]; then
        EVIDENCE_JSON+="${EVIDENCE[$stack]%,}"
    fi
done
EVIDENCE_JSON="${EVIDENCE_JSON%,}]"

# Output JSON
if command -v jq >/dev/null 2>&1; then
    jq -n \
        --arg stack "${MAX_STACK}" \
        --argjson confidence "${MAX_SCORE}" \
        --argjson evidence "${EVIDENCE_JSON}" \
        '{stack: $stack, confidence: $confidence, evidence: $evidence}'
elif command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json, sys
evidence = ${EVIDENCE_JSON}
print(json.dumps({'stack': '${MAX_STACK}', 'confidence': ${MAX_SCORE}, 'evidence': evidence}))
"
else
    # Basic JSON output without jq/python
    echo "{\"stack\":\"${MAX_STACK}\",\"confidence\":${MAX_SCORE},\"evidence\":${EVIDENCE_JSON}}"
fi