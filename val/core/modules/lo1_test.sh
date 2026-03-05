#!/bin/bash
# Logging Library Tests (lo1)

TEST_NAME="Logging Library"
TEST_CATEGORY="core"

source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

TEST_LO1_DIR=""

setup_lo1_test_env() {
    TEST_LO1_DIR="$(create_test_env "lo1_module")"
    export LOG_DIR="$TEST_LO1_DIR"
    export TMP_DIR="$TEST_LO1_DIR"
    export LOG_FILE="$TEST_LO1_DIR/lo1.log"
    export LOG_STATE_FILE="$TEST_LO1_DIR/log.state"
    export MASTER_TERMINAL_VERBOSITY=on
    export LO1_LOG_TERMINAL_VERBOSITY=on
    export LAB_LOG_LEVEL=normal

    source "${LAB_ROOT}/lib/core/log"
    source "${LAB_ROOT}/lib/core/lo1"
}

cleanup_lo1_test_env() {
    [[ -n "$TEST_LO1_DIR" ]] && cleanup_test_env "$TEST_LO1_DIR"
}

test_logging_functions_exist() {
    local functions=("lo1_log" "lo1_setlog" "lo1_init_logger" "lo1_cleanup_logger" "lo1_log_message")
    local func

    for func in "${functions[@]}"; do
        command -v "$func" >/dev/null 2>&1 || return 1
    done

    return 0
}

test_lo1_log_writes_message() {
    : > "$LOG_FILE"
    lo1_setlog on >/dev/null 2>&1
    lo1_log "lo1 primary write test" >/dev/null 2>&1
    grep -q "lo1 primary write test" "$LOG_FILE"
}

test_lo1_setlog_off_suppresses_writes() {
    : > "$LOG_FILE"
    lo1_setlog off >/dev/null 2>&1
    lo1_log "this should not be written" >/dev/null 2>&1
    ! grep -q "this should not be written" "$LOG_FILE"
}

test_lo1_legacy_lvl_signature_still_works() {
    : > "$LOG_FILE"
    lo1_setlog on >/dev/null 2>&1
    lo1_log "lvl" "legacy signature message" >/dev/null 2>&1
    grep -q "legacy signature message" "$LOG_FILE"
}

test_lo1_log_message_file_has_no_ansi_codes() {
    : > "$LOG_FILE"
    lo1_setlog on >/dev/null 2>&1

    local raw_message
    raw_message=$'ansi test \033[31mred\033[0m payload'
    lo1_log_message "$raw_message" 2 "lo1_test" >/dev/null 2>&1

    grep -q "ansi test" "$LOG_FILE" || return 1
    ! grep -q $'\033\[' "$LOG_FILE"
}

test_compat_wrappers_exist() {
    command -v log >/dev/null 2>&1 || return 1
    command -v setlog >/dev/null 2>&1 || return 1
    command -v init_logger >/dev/null 2>&1 || return 1
    command -v cleanup_logger >/dev/null 2>&1 || return 1
}

main() {
    test_header "$TEST_NAME"

    setup_lo1_test_env

    run_test test_logging_functions_exist
    run_test test_lo1_log_writes_message
    run_test test_lo1_setlog_off_suppresses_writes
    run_test test_lo1_legacy_lvl_signature_still_works
    run_test test_lo1_log_message_file_has_no_ansi_codes
    run_test test_compat_wrappers_exist

    cleanup_lo1_test_env
    test_footer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
