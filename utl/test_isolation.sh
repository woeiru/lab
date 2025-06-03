#!/bin/bash
# Test script to isolate the execution issue

echo "=== Testing main script initialization sequence ==="

# Test 1: Basic set flags
echo "Test 1: Setting bash flags..."
set -euo pipefail
echo "✅ set -euo pipefail successful"

# Test 2: Directory resolution
echo "Test 2: Directory resolution..."
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "SCRIPT_DIR: $SCRIPT_DIR"

if [[ -z "${LAB_DIR:-}" ]]; then
    readonly LAB_DIR="$(dirname "$SCRIPT_DIR")"
fi
echo "LAB_DIR: $LAB_DIR"

# Test 3: Config file paths
echo "Test 3: Config paths..."
readonly CONFIG_FILE="$LAB_DIR/utl/.doc_config"
readonly LOG_DIR="$LAB_DIR/.tmp/doc"
readonly LOCK_FILE="$LOG_DIR/orchestrator.lock"
echo "CONFIG_FILE: $CONFIG_FILE"
echo "LOG_DIR: $LOG_DIR"

# Test 4: Arrays
echo "Test 4: Arrays..."
readonly AVAILABLE_GENERATORS=(
    "functions:doc-func:Function metadata table generator::5"
    "variables:doc-var:Variable usage documentation generator::3"
)
echo "GENERATORS: ${#AVAILABLE_GENERATORS[@]} items"

# Test 5: Variables
echo "Test 5: Variables..."
VERBOSE=false
DRY_RUN=false
START_TIME=""
echo "Variables initialized"

echo "=== All tests passed! ==="
