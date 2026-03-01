#!/bin/bash
# Test for ana_scp (Variable Scope & Integrity Analysis)

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/gen/aux"
source "$(dirname "${BASH_SOURCE[0]}")/../../../lib/gen/ana"

test_header "ana_scp Analysis Tool"

test_ana_scp_terminal_output() {
    describe "ana_scp terminal output"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_scp "lib/core/col" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]] && echo "$output" | grep -q "COL_RESET" && echo "$output" | grep -q "Readonly" && echo "$output" | grep -q "Env Constant"; then
        pass "Terminal output contains expected sections and data"
    else
        fail "Terminal output missing expected sections or data"
        echo "Output was: $output"
    fi
}

test_ana_scp_json_output() {
    describe "ana_scp JSON output"
    ((FRAMEWORK_TESTS_RUN++))
    
    # Ensure cleanup
    rm -f .tmp/doc/lib_core_col_scp.json
    
    local output
    output=$(ana_scp -j "lib/core/col" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]]; then
        pass "Command executed successfully with -j"
    else
        fail "Command failed with -j"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_file=".tmp/doc/lib_core_col_scp.json"
    if [[ -f "$json_file" ]]; then
        pass "JSON file created successfully"
    else
        fail "JSON file not created at $json_file"
        return 1
    fi
    
    ((FRAMEWORK_TESTS_RUN++))
    local json_content=$(cat "$json_file")
    if echo "$json_content" | grep -q '"scope_analysis":' && \
       echo "$json_content" | grep -q '"file": "lib/core/col"' && \
       echo "$json_content" | grep -q '"type": "Readonly"' && \
       echo "$json_content" | grep -q '"variable": "COL_RESET"'; then
        pass "JSON content contains expected schema and data"
    else
        fail "JSON content missing expected schema or data"
        echo "JSON content: $json_content"
    fi
}

test_ana_scp_json_dir_option() {
    describe "ana_scp --json-dir option"
    ((FRAMEWORK_TESTS_RUN++))

    local custom_dir=".tmp/doc/scp_test"
    local expected_json="$custom_dir/lib_core_col_scp.json"

    rm -rf "$custom_dir"

    local output
    output=$(ana_scp -j --json-dir "$custom_dir" "lib/core/col" 2>&1)
    local status=$?

    if [[ $status -eq 0 ]] && [[ -f "$expected_json" ]]; then
        pass "Writes JSON output to custom directory"
    else
        fail "Failed to write JSON output to custom directory"
        echo "Status: $status, Output: $output"
    fi
}

test_ana_scp_empty_flag_compatibility() {
    describe "ana_scp empty flag compatibility"
    ((FRAMEWORK_TESTS_RUN++))

    local output
    output=$(ana_scp "" "lib/core/col" 2>&1)
    local status=$?

    if [[ $status -eq 0 ]] && echo "$output" | grep -q "COL_RESET"; then
        pass "Accepts empty flag argument from aux_ffl wrappers"
    else
        fail "Does not accept empty flag argument compatibility"
        echo "Status: $status, Output: $output"
    fi
}

test_ana_scp_missing_params() {
    describe "ana_scp missing parameters"
    ((FRAMEWORK_TESTS_RUN++))
    
    local output
    output=$(ana_scp 2>&1)
    local status=$?
    
    if [[ $status -ne 0 ]] && echo "$output" | grep -q "Usage:"; then
        pass "Handles missing parameters correctly"
    else
        fail "Did not handle missing parameters correctly"
        echo "Status: $status, Output: $output"
    fi
}

test_ana_scp_help_option() {
    describe "ana_scp help option"
    ((FRAMEWORK_TESTS_RUN++))

    local output
    output=$(ana_scp --help 2>&1)
    local status=$?

    if [[ $status -eq 0 ]] && echo "$output" | grep -q "Usage:" && echo "$output" | grep -q "ana_scp"; then
        pass "Supports --help contract"
    else
        fail "Help option does not follow expected contract"
        echo "Status: $status, Output: $output"
    fi
}

test_ana_scp_invalid_option() {
    describe "ana_scp invalid option"
    ((FRAMEWORK_TESTS_RUN++))

    local output
    output=$(ana_scp --nope 2>&1)
    local status=$?

    if [[ $status -eq 1 ]] && echo "$output" | grep -q "Invalid option" && echo "$output" | grep -q "Usage:"; then
        pass "Rejects unknown option with usage output"
    else
        fail "Unknown option handling is incorrect"
        echo "Status: $status, Output: $output"
    fi
}

test_ana_scp_json_escape_helper() {
    describe "ana_scp JSON escaping"
    ((FRAMEWORK_TESTS_RUN++))

    local escaped_quotes
    escaped_quotes=$(_ana_scp_json_escape 'a"b\c')

    if [[ "$escaped_quotes" == 'a\"b\\c' ]]; then
        pass "Escapes quotes and backslashes"
    else
        fail "Failed escaping quotes/backslashes"
        echo "Escaped output: $escaped_quotes"
    fi

    ((FRAMEWORK_TESTS_RUN++))
    local escaped_controls
    escaped_controls=$(_ana_scp_json_escape $'x\ny\t')

    if [[ "$escaped_controls" == 'x\ny\t' ]]; then
        pass "Escapes newline and tab characters"
    else
        fail "Failed escaping control characters"
        echo "Escaped output: $escaped_controls"
    fi
}

test_ana_scp_no_generic_helper_leaks() {
    describe "ana_scp helper namespace"
    ((FRAMEWORK_TESTS_RUN++))

    ana_scp "lib/core/col" >/dev/null 2>&1

    if ! declare -F truncate_and_pad >/dev/null 2>&1 && \
       ! declare -F print_separator >/dev/null 2>&1 && \
       ! declare -F print_row >/dev/null 2>&1; then
        pass "Does not leak generic helper functions"
    else
        fail "Generic helper function names leaked into global scope"
    fi
}

test_ana_scp_local_leak() {
    describe "ana_scp local leak detection"
    ((FRAMEWORK_TESTS_RUN++))
    
    cat << 'TESTFILE' > /tmp/test_scp_leak.sh
#!/bin/bash
leak_test() {
   some_leak="hello"
}
TESTFILE

    local output
    output=$(ana_scp "/tmp/test_scp_leak.sh" 2>&1)
    local status=$?
    
    if [[ $status -eq 0 ]] && echo "$output" | grep -q "Local Leak" && echo "$output" | grep -q "some_leak"; then
        pass "Terminal output correctly identifies local leaks"
    else
        fail "Terminal output failed to identify local leaks"
        echo "Output was: $output"
    fi
    
    rm -f /tmp/test_scp_leak.sh
}

# Run tests
test_ana_scp_terminal_output
test_ana_scp_json_output
test_ana_scp_json_dir_option
test_ana_scp_empty_flag_compatibility
test_ana_scp_missing_params
test_ana_scp_help_option
test_ana_scp_invalid_option
test_ana_scp_local_leak
test_ana_scp_json_escape_helper
test_ana_scp_no_generic_helper_leaks

test_footer
