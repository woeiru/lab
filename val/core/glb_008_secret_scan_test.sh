#!/bin/bash
#######################################################################
# GLB-008 Secret Hardcoding Scanner
#######################################################################
# File: val/core/glb_008_secret_scan_test.sh
# Description: Detects likely hardcoded secrets in source files under lib/
#              with optional report mode for staged enforcement.
#######################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"

readonly SCAN_ROOT="${LAB_ROOT}/lib"
MODE="strict"
MATCH_COUNT=0

scan_for_assignment_secrets() {
    local pattern='([A-Za-z_]*(SECRET|TOKEN|API_KEY|PASSWORD)[A-Za-z_]*[[:space:]]*=[[:space:]]*)["'"'"'][^$][^"'"'"']{7,}["'"'"']'
    grep -RInE "$pattern" "$SCAN_ROOT" \
        --exclude-dir='.git' \
        --exclude='*.md' \
        --exclude='*.spec' \
        --exclude='*.json' \
        2>/dev/null || true
}

scan_for_private_keys() {
    grep -RInE 'BEGIN (RSA|EC|OPENSSH|DSA) PRIVATE KEY' "$SCAN_ROOT" \
        --exclude-dir='.git' \
        --exclude='*.md' \
        --exclude='*.spec' \
        2>/dev/null || true
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
Usage: ./val/core/glb_008_secret_scan_test.sh [--report]

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

    test_header "GLB-008 SECRET SCAN"
    test_dir_exists "$SCAN_ROOT" "lib directory exists"

    local assignment_hits key_hits
    assignment_hits=$(scan_for_assignment_secrets)
    key_hits=$(scan_for_private_keys)

    if [[ -n "$assignment_hits" ]]; then
        echo "$assignment_hits"
        MATCH_COUNT=$((MATCH_COUNT + $(printf '%s\n' "$assignment_hits" | wc -l)))
    fi

    if [[ -n "$key_hits" ]]; then
        echo "$key_hits"
        MATCH_COUNT=$((MATCH_COUNT + $(printf '%s\n' "$key_hits" | wc -l)))
    fi

    echo "Potential secret matches: $MATCH_COUNT"

    if [[ "$MODE" == "report" ]]; then
        test_warning "Report mode enabled: returning success despite matches"
        return 0
    fi

    [[ $MATCH_COUNT -eq 0 ]]
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
