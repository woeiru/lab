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
    test_function_exists "error" "Error function should exist"
}

# Test: Warning function exists and works
test_warning_function_exists() {
    test_function_exists "warning" "Warning function should exist"
}

# Test: Debug function exists and works  
test_debug_function_exists() {
    test_function_exists "debug" "Debug function should exist"
}

# Test: Error function produces output
test_error_output() {
    local output
    output=$(error "Test error message" 2>&1) || true
    
    if [[ -n "$output" ]]; then
        echo "✓ Error function produces output"
        return 0
    else
        echo "✗ Error function should produce output"
        return 1
    fi
}

# Test: Error function with exit code
test_error_exit_behavior() {
    # Test that error function can handle exit codes
    local test_script="/tmp/error_test_$$"
    cat > "$test_script" << 'EOF'
#!/bin/bash
source "${LAB_ROOT}/lib/core/err"
error "Test error" 42
EOF
    chmod +x "$test_script"
    
    local exit_code
    "$test_script" 2>/dev/null
    exit_code=$?
    
    rm -f "$test_script"
    
    if [[ $exit_code -eq 42 ]]; then
        echo "✓ Error function respects exit codes"
        return 0
    else
        echo "✗ Error function should respect exit codes (got $exit_code, expected 42)"
        return 1
    fi
}

# Test: Warning function doesn't exit
test_warning_no_exit() {
    warning "Test warning message" 2>/dev/null
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "✓ Warning function doesn't exit script"
        return 0
    else
        echo "✗ Warning function should not exit script"
        return 1
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
