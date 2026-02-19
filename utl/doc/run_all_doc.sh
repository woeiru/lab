#!/bin/bash
#######################################################################
# Lab Environment Documentation Orchestrator
#######################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/settings"

PROJECT_ROOT=""
DOC_OUTPUT_DIR=""
VERBOSE=false

if [[ -f "$CONFIG_FILE" ]]; then
    while IFS='=' read -r key value; do
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        value=$(echo "$value" | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^['\''"]//;s/['\''"]$//')
        case $key in
            PROJECT_ROOT) PROJECT_ROOT="$value" ;;
            DOC_OUTPUT_DIR) DOC_OUTPUT_DIR="$value" ;;
            VERBOSE) VERBOSE="$value" ;;
        esac
    done < <(grep -E '^[^#]*=' "$CONFIG_FILE" 2>/dev/null || true)
fi

[[ -z "$PROJECT_ROOT" ]] && PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
[[ -z "$DOC_OUTPUT_DIR" ]] && DOC_OUTPUT_DIR="$PROJECT_ROOT/doc"

if [[ "$PROJECT_ROOT" == .* ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/$PROJECT_ROOT" && pwd)"
fi
if [[ "$DOC_OUTPUT_DIR" == .* ]]; then
    DOC_OUTPUT_DIR="$(cd "$SCRIPT_DIR/$DOC_OUTPUT_DIR" && pwd)"
fi

GENERATORS=(
    "functions:func:Function metadata generator"
    "variables:var:Variable usage generator"
    "stats:stats:System metrics generator"
    "hub:hub:Documentation structure generator"
)

declare -A DEPENDENCIES
DEPENDENCIES[hub]="functions variables"

log_info() { echo "[INFO] $*"; }
log_success() { echo "[SUCCESS] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

show_help() {
    cat << HELP
Lab Environment Documentation Orchestrator

USAGE:
    $(basename "$0") [OPTIONS] [TARGETS...]

OPTIONS:
    -h, --help      Show this help message
    --list          List available generators
    --dry-run       Show execution order without running
    --verbose       Enable verbose output

TARGETS:
    functions       Generate function metadata
    variables       Generate variable usage
    stats           Generate system metrics
    hub             Generate documentation structure

EXAMPLES:
    $(basename "$0")
    $(basename "$0") functions stats
    $(basename "$0") --dry-run
HELP
}

list_generators() {
    echo "Available generators:"
    echo "====================="
    printf "%-12s %-12s %s\n" "NAME" "SCRIPT" "DESCRIPTION"
    echo "====================="
    for gen in "${GENERATORS[@]}"; do
        name=$(echo "$gen" | cut -d: -f1)
        script=$(echo "$gen" | cut -d: -f2)
        desc=$(echo "$gen" | cut -d: -f3)
        printf "%-12s %-12s %s\n" "$name" "$script" "$desc"
        if [[ -n "${DEPENDENCIES[$name]:-}" ]]; then
            printf "%-12s %-12s Dependencies: %s\n" "" "" "${DEPENDENCIES[$name]}"
        fi
    done
}

get_execution_order() {
    local targets=("$@")
    local result=()
    local processed=()

    if [[ ${#targets[@]} -eq 0 ]]; then
        for gen in "${GENERATORS[@]}"; do
            targets+=("$(echo "$gen" | cut -d: -f1)")
        done
    fi

    process_generator() {
        local gen="$1"
        for p in "${processed[@]}"; do
            [[ "$p" == "$gen" ]] && return 0
        done
        if [[ -n "${DEPENDENCIES[$gen]:-}" ]]; then
            for dep in ${DEPENDENCIES[$gen]}; do
                process_generator "$dep"
            done
        fi
        result+=("$gen")
        processed+=("$gen")
    }

    for target in "${targets[@]}"; do
        process_generator "$target"
    done

    printf '%s\n' "${result[@]}"
}

run_generator() {
    local name="$1"
    local script_path=""

    for gen in "${GENERATORS[@]}"; do
        if [[ "$(echo "$gen" | cut -d: -f1)" == "$name" ]]; then
            local script_name
            script_name="$(echo "$gen" | cut -d: -f2)"
            local search_paths=(
                "$SCRIPT_DIR/$script_name"
                "$SCRIPT_DIR/generators/$script_name"
                "$SCRIPT_DIR/intelligence/$script_name"
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
        log_error "Generator script not found: $name"
        return 1
    fi

    export LAB_DIR="$PROJECT_ROOT"
    export DOC_DIR="$DOC_OUTPUT_DIR"

    log_info "Running $name..."
    if [[ "$name" == "stats" ]]; then
        "$script_path" --update
    else
        "$script_path"
    fi
    log_success "Completed $name"
}

main() {
    local targets=()
    local dry_run=false
    local list_mode=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; exit 0 ;;
            --list) list_mode=true; shift ;;
            --dry-run) dry_run=true; shift ;;
            --verbose) VERBOSE=true; shift ;;
            -*) log_error "Unknown option: $1"; exit 1 ;;
            *) targets+=("$1"); shift ;;
        esac
    done

    if [[ "$list_mode" == true ]]; then
        list_generators
        exit 0
    fi

    local ordered_generators
    readarray -t ordered_generators < <(get_execution_order "${targets[@]}")

    if [[ "$dry_run" == true ]]; then
        log_info "Dry run execution order:"
        for i in "${!ordered_generators[@]}"; do
            echo "$((i+1)). ${ordered_generators[$i]}"
        done
        exit 0
    fi

    local success_count=0
    local total_count=${#ordered_generators[@]}

    log_info "Starting documentation generation..."
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
        log_success "All generators completed successfully"
    else
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
