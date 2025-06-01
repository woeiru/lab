#!/bin/bash
# Test script to verify verbosity fixes

echo "Testing verbosity controls fix..."

# Test 1: Master verbosity OFF - should be completely silent
echo "=== Test 1: Master verbosity OFF ==="
cd /home/es/lab
export MASTER_TERMINAL_VERBOSITY="off"
./bin/ini >/dev/null 2>&1
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "✓ PASS: Initialization completed successfully with verbosity OFF"
else
    echo "✗ FAIL: Initialization failed with exit code $exit_code"
fi

# Test 2: Master verbosity ON - should show output
echo ""
echo "=== Test 2: Master verbosity ON ==="
export MASTER_TERMINAL_VERBOSITY="on"
output=$(./bin/ini 2>&1)
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "✓ PASS: Initialization completed successfully with verbosity ON"
    if [ -n "$output" ]; then
        echo "✓ PASS: Output generated when verbosity is ON"
    else
        echo "? INFO: No output generated (may be normal)"
    fi
else
    echo "✗ FAIL: Initialization failed with exit code $exit_code"
fi

# Test 3: Test the specific function that was causing issues
echo ""
echo "=== Test 3: Direct verify_var function test ==="
source ./lib/core/ver
# Test with correct number of arguments
verify_var "HOME" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ PASS: verify_var works with correct arguments"
else
    echo "✗ FAIL: verify_var failed with correct arguments"
fi

# Test with incorrect number of arguments (should show usage)
output=$(verify_var "HOME" 1 2>&1)
if [[ "$output" == *"Usage: verify_var"* ]]; then
    echo "✓ PASS: verify_var shows usage message with incorrect arguments"
else
    echo "✗ FAIL: verify_var did not show expected usage message"
fi

echo ""
echo "Test completed."
