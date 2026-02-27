#!/bin/bash
#######################################################################
# Logging Contract Consistency Test
#######################################################################
# File: val/core/log_contract_test.sh
# Description: Prevents drift between lib/.spec, lib/gen/aux, and cfg/log
#######################################################################

# Test configuration
TEST_NAME="Logging Contract Consistency"
TEST_CATEGORY="core"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"

test_contract_files_exist() {
    test_file_exists "${LAB_ROOT}/lib/.spec" "lib/.spec exists"
    test_file_exists "${LAB_ROOT}/lib/gen/aux" "lib/gen/aux exists"
    test_file_exists "${LAB_ROOT}/cfg/log/README.md" "cfg/log/README.md exists"
    test_file_exists "${LAB_ROOT}/cfg/log/filebeat.yml" "cfg/log/filebeat.yml exists"
    test_file_exists "${LAB_ROOT}/cfg/log/fluentd.conf" "cfg/log/fluentd.conf exists"
}

test_aux_emits_consolidated_targets() {
    local aux_file="${LAB_ROOT}/lib/gen/aux"

    run_test "aux emits aux.json" grep -qE 'aux\.json' "$aux_file"
    run_test "aux emits aux.csv" grep -qE 'aux\.csv' "$aux_file"
    run_test "aux emits aux.log" grep -qE 'aux\.log' "$aux_file"
}

test_cfg_log_ingests_current_targets() {
    local filebeat_cfg="${LAB_ROOT}/cfg/log/filebeat.yml"
    local fluentd_cfg="${LAB_ROOT}/cfg/log/fluentd.conf"

    run_test "filebeat ingests aux.json" grep -qE '/aux\.json' "$filebeat_cfg"
    run_test "filebeat ingests aux.log" grep -qE '/aux\.log' "$filebeat_cfg"
    run_test "fluentd ingests aux.json" grep -qE '/aux\.json' "$fluentd_cfg"
    run_test "fluentd ingests aux.log" grep -qE '/aux\.log' "$fluentd_cfg"
}

test_cfg_log_has_no_legacy_targets() {
    local cfg_log_dir="${LAB_ROOT}/cfg/log"

    run_test "cfg/log avoids aux_operational targets" \
        bash -c "! grep -R -qE 'aux_operational' '$cfg_log_dir'"
    run_test "cfg/log avoids aux_debug targets" \
        bash -c "! grep -R -qE 'aux_debug' '$cfg_log_dir'"
}

test_spec_references_cfg_log_contract() {
    local spec_file="${LAB_ROOT}/lib/.spec"
    run_test "lib/.spec references cfg/log contract" \
        grep -qE 'cfg/log/README\.md' "$spec_file"
}

main() {
    test_header "$TEST_NAME"

    run_test test_contract_files_exist
    run_test test_aux_emits_consolidated_targets
    run_test test_cfg_log_ingests_current_targets
    run_test test_cfg_log_has_no_legacy_targets
    run_test test_spec_references_cfg_log_contract

    test_footer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
