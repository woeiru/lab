#!/bin/bash
#######################################################################
# Lab Environment Documentation Orchestrator (Simple Version)
#######################################################################

# Use safer error handling
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

# Available generators with dependencies and timing estimates
# Format: "name:script:description:dependencies:estimate"
GENERATORS=(
    "functions:doc-func:Function metadata table generator::5"
    "variables:doc-var:Variable usage documentation generator::3"
    "stats:doc-stats:System metrics generator::4"
    "hub:doc-hub:Documentation index generator:functions,variables:7"
)

show_help() {
    echo "Lab Environment Documentation Orchestrator"
    echo ""
    echo "Usage: $0 [OPTIONS] [TARGETS...]"
    echo ""
    echo "OPTIONS:"
    echo "  --help      Show this help"
    echo "  --list      List available generators"
    echo "  --dry-run   Show what would be executed"
    echo "  --verbose   Show detailed output"
    echo "  --parallel  Run independent generators in parallel"
    echo "  --continue  Continue on errors (don't stop on first failure)"
    echo ""
    echo "TARGETS:"
    echo "  functions   Generate function metadata table"
    echo "  variables   Generate variable usage documentation"
    echo "  hub         Generate documentation index (depends on functions,variables)"
    echo "  stats       Generate system metrics"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all generators"
    echo "  $0 functions stats   # Run specific generators"
    echo "  $0 --dry-run         # Preview execution"
    echo "  $0 --parallel        # Run in parallel where possible"
}

list_generators() {
    echo "Available Documentation Generators:"
    echo "=================================================="
    printf "%-12s %-12s %-8s %s\n" "NAME" "SCRIPT" "TIME(s)" "DESCRIPTION"
    echo "=================================================="
    for gen in "${GENERATORS[@]}"; do
        name=$(echo "$gen" | cut -d: -f1)
        script=$(echo "$gen" | cut -d: -f2)
        desc=$(echo "$gen" | cut -d: -f3)
        deps=$(echo "$gen" | cut -d: -f4)
        estimate=$(echo "$gen" | cut -d: -f5)
        printf "%-12s %-12s %-8s %s\n" "$name" "$script" "$estimate" "$desc"
        if [[ -n "$deps" ]]; then
            printf "%-12s %-12s %-8s %s\n" "" "" "" "  Dependencies: $deps"
        fi
    done
}

# Dependency resolution function
resolve_dependencies() {
    local targets=("$@")
    local resolved=()
    
    # Simple dependency resolution for known dependencies
    for target in "${targets[@]}"; do
        case "$target" in
            "hub")
                # hub depends on functions and variables
                if [[ ! " ${resolved[*]} " =~ " functions " ]]; then
                    resolved+=("functions")
                fi
                if [[ ! " ${resolved[*]} " =~ " variables " ]]; then
                    resolved+=("variables")
                fi
                resolved+=("hub")
                ;;
            *)
                if [[ ! " ${resolved[*]} " =~ " $target " ]]; then
                    resolved+=("$target")
                fi
                ;;
        esac
    done
    
    printf "%s\n" "${resolved[@]}"
}

# Parallel execution function
run_parallel() {
    local targets=("$@")
    local pids=()
    local results=()
    
    echo "Starting parallel execution of ${#targets[@]} generators..."
    
    for target in "${targets[@]}"; do
        if [[ "$verbose" == true ]]; then
            echo "Starting $target in background..."
        fi
        (
            if run_generator "$target" "$dry_run"; then
                echo "SUCCESS:$target"
            else
                echo "FAILURE:$target"
            fi
        ) &
        pids+=($!)
    done
    
    # Wait for all background jobs
    local failure_count=0
    for i in "${!pids[@]}"; do
        local pid=${pids[$i]}
        local target=${targets[$i]}
        
        if wait "$pid"; then
            if [[ "$verbose" == true ]]; then
                echo "$target completed successfully"
            fi
        else
            echo "Error: $target failed"
            ((failure_count++))
        fi
    done
    
    return $failure_count
}

run_generator() {
    local name="$1"
    local dry_run="$2"
    
    # Find the generator
    local script=""
    for gen in "${GENERATORS[@]}"; do
        if [[ "$(echo "$gen" | cut -d: -f1)" == "$name" ]]; then
            script=$(echo "$gen" | cut -d: -f2)
            break
        fi
    done
    
    if [[ -z "$script" ]]; then
        echo "Error: Unknown generator '$name'"
        return 1
    fi
    
    local script_path="$SCRIPT_DIR/$script"
    
    if [[ "$dry_run" == "true" ]]; then
        echo "DRY RUN: Would execute $script_path"
        return 0
    fi
    
    if [[ ! -f "$script_path" ]]; then
        echo "Error: Script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        echo "Error: Script not executable: $script_path"
        return 1
    fi
    
    echo "Executing: $name ($script)"
    "$script_path"
}

main() {
    local targets=()
    local dry_run=false
    local verbose=false
    local parallel=false
    local continue_on_error=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --list|-l)
                list_generators
                exit 0
                ;;
            --dry-run|-n)
                dry_run=true
                ;;
            --verbose|-v)
                verbose=true
                ;;
            --parallel|-p)
                parallel=true
                ;;
            --continue|-c)
                continue_on_error=true
                ;;
            --*)
                echo "Error: Unknown option $1"
                exit 1
                ;;
            *)
                targets+=("$1")
                ;;
        esac
        shift
    done
    
    # Default to all generators if none specified
    if [[ ${#targets[@]} -eq 0 ]]; then
        for gen in "${GENERATORS[@]}"; do
            targets+=($(echo "$gen" | cut -d: -f1))
        done
    fi
    
    echo "Lab Environment Documentation Orchestrator"
    echo "=========================================="
    
    # Resolve dependencies
    local execution_order
    readarray -t execution_order < <(resolve_dependencies "${targets[@]}")
    
    if [[ "$verbose" == true ]]; then
        echo "Execution order: ${execution_order[*]}"
    fi
    
    if [[ "$dry_run" == true ]]; then
        echo "DRY RUN - No generators will be executed"
        for target in "${execution_order[@]}"; do
            echo "[DRY-RUN] Would run: $target"
        done
        exit 0
    fi
    
    # Execute generators
    local success=true
    if [[ "$parallel" == true ]]; then
        # For parallel execution, separate dependencies from independents
        local deps=()
        local independents=()
        
        for target in "${execution_order[@]}"; do
            if [[ "$target" == "hub" ]]; then
                deps+=("$target")
            else
                independents+=("$target")
            fi
        done
        
        # Run independent generators in parallel
        if [[ ${#independents[@]} -gt 0 ]]; then
            if ! run_parallel "${independents[@]}"; then
                success=false
            fi
        fi
        
        # Run dependent generators sequentially
        if [[ ${#deps[@]} -gt 0 && ("$success" == true || "$continue_on_error" == true) ]]; then
            for target in "${deps[@]}"; do
                if ! run_generator "$target" "$dry_run"; then
                    success=false
                    if [[ "$continue_on_error" == false ]]; then
                        break
                    fi
                fi
            done
        fi
    else
        # Sequential execution
        for target in "${execution_order[@]}"; do
            if ! run_generator "$target" "$dry_run"; then
                success=false
                if [[ "$continue_on_error" == false ]]; then
                    break
                fi
            fi
        done
    fi
    
    if [[ "$success" == true ]]; then
        echo "✅ All documentation generators completed successfully!"
    else
        echo "❌ Some generators failed"
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
