#!/bin/bash
# Test for ana_dep (List Module Dependencies)

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/gen/aux"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/gen/ana"

test_header "ana_dep Analysis Tool"

test_ana_dep_terminal_output() {
    describe "ana_dep terminal output"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_dep "lib/ops/pve" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]] && echo "$output" | grep -q "Dependencies for: lib/ops/pve" && echo "$output" | grep -q "Script Import" && echo "$output" | grep -q "Host Command" && echo "$output" | grep -q "bin/ini" && echo "$output" | grep -q "pct"; then
        pass "Terminal output contains expected sections and data"
    else
        fail "Terminal output missing expected sections or data"
        echo "Output was: $output"
    fi
}

test_ana_dep_json_output() {
    describe "ana_dep JSON output"
    ((FRAMEWORK_TESTS_RUN++))
    
    # Ensure cleanup
    rm -f .tmp/doc/lib_ops_pve.json
    
    local output
    output=$(ana_dep -j "lib/ops/pve" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]]; then
        pass "Command executed successfully with -j"
    else
        fail "Command failed with -j"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_file=".tmp/doc/lib_ops_pve.json"
    if [[ -f "$json_file" ]]; then
        pass "JSON file created successfully"
    else
        fail "JSON file not created at $json_file"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_content=$(cat "$json_file")
    if echo "$json_content" | grep -q '"analysis_type": "dependencies"' && \
       echo "$json_content" | grep -q '"target_file": "lib/ops/pve"' && \
       echo "$json_content" | grep -q '"scripts":' && \
       echo "$json_content" | grep -q '"commands":' && \
       echo "$json_content" | grep -q '"bin/ini"' && \
       echo "$json_content" | grep -q '"pct"'; then
        pass "JSON content contains expected schema and data"
    else
        fail "JSON content missing expected schema or data"
        echo "JSON content: $json_content"
    fi
}

test_ana_dep_missing_params() {
    describe "ana_dep missing parameters"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_dep 2>&1)
    local status=$?
    
    # aux_use returns 1 when called, which we expect
    if [[ $status -ne 0 ]] && echo "$output" | grep -q -i "Usage"; then
        pass "Handles missing parameters correctly"
    else
        fail "Did not handle missing parameters correctly"
        echo "Status: $status, Output: $output"
    fi
}

# Run tests
test_ana_dep_terminal_output
test_ana_dep_json_output
test_ana_dep_missing_params

test_footer
