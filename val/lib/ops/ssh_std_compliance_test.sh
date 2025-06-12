#!/bin/bash
# SSH Module .std Standards Compliance Test
# Tests SSH module functions for compliance with lib/ops/.std standards

# Test directory setup
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LIB_DIR="${TEST_DIR}/../../../lib"
SSH_MODULE="${LIB_DIR}/ops/ssh"

# Source test framework and SSH module
source "${TEST_DIR}/../../helpers/test_framework.sh"
source "${SSH_MODULE}"

# Test counter
test_count=0
passed_tests=0

# Test helper function
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((test_count++))
    echo "Running test ${test_count}: ${test_name}"
    
    if $test_function; then
        echo "✅ PASS: ${test_name}"
        ((passed_tests++))
    else
        echo "❌ FAIL: ${test_name}"
    fi
    echo ""
}

# Test 1: SSH module sources aux library
test_aux_library_sourced() {
    # Check if aux functions are available
    if declare -f aux_val >/dev/null 2>&1 && \
       declare -f aux_chk >/dev/null 2>&1 && \
       declare -f aux_info >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Test 2: Functions have proper help system
test_help_system() {
    local output
    
    # Test ssh_fun help
    output=$(ssh_fun --help 2>&1)
    if [[ $? -eq 0 ]] && [[ -n "$output" ]]; then
        return 0
    else
        return 1
    fi
}

# Test 3: Parameter validation on ssh_var
test_parameter_validation() {
    local output
    
    # Test with empty parameters (should fail)
    output=$(ssh_var "" "" 2>&1)
    if [[ $? -ne 0 ]] && [[ "$output" =~ "cannot be empty" ]]; then
        return 0
    else
        return 1
    fi
}

# Test 4: Dependency validation on ssh_lst  
test_dependency_validation() {
    local output
    
    # Create a temporary function that overrides aux_chk to simulate missing dependency
    aux_chk_original=$(declare -f aux_chk)
    
    aux_chk() {
        if [[ "$1" == "command" && "$2" == "ssh-add" ]]; then
            return 1  # Simulate missing dependency
        else
            # Call original aux_chk for other checks
            eval "$aux_chk_original"
            aux_chk "$@"
        fi
    }
    
    output=$(ssh_lst -x 2>&1)
    local exit_code=$?
    
    # Restore original aux_chk
    eval "$aux_chk_original"
    
    # Should return 127 (command not found) and contain error message
    if [[ $exit_code -eq 127 ]] && [[ "$output" =~ "not found" ]]; then
        return 0
    else
        return 1
    fi
}

# Test 5: Error handling and logging
test_error_logging() {
    local output
    
    # Test with invalid file path
    output=$(ssh_var "/nonexistent/file" "/nonexistent/dir" 2>&1)
    if [[ $? -ne 0 ]] && [[ "$output" =~ "not found" ]]; then
        return 0
    else
        return 1
    fi
}

# Test 6: Function naming convention
test_naming_convention() {
    # Get all function names from SSH module
    local functions
    functions=$(grep -o '^[a-zA-Z_][a-zA-Z0-9_]*()' "$SSH_MODULE" | sed 's/()//')
    
    # Check that all functions start with ssh_
    local non_compliant=0
    for func in $functions; do
        if [[ ! "$func" =~ ^ssh_ ]]; then
            non_compliant=1
            echo "Non-compliant function name: $func"
        fi
    done
    
    return $non_compliant
}

# Test 7: Return code standards
test_return_codes() {
    local output
    
    # Test invalid parameters (should return 1)
    ssh_var 2>/dev/null
    if [[ $? -eq 1 ]]; then
        return 0
    else
        return 1
    fi
}

# Test 8: Technical documentation format
test_technical_docs() {
    # Check if functions have proper technical documentation blocks
    if grep -q "# Technical Description:" "$SSH_MODULE" && \
       grep -q "# Dependencies:" "$SSH_MODULE" && \
       grep -q "# Arguments:" "$SSH_MODULE"; then
        return 0
    else
        return 1
    fi
}

# Main test execution
echo "🧪 SSH Module .std Standards Compliance Test Suite"
echo "=================================================="
echo ""

run_test "Aux library is properly sourced" test_aux_library_sourced
run_test "Help system is functional" test_help_system
run_test "Parameter validation is implemented" test_parameter_validation
run_test "Dependency validation is working" test_dependency_validation
run_test "Error logging is implemented" test_error_logging
run_test "Function naming convention is followed" test_naming_convention
run_test "Return code standards are followed" test_return_codes
run_test "Technical documentation format is correct" test_technical_docs

# Test summary
echo "=================================================="
echo "Test Results: ${passed_tests}/${test_count} tests passed"

if [[ $passed_tests -eq $test_count ]]; then
    echo "🎉 ALL TESTS PASSED - SSH module is .std compliant!"
    exit 0
else
    echo "❌ Some tests failed - SSH module needs additional work"
    exit 1
fi