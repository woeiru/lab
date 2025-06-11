#!/bin/bash
#######################################################################
# Lab Environment Documentation Orchestrator (Simplified Portable)
#######################################################################

set -e

# Configuration - PORTABLE with subfolder support
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/settings"

# Load basic configuration
PROJECT_ROOT=""
DOC_OUTPUT_DIR=""
VERBOSE=false

# Simple config loader
if [[ -f "$CONFIG_FILE" ]]; then
    while IFS='=' read -r key value; do
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        # Clean value: remove quotes and comments, trim whitespace
        value=$(echo "$value" | sed 's/^["'\'']*//;s/["'\'']*$//' | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # Remove any remaining quotes that might have been escaped
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        case $key in
            PROJECT_ROOT) PROJECT_ROOT="$value" ;;
            DOC_OUTPUT_DIR) DOC_OUTPUT_DIR="$value" ;;
            VERBOSE) VERBOSE="$value" ;;
        esac
    done < <(grep -E '^[^#]*=' "$CONFIG_FILE" 2>/dev/null || true)
fi

# Set defaults
[[ -z "$PROJECT_ROOT" ]] && PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
[[ -z "$DOC_OUTPUT_DIR" ]] && DOC_OUTPUT_DIR="$PROJECT_ROOT/doc"

# Available generators
GENERATORS=(
    "functions:func:Function metadata table generator"
    "variables:var:Variable usage documentation generator" 
    "stats:stats:System metrics generator"
    "hub:hub:Documentation index generator"
    "ai_docs:ai_doc_generator:AI-powered README generation with 13-phase intelligence"
)

# Dependencies (hub depends on functions and variables)
declare -A DEPENDENCIES
DEPENDENCIES[hub]="functions variables"
DEPENDENCIES[ai_docs]="functions variables hub stats"

# Logging
log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Help
show_help() {
    cat << EOF
Lab Environment Documentation Orchestrator (Simplified Portable)

USAGE:
    $(basename "$0") [OPTIONS] [TARGETS...]

OPTIONS:
    -h, --help      Show this help message
    --list          List all available documentation generators
    --dry-run       Show what would be executed without running
    --verbose       Show detailed progress information

TARGETS:
    functions       Generate function metadata table (func)
    variables       Generate variable usage documentation (var)
    stats           Generate system metrics (stats) 
    hub             Generate documentation index (hub)
    ai_docs         Generate AI-powered README with comprehensive intelligence analysis

CONFIGURATION:
    Project Root: $PROJECT_ROOT
    Doc Output: $DOC_OUTPUT_DIR
    Config File: $CONFIG_FILE

EXAMPLES:
    $(basename "$0")                    # Run all generators (including AI documentation)
    $(basename "$0") functions stats   # Run specific generators
    $(basename "$0") ai_docs           # Run AI documentation generator only
    $(basename "$0") --dry-run          # Preview execution

EOF
}

# List generators
list_generators() {
    echo "Available Documentation Generators:"
    echo "=================================="
    printf "%-12s %-12s %s\n" "NAME" "SCRIPT" "DESCRIPTION"
    echo "=================================="
    for gen in "${GENERATORS[@]}"; do
        name=$(echo "$gen" | cut -d: -f1)
        script=$(echo "$gen" | cut -d: -f2)
        desc=$(echo "$gen" | cut -d: -f3)
        printf "%-12s %-12s %s\n" "$name" "$script" "$desc"
        if [[ -n "${DEPENDENCIES[$name]:-}" ]]; then
            printf "%-12s %-12s Dependencies: %s\n" "" "" "${DEPENDENCIES[$name]}"
        fi
    done
    echo ""
    echo "Configuration:"
    echo "=============="
    echo "Script Directory: $SCRIPT_DIR"
    echo "Project Root: $PROJECT_ROOT"
    echo "Doc Output: $DOC_OUTPUT_DIR"
}

# Get execution order with dependency resolution
get_execution_order() {
    local targets=("$@")
    local result=()
    local processed=()
    
    # If no targets, use all generators
    if [[ ${#targets[@]} -eq 0 ]]; then
        for gen in "${GENERATORS[@]}"; do
            targets+=($(echo "$gen" | cut -d: -f1))
        done
    fi
    
    # Process dependencies recursively
    process_generator() {
        local gen="$1"
        
        # Skip if already processed
        for p in "${processed[@]}"; do
            [[ "$p" == "$gen" ]] && return 0
        done
        
        # Process dependencies first
        if [[ -n "${DEPENDENCIES[$gen]:-}" ]]; then
            for dep in ${DEPENDENCIES[$gen]}; do
                process_generator "$dep"
            done
        fi
        
        # Add to result
        result+=("$gen")
        processed+=("$gen")
    }
    
    # Process all targets
    for target in "${targets[@]}"; do
        process_generator "$target"
    done
    
    # Output result
    printf '%s\n' "${result[@]}"
}

# Run a single generator
run_generator() {
    local name="$1"
    local script_path=""
    
    # Find script for the generator - PORTABLE subfolder search
    for gen in "${GENERATORS[@]}"; do
        if [[ "$(echo "$gen" | cut -d: -f1)" == "$name" ]]; then
            local script_name="$(echo "$gen" | cut -d: -f2)"
            
            # Search in multiple locations for portability
            local search_paths=(
                "$SCRIPT_DIR/$script_name"                    # Current directory (backward compatibility)
                "$SCRIPT_DIR/generators/$script_name"         # Generators subfolder
                "$SCRIPT_DIR/intelligence/$script_name"       # Intelligence subfolder
                "$SCRIPT_DIR/ai/$script_name"                 # AI subfolder
            )
            
            for path in "${search_paths[@]}"; do
                if [[ -x "$path" ]]; then
                    script_path="$path"
                    break
                fi
            done
            break
        fi
    done
    
    if [[ ! -x "$script_path" ]]; then
        log_error "Generator script not found or not executable: $script_path"
        return 1
    fi
    
    log_info "Running $name..."
    
    # Set environment for the generator
    export LAB_DIR="$PROJECT_ROOT"
    export DOC_DIR="$DOC_OUTPUT_DIR"
    
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Executing: $script_path with LAB_DIR=$LAB_DIR"
    fi
    
    if "$script_path"; then
        log_success "Completed $name"
        return 0
    else
        local exit_code=$?
        log_error "Failed to run $name (exit code: $exit_code)"
        return $exit_code
    fi
}

# Main function
main() {
    local targets=()
    local dry_run=false
    local list_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --list)
                list_mode=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                targets+=("$1")
                shift
                ;;
        esac
    done
    
    if [[ "$list_mode" == "true" ]]; then
        list_generators
        exit 0
    fi
    
    # Get execution order
    local ordered_generators
    readarray -t ordered_generators < <(get_execution_order "${targets[@]}")
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Dry run - execution order:"
        for i in "${!ordered_generators[@]}"; do
            echo "$((i+1)). ${ordered_generators[$i]}"
        done
        echo "Total: ${#ordered_generators[@]} generators"
        echo "Project Root: $PROJECT_ROOT"
        echo "Doc Output: $DOC_OUTPUT_DIR"
        exit 0
    fi
    
    # Execute generators
    log_info "Starting documentation generation..."
    log_info "Project Root: $PROJECT_ROOT"
    log_info "Output Directory: $DOC_OUTPUT_DIR"
    
    local success_count=0
    local total_count=${#ordered_generators[@]}
    
    for name in "${ordered_generators[@]}"; do
        if run_generator "$name"; then
            success_count=$((success_count + 1))
        else
            log_error "Stopping due to failure in $name"
            break
        fi
    done
    
    log_info "Completed: $success_count/$total_count generators"
    
    if [[ $success_count -eq $total_count ]]; then
        log_success "All generators completed successfully!"
        exit 0
    else
        log_error "Some generators failed"
        exit 1
    fi
}

# Check if we're being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
