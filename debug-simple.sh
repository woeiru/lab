#!/bin/bash

echo "=== DEBUG: Testing doc-func issue ==="

LAB_DIR="/home/es/lab"
LIB_OPS_DIR="$LAB_DIR/lib/ops"

# Source the aux library
source "$LAB_DIR/lib/gen/aux"

echo "Generating JSON for sys file..."
aux_laf -j "$LIB_OPS_DIR/sys" >/dev/null 2>&1

JSON_FILE="$LAB_DIR/.tmp/doc/lib_ops_sys.json"
echo "Reading JSON file: $JSON_FILE"

if [[ -f "$JSON_FILE" ]]; then
    echo "=== First 10 function names from JSON ==="
    grep '"name":' "$JSON_FILE" | head -10 | while IFS= read -r line; do
        if [[ "$line" =~ \"name\":[[:space:]]*\"([^\"]+)\" ]]; then
            func_name="${BASH_REMATCH[1]}"
            echo "Function name: '$func_name'"
        fi
    done
else
    echo "JSON file not found: $JSON_FILE"
fi
