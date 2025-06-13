#!/bin/bash

# PVE module .std compliance testing framework
# Tests parameter validation, dependency checks, and operational logging

# Load test framework
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../../helpers/test_framework.sh"

# Load pve module
source /home/es/lab/lib/ops/pve

# Test parameter validation compliance
test_pve_parameter_validation() {
    describe "PVE functions parameter validation"
    
    # Test pve_var with missing parameters
    it "should require exactly 2 parameters for pve_var"
    if pve_var "/config" 2>/dev/null; then
        fail "pve_var should require 2 parameters"
    else
        pass "pve_var correctly requires 2 parameters"
    fi
    
    # Test pve_var with empty parameters
    it "should reject empty config file parameter"
    if pve_var "" "/dir" 2>/dev/null; then
        fail "pve_var should reject empty config file"
    else
        pass "pve_var correctly rejects empty config file"
    fi
    
    # Test pve_dsr execution flag validation
    it "should require -x execution flag for pve_dsr"
    if pve_dsr "invalid" 2>/dev/null; then
        fail "pve_dsr should require -x flag"
    else
        pass "pve_dsr correctly requires -x flag"
    fi
    
    # Test pve_rsn execution flag validation
    it "should require -x execution flag for pve_rsn"
    if pve_rsn "notx" 2>/dev/null; then
        fail "pve_rsn should require -x flag"
    else
        pass "pve_rsn correctly requires -x flag"
    fi
    
    # Test pve_clu execution flag validation
    it "should require -x execution flag for pve_clu"
    if pve_clu "" 2>/dev/null; then
        fail "pve_clu should require -x flag"
    else
        pass "pve_clu correctly requires -x flag"
    fi
    
    # Test pve_cdo parameter count validation
    it "should require exactly 2 parameters for pve_cdo"
    if pve_cdo "storage" 2>/dev/null; then
        fail "pve_cdo should require 2 parameters"
    else
        pass "pve_cdo correctly requires 2 parameters"
    fi
    
    # Test pve_cdo empty parameter validation
    it "should reject empty storage ID"
    if pve_cdo "" "template" 2>/dev/null; then
        fail "pve_cdo should reject empty storage ID"
    else
        pass "pve_cdo correctly rejects empty storage ID"
    fi
    
    # Test pve_cbm parameter count validation
    it "should require exactly 3 parameters for pve_cbm"
    if pve_cbm "101" "/host/path" 2>/dev/null; then
        fail "pve_cbm should require 3 parameters"
    else
        pass "pve_cbm correctly requires 3 parameters"
    fi
    
    # Test pve_cbm numeric validation
    it "should validate container ID as numeric"
    if pve_cbm "abc" "/host/path" "/container/path" 2>/dev/null; then
        fail "pve_cbm should validate numeric container ID"
    else
        pass "pve_cbm correctly validates numeric container ID"
    fi
    
    # Test pve_ctc parameter count validation
    it "should require exactly 18 parameters for pve_ctc"
    if pve_ctc "101" "template" "hostname" 2>/dev/null; then
        fail "pve_ctc should require 18 parameters"
    else
        pass "pve_ctc correctly requires 18 parameters"
    fi
    
    # Test pve_vck parameter validation
    it "should validate VM ID as numeric in pve_vck"
    if pve_vck "abc" "node1 node2" 2>/dev/null; then
        fail "pve_vck should validate numeric VM ID"
    else
        pass "pve_vck correctly validates numeric VM ID"
    fi
    
    # Test pve_vck empty parameters
    it "should reject empty VM ID in pve_vck"
    if pve_vck "" "node1 node2" 2>/dev/null; then
        fail "pve_vck should reject empty VM ID"
    else
        pass "pve_vck correctly rejects empty VM ID"
    fi
}

# Test dependency checking compliance
test_pve_dependency_checks() {
    describe "PVE functions dependency validation"
    
    # Mock missing commands for testing
    local original_path="$PATH"
    export PATH="/nonexistent"
    
    # Test pve_dsr dependency checks
    it "should check for sed command in pve_dsr"
    if pve_dsr -x 2>/dev/null; then
        fail "pve_dsr should check for sed dependency"
    else
        pass "pve_dsr correctly checks sed dependency"
    fi
    
    # Test pve_rsn dependency checks
    it "should check for sed and systemctl commands in pve_rsn"
    if pve_rsn -x 2>/dev/null; then
        fail "pve_rsn should check for command dependencies"
    else
        pass "pve_rsn correctly checks command dependencies"
    fi
    
    # Test pve_clu dependency checks
    it "should check for pveam command in pve_clu"
    if pve_clu -x 2>/dev/null; then
        fail "pve_clu should check for pveam dependency"
    else
        pass "pve_clu correctly checks pveam dependency"
    fi
    
    # Test pve_cdo dependency checks
    it "should check for pveam command in pve_cdo"
    if pve_cdo "storage" "template" 2>/dev/null; then
        fail "pve_cdo should check for pveam dependency"
    else
        pass "pve_cdo correctly checks pveam dependency"
    fi
    
    # Test pve_cbm dependency checks
    it "should check for pct command in pve_cbm"
    if pve_cbm "101" "/host/path" "/container/path" 2>/dev/null; then
        fail "pve_cbm should check for pct dependency"
    else
        pass "pve_cbm correctly checks pct dependency"
    fi
    
    # Test pve_ctc dependency checks
    it "should check for pct command in pve_ctc"
    if pve_ctc "101" "template" "hostname" "storage" "8G" "1024" "1024" "8.8.8.8" "domain.com" "password" "2" "no" "192.168.1.100" "24" "192.168.1.1" "/tmp/key" "vmbr0" "eth0" 2>/dev/null; then
        fail "pve_ctc should check for pct dependency"
    else
        pass "pve_ctc correctly checks pct dependency"
    fi
    
    # Restore PATH
    export PATH="$original_path"
}

# Test file/directory validation compliance
test_pve_file_validation() {
    describe "PVE functions file and directory validation"
    
    # Test pve_var file existence check
    it "should validate config file exists in pve_var"
    if pve_var "/nonexistent/config" "/tmp" 2>/dev/null; then
        fail "pve_var should check config file existence"
    else
        pass "pve_var correctly validates config file existence"
    fi
    
    # Test pve_var directory existence check
    it "should validate directory exists in pve_var"
    if pve_var "/etc/passwd" "/nonexistent/dir" 2>/dev/null; then
        fail "pve_var should check directory existence"
    else
        pass "pve_var correctly validates directory existence"
    fi
    
    # Test pve_cbm directory existence check
    it "should validate host mount path exists in pve_cbm"
    # Create a temporary directory for testing
    local temp_dir="/tmp/pve_test_$$"
    mkdir -p "$temp_dir"
    
    if pve_cbm "101" "/nonexistent/path" "/container/path" 2>/dev/null; then
        fail "pve_cbm should check host mount path existence"
    else
        pass "pve_cbm correctly validates host mount path existence"
    fi
    
    # Clean up
    rm -rf "$temp_dir"
}

# Test help system compliance
test_pve_help_system() {
    describe "PVE functions help system"
    
    # Test help flags for all major functions
    local functions=("pve_fun" "pve_var" "pve_dsr" "pve_rsn" "pve_clu" "pve_cdo" "pve_cbm" "pve_ctc" "pve_cto" "pve_vmd" "pve_vmc" "pve_vms" "pve_vmg" "pve_vpt" "pve_vck")
    
    for func in "${functions[@]}"; do
        it "should provide help for $func"
        if $func --help >/dev/null 2>&1; then
            pass "$func provides help system"
        else
            fail "$func missing help system"
        fi
        
        if $func -h >/dev/null 2>&1; then
            pass "$func supports -h flag"
        else
            fail "$func missing -h support"
        fi
    done
}

# Test operational logging compliance
test_pve_operational_logging() {
    describe "PVE functions operational logging"
    
    # Enable debug logging for testing
    export AUX_DEBUG_ENABLED=1
    
    # Test that aux functions are available
    it "should have aux_info available for logging"
    if type aux_info >/dev/null 2>&1; then
        pass "aux_info function available for logging"
    else
        fail "aux_info function not available"
    fi
    
    if type aux_err >/dev/null 2>&1; then
        pass "aux_err function available for error logging"
    else
        fail "aux_err function not available"
    fi
    
    if type aux_warn >/dev/null 2>&1; then
        pass "aux_warn function available for warnings"
    else
        fail "aux_warn function not available"
    fi
    
    if type aux_dbg >/dev/null 2>&1; then
        pass "aux_dbg function available for debug logging"
    else
        fail "aux_dbg function not available"
    fi
    
    if type aux_val >/dev/null 2>&1; then
        pass "aux_val function available for validation"
    else
        fail "aux_val function not available"
    fi
    
    if type aux_chk >/dev/null 2>&1; then
        pass "aux_chk function available for dependency checking"
    else
        fail "aux_chk function not available"
    fi
    
    if type aux_cmd >/dev/null 2>&1; then
        pass "aux_cmd function available for safe command execution"
    else
        fail "aux_cmd function not available"
    fi
}

# Test return code compliance
test_pve_return_codes() {
    describe "PVE functions return code compliance"
    
    # Test parameter validation failures return 1
    it "should return 1 for parameter validation failures"
    pve_cdo "storage" 2>/dev/null
    if [ $? -eq 1 ]; then
        pass "Returns 1 for parameter validation failure"
    else
        fail "Incorrect return code for parameter validation failure"
    fi
    
    # Test missing command returns 127
    local original_path="$PATH"
    export PATH="/nonexistent"
    
    pve_clu -x 2>/dev/null
    local exit_code=$?
    if [ $exit_code -eq 127 ]; then
        pass "Returns 127 for missing command dependency"
    else
        fail "Expected 127 for missing command, got $exit_code"
    fi
    
    export PATH="$original_path"
    
    # Test help returns 0
    it "should return 0 for help display"
    pve_fun --help >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        pass "Returns 0 for help display"
    else
        fail "Help should return 0"
    fi
    
    # Test file not found returns 2
    it "should return 2 for file access errors"
    pve_var "/nonexistent/config" "/tmp" 2>/dev/null
    local exit_code=$?
    if [ $exit_code -eq 2 ]; then
        pass "Returns 2 for file access errors"
    else
        fail "Expected 2 for file access error, got $exit_code"
    fi
}

# Test aux integration patterns
test_pve_aux_integration() {
    describe "PVE functions aux library integration"
    
    # Test that functions are using proper aux integration patterns
    it "should source aux library properly"
    if grep -q "source.*aux" /home/es/lab/lib/ops/pve; then
        pass "PVE module sources aux library"
    else
        fail "PVE module does not source aux library"
    fi
    
    # Test that functions use aux_val for validation
    it "should use aux_val for parameter validation"
    if grep -q "aux_val" /home/es/lab/lib/ops/pve; then
        pass "PVE module uses aux_val for validation"
    else
        fail "PVE module does not use aux_val"
    fi
    
    # Test that functions use aux_chk for dependency checking
    it "should use aux_chk for dependency validation"
    if grep -q "aux_chk" /home/es/lab/lib/ops/pve; then
        pass "PVE module uses aux_chk for dependency checking"
    else
        fail "PVE module does not use aux_chk"
    fi
    
    # Test that functions use aux_cmd for safe execution
    it "should use aux_cmd for safe command execution"
    if grep -q "aux_cmd" /home/es/lab/lib/ops/pve; then
        pass "PVE module uses aux_cmd for safe execution"
    else
        fail "PVE module does not use aux_cmd"
    fi
    
    # Test that functions use aux_info/err/warn for logging
    it "should use aux logging functions"
    if grep -q -E "aux_(info|err|warn|dbg)" /home/es/lab/lib/ops/pve; then
        pass "PVE module uses aux logging functions"
    else
        fail "PVE module does not use aux logging functions"
    fi
}

# Main test execution
main() {
    echo "=== PVE Module .std Compliance Tests ==="
    echo
    
    test_pve_parameter_validation
    echo
    
    test_pve_dependency_checks
    echo
    
    test_pve_file_validation
    echo
    
    test_pve_help_system
    echo
    
    test_pve_operational_logging
    echo
    
    test_pve_return_codes
    echo
    
    test_pve_aux_integration
    echo
    
    # Summary
    echo "=== Test Summary ==="
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✅ All tests passed - pve module is .std compliant"
        return 0
    else
        echo "❌ Some tests failed - compliance issues found"
        return 1
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi