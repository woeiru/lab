#!/bin/bash

set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
PLA_TMP="$TMP_DIR/pla"
CLI="$PLA_TMP/cli"
DB_PATH="$PLA_TMP/data/test-export.db"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        fail "$message (missing '$needle')"
    fi
}

assert_file_exists() {
    local path="$1"
    local message="$2"

    if [[ ! -f "$path" ]]; then
        fail "$message ($path)"
    fi
}

setup_workspace_copy() {
    cp -R "$LAB_ROOT/utl/pla" "$PLA_TMP"
}

test_default_export_writes_canonical_and_legacy() {
    local canonical="$PLA_TMP/export/summary-default.md"
    local legacy="$PLA_TMP/export/inventory-summary.md"
    local output

    "$CLI" init-db "$DB_PATH" >/dev/null
    output="$($CLI export-md "$DB_PATH")"

    assert_contains "$output" "wrote markdown snapshot: $canonical" "default export should write canonical summary path"
    assert_contains "$output" "wrote legacy compatibility snapshot: $legacy" "default export should write legacy compatibility snapshot"

    assert_file_exists "$canonical" "canonical summary export should exist"
    assert_file_exists "$legacy" "legacy summary export should exist"

    if ! cmp -s "$canonical" "$legacy"; then
        fail "canonical and legacy default exports should have identical content"
    fi
}

test_labeled_summary_path_is_supported() {
    local labeled="$PLA_TMP/export/summary-showcase1.md"
    local output

    output="$($CLI export-md "$DB_PATH" "$labeled")"

    assert_contains "$output" "wrote markdown snapshot: $labeled" "explicit summary label path should be honored"
    assert_file_exists "$labeled" "labeled summary export should exist"
}

echo "Running pla_export_naming_test"
setup_workspace_copy
test_default_export_writes_canonical_and_legacy
test_labeled_summary_path_is_supported
echo "PASS: pla_export_naming_test"
