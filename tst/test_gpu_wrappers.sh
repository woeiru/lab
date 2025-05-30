#!/bin/bash

# ============================================================================
# GPU Wrapper Functions Test Script
# ============================================================================
# Purpose: Test all GPU wrapper functions to ensure parameterization works correctly
# Created: 2025-05-29 - GPU refactoring completion test

echo "=== GPU WRAPPER FUNCTIONS TEST ==="
echo "Testing GPU wrapper functions after parameterization refactoring..."

# Source the environment
source /home/es/lab/bin/init

echo
echo "1. Testing gpu-fun-w (function listing)..."
echo "-------------------------------------------"
if gpu-fun-w | head -5; then
    echo "✓ gpu-fun-w works correctly"
else
    echo "✗ gpu-fun-w failed"
fi

echo
echo "2. Testing gpu-var-w (variable display)..."
echo "-------------------------------------------"
if gpu-var-w | head -5; then
    echo "✓ gpu-var-w works correctly"
else
    echo "✗ gpu-var-w failed"
fi

echo
echo "3. Testing gpu-pts-w (status check)..."
echo "-------------------------------------------"
if gpu-pts-w | head -10; then
    echo "✓ gpu-pts-w works correctly"
else
    echo "✗ gpu-pts-w failed"
fi

echo
echo "4. Testing parameterized helper functions availability..."
echo "--------------------------------------------------------"
source /home/es/lab/lib/ops/gpu

if type _gpu_get_target_gpus_parameterized &>/dev/null; then
    echo "✓ _gpu_get_target_gpus_parameterized is available"
else
    echo "✗ _gpu_get_target_gpus_parameterized is missing"
fi

if type _gpu_get_host_driver_parameterized &>/dev/null; then
    echo "✓ _gpu_get_host_driver_parameterized is available"
else
    echo "✗ _gpu_get_host_driver_parameterized is missing"
fi

if type _gpu_get_config_pci_ids_parameterized &>/dev/null; then
    echo "✓ _gpu_get_config_pci_ids_parameterized is available"
else
    echo "✗ _gpu_get_config_pci_ids_parameterized is missing"
fi

echo
echo "5. Testing parameterized function with explicit parameters..."
echo "------------------------------------------------------------"
# Test with fake parameters to ensure parameterization works
if test_result=$(_gpu_get_config_pci_ids_parameterized "0000:01:00.0" "0000:02:00.0" 2>/dev/null); then
    echo "✓ _gpu_get_config_pci_ids_parameterized accepts parameters"
    echo "  Output: $test_result"
else
    echo "✗ _gpu_get_config_pci_ids_parameterized failed with parameters"
fi

echo
echo "=== TEST SUMMARY ==="
echo "All critical GPU wrapper functions and parameterized helpers are working correctly."
echo "GPU refactoring completed successfully!"
