#!/bin/bash
#######################################################################
# Comprehensive Library Testing Suite
#######################################################################
# File: val/lib/run_all_tests.sh
# Description: Master test runner for all library components including
#              core, ops, and gen libraries with comprehensive reporting.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"
readonly VAL_DIR="$TEST_LAB_DIR/val"

# ANSI colors for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global test tracking
declare -g TOTAL_SUITES=0
declare -g PASSED_SUITES=0
declare -g FAILED_SUITES=0
declare -g SKIPPED_SUITES=0

# Print banner
print_banner() {
    echo -e "${CYAN}#######################################################################${NC}"
    echo -e "${WHITE}                    LAB LIBRARY TESTING SUITE${NC}"
    echo -e "${CYAN}#######################################################################${NC}"
    echo -e "${YELLOW}Testing comprehensive lab environment management library components${NC}"
    echo -e "${PURPLE}Location: ${TEST_LAB_DIR}${NC}"
    echo -e "${PURPLE}Started:  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}#######################################################################${NC}"
    echo
}

# Print section header
print_section() {
    local section="$1"
    local description="$2"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${section}: ${description}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Run a single test suite
run_test_suite() {
    local test_file="$1"
    local suite_name="$2"
    local category="$3"
    
    ((TOTAL_SUITES++))
    
    if [[ ! -f "$test_file" ]]; then
        echo -e "${YELLOW}⚠️  SKIP: ${suite_name} (test file not found: $test_file)${NC}"
        ((SKIPPED_SUITES++))
        return 0
    fi
    
    if [[ ! -x "$test_file" ]]; then
        echo -e "${YELLOW}⚠️  SKIP: ${suite_name} (test file not executable: $test_file)${NC}"
        ((SKIPPED_SUITES++))
        return 0
    fi
    
    echo -e "${CYAN}🧪  Running: ${suite_name}${NC}"
    echo -e "${PURPLE}   Category: ${category}${NC}"
    echo -e "${PURPLE}   File: ${test_file}${NC}"
    echo
    
    local start_time=$(date +%s.%N)
    
    # Run the test suite and capture output
    if "$test_file" 2>&1; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.1")
        echo
        echo -e "${GREEN}✅ PASS: ${suite_name} (${duration}s)${NC}"
        ((PASSED_SUITES++))
        return 0
    else
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.1")
        echo
        echo -e "${RED}❌ FAIL: ${suite_name} (${duration}s)${NC}"
        ((FAILED_SUITES++))
        return 1
    fi
}

# Test core libraries
test_core_libraries() {
    print_section "CORE LIBRARIES" "Foundation system components (err, lo1, tme, ver)"
    
    # Core libraries (if tests exist)
    local core_tests=(
        "core/err_test.sh:Error Handling:Core"
        "core/lo1_test.sh:Logging System:Core"
        "core/tme_test.sh:Timing Management:Core"
        "core/ver_test.sh:Version Control:Core"
    )
    
    for test_def in "${core_tests[@]}"; do
        IFS=':' read -r test_file suite_name category <<< "$test_def"
        run_test_suite "$VAL_DIR/lib/$test_file" "$suite_name" "$category"
        echo
    done
}

# Test operations libraries
test_ops_libraries() {
    print_section "OPERATIONS LIBRARIES" "Infrastructure management and service operations"
    
    # Operations libraries
    local ops_tests=(
        "ops/pbs_test.sh:PBS Operations:Operations"
        "ops/srv_test.sh:Service Operations:Operations"
        "ops/pve_test.sh:Proxmox VE Operations:Operations"
        "ops/gpu_test.sh:GPU Management:Operations"
        "ops/sys_test.sh:System Administration:Operations"
        "ops/net_test.sh:Network Management:Operations"
        "ops/sto_test.sh:Storage Management:Operations"
        "ops/usr_test.sh:User Management:Operations"
        "ops/ssh_test.sh:SSH Management:Operations"
    )
    
    for test_def in "${ops_tests[@]}"; do
        IFS=':' read -r test_file suite_name category <<< "$test_def"
        run_test_suite "$VAL_DIR/lib/$test_file" "$suite_name" "$category"
        echo
    done
}

# Test general utilities libraries
test_gen_libraries() {
    print_section "GENERAL UTILITIES" "Development tools and specialized utilities"
    
    # General utilities libraries
    local gen_tests=(
        "gen/aux_test.sh:Auxiliary Functions:Utilities"
        "gen/env_test.sh:Environment Management:Utilities"
        "gen/inf_test.sh:Infrastructure Utilities:Utilities"
        "gen/sec_test.sh:Security Utilities:Utilities"
    )
    
    for test_def in "${gen_tests[@]}"; do
        IFS=':' read -r test_file suite_name category <<< "$test_def"
        run_test_suite "$VAL_DIR/lib/$test_file" "$suite_name" "$category"
        echo
    done
}

# Test integration scenarios
test_integration_scenarios() {
    print_section "INTEGRATION TESTS" "Cross-component functionality and workflows"
    
    local integration_tests=(
        "integration/library_loading_test.sh:Library Loading:Integration"
        "integration/cross_component_test.sh:Cross-Component:Integration"
        "integration/deployment_workflow_test.sh:Deployment Workflow:Integration"
    )
    
    for test_def in "${integration_tests[@]}"; do
        IFS=':' read -r test_file suite_name category <<< "$test_def"
        run_test_suite "$VAL_DIR/lib/$test_file" "$suite_name" "$category"
        echo
    done
}

# Print final results
print_results() {
    echo -e "${CYAN}#######################################################################${NC}"
    echo -e "${WHITE}                          TEST RESULTS${NC}"
    echo -e "${CYAN}#######################################################################${NC}"
    echo
    
    local pass_rate=0
    if [[ $TOTAL_SUITES -gt 0 ]]; then
        pass_rate=$(echo "scale=1; $PASSED_SUITES * 100 / $TOTAL_SUITES" | bc 2>/dev/null || echo "0")
    fi
    
    echo -e "${WHITE}Total Test Suites: ${TOTAL_SUITES}${NC}"
    echo -e "${GREEN}Passed: ${PASSED_SUITES}${NC}"
    echo -e "${RED}Failed: ${FAILED_SUITES}${NC}"
    echo -e "${YELLOW}Skipped: ${SKIPPED_SUITES}${NC}"
    echo -e "${WHITE}Pass Rate: ${pass_rate}%${NC}"
    echo
    
    if [[ $FAILED_SUITES -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Library system is functioning correctly.${NC}"
        local status="SUCCESS"
    else
        echo -e "${RED}❌ Some tests failed. Please review the failures above.${NC}"
        local status="FAILURE"
    fi
    
    echo
    echo -e "${PURPLE}Completed: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}#######################################################################${NC}"
    
    # Return appropriate exit code
    [[ $FAILED_SUITES -eq 0 ]] && return 0 || return 1
}

# Print usage information
print_usage() {
    echo "Lab Library Testing Suite"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c, --core          Test only core libraries"
    echo "  -o, --ops           Test only operations libraries" 
    echo "  -g, --gen           Test only general utilities"
    echo "  -i, --integration   Test only integration scenarios"
    echo "  -h, --help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0                  # Run all tests"
    echo "  $0 --core           # Test only core libraries"
    echo "  $0 --ops --gen      # Test ops and gen libraries"
}

# Main execution
main() {
    local test_core=false
    local test_ops=false
    local test_gen=false
    local test_integration=false
    local test_all=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--core)
                test_core=true
                test_all=false
                shift
                ;;
            -o|--ops)
                test_ops=true
                test_all=false
                shift
                ;;
            -g|--gen)
                test_gen=true
                test_all=false
                shift
                ;;
            -i|--integration)
                test_integration=true
                test_all=false
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Start the test suite
    print_banner
    
    # Run selected test categories
    if [[ "$test_all" == "true" ]]; then
        test_core_libraries
        test_ops_libraries
        test_gen_libraries
        test_integration_scenarios
    else
        [[ "$test_core" == "true" ]] && test_core_libraries
        [[ "$test_ops" == "true" ]] && test_ops_libraries
        [[ "$test_gen" == "true" ]] && test_gen_libraries
        [[ "$test_integration" == "true" ]] && test_integration_scenarios
    fi
    
    # Print final results
    print_results
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
