#!/bin/bash

cd /home/es/lab
source lib/ops/gpu 2>/dev/null

echo "=== Testing GPU Help System ==="

help_score=0
functions_tested=0

for func in gpu_fun gpu_var gpu_nds gpu_ptd gpu_pta gpu_pts; do
    echo "Testing function: $func"
    
    if declare -f "$func" >/dev/null 2>&1; then
        echo "  ✓ Function exists"
        ((functions_tested++))
        
        # Test --help flag
        echo "  Testing --help flag..."
        if $func --help >/dev/null 2>&1; then
            echo "  ✓ --help works"
            ((help_score++))
        else
            echo "  ✗ --help failed (exit code: $?)"
        fi
        
        # Test -h flag
        echo "  Testing -h flag..."
        if $func -h >/dev/null 2>&1; then
            echo "  ✓ -h works"
            ((help_score++))
        else
            echo "  ✗ -h failed (exit code: $?)"
        fi
    else
        echo "  ✗ Function does not exist"
    fi
    echo ""
done

echo "=== Results ==="
echo "Functions tested: $functions_tested"
echo "Help calls working: $help_score"
echo "Expected: $((functions_tested * 2))"

if [[ $help_score -eq $((functions_tested * 2)) ]]; then
    echo "✅ All help tests passed!"
else
    echo "❌ Some help tests failed"
fi
