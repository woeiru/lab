#!/bin/bash
#######################################################################
# Gen .spec Compliance Test
#######################################################################
# File: val/lib/gen/std_compliance_test.sh
# Description: Validates `lib/gen/*` against `lib/.spec` + `lib/gen/.spec`
#              with optional report mode for staged enforcement.
#######################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

readonly GEN_DIR="${LAB_ROOT}/lib/gen"
MODE="strict"

TOTAL_FUNCTIONS=0
FAILURES=0
WARNINGS=0

record_failure() {
    local message="$1"
    test_failure "$message"
    FAILURES=$((FAILURES + 1))
}

record_pass() {
    local message="$1"
    test_success "$message"
}

record_warning() {
    local message="$1"
    test_warning "$message"
    WARNINGS=$((WARNINGS + 1))
}

is_exempt_function() {
    local func="$1"
    [[ "$func" == "main" ]]
}

is_public_function() {
    local module="$1"
    local func="$2"
    [[ "$func" == "${module}_"* ]]
}

list_gen_files() {
    local file
    for file in "${GEN_DIR}"/*; do
        [[ -f "$file" ]] || continue
        local base
        base="$(basename "$file")"
        [[ "$base" == .* || "$base" == *.md || "$base" == *.spec ]] && continue
        printf '%s\n' "$file"
    done
}

check_glb001_naming() {
    local file="$1"
    local module
    module="$(basename "$file")"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local func
        func="${line%%(*}"
        TOTAL_FUNCTIONS=$((TOTAL_FUNCTIONS + 1))

        if is_exempt_function "$func"; then
            record_warning "GLB-001 exempt compatibility function: ${module}:${func}"
            continue
        fi

        if [[ "$func" == _* ]]; then
            record_pass "GLB-001 helper naming: ${module}:${func}"
        elif [[ "$func" == "${module}_"* ]]; then
            record_pass "GLB-001 public naming: ${module}:${func}"
        else
            record_warning "GLB-001 non-prefixed internal candidate: ${module}:${func}"
        fi
    done < <(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$file" || true)
}

check_glb003_glb004_help_validation() {
    local file="$1"
    local module
    module="$(basename "$file")"

    while IFS=: read -r line_no func_decl; do
        [[ -z "$line_no" ]] && continue
        local func body
        func="${func_decl%%(*}"
        body=$(sed -n "${line_no},$((line_no + 35))p" "$file")

        if echo "$body" | grep -q -- '--help' || echo "$body" | grep -q -- '"-h"'; then
            if echo "$body" | grep -q 'return 0'; then
                record_pass "GLB-003 help return: ${module}:${func}"
            else
                record_failure "GLB-003 missing return 0: ${module}:${func}"
            fi
        fi

        if echo "$body" | grep -q 'aux_use' || echo "$body" | grep -q 'return 1'; then
            record_pass "GLB-004 invalid usage path present: ${module}:${func}"
        fi
    done < <(grep -nE '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$file" || true)
}

check_glb005_docs() {
    local file="$1"
    local module
    module="$(basename "$file")"

    while IFS=: read -r line_no func_decl; do
        [[ -z "$line_no" ]] && continue
        local func
        func="${func_decl%%(*}"

        if ! is_public_function "$module" "$func"; then
            continue
        fi

        local body
        body=$(sed -n "${line_no},$((line_no + 30))p" "$file")
        if ! echo "$body" | grep -q 'aux_use\|aux_tec\|--help\|"-h"'; then
            continue
        fi

        local d1 d2 d3
        d1=$(sed -n "$((line_no - 3))p" "$file")
        d2=$(sed -n "$((line_no - 2))p" "$file")
        d3=$(sed -n "$((line_no - 1))p" "$file")
        if [[ "$d1" =~ ^# ]] && [[ "$d2" =~ ^# ]] && [[ "$d3" =~ ^# ]]; then
            record_pass "GLB-005 usage block: ${module}:${func}"
        else
            record_failure "GLB-005 missing usage block: ${module}:${func}"
        fi

        local tech
        tech=$(sed -n "$((line_no + 1)),$((line_no + 40))p" "$file")
        if echo "$tech" | grep -q 'Technical Description:' && \
           echo "$tech" | grep -q 'Dependencies:' && \
           echo "$tech" | grep -q 'Arguments:'; then
            record_pass "GLB-005 technical block: ${module}:${func}"
        else
            record_failure "GLB-005 missing technical block: ${module}:${func}"
        fi
    done < <(grep -nE '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$file" || true)
}

check_gen_aux_usage() {
    local file="$1"
    local module
    module="$(basename "$file")"

    local uses_aux
    uses_aux=$(grep -c 'aux_' "$file" 2>/dev/null || true)
    if [[ "$module" == "aux" ]]; then
        record_pass "GEN module aux exempt from self-usage requirement"
        return
    fi

    if [[ ${uses_aux:-0} -gt 0 ]]; then
        record_pass "GEN-001 aux integration present: $module"
    else
        record_warning "GEN-001 aux integration not detected: $module"
    fi
}

run_gen_checks() {
    test_header "GEN STD COMPLIANCE"
    test_dir_exists "$GEN_DIR" "gen directory exists"

    local file
    while IFS= read -r file; do
        check_glb001_naming "$file"
        check_glb003_glb004_help_validation "$file"
        check_glb005_docs "$file"
        check_gen_aux_usage "$file"
    done < <(list_gen_files)

    echo
    echo "Mode: $MODE"
    echo "Functions scanned: $TOTAL_FUNCTIONS"
    echo "Rule failures: $FAILURES"
    echo "Rule warnings: $WARNINGS"

    if [[ "$MODE" == "report" ]]; then
        test_warning "Report mode enabled: returning success despite failures"
        return 0
    fi

    [[ $FAILURES -eq 0 ]]
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --report)
                MODE="report"
                shift
                ;;
            --help|-h)
                cat <<'EOF'
Usage: ./val/lib/gen/std_compliance_test.sh [--report]

Options:
  --report   Report-only mode (always exits 0)
  -h, --help Show this help
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    run_gen_checks
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
