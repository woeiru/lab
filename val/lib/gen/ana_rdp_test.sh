#!/bin/bash
# Test for ana_rdp (Reverse Dependency Call Graph)

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/gen/ana"

test_header "ana_rdp Analysis Tool"

test_ana_rdp_terminal_output() {
    describe "ana_rdp terminal output"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_rdp "lib/core/tme" "lib/ops" "src/set" "bin" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]] && echo "$output" | grep -q "Target Function" && echo "$output" | grep -q "Dependent File" && echo "$output" | grep -q "Occurrences" && echo "$output" | grep -q "tme_start_timer" && echo "$output" | grep -q "bin/ini"; then
        pass "Terminal output contains expected columns and data"
    else
        fail "Terminal output missing expected columns or data"
        echo "Output was: $output"
    fi
}

test_ana_rdp_json_output() {
    describe "ana_rdp JSON output"
    ((FRAMEWORK_TESTS_RUN++))
    
    # Ensure cleanup
    rm -f .tmp/doc/lib_core_tme.json
    
    local output
    output=$(ana_rdp -j "lib/core/tme" "lib/ops" "src/set" "bin" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]]; then
        pass "Command executed successfully with -j"
    else
        fail "Command failed with -j"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_file="$LAB_ROOT/.tmp/doc/lib_core_tme.json"
    if [[ -f "$json_file" ]]; then
        pass "JSON file created successfully"
    else
        fail "JSON file not created at $json_file"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_content=$(cat "$json_file")
    if echo "$json_content" | grep -q '"analysis_type": "reverse_dependencies"' && \
       echo "$json_content" | grep -q '"target_file": "lib/core/tme"' && \
       echo "$json_content" | grep -q '"tme_start_timer"' && \
       echo "$json_content" | grep -q '"bin/ini"'; then
        pass "JSON content contains expected schema and data"
    else
        fail "JSON content missing expected schema or data"
        echo "JSON content: $json_content"
    fi
}

test_ana_rdp_missing_params() {
    describe "ana_rdp missing parameters"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_rdp "lib/core/tme" 2>&1)
    local status=$?
    
    if [[ $status -eq 1 ]] && echo "$output" | grep -q "callsite"; then
        pass "Handles missing call-site parameters correctly"
    else
        fail "Did not handle missing call-site parameters correctly"
        echo "Status: $status, Output: $output"
    fi
}

test_ana_rdp_std_wrapper() {
    describe "ana_rdp_std wrapper"
    ((FRAMEWORK_TESTS_RUN++))

    local output
    output=$(ana_rdp_std "lib/core/tme" 2>&1)
    local status=$?

    if [[ $status -eq 0 ]] && echo "$output" | grep -q "Target Function" && echo "$output" | grep -q "tme_start_timer" && echo "$output" | grep -q "bin/ini"; then
        pass "ana_rdp_std runs with standard call-site profile"
    else
        fail "ana_rdp_std did not run with expected profile"
        echo "Status: $status, Output: $output"
    fi
}

# Run tests
test_ana_rdp_terminal_output
test_ana_rdp_json_output
test_ana_rdp_missing_params
test_ana_rdp_std_wrapper

test_footer
