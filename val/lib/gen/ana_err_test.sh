#!/bin/bash
# Test for ana_err (Error & Exit Code Analytics)

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/gen/ana"

test_header "ana_err Analysis Tool"

test_ana_err_terminal_output() {
    describe "ana_err terminal output"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_err "lib/ops/pve" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]] && echo "$output" | grep -q "Message/Code" && echo "$output" | grep -q "aux_err" && echo "$output" | grep -q "return"; then
        pass "Terminal output contains expected sections and data"
    else
        fail "Terminal output missing expected sections or data"
        echo "Output was: $output"
    fi
}

test_ana_err_terminal_output_func() {
    describe "ana_err terminal output with specific function"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_err "lib/ops/pve" "pve_dsr" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]] && echo "$output" | grep -q "pve_dsr" && echo "$output" | grep -q "aux_warn" && ! echo "$output" | grep -q "pve_var"; then
        pass "Terminal output contains expected function data"
    else
        fail "Terminal output missing expected function data or contains others"
        echo "Output was: $output"
    fi
}

test_ana_err_json_output() {
    describe "ana_err JSON output"
    ((FRAMEWORK_TESTS_RUN++))
    
    # Ensure cleanup
    rm -f .tmp/doc/lib_ops_pve.err.json
    
    local output
    output=$(ana_err -j "lib/ops/pve" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]]; then
        pass "Command executed successfully with -j"
    else
        fail "Command failed with -j"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_file=".tmp/doc/lib_ops_pve.err.json"
    if [[ -f "$json_file" ]]; then
        pass "JSON file created successfully"
    else
        fail "JSON file not created at $json_file"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_content=$(cat "$json_file")
    if echo "$json_content" | grep -q '"file": "lib/ops/pve"' && \
       echo "$json_content" | grep -q '"errors":' && \
       echo "$json_content" | grep -q '"type": "return"' && \
       echo "$json_content" | grep -q '"type": "aux_err"'; then
        pass "JSON content contains expected schema and data"
    else
        fail "JSON content missing expected schema or data"
        echo "JSON content: $json_content"
    fi
}

test_ana_err_missing_params() {
    describe "ana_err missing parameters"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    # Since we are mocking aux_use or using real aux_use, if not loaded it fails. 
    # Let's mock aux_use temporarily to avoid command not found if not sourced via ini
    aux_use() {
        echo "Usage:"
        return 1
    }
    output=$(ana_err 2>&1)
    local status=$?
    
    if [[ $status -ne 0 ]] && echo "$output" | grep -q -i "Usage"; then
        pass "Handles missing parameters correctly"
    else
        fail "Did not handle missing parameters correctly"
        echo "Status: $status, Output: $output"
    fi
}

# Run tests
test_ana_err_terminal_output
test_ana_err_terminal_output_func
test_ana_err_json_output
test_ana_err_missing_params

test_footer
