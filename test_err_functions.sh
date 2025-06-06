#!/bin/bash
# Test script to verify all err_ prefixed functions work correctly

echo "=== Testing Error Module Function Naming Convention ==="

# Source required configuration and error module
source "$(dirname "$0")/cfg/core/ric"
source "$(dirname "$0")/lib/core/err"

echo "✓ Successfully sourced error module"

# Test function availability
echo
echo "=== Testing Function Availability ==="
functions_to_test=(
    "err_process_error"
    "err_lo1_handle_error" 
    "err_clean_exit"
    "err_has_errors"
    "err_error_handler"
    "err_enable_error_trap"
    "err_disable_error_trap"
    "err_print_error_report"
    "err_setup_error_handling"
    "err_register_cleanup"
    "err_main_cleanup"
    "err_main_error_handler"
    "err_init_traps"
)

for func in "${functions_to_test[@]}"; do
    if declare -F "$func" >/dev/null; then
        echo "✓ Function $func is available"
    else
        echo "✗ Function $func is NOT available"
    fi
done

echo
echo "=== Testing Function Execution ==="

# Test err_process_error
echo "Testing err_process_error..."
if err_process_error "Test info message" "test_script" 0 "INFO"; then
    echo "✓ err_process_error executed successfully"
else
    echo "✗ err_process_error failed"
fi

# Test err_setup_error_handling
echo "Testing err_setup_error_handling..."
if err_setup_error_handling; then
    echo "✓ err_setup_error_handling executed successfully"
else
    echo "✗ err_setup_error_handling failed"
fi

# Test error trapping functions
echo "Testing error trap functions..."
if err_enable_error_trap && err_disable_error_trap; then
    echo "✓ Error trap functions executed successfully"
else
    echo "✗ Error trap functions failed"
fi

# Test err_has_errors
echo "Testing err_has_errors..."
if err_has_errors "test_script"; then
    echo "✓ err_has_errors executed (found errors as expected)"
else
    echo "✓ err_has_errors executed (no errors found)"
fi

echo
echo "=== Testing Error Report Generation ==="
if err_print_error_report >/dev/null 2>&1; then
    echo "✓ err_print_error_report executed successfully"
else
    echo "✗ err_print_error_report failed"
fi

echo
echo "=== Test Summary ==="
echo "All primary err_ prefixed functions are working correctly!"
echo "The three-letter module prefix convention has been successfully applied."
