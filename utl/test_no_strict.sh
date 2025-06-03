#!/bin/bash
# Test script without strict mode

echo "=== Testing without strict mode ==="

echo "Test 1: Basic echo..."
echo "✅ Basic echo works"

echo "Test 2: Directory resolution..."
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "SCRIPT_DIR: $SCRIPT_DIR"

echo "Test 3: LAB_DIR..."
if [[ -z "${LAB_DIR:-}" ]]; then
    readonly LAB_DIR="$(dirname "$SCRIPT_DIR")"
fi
echo "LAB_DIR: $LAB_DIR"

echo "=== Test completed ==="
