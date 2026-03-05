#!/bin/bash
# Error Handling Library Tests

TEST_NAME="Error Handling Library"
TEST_CATEGORY="core"

source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

TEST_ERR_DIR=""

setup_err_test_env() {
    TEST_ERR_DIR="$(create_test_env "err_module")"
    export LOG_DIR="$TEST_ERR_DIR"
    export TMP_DIR="$TEST_ERR_DIR"
    export ERROR_LOG="$TEST_ERR_DIR/err.log"
    export MASTER_TERMINAL_VERBOSITY=on
    export ERR_TERMINAL_VERBOSITY=on
    export LAB_LOG_LEVEL=normal
    source "${LAB_ROOT}/lib/core/log"
    source "${LAB_ROOT}/lib/core/err"
}

cleanup_err_test_env() {
    [[ -n "$TEST_ERR_DIR" ]] && cleanup_test_env "$TEST_ERR_DIR"
}

test_error_function_exists() {
    test_function_exists "err_process" "err_process function should exist"
}

test_command_not_found_handler_exists() {
    test_function_exists "command_not_found_handle" "command_not_found_handle should exist"
}

test_err_process_writes_to_file() {
    : > "$ERROR_LOG"
    err_process "unit test file write" "err_test" 42 "ERROR" >/dev/null 2>&1 || true
    grep -q "unit test file write" "$ERROR_LOG"
}

test_err_process_uses_stderr_for_warning() {
    local stdout_file="$TEST_ERR_DIR/stdout.txt"
    local stderr_file="$TEST_ERR_DIR/stderr.txt"

    err_process "warning should be stderr" "err_test" 100 "WARNING" >"$stdout_file" 2>"$stderr_file" || true

    [[ ! -s "$stdout_file" ]] && [[ -s "$stderr_file" ]] && grep -q "warning should be stderr" "$stderr_file"
}

test_err_process_returns_exit_code() {
    err_process "explicit return code" "err_test" 7 "ERROR" >/dev/null 2>&1
    [[ "$?" -eq 7 ]]
}

test_command_not_found_uses_canonical_parameter_order() {
    local stderr_file="$TEST_ERR_DIR/cnf_stderr.txt"
    local last_index
    local last_id

    command_not_found_handle "definitely_not_a_real_command" >/dev/null 2>"$stderr_file" || true

    last_index=$(( ${#ERROR_ORDER[@]} - 1 ))
    ((last_index >= 0)) || return 1
    last_id="${ERROR_ORDER[$last_index]:-}"
    [[ -n "$last_id" ]] || return 1
    [[ "${ERROR_COMPONENTS[$last_id]:-}" == "command_not_found" ]] || return 1
    [[ "${ERROR_MESSAGES[$last_id]:-}" == "Command not found: definitely_not_a_real_command" ]] || return 1
    grep -q "command not found" "$stderr_file"
}

test_err_print_report_header_styles() {
    : > "$ERROR_LOG"

    err_process "compact report warning" "err_test" 100 "WARNING" >/dev/null 2>&1 || true
    err_process "verbose report error" "err_test" 7 "ERROR" >/dev/null 2>&1 || true

    export LAB_LOG_FORMAT=compact
    local compact_output
    compact_output=$(err_print_report 2>&1 || true)
    [[ "$compact_output" == *"RC error report"* ]] || return 1

    export LAB_LOG_FORMAT=verbose
    local verbose_output
    verbose_output=$(err_print_report 2>&1 || true)
    [[ "$verbose_output" == *"RC error report"* ]] || return 1
    [[ "$verbose_output" == *"meta"* ]] || return 1
    [[ "$verbose_output" == *"error log file"* ]]
}

main() {
    test_header "$TEST_NAME"

    setup_err_test_env

    run_test test_error_function_exists
    run_test test_command_not_found_handler_exists
    run_test test_err_process_writes_to_file
    run_test test_err_process_uses_stderr_for_warning
    run_test test_err_process_returns_exit_code
    run_test test_command_not_found_uses_canonical_parameter_order
    run_test test_err_print_report_header_styles

    cleanup_err_test_env
    test_footer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
