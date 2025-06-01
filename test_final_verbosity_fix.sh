#!/bin/bash
echo "=== Final Verbosity Control Test ==="
echo

# Test 1: Verbosity OFF (should produce no terminal output)
echo "Test 1: MASTER_TERMINAL_VERBOSITY=off (should be silent)"
echo "Running: MASTER_TERMINAL_VERBOSITY=off ./bin/ini"
MASTER_TERMINAL_VERBOSITY="off" ./bin/ini 2>&1
exit_code=$?
echo "Exit code: $exit_code"
echo "Should be completely silent above."
echo

# Test 2: Verbosity ON (should produce terminal output)
echo "Test 2: MASTER_TERMINAL_VERBOSITY=on (should show output)"
echo "Running: MASTER_TERMINAL_VERBOSITY=on ./bin/ini"
MASTER_TERMINAL_VERBOSITY="on" ./bin/ini 2>&1
exit_code=$?
echo "Exit code: $exit_code"
echo "Should show initialization messages above."
echo

# Test 3: Original issue test - ensure the "Usage: verify_var" message doesn't appear with verbosity off
echo "Test 3: Checking that the original 'Usage: verify_var' message doesn't appear"
echo "Running with verbosity off and checking stderr..."
stderr_output=$(MASTER_TERMINAL_VERBOSITY="off" ./bin/ini 2>&1)
if echo "$stderr_output" | grep -q "Usage: verify_var"; then
    echo "❌ FAILED: The 'Usage: verify_var' message still appears!"
    echo "Output: $stderr_output"
else
    echo "✅ PASSED: No 'Usage: verify_var' message found when verbosity is off"
fi

# Test 3.5: Check that the new "Usage: verify_function" message doesn't appear with verbosity off
echo "Test 3.5: Checking that the 'Usage: verify_function' message doesn't appear"
echo "Running with verbosity off and checking stderr..."
if echo "$stderr_output" | grep -q "Usage: verify_function"; then
    echo "❌ FAILED: The 'Usage: verify_function' message still appears!"
    echo "Output: $stderr_output"
else
    echo "✅ PASSED: No 'Usage: verify_function' message found when verbosity is off"
fi
echo

# Test 4: Check that the system completes successfully
echo "Test 4: Checking that initialization completes successfully"
rm -f .log/ini.log
MASTER_TERMINAL_VERBOSITY="off" ./bin/ini 2>&1
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    echo "✅ PASSED: Initialization completed with exit code 0"
else
    echo "❌ FAILED: Initialization failed with exit code $exit_code"
fi

# Check the log for completion
if tail -1 .log/ini.log | grep -q "Main initialization completed successfully"; then
    echo "✅ PASSED: Log shows successful completion"
else
    echo "❌ FAILED: Log does not show successful completion"
    echo "Last log line:"
    tail -1 .log/ini.log
fi

echo
echo "=== Test Complete ==="
echo "Summary: The verbosity control fix should ensure:"
echo "1. When MASTER_TERMINAL_VERBOSITY=off, no terminal output appears"
echo "2. When MASTER_TERMINAL_VERBOSITY=on, initialization messages appear"
echo "3. The 'Usage: verify_var' message no longer appears incorrectly"
echo "4. The 'Usage: verify_function' message no longer appears incorrectly"
echo "5. The system completes initialization successfully"
