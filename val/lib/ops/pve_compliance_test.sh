#!/bin/bash
# PVE Module .std Standards Compliance Test
# Tests PVE module functions for compliance with lib/ops/.std standards

# Test directory setup
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LIB_DIR="${TEST_DIR}/../../../lib"
PVE_MODULE="${LIB_DIR}/ops/pve"

# Source test framework and PVE module
source "${TEST_DIR}/../../helpers/test_framework.sh"
source "${PVE_MODULE}"

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

# Test 1: PVE module sources aux library
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
    
    # Test pve_fun help
    output=$(pve_fun --help 2>/dev/null)
    if [[ $? -eq 0 ]] && [[ -n "$output" ]]; then
        return 0
    else
        return 1
    fi
}

# Test 3: Parameter validation for pve_var
test_pve_var_validation() {
    # Test empty config file
    if pve_var "" "/tmp" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test empty analysis dir
    if pve_var "/etc/passwd" "" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test nonexistent config file
    if pve_var "/nonexistent/config" "/tmp" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    return 0  # All validation tests passed
}

# Test 4: Parameter validation for pve_cdo
test_pve_cdo_validation() {
    # Test missing parameters
    if pve_cdo 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test empty storage ID
    if pve_cdo "" "template" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test empty template name
    if pve_cdo "storage" "" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    return 0  # All validation tests passed
}

# Test 5: Parameter validation for pve_cbm
test_pve_cbm_validation() {
    # Test missing parameters
    if pve_cbm 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test non-numeric container ID
    if pve_cbm "abc" "/host/path" "/container/path" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test empty container ID
    if pve_cbm "" "/host/path" "/container/path" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    return 0  # All validation tests passed
}

# Test 6: Parameter validation for pve_vck
test_pve_vck_validation() {
    # Test empty VM ID
    if pve_vck "" "node1 node2" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test non-numeric VM ID
    if pve_vck "abc" "node1 node2" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    # Test empty cluster nodes
    if pve_vck "101" "" 2>/dev/null; then
        return 1  # Should fail
    fi
    
    return 0  # All validation tests passed
}

# Test 7: Dependency checking
test_dependency_checking() {
    # Save original PATH
    local original_path="$PATH"
    
    # Set PATH to nonexistent directory to simulate missing commands
    export PATH="/nonexistent"
    
    # Test pve_clu dependency check (should fail with missing pveam)
    if pve_clu -x 2>/dev/null; then
        export PATH="$original_path"
        return 1  # Should have failed due to missing pveam
    fi
    
    # Restore PATH
    export PATH="$original_path"
    return 0
}

# Test 8: Return codes compliance
test_return_codes() {
    # Test parameter validation returns 1
    pve_cdo "storage" 2>/dev/null
    local exit_code=$?
    if [[ $exit_code -ne 1 ]]; then
        return 1
    fi
    
    # Test help returns 0
    pve_fun --help >/dev/null 2>&1
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        return 1
    fi
    
    return 0
}

# Test 9: Aux integration patterns
test_aux_integration() {
    # Check if PVE module contains aux function calls
    if ! grep -q "aux_val" "${PVE_MODULE}" || \
       ! grep -q "aux_chk" "${PVE_MODULE}" || \
       ! grep -q "aux_info\|aux_err" "${PVE_MODULE}"; then
        return 1
    fi
    
    return 0
}

# Test 10: Module variables defined
test_module_variables() {
    if [[ -n "$DIR_FUN" ]] && [[ -n "$FILE_FUN" ]] && [[ -n "$BASE_FUN" ]]; then
        return 0
    else
        return 1
    fi
}

# Main test execution
main() {
    echo "=== PVE Module .std Standards Compliance Test ==="
    echo "Testing module: ${PVE_MODULE}"
    echo ""
    
    # Run all tests
    run_test "Aux library sourced" test_aux_library_sourced
    run_test "Help system functional" test_help_system
    run_test "pve_var parameter validation" test_pve_var_validation
    run_test "pve_cdo parameter validation" test_pve_cdo_validation
    run_test "pve_cbm parameter validation" test_pve_cbm_validation
    run_test "pve_vck parameter validation" test_pve_vck_validation
    run_test "Dependency checking" test_dependency_checking
    run_test "Return codes compliance" test_return_codes
    run_test "Aux integration patterns" test_aux_integration
    run_test "Module variables defined" test_module_variables
    
    # Test summary
    echo "=== Test Summary ==="
    echo "Total tests: ${test_count}"
    echo "Passed: ${passed_tests}"
    echo "Failed: $((test_count - passed_tests))"
    echo ""
    
    if [[ $passed_tests -eq $test_count ]]; then
        echo "✅ All tests passed - PVE module is .std compliant!"
        return 0
    else
        echo "❌ Some tests failed - compliance issues found"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi