#!/bin/bash
TEST_NAME="ana_tst - Test Coverage Traceability"
TEST_CATEGORY="lib"

source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"
source "${LAB_ROOT}/lib/gen/ana"

test_ana_tst_usage() {
    ana_tst 2>&1 | grep -q "Usage: ana_tst <target file>"
    return $?
}

test_ana_tst_table() {
    local output
    output=$(ana_tst "${LAB_ROOT}/lib/ops/srv")
    echo "$output" | grep -q "srv_test.sh"
    return $?
}

test_ana_tst_json() {
    local output tmp_file
    output=$(ana_tst -j "${LAB_ROOT}/lib/ops/srv")
    echo "$output" | grep -q "JSON output written" || return 1
    tmp_file="${LAB_ROOT}/.tmp/doc/lib_ops_srv.json"
    [ -f "$tmp_file" ] || return 1
    grep -q '"target":.*lib/ops/srv' "$tmp_file" || return 1
    grep -q '"file":.*srv_test.sh' "$tmp_file" || return 1
    return 0
}

test_ana_tst_no_match_counters() {
    local test_target="${LAB_ROOT}/lib/ops/dummy_mod"
    local test_dir="${LAB_ROOT}/val/lib/ops"
    mkdir -p "$test_dir"
    touch "$test_target"
    touch "${test_dir}/dummy_mod_test.sh"
    
    local output
    output=$(ana_tst "$test_target" 2>&1)
    
    rm -f "$test_target" "${test_dir}/dummy_mod_test.sh"
    
    # Check that it did not error out
    echo "$output" | grep -q "syntax error" && return 1
    # Check that it found the test file with count 0 and type Unknown
    echo "$output" | grep -q "|.*dummy_mod_test\.sh.*|.*0.*|.*Unknown" || return 1
    return 0
}

test_ana_tst_basename_collisions() {
    local test_target="${LAB_ROOT}/lib/core/dummy_col"
    local right_dir="${LAB_ROOT}/val/lib/core"
    local wrong_dir="${LAB_ROOT}/val/lib/ops"
    mkdir -p "$right_dir" "$wrong_dir"
    touch "$test_target"
    touch "${right_dir}/dummy_col_test.sh"
    touch "${wrong_dir}/dummy_col_test.sh"
    
    local output
    output=$(ana_tst "$test_target")
    
    # Keep the real file if it was there, otherwise remove it
    rm -f "$test_target" "${wrong_dir}/dummy_col_test.sh"
    
    echo "$output" | grep -q "val/lib/core/dummy_col_test\.sh" || return 1
    echo "$output" | grep -q "val/lib/ops/dummy_col_test\.sh" && return 1
    return 0
}

test_ana_tst_json_escaping() {
    local test_target="${LAB_ROOT}/lib/ops/dummy_json"
    local test_dir="${LAB_ROOT}/val/lib/ops"
    mkdir -p "$test_dir"
    touch "$test_target"
    
    cat << 'JSONEOF' > "${test_dir}/dummy_json_test.sh"
function test_dummy_json() {
  echo "has \"quotes\" and \slashes"
}
JSONEOF
    
    local output tmp_file
    output=$(ana_tst -j "$test_target")
    tmp_file="${LAB_ROOT}/.tmp/doc/lib_ops_dummy_json.json"
    
    local content=$(cat "$tmp_file" 2>/dev/null)
    
    rm -f "$test_target" "${test_dir}/dummy_json_test.sh" "$tmp_file"
    
    # Verify the generated JSON is parseable by python
    if command -v python3 >/dev/null; then
        echo "$content" | python3 -c 'import sys, json; json.load(sys.stdin)' >/dev/null 2>&1 || return 1
    fi
    return 0
}

test_ana_tst_strict_j_cleanliness() {
    local output
    output=$(ana_tst -j "${LAB_ROOT}/lib/ops/srv")
    echo "$output" | grep -q "+---" && return 1
    echo "$output" | grep -q "Test File" && return 1
    echo "$output" | grep -q "|" && return 1
    return 0
}

test_ana_tst_no_test_found() {
    local test_target="${LAB_ROOT}/lib/ops/no_such_test_mod"
    touch "$test_target"
    
    local output
    output=$(ana_tst "$test_target")
    
    rm -f "$test_target"
    
    echo "$output" | grep -q "No test files found for" || return 1
    return 0
}

main() {
    test_header "$TEST_NAME"
    run_test "Usage without arguments" test_ana_tst_usage
    run_test "Table view for srv" test_ana_tst_table
    run_test "JSON view for srv" test_ana_tst_json
    run_test "No-match counters bug" test_ana_tst_no_match_counters
    run_test "Ambiguous basename collisions" test_ana_tst_basename_collisions
    run_test "JSON escaping" test_ana_tst_json_escaping
    run_test "Strict -j cleanliness" test_ana_tst_strict_j_cleanliness
    run_test "No test found behavior" test_ana_tst_no_test_found
    test_footer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
