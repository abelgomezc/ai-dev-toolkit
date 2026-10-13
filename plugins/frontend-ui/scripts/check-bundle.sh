#!/usr/bin/env bash
# check-bundle.sh - Bundle size validation script for frontend-ui
# Uso: ./check-bundle.sh [--ci] [--budget=500] [--analyze]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CI_MODE=false
BUDGET_KB=500  # Default 500KB gzipped for initial bundle
ANALYZE=false

for arg in "$@"; do
    case $arg in
        --ci) CI_MODE=true ;;
        --budget=*) BUDGET_KB="${arg#*=}" ;;
        --analyze) ANALYZE=true ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# Detect framework
detect_framework() {
    if [[ -f "$PROJECT_ROOT/next.config.js" ]] || [[ -f "$PROJECT_ROOT/next.config.mjs" ]]; then
        echo "nextjs"
    elif [[ -f "$PROJECT_ROOT/vite.config.ts" ]] || [[ -f "$PROJECT_ROOT/vite.config.js" ]]; then
        echo "vite"
    elif [[ -f "$PROJECT_ROOT/angular.json" ]]; then
        echo "angular"
    elif [[ -f "$PROJECT_ROOT/astro.config.mjs" ]]; then
        echo "astro"
    else
        echo "unknown"
    fi
}

FRAMEWORK=$(detect_framework)
echo "📦 Bundle Size Check"
echo "   Project: $PROJECT_ROOT"
echo "   Framework: $FRAMEWORK"
echo "   Budget: ${BUDGET_KB}KB gzipped (initial)"
echo "   CI mode: $CI_MODE"
echo ""

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

# Build if needed
build_project() {
    echo "  Building project..."
    if ! "${RUN_CMD[@]}" build 2>&1 | tail -20; then
        echo "  ❌ Build failed"
        return 1
    fi
    echo "  ✅ Build successful"
    return 0
}

# Next.js bundle analysis
analyze_nextjs() {
    local build_dir="$PROJECT_ROOT/.next"
    local static_dir="$build_dir/static/chunks"
    
    if [[ ! -d "$static_dir" ]]; then
        echo "  ⚠️  Next.js build output not found at $static_dir"
        return 1
    fi
    
    echo "  Analyzing Next.js bundles..."
    
    # Find all JS chunks
    local chunks=()
    while IFS= read -r -d '' file; do
        chunks+=("$file")
    done < <(find "$static_dir" -name "*.js" -print0 2>/dev/null)
    
    if [[ ${#chunks[@]} -eq 0 ]]; then
        echo "  ⚠️  No JS chunks found"
        return 1
    fi
    
    # Calculate sizes
    local total_bytes=0
    local largest_chunk=""
    local largest_size=0
    
    for chunk in "${chunks[@]}"; do
        local size=$(stat -c%s "$chunk" 2>/dev/null || stat -f%z "$chunk" 2>/dev/null)
        local gzipped_size=$(gzip -c "$chunk" | wc -c)
        
        total_bytes=$((total_bytes + gzipped_size))
        
        if [[ $gzipped_size -gt $largest_size ]]; then
            largest_size=$gzipped_size
            largest_chunk=$(basename "$chunk")
        fi
        
        local kb=$((gzipped_size / 1024))
        if [[ $kb -gt 100 ]]; then
            echo "    ⚠️  Large chunk: $(basename "$chunk") = ${kb}KB gzipped"
        fi
    done
    
    local total_kb=$((total_bytes / 1024))
    local largest_kb=$((largest_size / 1024))
    
    echo "  📊 Bundle Summary:"
    echo "     Total chunks: ${#chunks[@]}"
    echo "     Total size (gzipped): ${total_kb}KB"
    echo "     Largest chunk: $largest_chunk (${largest_kb}KB)"
    
    # Check budget
    if [[ $total_kb -gt $BUDGET_KB ]]; then
        echo "  ❌ BUDGET EXCEEDED: ${total_kb}KB > ${BUDGET_KB}KB"
        return 1
    fi
    
    echo "  ✅ Within budget (${total_kb}KB <= ${BUDGET_KB}KB)"
    
    # Run bundle analyzer if requested
    if $ANALYZE; then
        echo "  Running @next/bundle-analyzer..."
        ANALYZE=true "${RUN_CMD[@]}" build 2>&1 | tail -30
    fi
    
    return 0
}

# Vite bundle analysis
analyze_vite() {
    local build_dir="$PROJECT_ROOT/dist"
    
    if [[ ! -d "$build_dir" ]]; then
        echo "  ⚠️  Vite build output not found at $build_dir"
        return 1
    fi
    
    echo "  Analyzing Vite bundles..."
    
    local assets_dir="$build_dir/assets"
    if [[ ! -d "$assets_dir" ]]; then
        echo "  ⚠️  No assets directory found"
        return 1
    fi
    
    local chunks=()
    while IFS= read -r -d '' file; do
        chunks+=("$file")
    done < <(find "$assets_dir" -name "*.js" -print0 2>/dev/null)
    
    if [[ ${#chunks[@]} -eq 0 ]]; then
        echo "  ⚠️  No JS chunks found"
        return 1
    fi
    
    local total_bytes=0
    local largest_chunk=""
    local largest_size=0
    
    for chunk in "${chunks[@]}"; do
        local size=$(stat -c%s "$chunk" 2>/dev/null || stat -f%z "$chunk" 2>/dev/null)
        local gzipped_size=$(gzip -c "$chunk" | wc -c)
        
        total_bytes=$((total_bytes + gzipped_size))
        
        if [[ $gzipped_size -gt $largest_size ]]; then
            largest_size=$gzipped_size
            largest_chunk=$(basename "$chunk")
        fi
        
        local kb=$((gzipped_size / 1024))
        if [[ $kb -gt 100 ]]; then
            echo "    ⚠️  Large chunk: $(basename "$chunk") = ${kb}KB gzipped"
        fi
    done
    
    local total_kb=$((total_bytes / 1024))
    local largest_kb=$((largest_size / 1024))
    
    echo "  📊 Bundle Summary:"
    echo "     Total chunks: ${#chunks[@]}"
    echo "     Total size (gzipped): ${total_kb}KB"
    echo "     Largest chunk: $largest_chunk (${largest_kb}KB)"
    
    if [[ $total_kb -gt $BUDGET_KB ]]; then
        echo "  ❌ BUDGET EXCEEDED: ${total_kb}KB > ${BUDGET_KB}KB"
        return 1
    fi
    
    echo "  ✅ Within budget (${total_kb}KB <= ${BUDGET_KB}KB)"
    
    if $ANALYZE; then
        echo "  Running vite-bundle-analyzer..."
        npx -y vite-bundle-analyzer "$build_dir" 2>&1 | head -50
    fi
    
    return 0
}

# Angular bundle analysis
analyze_angular() {
    local build_dir="$PROJECT_ROOT/dist"
    
    # Find browser output
    local browser_dir=$(find "$build_dir" -name "browser" -type d 2>/dev/null | head -1)
    if [[ -z "$browser_dir" ]]; then
        browser_dir=$(find "$build_dir" -maxdepth 1 -type d ! -path "$build_dir" | head -1)
    fi
    
    if [[ ! -d "$browser_dir" ]]; then
        echo "  ⚠️  Angular build output not found"
        return 1
    fi
    
    echo "  Analyzing Angular bundles..."
    
    local chunks=()
    while IFS= read -r -d '' file; do
        chunks+=("$file")
    done < <(find "$browser_dir" -name "*.js" -print0 2>/dev/null)
    
    if [[ ${#chunks[@]} -eq 0 ]]; then
        echo "  ⚠️  No JS chunks found"
        return 1
    fi
    
    local total_bytes=0
    local largest_chunk=""
    local largest_size=0
    
    for chunk in "${chunks[@]}"; do
        local size=$(stat -c%s "$chunk" 2>/dev/null || stat -f%z "$chunk" 2>/dev/null)
        local gzipped_size=$(gzip -c "$chunk" | wc -c)
        
        total_bytes=$((total_bytes + gzipped_size))
        
        if [[ $gzipped_size -gt $largest_size ]]; then
            largest_size=$gzipped_size
            largest_chunk=$(basename "$chunk")
        fi
        
        local kb=$((gzipped_size / 1024))
        if [[ $kb -gt 100 ]]; then
            echo "    ⚠️  Large chunk: $(basename "$chunk") = ${kb}KB gzipped"
        fi
    done
    
    local total_kb=$((total_bytes / 1024))
    local largest_kb=$((largest_size / 1024))
    
    echo "  📊 Bundle Summary:"
    echo "     Total chunks: ${#chunks[@]}"
    echo "     Total size (gzipped): ${total_kb}KB"
    echo "     Largest chunk: $largest_chunk (${largest_kb}KB)"
    
    # Check Angular budgets from angular.json
    if [[ -f "$PROJECT_ROOT/angular.json" ]]; then
        echo "  Checking angular.json budgets..."
        # angular CLI already validates budgets during build
    fi
    
    if [[ $total_kb -gt $BUDGET_KB ]]; then
        echo "  ❌ BUDGET EXCEEDED: ${total_kb}KB > ${BUDGET_KB}KB"
        return 1
    fi
    
    echo "  ✅ Within budget (${total_kb}KB <= ${BUDGET_KB}KB)"
    
    if $ANALYZE; then
        echo "  Running webpack-bundle-analyzer..."
        npx -y webpack-bundle-analyzer "$browser_dir" 2>&1 | head -50
    fi
    
    return 0
}

# Generic fallback
analyze_generic() {
    local build_dirs=("$PROJECT_ROOT/dist" "$PROJECT_ROOT/build" "$PROJECT_ROOT/.next" "$PROJECT_ROOT/public")
    
    for dir in "${build_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "  Analyzing $dir..."
            
            local chunks=()
            while IFS= read -r -d '' file; do
                chunks+=("$file")
            done < <(find "$dir" -name "*.js" -print0 2>/dev/null)
            
            if [[ ${#chunks[@]} -eq 0 ]]; then
                continue
            fi
            
            local total_bytes=0
            for chunk in "${chunks[@]}"; do
                local gzipped_size=$(gzip -c "$chunk" | wc -c)
                total_bytes=$((total_bytes + gzipped_size))
            done
            
            local total_kb=$((total_bytes / 1024))
            echo "  📊 Total size (gzipped): ${total_kb}KB"
            
            if [[ $total_kb -gt $BUDGET_KB ]]; then
                echo "  ❌ BUDGET EXCEEDED: ${total_kb}KB > ${BUDGET_KB}KB"
                return 1
            fi
            
            echo "  ✅ Within budget"
            return 0
        fi
    done
    
    echo "  ⚠️  No build output found in standard locations"
    return 1
}

# Main execution
main() {
    local overall_exit=0
    
    # Build first (unless CI and artifacts exist)
    if $CI_MODE && [[ -d "$PROJECT_ROOT/.next" || -d "$PROJECT_ROOT/dist" || -d "$PROJECT_ROOT/build" ]]; then
        echo "  CI mode: using existing build artifacts"
    else
        build_project || overall_exit=$?
    fi
    
    if [[ $overall_exit -ne 0 ]]; then
        echo ""
        echo "❌ Bundle check FAILED (build failed)"
        return 1
    fi
    
    echo ""
    echo "  Analyzing bundles for $FRAMEWORK..."
    
    case $FRAMEWORK in
        nextjs)
            analyze_nextjs || overall_exit=$?
            ;;
        vite)
            analyze_vite || overall_exit=$?
            ;;
        angular)
            analyze_angular || overall_exit=$?
            ;;
        *)
            analyze_generic || overall_exit=$?
            ;;
    esac
    
    echo ""
    if [[ $overall_exit -eq 0 ]]; then
        echo "✅ Bundle size check PASSED"
    else
        echo "❌ Bundle size check FAILED"
    fi
    
    return $overall_exit
}

main "$@"