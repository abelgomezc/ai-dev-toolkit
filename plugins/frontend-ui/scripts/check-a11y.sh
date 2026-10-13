#!/usr/bin/env bash
# check-a11y.sh - Accessibility validation script for frontend-ui
# Uso: ./check-a11y.sh [--ci] [--fix] [--report=html|json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="${PROJECT_ROOT}/packages/frontend"  # Ajustar según estructura

CI_MODE=false
FIX_MODE=false
REPORT_FORMAT="console"

# Parse args
for arg in "$@"; do
    case $arg in
        --ci) CI_MODE=true ;;
        --fix) FIX_MODE=true ;;
        --report=*) REPORT_FORMAT="${arg#*=}" ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# Detect package manager
if [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then
    PKG_MGR="pnpm"
elif [[ -f "$PROJECT_ROOT/yarn.lock" ]]; then
    PKG_MGR="yarn"
elif [[ -f "$PROJECT_ROOT/package-lock.json" ]]; then
    PKG_MGR="npm"
else
    PKG_MGR="npm"
fi

RUN_CMD=("$PKG_MGR" "run")

echo "🔍 Accessibility Check (WCAG 2.1 AA)"
echo "   Project: $PROJECT_ROOT"
echo "   Package manager: $PKG_MGR"
echo "   CI mode: $CI_MODE"
echo ""

# Check if axe-core is available
check_axe_installed() {
    if [[ -f "$PROJECT_ROOT/node_modules/.bin/axe" ]] || \
       [[ -f "$PROJECT_ROOT/node_modules/.bin/axe-cli" ]] || \
       grep -q '"@axe-core' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Run axe-core CLI
run_axe_cli() {
    local urls=("$@")
    local exit_code=0
    
    for url in "${urls[@]}"; do
        echo "  Scanning: $url"
        if command -v axe >/dev/null 2>&1; then
            axe "$url" --save --format="${REPORT_FORMAT}" || exit_code=$?
        elif [[ -f "$PROJECT_ROOT/node_modules/.bin/axe-cli" ]]; then
            "$PROJECT_ROOT/node_modules/.bin/axe-cli" "$url" --save --format="${REPORT_FORMAT}" || exit_code=$?
        else
            # Use npx
            npx -y @axe-core/cli "$url" --save --format="${REPORT_FORMAT}" || exit_code=$?
        fi
    done
    
    return $exit_code
}

# Run Playwright + axe (E2E)
run_playwright_a11y() {
    local test_file="$PROJECT_ROOT/tests/a11y.spec.ts"
    
    if [[ ! -f "$test_file" ]]; then
        echo "  ⚠️  Playwright a11y test not found: $test_file"
        echo "     Create tests/a11y.spec.ts with @axe-core/playwright"
        return 1
    fi
    
    echo "  Running Playwright + axe-core..."
    "${RUN_CMD[@]}" test:a11y 2>/dev/null || "${RUN_CMD[@]}" test --grep "a11y" 2>/dev/null || {
        echo "  ⚠️  Playwright test failed or not configured"
        return 1
    }
}

# Run eslint-plugin-jsx-a11y
run_eslint_a11y() {
    echo "  Running eslint-plugin-jsx-a11y..."
    if grep -q "jsx-a11y" "$PROJECT_ROOT/.eslintrc.json" 2>/dev/null || \
       grep -q "jsx-a11y" "$PROJECT_ROOT/eslint.config.js" 2>/dev/null; then
        "${RUN_CMD[@]}" lint 2>&1 | grep -i "jsx-a11y" || true
    else
        echo "  ⚠️  jsx-a11y not configured in ESLint"
        return 1
    fi
}

# Check for common violations in source
check_source_violations() {
    local violations=0
    
    echo "  Checking source for common violations..."
    
    # Check for missing alt on images
    if grep -r '<img ' --include="*.tsx" --include="*.jsx" "$PROJECT_ROOT/src" 2>/dev/null | \
       grep -v 'alt=' | grep -v 'aria-hidden' | grep -v 'test' | head -5; then
        echo "    ⚠️  Images without alt attribute found"
        ((violations++))
    fi
    
    # Check for hardcoded colors (common a11y issue)
    if grep -rE '(text-gray-400|text-gray-500|bg-gray-100|bg-gray-200).*text-' --include="*.tsx" "$PROJECT_ROOT/src" 2>/dev/null | head -3; then
        echo "    ⚠️  Potential contrast issues with gray text on light backgrounds"
        ((violations++))
    fi
    
    # Check for missing labels on inputs
    if grep -r '<input ' --include="*.tsx" --include="*.jsx" "$PROJECT_ROOT/src" 2>/dev/null | \
       grep -v 'id=' | grep -v 'aria-label' | grep -v 'aria-labelledby' | head -3; then
        echo "    ⚠️  Inputs without accessible labels found"
        ((violations++))
    fi
    
    # Check for missing focus styles
    if ! grep -r ':focus-visible' --include="*.css" --include="*.scss" --include="*.tsx" "$PROJECT_ROOT/src" 2>/dev/null | head -1; then
        echo "    ⚠️  No :focus-visible styles found"
        ((violations++))
    fi
    
    return $violations
}

# Main execution
main() {
    local overall_exit=0
    
    # 1. Source code static checks
    echo "1️⃣  Static source analysis..."
    check_source_violations || overall_exit=$?
    
    # 2. ESLint jsx-a11y
    echo ""
    echo "2️⃣  ESLint jsx-a11y..."
    run_eslint_a11y || overall_exit=$?
    
    # 3. Playwright + axe (if available)
    echo ""
    echo "3️⃣  Playwright + axe-core (E2E)..."
    run_playwright_a11y || overall_exit=$?
    
    # 4. axe-cli on built pages (if CI and build exists)
    if $CI_MODE; then
        echo ""
        echo "4️⃣  axe-cli on production build..."
        BUILD_DIR="$PROJECT_ROOT/dist"
        if [[ -d "$BUILD_DIR" ]]; then
            # Start preview server
            npx -y serve -s "$BUILD_DIR" -l 3000 &
            SERVER_PID=$!
            sleep 3
            
            run_axe_cli "http://localhost:3000" || overall_exit=$?
            
            kill $SERVER_PID 2>/dev/null || true
        else
            echo "  ⚠️  No build directory found, skipping axe-cli"
        fi
    fi
    
    echo ""
    if [[ $overall_exit -eq 0 ]]; then
        echo "✅ Accessibility checks PASSED"
    else
        echo "❌ Accessibility checks FAILED"
    fi
    
    return $overall_exit
}

main "$@"