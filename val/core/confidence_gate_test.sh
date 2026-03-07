#!/bin/bash
#######################################################################
# Confidence Gate Policy Tests
#######################################################################
# File: val/core/confidence_gate_test.sh
# Description: Validates risk-class command selection and argument
#              handling for val/lib/confidence_gate.sh.
#######################################################################

source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"

readonly GATE_SCRIPT="${LAB_ROOT}/val/lib/confidence_gate.sh"

assert_rejects_missing_risk() {
    local output=""

    if output="$(bash "${GATE_SCRIPT}" --dry-run lib/ops/ssh 2>&1)"; then
        return 1
    fi

    [[ "$output" == *"missing required --risk"* ]]
}

assert_low_risk_selects_targeted_module_test() {
    local output=""

    output="$(bash "${GATE_SCRIPT}" --risk low --dry-run lib/ops/ssh 2>&1)" || return 1

    [[ "$output" == *"bash -n lib/ops/ssh"* ]] || return 1
    [[ "$output" == *"bash val/lib/ops/ssh_test.sh"* ]] || return 1
    if printf '%s\n' "$output" | grep -q '^  - bash val/run_all_tests.sh lib$'; then
        return 1
    fi

    return 0
}

assert_medium_risk_includes_lib_category_suite() {
    local output=""

    output="$(bash "${GATE_SCRIPT}" --risk medium --dry-run lib/ops/ssh 2>&1)" || return 1

    printf '%s\n' "$output" | grep -q '^  - bash val/run_all_tests.sh lib$'
}

assert_high_risk_includes_full_suite() {
    local output=""

    output="$(bash "${GATE_SCRIPT}" --risk high --dry-run lib/ops/ssh 2>&1)" || return 1

    printf '%s\n' "$output" | grep -q '^  - bash val/run_all_tests.sh lib$' || return 1
    printf '%s\n' "$output" | grep -q '^  - bash val/run_all_tests.sh$'
}

test_rejects_missing_risk() {
    run_test "Rejects missing risk flag" assert_rejects_missing_risk
}

test_low_risk_selects_targeted_module_checks() {
    run_test "Low risk selects targeted module checks" assert_low_risk_selects_targeted_module_test
}

test_medium_risk_includes_lib_category_suite() {
    run_test "Medium risk includes lib category suite" assert_medium_risk_includes_lib_category_suite
}

test_high_risk_includes_full_suite() {
    run_test "High risk includes full suite" assert_high_risk_includes_full_suite
}

test_header "Confidence Gate Policy"

run_test_group "Argument Validation" \
    test_rejects_missing_risk

run_test_group "Risk Class Matrix" \
    test_low_risk_selects_targeted_module_checks \
    test_medium_risk_includes_lib_category_suite \
    test_high_risk_includes_full_suite

test_footer
