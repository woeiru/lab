#!/bin/bash

set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="$LAB_ROOT/utl/pla/cli"
APPROVED_MAPPING="$LAB_ROOT/utl/pla/map/runs/20260307-0057_present-showcase1/approved-mapping.json"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [[ "$expected" != "$actual" ]]; then
        fail "$message (expected=$expected actual=$actual)"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        fail "$message (missing '$needle')"
    fi
}

seed_snapshot() {
    local db_path="$1"
    python3 - "$db_path" << 'PY'
import pathlib
import sqlite3
import sys

db_path = pathlib.Path(sys.argv[1])
conn = sqlite3.connect(db_path)
try:
    conn.execute(
        "INSERT INTO plg_cfg_snapshot (snapshot_id, env_root, digest, raw_json) VALUES (1, ?, ?, '{}')",
        ("/tmp/test-env", "digest-test-1"),
    )
    conn.commit()
finally:
    conn.close()
PY
}

sql_scalar() {
    local db_path="$1"
    local query="$2"
    python3 - "$db_path" "$query" << 'PY'
import pathlib
import sqlite3
import sys

db_path = pathlib.Path(sys.argv[1])
query = sys.argv[2]
conn = sqlite3.connect(db_path)
try:
    row = conn.execute(query).fetchone()
    if row is None:
        print("")
    else:
        print(row[0])
finally:
    conn.close()
PY
}

test_dry_run_does_not_write() {
    local db_path="$TMP_DIR/dry-run.db"
    "$CLI" init-db "$db_path" >/dev/null
    seed_snapshot "$db_path"

    local output
    output="$($CLI apply-mapping "$db_path" "$APPROVED_MAPPING" --dry-run)"

    assert_contains "$output" '"mode": "dry-run"' "dry-run output should include mode"
    assert_eq "0" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_entity")" "dry-run must not persist entities"
    assert_eq "0" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_state")" "dry-run must not persist state"
}

test_apply_is_idempotent() {
    local db_path="$TMP_DIR/apply-idempotent.db"
    "$CLI" init-db "$db_path" >/dev/null
    seed_snapshot "$db_path"

    "$CLI" apply-mapping "$db_path" "$APPROVED_MAPPING" --apply >/dev/null
    "$CLI" apply-mapping "$db_path" "$APPROVED_MAPPING" --apply >/dev/null

    assert_eq "8" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_entity")" "apply should create eight entities"
    assert_eq "1" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_state WHERE name = 'present-showcase1'")" "apply should create one target state"
    assert_eq "8" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_state_entity")" "apply should bind eight entities into state"
    assert_eq "8" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_cfg_binding")" "apply should create eight cfg bindings"
}

test_collision_is_rejected() {
    local db_path="$TMP_DIR/collision.db"
    "$CLI" init-db "$db_path" >/dev/null
    seed_snapshot "$db_path"
    "$CLI" upsert-entity "$db_path" ct h1 "Host h1" >/dev/null

    local output
    if output="$($CLI apply-mapping "$db_path" "$APPROVED_MAPPING" --apply 2>&1)"; then
        fail "collision scenario should fail"
    fi

    assert_contains "$output" "entity collision" "collision failure should mention collision"
}

test_failpoint_rolls_back_transaction() {
    local db_path="$TMP_DIR/failpoint.db"
    "$CLI" init-db "$db_path" >/dev/null
    seed_snapshot "$db_path"

    if PLY_APPLY_FAILPOINT=after_entities "$CLI" apply-mapping "$db_path" "$APPROVED_MAPPING" --apply >/dev/null 2>&1; then
        fail "failpoint execution should fail"
    fi

    assert_eq "0" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_entity")" "failpoint rollback should leave no entities"
    assert_eq "0" "$(sql_scalar "$db_path" "SELECT COUNT(*) FROM plg_state")" "failpoint rollback should leave no state"
}

echo "Running pla_apply_mapping_test"
test_dry_run_does_not_write
test_apply_is_idempotent
test_collision_is_rejected
test_failpoint_rolls_back_transaction
echo "PASS: pla_apply_mapping_test"
