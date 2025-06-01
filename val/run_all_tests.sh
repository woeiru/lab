#!/bin/bash
#######################################################################
# Master Test Runner - Validation Suite Controller
#######################################################################
# File: val/run_all_tests.sh
# Description: Master test runner that executes all validation tests
#              in the correct order with comprehensive reporting and
#              optional test categories for targeted testing.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/helpers/test_framework.sh"

# Configuration
readonly VAL_DIR="$(dirname "${BASH_SOURCE[0]}")"
readonly TEST_LAB_DIR="/home/es/lab"

# Test categories
declare -A TEST_CATEGORIES=(
    ["core"]="Core system tests"
    ["lib"]="Library function tests"
    ["integration"]="Integration tests"
    ["legacy"]="Legacy validation scripts"
    ["all"]="All test categories"
)

# Test discovery
discover_tests() {
    local category="$1"
    local tests=()
    
    case "$category" in
        "core")
            tests+=($(find "$VAL_DIR/core" -name "*_test.sh" -type f 2>/dev/null | sort))
            ;;
        "lib")
            tests+=($(find "$VAL_DIR/lib" -name "*_test.sh" -type f 2>/dev/null | sort))
            ;;
        "integration")
            tests+=($(find "$VAL_DIR/integration" -name "*_test.sh" -type f 2>/dev/null | sort))
            ;;
        "legacy")
            # Legacy scripts (existing ones)
            local legacy_scripts=("system" "environment" "refactor" "complete_refactor" 
                                 "gpu_refactoring" "gpu_wrappers" "verbosity_controls")
            for script in "${legacy_scripts[@]}"; do
                if [[ -f "$VAL_DIR/$script" ]]; then
                    tests+=("$VAL_DIR/$script")
                fi
            done
            ;;
        "all"|*)
            tests+=($(discover_tests "core"))
            tests+=($(discover_tests "lib"))
            tests+=($(discover_tests "integration"))
            tests+=($(discover_tests "legacy"))
            ;;
    esac
    
    printf '%s\n' "${tests[@]}"
}

# Execute test
run_single_test() {
    local test_script="$1"
    local test_name="$(basename "$test_script" .sh)"
    
    echo -e "${BLUE}[RUNNER]${NC} Executing: $test_name"
    
    if [[ -x "$test_script" ]]; then
        if "$test_script"; then
            test_success "Test completed: $test_name"
            return 0
        else
            test_failure "Test failed: $test_name"
            return 1
        fi
    else
        test_warning "Test not executable: $test_name"
        return 1
    fi
}

# Execute legacy validation script
run_legacy_script() {
    local script="$1"
    local script_name="$(basename "$script")"
    
    echo -e "${BLUE}[LEGACY]${NC} Running: $script_name"
    
    cd "$TEST_LAB_DIR" || {
        test_failure "Cannot change to lab directory"
        return 1
    }
    
    if "$script" >/dev/null 2>&1; then
        test_success "Legacy validation: $script_name"
        return 0
    else
        test_failure "Legacy validation failed: $script_name" 
        return 1
    fi
}

# Display usage
show_usage() {
    cat << EOF
Usage: $0 [CATEGORY] [OPTIONS]

Test Categories:
EOF
    for category in "${!TEST_CATEGORIES[@]}"; do
        printf "  %-12s %s\n" "$category" "${TEST_CATEGORIES[$category]}"
    done
    
    cat << EOF

Options:
  -h, --help      Show this help message
  -l, --list      List available tests
  -v, --verbose   Verbose output
  -q, --quick     Quick tests only (skip slow integration tests)
  
Examples:
  $0                    # Run all tests
  $0 core              # Run only core tests  
  $0 lib               # Run only library tests
  $0 integration       # Run only integration tests
  $0 legacy            # Run only legacy validation scripts
  $0 --list            # Show available tests
EOF
}

# List available tests
list_tests() {
    local category="${1:-all}"
    
    echo "Available tests for category: $category"
    echo "======================================="
    
    local tests
    readarray -t tests < <(discover_tests "$category")
    
    if [[ ${#tests[@]} -eq 0 ]]; then
        echo "No tests found for category: $category"
        return 1
    fi
    
    for test in "${tests[@]}"; do
        local test_name="$(basename "$test" .sh)"
        local test_type="NEW"
        
        # Determine test type
        if [[ "$test" =~ /core/ ]]; then
            test_type="CORE"
        elif [[ "$test" =~ /lib/ ]]; then
            test_type="LIB"
        elif [[ "$test" =~ /integration/ ]]; then
            test_type="INTEGRATION"
        elif [[ ! "$test" =~ _test\.sh$ ]]; then
            test_type="LEGACY"
        fi
        
        printf "  [%s] %s\n" "$test_type" "$test_name"
    done
    
    echo
    echo "Total tests: ${#tests[@]}"
}

# Main test execution
run_tests() {
    local category="${1:-all}"
    local verbose="${2:-false}"
    local quick="${3:-false}"
    
    framework_init
    
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    VALIDATION SUITE                           ║${NC}"
    echo -e "${PURPLE}║                 Category: $(printf "%-8s" "$category")                        ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    local tests
    readarray -t tests < <(discover_tests "$category")
    
    if [[ ${#tests[@]} -eq 0 ]]; then
        test_failure "No tests found for category: $category"
        return 1
    fi
    
    echo -e "${CYAN}Found ${#tests[@]} tests to execute${NC}"
    echo
    
    local failed_tests=()
    local skipped_tests=()
    
    for test in "${tests[@]}"; do
        local test_name="$(basename "$test" .sh)"
        
        # Skip slow tests in quick mode
        if [[ "$quick" == "true" ]] && [[ "$test_name" =~ (integration|complete) ]]; then
            test_skip "Skipping slow test: $test_name (quick mode)"
            skipped_tests+=("$test_name")
            continue
        fi
        
        # Execute test based on type
        if [[ "$test" =~ _test\.sh$ ]]; then
            if ! run_single_test "$test"; then
                failed_tests+=("$test_name")
            fi
        else
            if ! run_legacy_script "$test"; then
                failed_tests+=("$test_name")
            fi
        fi
        
        echo  # Add spacing between tests
    done
    
    # Final summary
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                        SUITE SUMMARY${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo "Category: $category"
    echo "Total Tests: ${#tests[@]}"
    echo "Skipped: ${#skipped_tests[@]}"
    echo "Failed: ${#failed_tests[@]}"
    echo "Passed: $((${#tests[@]} - ${#failed_tests[@]} - ${#skipped_tests[@]}))"
    
    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${failed_tests[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
    fi
    
    if [[ ${#skipped_tests[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Skipped Tests:${NC}"
        for test in "${skipped_tests[@]}"; do
            echo -e "  ${YELLOW}⊘${NC} $test"
        done
    fi
    
    # Return appropriate exit code
    [[ ${#failed_tests[@]} -eq 0 ]]
}

# Parse command line arguments
main() {
    local category="all"
    local verbose="false"
    local quick="false"
    local list_only="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                list_only="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                shift
                ;;
            -q|--quick)
                quick="true"
                shift
                ;;
            core|lib|integration|legacy|all)
                category="$1"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate category
    if [[ ! "${TEST_CATEGORIES[$category]:-}" ]]; then
        echo "Invalid category: $category"
        show_usage
        exit 1
    fi
    
    # Execute based on mode
    if [[ "$list_only" == "true" ]]; then
        list_tests "$category"
    else
        run_tests "$category" "$verbose" "$quick"
    fi
}

# Make sure we're in the right directory
cd "$TEST_LAB_DIR" || {
    echo "Error: Cannot change to lab directory: $TEST_LAB_DIR"
    exit 1
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
