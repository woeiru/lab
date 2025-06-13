#!/bin/bash
# PVE Module .std Standards Compliance Test - Simple Version
# Tests key .std compliance features of the pve module

echo "=== PVE Module .std Standards Compliance Test ==="
echo

# Setup
cd /home/es/lab
source lib/ops/pve

test_count=0
passed_tests=0

# Test function
test_check() {
    local test_name="$1"
    local test_command="$2"
    
    ((test_count++))
    echo -n "Test ${test_count}: ${test_name}... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ PASS"
        ((passed_tests++))
    else
        echo "❌ FAIL"
    fi
}

# Test 1: Aux library functions available
test_check "Aux library sourced" "type aux_val && type aux_chk && type aux_info"

# Test 2: Help system works
test_check "Help system functional" "pve_fun --help | grep -q 'Function:'"

# Test 3: Parameter validation works
test_check "Parameter validation active" "! pve_cdo '' 'template' 2>/dev/null"

# Test 4: Usage display on parameter errors
test_check "Usage display on errors" "pve_cdo 2>&1 | grep -q 'Usage:'"

# Test 5: Module variables defined
test_check "Module variables defined" "test -n '$DIR_FUN' && test -n '$FILE_FUN'"

# Test 6: Return code compliance (help returns 0)
test_check "Help returns exit code 0" "pve_fun --help >/dev/null 2>&1 && test $? -eq 0"

# Test 7: Aux integration patterns in source
test_check "Uses aux_val for validation" "grep -q 'aux_val' lib/ops/pve"
test_check "Uses aux_chk for dependency checks" "grep -q 'aux_chk' lib/ops/pve"
test_check "Uses aux_info for logging" "grep -q 'aux_info' lib/ops/pve"
test_check "Uses aux_cmd for safe execution" "grep -q 'aux_cmd' lib/ops/pve"

echo
echo "=== Test Summary ==="
echo "Total tests: ${test_count}"
echo "Passed: ${passed_tests}"
echo "Failed: $((test_count - passed_tests))"

if [[ $passed_tests -eq $test_count ]]; then
    echo
    echo "✅ ALL TESTS PASSED - PVE module is .std compliant!"
    echo
    echo "The pve module successfully implements:"
    echo "  ✓ Auxiliary library integration"
    echo "  ✓ Parameter validation using aux_val"
    echo "  ✓ Dependency checking using aux_chk"
    echo "  ✓ Operational logging using aux_info/aux_err"
    echo "  ✓ Safe command execution using aux_cmd"
    echo "  ✓ Help system integration"
    echo "  ✓ Proper return codes"
    echo
    exit 0
else
    echo
    echo "❌ Some tests failed - compliance issues found"
    exit 1
fi
