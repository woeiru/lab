#!/bin/bash
# Debug script to test individual phases of ai_doc_generator

set -euo pipefail

LAB_ROOT="/home/es/lab"
target_dir="/home/es/lab/lib/ops"
WORK_DIR="/tmp/ai_debug_$$"

mkdir -p "$WORK_DIR"
trap "rm -rf '$WORK_DIR'" EXIT

echo "=== Testing Performance Intelligence Module ==="
if [[ -x "$LAB_ROOT/utl/doc/perf" ]]; then
    "$LAB_ROOT/utl/doc/perf" "$target_dir" > "$WORK_DIR/perf.json" 2>/dev/null
    echo "Performance module: OK"
else
    echo "Performance module: NOT EXECUTABLE"
fi

echo "=== Testing Dependency Intelligence Module ==="
if [[ -x "$LAB_ROOT/utl/doc/deps" ]]; then
    "$LAB_ROOT/utl/doc/deps" "$target_dir" > "$WORK_DIR/deps.json" 2>/dev/null
    echo "Dependency module: OK"
else
    echo "Dependency module: NOT EXECUTABLE"
fi

echo "=== Testing Testing Intelligence Module ==="
if [[ -x "$LAB_ROOT/utl/doc/test" ]]; then
    "$LAB_ROOT/utl/doc/test" "$target_dir" > "$WORK_DIR/test.json" 2>/dev/null
    echo "Testing module: OK"
else
    echo "Testing module: NOT EXECUTABLE"
fi

echo "=== Testing UX Intelligence Module ==="
if [[ -x "$LAB_ROOT/utl/doc/ux" ]]; then
    "$LAB_ROOT/utl/doc/ux" "$target_dir" > "$WORK_DIR/ux.json" 2>/dev/null
    echo "UX module: OK"
else
    echo "UX module: NOT EXECUTABLE"
fi

echo "=== All modules tested ==="
