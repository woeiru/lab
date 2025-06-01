#!/bin/bash
# Debug script to test the verify_var issue

echo "=== Debug: Testing verify_var fix ==="

# Set up environment
cd /home/es/lab
export MASTER_TERMINAL_VERBOSITY="on"

# Source the required files
echo "1. Sourcing ric..."
if source ./cfg/core/ric; then
    echo "   ✓ ric sourced successfully"
else
    echo "   ✗ Failed to source ric"
    exit 1
fi

echo "2. Sourcing rdc..."
if source ./cfg/core/rdc; then
    echo "   ✓ rdc sourced successfully"
else
    echo "   ✗ Failed to source rdc"
    exit 1
fi

echo "3. Sourcing ver..."
if source ./lib/core/ver; then
    echo "   ✓ ver sourced successfully"
else
    echo "   ✗ Failed to source ver"
    exit 1
fi

echo "4. Testing verify_var function..."
echo "   REGISTERED_FUNCTIONS array contents:"
if declare -p REGISTERED_FUNCTIONS &>/dev/null; then
    echo "   Array is declared: ${#REGISTERED_FUNCTIONS[@]} elements"
    for i in "${!REGISTERED_FUNCTIONS[@]}"; do
        echo "   [$i]: ${REGISTERED_FUNCTIONS[$i]}"
    done
else
    echo "   ✗ REGISTERED_FUNCTIONS array is not declared"
fi

echo "5. Testing verify_var with REGISTERED_FUNCTIONS..."
if verify_var "REGISTERED_FUNCTIONS"; then
    echo "   ✓ verify_var REGISTERED_FUNCTIONS succeeded"
else
    echo "   ✗ verify_var REGISTERED_FUNCTIONS failed"
fi

echo "6. Testing with a known good variable..."
if verify_var "HOME"; then
    echo "   ✓ verify_var HOME succeeded"
else
    echo "   ✗ verify_var HOME failed"
fi

echo "7. Running a minimal init test..."
echo "   Testing essential_check..."
if essential_check; then
    echo "   ✓ essential_check passed"
else
    echo "   ✗ essential_check failed"
fi

echo "=== Debug complete ==="
