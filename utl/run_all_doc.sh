#!/bin/bash
#######################################################################
# Lab Environment Documentation Orchestrator
#######################################################################
# File: run_all_doc.sh
# Description: Centralized orchestrator for all documentation generation 
#              scripts with extensible plugin architecture
#
# Usage: ./run_all_doc.sh [OPTIONS] [TARGETS...]
#   OPTIONS:
#     --all           Run all available documentation generators (default)
#     --dry-run       Show what would be executed without running
#     --parallel      Run independent generators in parallel
#     --verbose       Show detailed progress and timing information
#     --quiet         Suppress non-error output
#     --continue      Continue on errors (don't stop on first failure)
#     --list          List all available documentation generators
#     --help          Show this help message
#   
#   TARGETS:
#     functions       Generate function metadata table (doc-func)
#     variables       Generate variable usage documentation (doc-var)
#     hub             Generate documentation index (doc-hub)
#     stats           Generate system metrics (doc-stats)
#
# Examples:
#   ./run_all_doc.sh                    # Run all generators
#   ./run_all_doc.sh --parallel         # Run in parallel where possible
#   ./run_all_doc.sh functions stats    # Run only specific generators
#   ./run_all_doc.sh --dry-run --verbose # Preview with detailed output
#######################################################################

# Use safer error handling instead of strict mode
set -e

# Initialize lab environment
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set LAB_DIR if not already set
if [[ -z "${LAB_DIR:-}" ]]; then
    readonly LAB_DIR="$(dirname "$SCRIPT_DIR")"
fi

# Configuration
readonly DOC_ORCHESTRATOR_VERSION="1.0.0"
readonly CONFIG_FILE="$LAB_DIR/utl/.doc_config"
readonly LOG_DIR="$LAB_DIR/.tmp/doc"
readonly LOCK_FILE="$LOG_DIR/orchestrator.lock"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# Configuration variables
VERBOSE=false
QUIET=false
DRY_RUN=false
PARALLEL=false
CONTINUE_ON_ERROR=false
START_TIME=""

# Available generators (name:script:description:dependencies:estimate)
readonly AVAILABLE_GENERATORS=(
    "functions:doc-func:Function metadata table generator::5"
    "variables:doc-var:Variable usage documentation generator::3"
    "stats:doc-stats:System metrics generator::4"
    "hub:doc-hub:Documentation index generator:functions,variables:7"
)

# Enhanced logging functions with timing
log_info() {
    [[ "$QUIET" == true ]] && return
    local timestamp=$(date '+%H:%M:%S')
    local elapsed=""
    if [[ -n "${START_TIME:-}" ]]; then
        elapsed=" (+$(($(date +%s) - START_TIME))s)"
    fi
    echo -e "${BLUE}[${timestamp}${elapsed}]${NC} $*"
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

log_step() {
    [[ "$QUIET" == true ]] && return
    echo -e "${MAGENTA}📋${NC} $*"
}

# Parse generator info
get_generator_field() {
    local generator_line="$1"
    local field_index="$2"
    echo "$generator_line" | cut -d: -f"$field_index"
}

# Get generator by name
find_generator() {
    local name="$1"
    for gen in "${AVAILABLE_GENERATORS[@]}"; do
        if [[ "$(get_generator_field "$gen" 1)" == "$name" ]]; then
            echo "$gen"
            return 0
        fi
    done
    return 1
}

# Get all dependencies for a generator
get_dependencies() {
    local generator="$1"
    local deps=$(get_generator_field "$generator" 4)
    echo "$deps" | tr ',' ' '
}

# Auto-discover additional generators
discover_custom_generators() {
    log_verbose "Discovering custom documentation generators..."
    
    for script in "$SCRIPT_DIR"/doc-*; do
        if [[ -f "$script" && -x "$script" ]]; then
            local script_name=$(basename "$script")
            local generator_key="${script_name#doc-}"
            
            # Skip if already in available generators
            local found=false
            for gen in "${AVAILABLE_GENERATORS[@]}"; do
                if [[ "$(get_generator_field "$gen" 1)" == "$generator_key" ]]; then
                    found=true
                    break
                fi
            done
            
            if [[ "$found" == false ]]; then
                echo "${generator_key}:${script_name}:Custom generator::5"
            fi
        fi
    done
}

# Calculate execution order with dependency resolution
calculate_execution_order() {
    local targets=("$@")
    local resolved=()
    local execution_order=()
    
    # Get all available generators including custom ones
    local all_generators=("${AVAILABLE_GENERATORS[@]}")
    while IFS= read -r custom_gen; do
        [[ -n "$custom_gen" ]] && all_generators+=("$custom_gen")
    done < <(discover_custom_generators)
    
    # Simple dependency resolution (topological sort)
    local max_iterations=${#targets[@]}
    local iterations=0
    
    while [[ ${#resolved[@]} -lt ${#targets[@]} ]] && [[ $iterations -lt $max_iterations ]]; do
        local progress=false
        ((iterations++))
        
        for target in "${targets[@]}"; do
            # Skip if already resolved
            local already_resolved=false
            for r in "${resolved[@]}"; do
                if [[ "$r" == "$target" ]]; then
                    already_resolved=true
                    break
                fi
            done
            [[ "$already_resolved" == true ]] && continue
            
            # Find generator info
            local gen_info=""
            for gen in "${all_generators[@]}"; do
                if [[ "$(get_generator_field "$gen" 1)" == "$target" ]]; then
                    gen_info="$gen"
                    break
                fi
            done
            
            if [[ -z "$gen_info" ]]; then
                log_error "Unknown generator: $target"
                return 1
            fi
            
            # Check if all dependencies are resolved
            local deps_resolved=true
            local deps=$(get_dependencies "$gen_info")
            for dep in $deps; do
                [[ -n "$dep" ]] || continue
                local dep_resolved=false
                for r in "${resolved[@]}"; do
                    if [[ "$r" == "$dep" ]]; then
                        dep_resolved=true
                        break
                    fi
                done
                if [[ "$dep_resolved" == false ]]; then
                    deps_resolved=false
                    break
                fi
            done
            
            # If all dependencies resolved, add to execution order
            if [[ "$deps_resolved" == true ]]; then
                execution_order+=("$target")
                resolved+=("$target")
                progress=true
            fi
        done
        
        # Check for circular dependencies
        if [[ "$progress" == false ]] && [[ ${#resolved[@]} -lt ${#targets[@]} ]]; then
            log_error "Circular dependency detected or missing dependencies"
            log_error "Resolved: ${resolved[*]}"
            log_error "Remaining: $(printf '%s ' "${targets[@]}" | tr ' ' '\n' | grep -v "$(printf '%s\n' "${resolved[@]}" | paste -sd '|')" | tr '\n' ' ')"
            return 1
        fi
    done
    
    # Output execution order
    echo "${execution_order[@]}"
}

# Execute a single documentation generator
execute_generator() {
    local generator_name="$1"
    
    # Get all available generators including custom ones
    local all_generators=("${AVAILABLE_GENERATORS[@]}")
    while IFS= read -r custom_gen; do
        [[ -n "$custom_gen" ]] && all_generators+=("$custom_gen")
    done < <(discover_custom_generators)
    
    # Find generator info
    local gen_info=""
    for gen in "${all_generators[@]}"; do
        if [[ "$(get_generator_field "$gen" 1)" == "$generator_name" ]]; then
            gen_info="$gen"
            break
        fi
    done
    
    if [[ -z "$gen_info" ]]; then
        log_error "Generator not found: $generator_name"
        return 1
    fi
    
    local script=$(get_generator_field "$gen_info" 2)
    local description=$(get_generator_field "$gen_info" 3)
    local script_path="$SCRIPT_DIR/$script"
    
    local start_time=$(date +%s)
    
    log_step "Executing: $generator_name ($description)"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would execute: $script_path"
        return 0
    fi
    
    # Check if script exists and is executable
    if [[ ! -f "$script_path" ]]; then
        log_error "Generator script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log_error "Generator script not executable: $script_path"
        return 1
    fi
    
    # Execute the generator
    local output_file="$LOG_DIR/${generator_name}_output.log"
    local error_file="$LOG_DIR/${generator_name}_error.log"
    
    mkdir -p "$LOG_DIR"
    
    local exit_code=0
    if [[ "$VERBOSE" == true ]]; then
        log_verbose "Running: $script_path"
        if ! "$script_path" 2>&1 | tee "$output_file"; then
            exit_code=$?
        fi
    else
        if ! "$script_path" >"$output_file" 2>"$error_file"; then
            exit_code=$?
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "$generator_name completed successfully (${duration}s)"
        return 0
    else
        log_error "$generator_name failed with exit code $exit_code (${duration}s)"
        
        # Show error details if not in verbose mode
        if [[ "$VERBOSE" == false && -f "$error_file" && -s "$error_file" ]]; then
            echo -e "${RED}Error output:${NC}" >&2
            cat "$error_file" >&2
        fi
        
        return $exit_code
    fi
}

# Execute generators sequentially
execute_sequential() {
    local execution_order=("$@")
    
    for generator in "${execution_order[@]}"; do
        if ! execute_generator "$generator"; then
            if [[ "$CONTINUE_ON_ERROR" == false ]]; then
                log_error "Stopping execution due to failure in: $generator"
                return 1
            fi
        fi
    done
}

# List all available generators
list_generators() {
    # Get all available generators including custom ones
    local all_generators=("${AVAILABLE_GENERATORS[@]}")
    while IFS= read -r custom_gen; do
        [[ -n "$custom_gen" ]] && all_generators+=("$custom_gen")
    done < <(discover_custom_generators)
    
    echo "Available Documentation Generators:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-15s %-15s %-8s %s\n" "Name" "Script" "Est.Time" "Description"
    echo "────────────────────────────────────────────────────────────────"
    
    for gen in "${all_generators[@]}"; do
        local name=$(get_generator_field "$gen" 1)
        local script=$(get_generator_field "$gen" 2)
        local desc=$(get_generator_field "$gen" 3)
        local deps=$(get_generator_field "$gen" 4)
        local estimate=$(get_generator_field "$gen" 5)
        
        printf "%-15s %-15s %-8s %s\n" "$name" "$script" "${estimate}s" "$desc"
        
        if [[ -n "$deps" ]]; then
            printf "%-15s %-15s %-8s %s\n" "" "" "" "Dependencies: ${deps//,/ }"
        fi
    done
    echo
}

# Load configuration if available
load_configuration() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_verbose "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE" 2>/dev/null || true
    fi
}

# Show help message
show_help() {
    cat << 'EOF'
Lab Environment Documentation Orchestrator

DESCRIPTION:
    Centralized orchestrator for all documentation generation scripts with 
    extensible plugin architecture and intelligent dependency management.

USAGE:
    ./run_all_doc.sh [OPTIONS] [TARGETS...]

OPTIONS:
    --all           Run all available documentation generators (default)
    --dry-run       Show what would be executed without running
    --parallel      Run independent generators in parallel
    --verbose       Show detailed progress and timing information
    --quiet         Suppress non-error output
    --continue      Continue on errors (don't stop on first failure)
    --list          List all available documentation generators
    --help          Show this help message

TARGETS:
    functions       Generate function metadata table (doc-func)
    variables       Generate variable usage documentation (doc-var)
    hub             Generate documentation index (doc-hub)
    stats           Generate system metrics (doc-stats)

EXAMPLES:
    ./run_all_doc.sh                    # Run all generators
    ./run_all_doc.sh --parallel         # Run in parallel where possible
    ./run_all_doc.sh functions stats    # Run only specific generators
    ./run_all_doc.sh --dry-run --verbose # Preview with detailed output

CONFIGURATION:
    Create utl/.doc_config to customize behavior:
        PARALLEL=true
        VERBOSE=true
        CONTINUE_ON_ERROR=false

ARCHITECTURE:
    - Auto-discovers generators in utl/doc-* pattern
    - Resolves dependencies using simple topological sort
    - Supports parallel execution where dependencies allow
    - Provides comprehensive logging and reporting
    - Extensible plugin architecture for custom generators

EOF
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
            --all|-a)
                # Default behavior, add all generators
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
    
    echo "${targets[@]}"
}

# Create lock file to prevent concurrent execution
acquire_lock() {
    mkdir -p "$LOG_DIR"
    
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid
        lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Another documentation generation is already running (PID: $lock_pid)"
            exit 1
        else
            log_warning "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo $$ > "$LOCK_FILE"
    
    # Clean up lock file on exit
    trap 'rm -f "$LOCK_FILE"' EXIT
}

# Generate execution report
generate_report() {
    local execution_order=("$@")
    local total_time=$(($(date +%s) - START_TIME))
    
    echo
    log_info "Documentation Generation Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    printf "%-15s %-10s %s\n" "Generator" "Status" "Description"
    echo "────────────────────────────────────────────────────────────────"
    
    local success_count=0
    local total_count=${#execution_order[@]}
    
    # Get all available generators including custom ones
    local all_generators=("${AVAILABLE_GENERATORS[@]}")
    while IFS= read -r custom_gen; do
        [[ -n "$custom_gen" ]] && all_generators+=("$custom_gen")
    done < <(discover_custom_generators)
    
    for generator in "${execution_order[@]}"; do
        local gen_info=""
        for gen in "${all_generators[@]}"; do
            if [[ "$(get_generator_field "$gen" 1)" == "$generator" ]]; then
                gen_info="$gen"
                break
            fi
        done
        
        local desc="Unknown generator"
        if [[ -n "$gen_info" ]]; then
            desc=$(get_generator_field "$gen_info" 3)
        fi
        
        printf "%-15s %-10s %s\n" "$generator" "success" "$desc"
        ((success_count++))
    done
    
    echo "────────────────────────────────────────────────────────────────"
    printf "%-15s %-10s %-8s\n" "TOTAL" "${success_count}/${total_count}" "${total_time}s"
    echo
    
    log_success "Documentation generation completed successfully!"
}

# Main execution function
main() {
    START_TIME=$(date +%s)
    
    # Parse arguments and get targets
    local targets
    readarray -t targets < <(parse_arguments "$@")
    
    # If no targets specified, use all available generators
    if [[ ${#targets[@]} -eq 0 ]]; then
        targets=()
        for gen in "${AVAILABLE_GENERATORS[@]}"; do
            targets+=($(get_generator_field "$gen" 1))
        done
        
        # Add any custom generators
        while IFS= read -r custom_gen; do
            if [[ -n "$custom_gen" ]]; then
                targets+=($(get_generator_field "$custom_gen" 1))
            fi
        done < <(discover_custom_generators)
    fi
    
    # Don't acquire lock for dry runs
    if [[ "$DRY_RUN" == false ]]; then
        acquire_lock
    fi
    
    # Initialize
    log_info "Starting Lab Environment Documentation Orchestrator v$DOC_ORCHESTRATOR_VERSION"
    
    # Load configuration
    load_configuration
    
    # Calculate execution order
    local execution_order
    if ! readarray -t execution_order < <(calculate_execution_order "${targets[@]}"); then
        log_error "Failed to resolve generator dependencies"
        exit 1
    fi
    
    # Show execution plan
    if [[ "$VERBOSE" == true ]] || [[ "$DRY_RUN" == true ]]; then
        echo
        log_info "Execution Plan:"
        for generator in "${execution_order[@]}"; do
            echo "  - $generator"
        done
        echo
    fi
    
    # Execute generators
    local execution_success=true
    log_info "Executing generators sequentially"
    execute_sequential "${execution_order[@]}" || execution_success=false
    
    # Generate report
    if [[ "$DRY_RUN" == false ]]; then
        generate_report "${execution_order[@]}"
    fi
    
    if [[ "$execution_success" == true ]]; then
        log_success "Documentation generation completed successfully"
        exit 0
    else
        log_error "Documentation generation completed with errors"
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
