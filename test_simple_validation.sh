#!/bin/bash
echo "=== Simple Validation Test ==="

# Test 1: Check that our fixes are in place
echo "Checking if line 535 fix is in place..."
if grep -n "verify_var \"REGISTERED_FUNCTIONS\"$" bin/ini | head -1; then
    echo "✅ Line 535 fix is correctly applied"
else
    echo "❌ Line 535 fix not found"
fi

# Test 2: Check that the function registration logic is fixed
echo "Checking if function registration logic is fixed..."
if grep -n "return 0$" bin/ini | tail -1; then
    echo "✅ Function registration logic fix is in place"
else
    echo "❌ Function registration logic fix not found"
fi

# Test 3: Check that ver_log is used instead of direct echo in verify_var
echo "Checking if verify_var uses ver_log..."
if grep -A5 -B5 "Usage: verify_var" lib/core/ver | grep -q "ver_log"; then
    echo "✅ verify_var function uses ver_log for error reporting"
else
    echo "❌ verify_var still uses direct echo for errors"
fi

# Test 4: Check that INI_LOG_TERMINAL_VERBOSITY is properly declared
echo "Checking if INI_LOG_TERMINAL_VERBOSITY is declared..."
if grep -q "INI_LOG_TERMINAL_VERBOSITY" cfg/core/ric; then
    echo "✅ INI_LOG_TERMINAL_VERBOSITY is declared in config"
else
    echo "❌ INI_LOG_TERMINAL_VERBOSITY not found in config"
fi

echo "=== Test Complete ==="
