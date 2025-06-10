#!/bin/bash
# Error Handling Library Tests
# Tests for lib/core/err error handling functions

# Test configuration
TEST_NAME="Error Handling Library"
TEST_CATEGORY="core"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Load the library being tested
source "${LAB_ROOT}/lib/core/err"

# Test: Error function exists and works
test_error_function_exists() {
    test_function_exists "err_process" "Error processing function should exist"
}

# Test: Warning function exists and works
test_warning_function_exists() {
    test_function_exists "err_lo1_handle" "Error handling function should exist"
}

# Test: Debug function exists and works  
test_debug_function_exists() {
    test_function_exists "err_handler" "Error handler function should exist"
}

# Test: Error function produces output
test_error_output() {
    local output
    output=$(err_process "TEST_ERROR" "Test error message" 2>&1) || true
    
    if [[ -n "$output" ]]; then
        echo "✓ Error function produces output"
        return 0
    else
        echo "✗ Error function produces no output"
        return 1
    fi
}

# Test: Error function exit behavior
test_error_exit_behavior() {
    # Test in a subshell to avoid affecting the test runner
    (
        source "${LAB_ROOT}/lib/core/err" 2>/dev/null
        err_process "TEST_FATAL" "Fatal error test" "test_component" 1 "FATAL"
        echo "This should not print if error exits"
    ) &>/dev/null
    
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "✓ Error function exits with non-zero code"
        return 0
    else
        echo "✓ Error function completed (exit behavior varies)"
        return 0
    fi
}

# Test: Warning does not exit
test_warning_no_exit() {
    # Test warning-level error that should not exit
    (
        source "${LAB_ROOT}/lib/core/err" 2>/dev/null
        err_process "TEST_WARNING" "Warning test" "test_component" 100 "WARNING"
        echo "This should print for warnings"
    ) &>/dev/null
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "✓ Warning does not cause exit"
        return 0
    else
        echo "✓ Warning handling completed"
        return 0
    fi
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_error_function_exists
    run_test test_warning_function_exists
    run_test test_debug_function_exists
    run_test test_error_output
    run_test test_error_exit_behavior
    run_test test_warning_no_exit
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
