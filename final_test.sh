#!/bin/bash

echo "=== Final Verbosity Control Validation ==="
echo "Testing the fixes for the 'Usage: verify_var' message issue"
echo

# Ensure we're in the right directory
cd /home/es/lab

# Clean up any existing logs
rm -f .log/ini.log .log/ver.log

echo "1. Testing with MASTER_TERMINAL_VERBOSITY=off (should be silent)..."
output=$(MASTER_TERMINAL_VERBOSITY="off" timeout 30 ./bin/ini 2>&1)
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    echo "   ✅ Initialization completed successfully (exit code: $exit_code)"
else
    echo "   ⚠️  Initialization exited with code: $exit_code"
fi

if [[ -z "$output" ]]; then
    echo "   ✅ No terminal output produced (verbosity correctly controlled)"
else
    echo "   ❌ Unexpected terminal output:"
    echo "   $output"
fi

# Check for the specific error message we were trying to fix
if echo "$output" | grep -q "Usage: verify_var"; then
    echo "   ❌ CRITICAL: 'Usage: verify_var' message still appears!"
    echo "   This indicates the fix was not successful."
else
    echo "   ✅ 'Usage: verify_var' message correctly suppressed"
fi

echo
echo "2. Checking log file for successful completion..."
if [[ -f .log/ini.log ]]; then
    if tail -1 .log/ini.log | grep -q "Main initialization completed successfully"; then
        echo "   ✅ Log shows successful completion"
    else
        echo "   ⚠️  Log does not show standard completion message"
        echo "   Last log line: $(tail -1 .log/ini.log)"
    fi
else
    echo "   ⚠️  No initialization log file found"
fi

echo
echo "3. Summary of fixes applied:"
echo "   • Fixed incorrect verify_var call in bin/ini line 535"
echo "   • Fixed function registration logic to allow 0 registered functions"
echo "   • Updated verify_var error messages to use ver_log instead of direct echo"
echo "   • Added missing INI_LOG_TERMINAL_VERBOSITY configuration"
echo "   • All error messages now respect verbosity controls"

echo
echo "=== Test Complete ==="

# Final validation
if [[ $exit_code -eq 0 ]] && [[ -z "$output" ]] && ! echo "$output" | grep -q "Usage: verify_var"; then
    echo "🎉 SUCCESS: All verbosity control fixes are working correctly!"
    exit 0
else
    echo "❌ ISSUES DETECTED: Some fixes may need additional attention"
    exit 1
fi
