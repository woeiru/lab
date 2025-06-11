#!/bin/bash
#########run_dic_test_suite() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    DIC SYSTEM TESTS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Dependency Injection Container validation${NC}"
    echo############################################################
# DIC Framework Integration Test
#######################################################################
# File: val/src/dic_framework_test.sh
# Description: Framework-integrated wrapper for DIC system tests
#              that adapts the existing DIC tests to use the 
#              standardized test framework for consistent reporting.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"

# Initialize framework
framework_init

# Test suite configuration
readonly DIC_TEST_DIR="$(dirname "${BASH_SOURCE[0]}")/dic"
readonly SUITE_NAME="DIC System Integration"

# Test discovery and execution
run_dic_test_suite() {
    test_section "DIC SYSTEM TESTS" "Dependency Injection Container validation"
    
    # Define DIC test cases
    local dic_tests=(
        "dic_basic_test.sh:DIC Basic Functions:Core functionality and parameter injection"
        "dic_integration_test.sh:DIC Integration:Complete system integration testing"
        "dic_simple_test.sh:DIC Simple:Quick validation checks"
        "dic_phase1_completion_test.sh:DIC Phase 1:Phase 1 completion validation"
    )
    
    local failed_tests=()
    
    for test_def in "${dic_tests[@]}"; do
        IFS=':' read -r test_file test_name test_desc <<< "$test_def"
        local test_path="$DIC_TEST_DIR/$test_file"
        
        if [[ ! -f "$test_path" ]]; then
            test_skip "DIC test not found: $test_file"
            continue
        fi
        
        test_log "Starting: $test_name - $test_desc"
        
        # Execute DIC test and capture output
        local test_output
        local test_exit_code
        
        if test_output=$(cd /root/lab && "$test_path" 2>&1); then
            test_exit_code=$?
        else
            test_exit_code=$?
        fi
        
        # Parse DIC test results (they use their own counters)
        local passed_count=0
        local failed_count=0
        local total_count=0
        
        if echo "$test_output" | grep -q "TESTS_PASSED\|Tests passed\|✓"; then
            passed_count=$(echo "$test_output" | grep -o "TESTS_PASSED=[0-9]*\|Tests passed: [0-9]*\|✓.*[0-9]*" | grep -o "[0-9]*" | tail -1)
            passed_count=${passed_count:-0}
        fi
        
        if echo "$test_output" | grep -q "TESTS_FAILED\|Tests failed\|✗"; then
            failed_count=$(echo "$test_output" | grep -o "TESTS_FAILED=[0-9]*\|Tests failed: [0-9]*\|✗.*[0-9]*" | grep -o "[0-9]*" | tail -1)
            failed_count=${failed_count:-0}
        fi
        
        total_count=$((passed_count + failed_count))
        
        # Report results through framework
        if [[ $test_exit_code -eq 0 ]] && [[ $failed_count -eq 0 ]]; then
            test_success "$test_name completed successfully ($passed_count/$total_count passed)"
        else
            test_failure "$test_name failed ($failed_count/$total_count failed)"
            failed_tests+=("$test_name")
            
            # Show relevant error output
            if [[ -n "$test_output" ]]; then
                echo "Error details:"
                echo "$test_output" | tail -10
            fi
        fi
    done
    
    # Final suite summary
    if [[ ${#failed_tests[@]} -eq 0 ]]; then
        test_success "All DIC tests passed"
    else
        test_failure "Failed tests: ${failed_tests[*]}"
        return 1
    fi
}

# Execute main test function
main() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    DIC SYSTEM TEST SUITE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Validate environment
    if [[ ! -d "$DIC_TEST_DIR" ]]; then
        test_failure "DIC test directory not found: $DIC_TEST_DIR"
        print_test_summary
        exit 1
    fi
    
    if [[ ! -f "/root/lab/src/dic/ops" ]]; then
        test_failure "DIC system not found at /root/lab/src/dic/ops"
        print_test_summary
        exit 1
    fi
    
    # Run test suite
    run_dic_test_suite
    
    # Framework summary
    print_test_summary
    
    # Return exit code based on framework results
    [[ $FRAMEWORK_TESTS_FAILED -eq 0 ]]
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
