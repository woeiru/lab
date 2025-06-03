#!/bin/bash
#######################################################################
# Lab Environment Documentation Orchestrator (Enhanced Version)
#######################################################################
# 
# Centralized orchestrator for all documentation generation scripts with
# parallel execution, dependency management, and extensible architecture
#
# Usage: ./run_all_doc_enhanced.sh [OPTIONS] [TARGETS...]
#######################################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$LAB_DIR/utl/.doc_config"

# Default settings
VERBOSE=false
QUIET=false
DRY_RUN=false
PARALLEL=false
CONTINUE_ON_ERROR=false

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Available generators with dependencies (name:script:description:dependencies:estimate)
GENERATORS=(
    "functions:doc-func:Function metadata table generator::5"
    "variables:doc-var:Variable usage documentation generator::3"
    "stats:doc-stats:System metrics generator::4"
    "hub:doc-hub:Documentation index generator:functions,variables:7"
)

# Logging functions
log_info() {
    [[ "$QUIET" == true ]] && return
    echo -e "${BLUE}ℹ️${NC} $*"
}

log_success() {
    [[ "$QUIET" == true ]] && return
    echo -e "${GREEN}✅${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $*" >&2
}

log_error() {
    echo -e "${RED}❌${NC} $*" >&2
}

log_verbose() {
    [[ "$VERBOSE" == true ]] || return
    echo -e "${CYAN}🔍${NC} $*"
}

# Helper functions
get_field() {
    local generator="$1"
    local field="$2"
    echo "$generator" | cut -d: -f"$field"
}

show_help() {
    cat << 'EOF'
Lab Environment Documentation Orchestrator (Enhanced)

DESCRIPTION:
    Centralized orchestrator for documentation generation with parallel
    execution, dependency management, and extensible plugin architecture.

USAGE:
    ./run_all_doc_enhanced.sh [OPTIONS] [TARGETS...]

OPTIONS:
    --help          Show this help message
    --list          List all available documentation generators
    --dry-run       Show what would be executed without running
    --parallel      Run independent generators in parallel
    --verbose       Show detailed progress information
    --quiet         Suppress non-error output
    --continue      Continue on errors (don't stop on first failure)

TARGETS:
    functions       Generate function metadata table (doc-func)
    variables       Generate variable usage documentation (doc-var)
    hub             Generate documentation index (doc-hub)
    stats           Generate system metrics (doc-stats)

DEPENDENCIES:
    hub            Depends on: functions, variables

EXAMPLES:
    ./run_all_doc_enhanced.sh                    # Run all generators
    ./run_all_doc_enhanced.sh --parallel         # Run in parallel where possible
    ./run_all_doc_enhanced.sh functions stats   # Run only specific generators
    ./run_all_doc_enhanced.sh --dry-run --verbose # Preview with detailed output

EOF
}

list_generators() {
    echo "Available Documentation Generators:"
    echo "=================================================="
    printf "%-12s %-12s %-8s %s\n" "NAME" "SCRIPT" "TIME(s)" "DESCRIPTION"
    echo "=================================================="
    
    for gen in "${GENERATORS[@]}"; do
        name=$(get_field "$gen" 1)
        script=$(get_field "$gen" 2)
        desc=$(get_field "$gen" 3)
        deps=$(get_field "$gen" 4)
        estimate=$(get_field "$gen" 5)
        
        printf "%-12s %-12s %-8s %s\n" "$name" "$script" "$estimate" "$desc"
        if [[ -n "$deps" ]]; then
            printf "%-12s %-12s %-8s %s\n" "" "" "" "  Dependencies: $deps"
        fi
    done
    echo ""
    
    # Check for custom generators
    log_verbose "Scanning for custom generators..."
    local custom_found=false
    for script in "$LAB_DIR"/utl/doc-*; do
        if [[ -x "$script" ]] && [[ "$(basename "$script")" != "doc-func" ]] && \
           [[ "$(basename "$script")" != "doc-hub" ]] && \
           [[ "$(basename "$script")" != "doc-stats" ]] && \
           [[ "$(basename "$script")" != "doc-var" ]]; then
            if [[ "$custom_found" == false ]]; then
                echo "Custom Generators Found:"
                echo "========================"
                custom_found=true
            fi
            printf "%-12s %-12s %-8s %s\n" "$(basename "$script" | sed 's/^doc-//')" "$(basename "$script")" "?" "Custom generator"
        fi
    done
}

# Dependency resolution using topological sort
resolve_dependencies() {
    local targets=("$@")
    local resolved=()
    local visited=()
    
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
    
    # Find the generator script
    local script_name=""
    for gen in "${GENERATORS[@]}"; do
        if [[ "$(get_field "$gen" 1)" == "$name" ]]; then
            script_name=$(get_field "$gen" 2)
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
    
    log_info "Running $name generator ($script_name)..."
    log_verbose "Executing: $script_path"
    
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

# Execute generators in parallel
run_parallel() {
    local targets=("$@")
    local pids=()
    local results=()
    
    log_info "Starting parallel execution of ${#targets[@]} generators..."
    
    for target in "${targets[@]}"; do
        log_verbose "Starting $target in background..."
        (
            if run_generator "$target" "$DRY_RUN"; then
                echo "SUCCESS:$target"
            else
                echo "FAILURE:$target"
            fi
        ) &
        pids+=($!)
    done
    
    # Wait for all background jobs
    for i in "${!pids[@]}"; do
        local pid=${pids[$i]}
        local target=${targets[$i]}
        
        if wait "$pid"; then
            log_verbose "$target process completed successfully"
            results+=("SUCCESS:$target")
        else
            log_verbose "$target process failed"
            results+=("FAILURE:$target")
        fi
    done
    
    # Report results
    local success_count=0
    local failure_count=0
    
    for result in "${results[@]}"; do
        if [[ "$result" == SUCCESS:* ]]; then
            ((success_count++))
        else
            ((failure_count++))
        fi
    done
    
    log_info "Parallel execution completed: $success_count successes, $failure_count failures"
    return $failure_count
}

# Execute generators sequentially
run_sequential() {
    local targets=("$@")
    local success_count=0
    local failure_count=0
    
    log_info "Starting sequential execution of ${#targets[@]} generators..."
    
    for target in "${targets[@]}"; do
        if run_generator "$target" "$DRY_RUN"; then
            ((success_count++))
        else
            ((failure_count++))
            if [[ "$CONTINUE_ON_ERROR" == false ]]; then
                log_error "Stopping execution due to failure in $target"
                break
            fi
        fi
    done
    
    log_info "Sequential execution completed: $success_count successes, $failure_count failures"
    return $failure_count
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_verbose "Loading configuration from $CONFIG_FILE"
        # Source the config file safely
        source "$CONFIG_FILE" 2>/dev/null || log_warning "Could not load config file"
    fi
}

# Parse command line arguments
parse_arguments() {
    local targets=()
    
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
            --verbose|-v)
                VERBOSE=true
                ;;
            --quiet|-q)
                QUIET=true
                ;;
            --dry-run|-n)
                DRY_RUN=true
                ;;
            --parallel|-p)
                PARALLEL=true
                ;;
            --continue|-c)
                CONTINUE_ON_ERROR=true
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
    
    printf "%s\n" "${targets[@]}"
}

# Main execution function
main() {
    local start_time=$(date +%s)
    
    log_info "Lab Environment Documentation Orchestrator (Enhanced)"
    log_verbose "Script directory: $SCRIPT_DIR"
    log_verbose "Lab directory: $LAB_DIR"
    
    # Load configuration
    load_config
    
    # Parse arguments
    local targets
    readarray -t targets < <(parse_arguments "$@")
    
    # If no targets specified, use all available generators
    if [[ ${#targets[@]} -eq 0 ]]; then
        targets=()
        for gen in "${GENERATORS[@]}"; do
            targets+=($(get_field "$gen" 1))
        done
    fi
    
    log_info "Target generators: ${targets[*]}"
    
    # Validate targets
    local valid_targets=()
    for target in "${targets[@]}"; do
        local found=false
        for gen in "${GENERATORS[@]}"; do
            if [[ "$(get_field "$gen" 1)" == "$target" ]]; then
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
                log_verbose "Found custom generator: doc-$target"
            else
                log_error "Unknown generator: $target"
                exit 1
            fi
        fi
    done
    
    # Resolve dependencies
    local execution_order
    readarray -t execution_order < <(resolve_dependencies "${valid_targets[@]}")
    
    log_info "Execution order: ${execution_order[*]}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN - No generators will be executed"
        for target in "${execution_order[@]}"; do
            log_info "[DRY-RUN] Would run: $target"
        done
        exit 0
    fi
    
    # Execute generators
    local exit_code=0
    if [[ "$PARALLEL" == true ]]; then
        # For parallel execution, we need to be smarter about dependencies
        # For now, run dependencies first, then parallel
        local deps=()
        local independents=()
        
        for target in "${execution_order[@]}"; do
            if [[ "$target" == "hub" ]]; then
                deps+=("$target")
            else
                independents+=("$target")
            fi
        done
        
        if [[ ${#independents[@]} -gt 0 ]]; then
            if ! run_parallel "${independents[@]}"; then
                exit_code=1
            fi
        fi
        
        if [[ ${#deps[@]} -gt 0 && ($exit_code -eq 0 || $CONTINUE_ON_ERROR == true) ]]; then
            if ! run_sequential "${deps[@]}"; then
                exit_code=1
            fi
        fi
    else
        if ! run_sequential "${execution_order[@]}"; then
            exit_code=1
        fi
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Documentation generation completed successfully! (${total_duration}s total)"
    else
        log_error "Documentation generation completed with errors (${total_duration}s total)"
    fi
    
    exit $exit_code
}

# Execute main if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
