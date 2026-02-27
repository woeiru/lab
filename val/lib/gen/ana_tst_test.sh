#!/bin/bash
TEST_NAME="ana_tst - Test Coverage Traceability"
TEST_CATEGORY="lib"

source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"
source "${LAB_ROOT}/lib/gen/ana"

test_ana_tst_usage() {
    ana_tst 2>&1 | grep -q "Usage: ana_tst"
    return $?
}

test_ana_tst_table() {
    # It should find srv_test.sh for lib/ops/srv
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

main() {
    test_header "$TEST_NAME"
    run_test "Usage without arguments" test_ana_tst_usage
    run_test "Table view for srv" test_ana_tst_table
    run_test "JSON view for srv" test_ana_tst_json
    test_footer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
