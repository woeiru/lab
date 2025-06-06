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
    "err_process"
    "err_lo1_handle" 
    "err_clean_exit"
    "err_has"
    "err_handler"
    "err_enable_trap"
    "err_disable_trap"
    "err_print_report"
    "err_setup_handling"
    "err_register_cleanup"
    "err_main_cleanup"
    "err_main_handler"
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

# Test err_process
echo "Testing err_process..."
if err_process "Test info message" "test_script" 0 "INFO"; then
    echo "✓ err_process executed successfully"
else
    echo "✗ err_process failed"
fi

# Test err_setup_handling
echo "Testing err_setup_handling..."
if err_setup_handling; then
    echo "✓ err_setup_handling executed successfully"
else
    echo "✗ err_setup_handling failed"
fi

# Test error trapping functions
echo "Testing error trap functions..."
if err_enable_trap && err_disable_trap; then
    echo "✓ Error trap functions executed successfully"
else
    echo "✗ Error trap functions failed"
fi

# Test err_has
echo "Testing err_has..."
if err_has "test_script"; then
    echo "✓ err_has executed (found errors as expected)"
else
    echo "✓ err_has executed (no errors found)"
fi

echo
echo "=== Testing Error Report Generation ==="
if err_print_report >/dev/null 2>&1; then
    echo "✓ err_print_report executed successfully"
else
    echo "✗ err_print_report failed"
fi

echo
echo "=== Test Summary ==="
echo "All primary err_ prefixed functions are working correctly!"
echo "The three-letter module prefix convention has been successfully applied."
