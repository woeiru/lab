#!/bin/bash
#######################################################################
# Lab Environment Documentation Orchestrator (Production Version)
#######################################################################
# 
# Centralized orchestrator for all documentation generation scripts
# with dependency management, parallel execution, and extensible architecture
#
# Usage: ./run_all_doc_production.sh [OPTIONS] [TARGETS...]
#######################################################################

# Configuration
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

# Logging functions
log_info() {
    echo "ℹ️  $*"
}

log_success() {
    echo "✅ $*"
}

log_error() {
    echo "❌ $*" >&2
}

show_help() {
    cat << 'EOF'
Lab Environment Documentation Orchestrator

DESCRIPTION:
    Centralized orchestrator for documentation generation with parallel
    execution, dependency management, and extensible plugin architecture.

USAGE:
    ./run_all_doc_production.sh [OPTIONS] [TARGETS...]

OPTIONS:
    --help          Show this help message
    --list          List all available documentation generators
    --dry-run       Show what would be executed without running
    --parallel      Run independent generators in parallel
    --verbose       Show detailed progress information
    --continue      Continue on errors (don't stop on first failure)

TARGETS:
    functions       Generate function metadata table (doc-func)
    variables       Generate variable usage documentation (doc-var)
    hub             Generate documentation index (doc-hub) [depends: functions,variables]
    stats           Generate system metrics (doc-stats)

EXAMPLES:
    ./run_all_doc_production.sh                    # Run all generators
    ./run_all_doc_production.sh --parallel         # Run in parallel where possible
    ./run_all_doc_production.sh functions stats   # Run only specific generators
    ./run_all_doc_production.sh --dry-run          # Preview execution

EOF
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
    
    # Check for custom generators
    echo ""
    echo "Custom Generators:"
    echo "=================="
    local custom_found=false
    for script in "$LAB_DIR"/utl/doc-*; do
        if [[ -x "$script" ]]; then
            local basename_script=$(basename "$script")
            if [[ "$basename_script" != "doc-func" ]] && \
               [[ "$basename_script" != "doc-hub" ]] && \
               [[ "$basename_script" != "doc-stats" ]] && \
               [[ "$basename_script" != "doc-var" ]]; then
                printf "%-12s %-12s %-8s %s\n" "$(echo "$basename_script" | sed 's/^doc-//')" "$basename_script" "?" "Custom generator"
                custom_found=true
            fi
        fi
    done
    if [[ "$custom_found" == false ]]; then
        echo "(none found)"
    fi
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

# Execute generator
run_generator() {
    local name="$1"
    local dry_run="$2"
    local verbose="${3:-false}"
    
    # Find the generator script
    local script_name=""
    for gen in "${GENERATORS[@]}"; do
        if [[ "$(echo "$gen" | cut -d: -f1)" == "$name" ]]; then
            script_name=$(echo "$gen" | cut -d: -f2)
            break
        fi
    done
    
    if [[ -z "$script_name" ]]; then
        # Try custom generator
        script_name="doc-$name"
    fi
    
    local script_path="$LAB_DIR/utl/$script_name"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Generator script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log_error "Generator script not executable: $script_path"
        return 1
    fi
    
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] Would execute: $script_path"
        return 0
    fi
    
    if [[ "$verbose" == true ]]; then
        log_info "Running $name generator ($script_name)..."
    fi
    
    local start_time=$(date +%s)
    
    if "$script_path"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "$name completed successfully (${duration}s)"
        return 0
    else
        local exit_code=$?
        log_error "$name failed with exit code $exit_code"
        return $exit_code
    fi
}

# Parallel execution function
run_parallel() {
    local targets=("$@")
    local verbose="${verbose:-false}"
    local dry_run="${dry_run:-false}"
    local pids=()
    
    log_info "Starting parallel execution of ${#targets[@]} generators..."
    
    for target in "${targets[@]}"; do
        if [[ "$verbose" == true ]]; then
            echo "Starting $target in background..."
        fi
        (
            if run_generator "$target" "$dry_run" "$verbose"; then
                exit 0
            else
                exit 1
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
            log_error "$target failed"
            ((failure_count++))
        fi
    done
    
    return $failure_count
}

# Main execution function
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
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
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
    
    # Validate targets
    local valid_targets=()
    for target in "${targets[@]}"; do
        local found=false
        for gen in "${GENERATORS[@]}"; do
            if [[ "$(echo "$gen" | cut -d: -f1)" == "$target" ]]; then
                found=true
                break
            fi
        done
        
        if [[ "$found" == true ]]; then
            valid_targets+=("$target")
        else
            # Check for custom generator
            if [[ -x "$LAB_DIR/utl/doc-$target" ]]; then
                valid_targets+=("$target")
                if [[ "$verbose" == true ]]; then
                    echo "Found custom generator: doc-$target"
                fi
            else
                log_error "Unknown generator: $target"
                exit 1
            fi
        fi
    done
    
    # Resolve dependencies
    local execution_order
    readarray -t execution_order < <(resolve_dependencies "${valid_targets[@]}")
    
    if [[ "$verbose" == true ]]; then
        echo "Execution order: ${execution_order[*]}"
    fi
    
    if [[ "$dry_run" == true ]]; then
        log_info "DRY RUN - No generators will be executed"
        for target in "${execution_order[@]}"; do
            echo "[DRY-RUN] Would run: $target"
        done
        exit 0
    fi
    
    # Execute generators
    local start_time=$(date +%s)
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
                if ! run_generator "$target" "$dry_run" "$verbose"; then
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
            if ! run_generator "$target" "$dry_run" "$verbose"; then
                success=false
                if [[ "$continue_on_error" == false ]]; then
                    break
                fi
            fi
        done
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    if [[ "$success" == true ]]; then
        log_success "All documentation generators completed successfully! (${total_duration}s total)"
        exit 0
    else
        log_error "Some generators failed (${total_duration}s total)"
        exit 1
    fi
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
