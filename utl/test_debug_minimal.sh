#!/bin/bash
set -euo pipefail

echo "Starting test..."

# Test basic variable assignment
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "SCRIPT_DIR: $SCRIPT_DIR"

# Test LAB_DIR assignment like in main script
if [[ -z "${LAB_DIR:-}" ]]; then
    readonly LAB_DIR="$(dirname "$SCRIPT_DIR")"
fi
echo "LAB_DIR: $LAB_DIR"

echo "Test completed successfully"
