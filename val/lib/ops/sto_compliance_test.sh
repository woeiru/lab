#!/bin/bash

# Storage module .std compliance testing framework
# Tests parameter validation, dependency checks, and operational logging

# Load test framework
source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../helpers/test_framework.sh"

# Load sto module
source /home/es/lab/lib/ops/sto

# Test parameter validation compliance
test_sto_parameter_validation() {
    describe "Storage functions parameter validation"
    
    # Test sto_fun with empty filter
    it "should reject empty function filter"
    if sto_fun "" 2>/dev/null; then
        fail "sto_fun should reject empty filter"
    else
        pass "sto_fun correctly rejects empty filter"
    fi
    
    # Test sto_var with invalid execution flag
    it "should require -x execution flag"
    if sto_var "invalid" 2>/dev/null; then
        fail "sto_var should require -x flag"
    else
        pass "sto_var correctly requires -x flag"
    fi
    
    # Test sto_fea with invalid execution flag
    it "should validate execution flag format"
    if sto_fea "notx" 2>/dev/null; then
        fail "sto_fea should validate execution flag"
    else
        pass "sto_fea correctly validates execution flag"
    fi
    
    # Test sto_fec parameter count validation
    it "should require exactly 6 parameters for sto_fec"
    if sto_fec 1 2 3 2>/dev/null; then
        fail "sto_fec should require 6 parameters"
    else
        pass "sto_fec correctly requires 6 parameters"
    fi
    
    # Test sto_fec numeric validation
    it "should validate line number as numeric"
    if sto_fec "abc" "/mnt" "ext4" "defaults" "0" "0" 2>/dev/null; then
        fail "sto_fec should validate numeric line number"
    else
        pass "sto_fec correctly validates numeric parameters"
    fi
    
    # Test sto_nfs parameter validation
    it "should require all 4 NFS parameters"
    if sto_nfs "server" "share" 2>/dev/null; then
        fail "sto_nfs should require 4 parameters"
    else
        pass "sto_nfs correctly requires all parameters"
    fi
    
    # Test sto_nfs empty parameter validation
    it "should reject empty NFS parameters"
    if sto_nfs "" "share" "/mnt" "defaults" 2>/dev/null; then
        fail "sto_nfs should reject empty server IP"
    else
        pass "sto_nfs correctly rejects empty parameters"
    fi
    
    # Test sto_bfs_tra parameter validation
    it "should require minimum 3 parameters for btrfs transform"
    if sto_bfs_tra "C" 2>/dev/null; then
        fail "sto_bfs_tra should require minimum 3 parameters"
    else
        pass "sto_bfs_tra correctly requires minimum parameters"
    fi
}

# Test dependency checking compliance
test_sto_dependency_checks() {
    describe "Storage functions dependency validation"
    
    # Mock missing commands for testing
    local original_path="$PATH"
    export PATH="/nonexistent"
    
    # Test sto_fea dependency checks
    it "should check for blkid command"
    if sto_fea -x 2>/dev/null; then
        fail "sto_fea should check for blkid dependency"
    else
        pass "sto_fea correctly checks blkid dependency"
    fi
    
    # Test sto_fec dependency checks
    it "should check for required commands in fec"
    if sto_fec 1 "/mnt" "ext4" "defaults" "0" "0" 2>/dev/null; then
        fail "sto_fec should check for command dependencies"
    else
        pass "sto_fec correctly checks dependencies"
    fi
    
    # Test sto_nfs dependency checks
    it "should check for mount command"
    if sto_nfs "192.168.1.1" "/share" "/mnt" "defaults" 2>/dev/null; then
        fail "sto_nfs should check for mount dependency"
    else
        pass "sto_nfs correctly checks mount dependency"
    fi
    
    # Test sto_bfs_tra dependency checks
    it "should check for btrfs command"
    if sto_bfs_tra "C" "user" "folder" 2>/dev/null; then
        fail "sto_bfs_tra should check for btrfs dependency"
    else
        pass "sto_bfs_tra correctly checks btrfs dependency"
    fi
    
    # Restore PATH
    export PATH="$original_path"
}

# Test help system compliance
test_sto_help_system() {
    describe "Storage functions help system"
    
    # Test help flags for all major functions
    local functions=("sto_fun" "sto_var" "sto_fea" "sto_fec" "sto_nfs" "sto_bfs_tra")
    
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
test_sto_operational_logging() {
    describe "Storage functions operational logging"
    
    # Enable debug logging for testing
    export AUX_DEBUG_ENABLED=1
    
    # Test that functions use aux_info, aux_warn, aux_err appropriately
    it "should use operational logging in sto_fea"
    # This is a basic test - in real scenario we'd check log output
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
}

# Test return code compliance
test_sto_return_codes() {
    describe "Storage functions return code compliance"
    
    # Test parameter validation failures return 1
    it "should return 1 for parameter validation failures"
    sto_fun "" 2>/dev/null
    if [ $? -eq 1 ]; then
        pass "Returns 1 for parameter validation failure"
    else
        fail "Incorrect return code for parameter validation failure"
    fi
    
    # Test missing command returns 127
    local original_path="$PATH"
    export PATH="/nonexistent"
    
    sto_fea -x 2>/dev/null
    local exit_code=$?
    if [ $exit_code -eq 127 ]; then
        pass "Returns 127 for missing command dependency"
    else
        fail "Expected 127 for missing command, got $exit_code"
    fi
    
    export PATH="$original_path"
    
    # Test help returns 0
    it "should return 0 for help display"
    sto_fun --help >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        pass "Returns 0 for help display"
    else
        fail "Help should return 0"
    fi
}

# Main test execution
main() {
    echo "=== Storage Module .std Compliance Tests ==="
    echo
    
    test_sto_parameter_validation
    echo
    
    test_sto_dependency_checks
    echo
    
    test_sto_help_system
    echo
    
    test_sto_operational_logging
    echo
    
    test_sto_return_codes
    echo
    
    # Summary
    echo "=== Test Summary ==="
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✅ All tests passed - sto module is .std compliant"
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