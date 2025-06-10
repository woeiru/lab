#!/bin/bash
#######################################################################
# Test Framework - Core Testing Utilities
#######################################################################
# File: val/helpers/test_framework.sh
# Description: Common testing framework for all validation scripts
#              providing standardized test functions, assertions,
#              and reporting capabilities.
#
# Usage: source val/helpers/test_framework.sh
#
# Features:
#   - Standardized test execution
#   - Color-coded output
#   - Test counters and reporting
#   - Error handling
#   - Test isolation
#   - Performance timing
#######################################################################

# Test framework globals
FRAMEWORK_TESTS_RUN=0
FRAMEWORK_TESTS_PASSED=0
FRAMEWORK_TESTS_FAILED=0
FRAMEWORK_START_TIME=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Framework initialization
framework_init() {
    FRAMEWORK_START_TIME=$(date +%s)
    
    # Set LAB_ROOT if not already set
    if [[ -z "$LAB_ROOT" ]]; then
        # Start from the script's directory
        LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        
        # Navigate up to find the lab root (look for bin/ini or README.md)
        while [[ "$LAB_ROOT" != "/" ]]; do
            if [[ -f "$LAB_ROOT/bin/ini" ]] && [[ -d "$LAB_ROOT/lib" ]] && [[ -d "$LAB_ROOT/cfg" ]]; then
                break
            fi
            LAB_ROOT="$(dirname "$LAB_ROOT")"
        done
        
        # Fallback to /home/es/lab if not found
        if [[ "$LAB_ROOT" == "/" ]] || [[ ! -d "$LAB_ROOT/lib" ]]; then
            LAB_ROOT="/home/es/lab"
        fi
        export LAB_ROOT
    fi
    
    echo -e "${BLUE}[FRAMEWORK]${NC} Test framework initialized (LAB_ROOT: $LAB_ROOT)"
}

# Logging functions
test_log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

test_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

test_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((FRAMEWORK_TESTS_PASSED++))
}

test_failure() {
    echo -e "${RED}✗${NC} $1"
    ((FRAMEWORK_TESTS_FAILED++))
}

test_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

test_skip() {
    echo -e "${YELLOW}⊘${NC} $1 (skipped)"
}

# Core test execution function
run_test() {
    local test_name="$1"
    shift
    ((FRAMEWORK_TESTS_RUN++))
    
    test_log "Running: $test_name"
    
    if "$@" >/dev/null 2>&1; then
        test_success "$test_name"
        return 0
    else
        test_failure "$test_name"
        return 1
    fi
}

# Test function existence
test_function_exists() {
    local func_name="$1"
    local description="${2:-Function $func_name exists}"
    
    run_test "$description" declare -f "$func_name"
}

# Test file existence
test_file_exists() {
    local file_path="$1"
    local description="${2:-File $file_path exists}"
    
    run_test "$description" test -f "$file_path"
}

# Test directory existence
test_dir_exists() {
    local dir_path="$1"
    local description="${2:-Directory $dir_path exists}"
    
    run_test "$description" test -d "$dir_path"
}

# Test command availability
test_command_exists() {
    local command="$1"
    local description="${2:-Command $command is available}"
    
    run_test "$description" command -v "$command"
}

# Test variable is set
test_var_set() {
    local var_name="$1"
    local description="${2:-Variable $var_name is set}"
    
    run_test "$description" test -n "${!var_name:-}"
}

# Test sourcing capability
test_source() {
    local file_path="$1"
    local description="${2:-Can source $file_path}"
    
    run_test "$description" source "$file_path"
}

# Advanced test: function with specific output
test_function_output() {
    local func_name="$1"
    local expected_pattern="$2"
    local description="${3:-Function $func_name produces expected output}"
    
    ((FRAMEWORK_TESTS_RUN++))
    test_log "Running: $description"
    
    local output
    if output=$($func_name 2>/dev/null) && echo "$output" | grep -q "$expected_pattern"; then
        test_success "$description"
        return 0
    else
        test_failure "$description"
        return 1
    fi
}

# Test with timeout
test_with_timeout() {
    local timeout_seconds="$1"
    local test_name="$2"
    shift 2
    
    ((FRAMEWORK_TESTS_RUN++))
    test_log "Running: $test_name (timeout: ${timeout_seconds}s)"
    
    if timeout "$timeout_seconds" "$@" >/dev/null 2>&1; then
        test_success "$test_name"
        return 0
    else
        test_failure "$test_name (timed out or failed)"
        return 1
    fi
}

# Test group execution
run_test_group() {
    local group_name="$1"
    shift
    
    echo
    echo -e "${PURPLE}═══ $group_name ═══${NC}"
    
    local group_start=$FRAMEWORK_TESTS_RUN
    
    # Run all test functions passed as parameters
    for test_func in "$@"; do
        if declare -f "$test_func" >/dev/null 2>&1; then
            $test_func
        else
            test_failure "Test function $test_func not found"
        fi
    done
    
    local group_total=$((FRAMEWORK_TESTS_RUN - group_start))
    echo -e "${PURPLE}═══ $group_name Complete ($group_total tests) ═══${NC}"
}

# Performance testing
start_performance_test() {
    local test_name="$1"
    echo -e "${CYAN}⏱${NC} Starting performance test: $test_name"
    PERF_START_TIME=$(date +%s%N)
}

end_performance_test() {
    local test_name="$1"
    local threshold_ms="${2:-1000}"  # Default 1 second threshold
    
    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - PERF_START_TIME) / 1000000 ))
    
    if [ $duration_ms -le $threshold_ms ]; then
        test_success "Performance test: $test_name (${duration_ms}ms)"
    else
        test_warning "Performance test: $test_name (${duration_ms}ms, threshold: ${threshold_ms}ms)"
    fi
}

# Test isolation
create_test_env() {
    local test_name="$1"
    local test_dir="/tmp/val_test_${test_name}_$$"
    
    mkdir -p "$test_dir"
    chmod 700 "$test_dir"
    echo "$test_dir"
}

cleanup_test_env() {
    local test_dir="$1"
    
    if [[ -d "$test_dir" && "$test_dir" =~ ^/tmp/val_test_ ]]; then
        rm -rf "$test_dir"
    fi
}

# Test header and footer for formatted output
test_header() {
    local test_name="$1"
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║$(printf "%-38s" "          $test_name")║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    echo
}

test_footer() {
    echo
    print_test_summary
}

# Test summary and results
print_test_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - FRAMEWORK_START_TIME))
    
    echo
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}           TEST SUMMARY${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "Total Tests Run:     ${FRAMEWORK_TESTS_RUN}"
    echo -e "${GREEN}Tests Passed:        ${FRAMEWORK_TESTS_PASSED}${NC}"
    
    if [ $FRAMEWORK_TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Tests Failed:        ${FRAMEWORK_TESTS_FAILED}${NC}"
    else
        echo -e "Tests Failed:        ${FRAMEWORK_TESTS_FAILED}"
    fi
    
    echo -e "Execution Time:      ${duration}s"
    
    if [ $FRAMEWORK_TESTS_FAILED -eq 0 ] && [ $FRAMEWORK_TESTS_RUN -gt 0 ]; then
        echo -e "${GREEN}Status:              ALL TESTS PASSED${NC}"
        return 0
    else
        echo -e "${RED}Status:              SOME TESTS FAILED${NC}"
        return 1
    fi
}

# Main test execution wrapper
run_test_suite() {
    local suite_name="$1"
    shift
    
    framework_init
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║          $suite_name${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    
    # Run all test functions
    for test_func in "$@"; do
        if declare -f "$test_func" >/dev/null 2>&1; then
            $test_func
        else
            test_failure "Test suite function $test_func not found"
        fi
    done
    
    print_test_summary
}

# Export all functions
export -f framework_init test_log test_info test_success test_failure test_warning test_skip
export -f run_test test_function_exists test_file_exists test_dir_exists test_command_exists
export -f test_var_set test_source test_function_output test_with_timeout run_test_group
export -f start_performance_test end_performance_test create_test_env cleanup_test_env
export -f test_header test_footer print_test_summary run_test_suite

# Auto-initialize framework when sourced
framework_init
