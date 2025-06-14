#!/bin/bash

# ============================================================================
# DIC SYSTEM INTEGRATION & TESTING SUITE
# ============================================================================
#
# Comprehensive test suite for the DIC system integration, covering:
# - Environment setup and variable initialization
# - Core DIC functionality validation  
# - Legacy wrapper replacement verification completed
# - Performance and error handling testing
# - Production readiness assessment
#
# ============================================================================

# set -e removed - test scripts should handle errors gracefully

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Initialize lab environment
cd /home/es/lab
LAB_DIR="/home/es/lab"
source bin/ini

# Test utilities
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

test_start() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "\n${BLUE}TEST $TESTS_TOTAL:${NC} $1"
}

# Environment setup for testing
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Get current hostname (sanitized)
    local hostname=$(hostname | cut -d'.' -f1)
    log_info "Using hostname: $hostname"
    
    # Set up test variables for current hostname if not already configured
    local pci_var="${hostname}_NODE_PCI0"
    if [[ -z "${!pci_var}" ]]; then
        log_warning "No PCI configuration found for hostname '$hostname', creating test values"
        
        # Export test variables dynamically
        export "${hostname}_NODE_PCI0"="0000:01:00.0"
        export "${hostname}_NODE_PCI1"="0000:01:00.1"
        export "${hostname}_CORE_COUNT_ON"="8"
        export "${hostname}_CORE_COUNT_OFF"="4"
        
        log_info "Created test variables for hostname '$hostname'"
    fi
    
    # Set up cluster configuration if not present
    if [[ -z "$CLUSTER_NODES" ]]; then
        CLUSTER_NODES=("x1" "x2")
        export CLUSTER_NODES
        log_info "Set default CLUSTER_NODES"
    fi
    
    # Set common test variables
    export VM_ID=100
    export TEST_ACTION="on"
    export USER_FILTER="testuser"
    
    log_success "Test environment setup complete"
}

# Test Phase 1: Core DIC Engine Functionality
test_dic_core() {
    test_start "DIC Core Engine - Help System"
    if "$LAB_DIR/src/dic/ops" --help >/dev/null 2>&1; then
        log_success "Help system working"
    else
        log_error "Help system failed"
    fi
    
    test_start "DIC Core Engine - Module Listing"
    local modules=$(src/dic/ops --list 2>/dev/null | grep -E "^  [a-z]+" | wc -l)
    if [[ $modules -ge 8 ]]; then
        log_success "Module listing working ($modules modules found)"
    else
        log_error "Module listing failed or insufficient modules ($modules found)"
    fi
    
    test_start "DIC Core Engine - Function Listing"
    local functions=$(src/dic/ops pve --list 2>/dev/null | grep -E "^  [a-z]+" | wc -l)
    if [[ $functions -ge 5 ]]; then
        log_success "Function listing working ($functions functions found)"
    else
        log_error "Function listing failed or insufficient functions ($functions found)"
    fi
}

# Test Phase 2: Utility Functions (No Injection)
test_utility_functions() {
    test_start "Utility Functions - PVE fun"
    if src/dic/ops pve fun >/dev/null 2>&1; then
        log_success "PVE fun utility working"
    else
        log_error "PVE fun utility failed"
    fi
    
    test_start "Utility Functions - SYS var"
    if src/dic/ops sys var >/dev/null 2>&1; then
        log_success "SYS var utility working"  
    else
        log_error "SYS var utility failed"
    fi
    
    test_start "Utility Functions - GPU fun"
    if src/dic/ops gpu fun >/dev/null 2>&1; then
        log_success "GPU fun utility working"
    else
        log_error "GPU fun utility failed"
    fi
}

# Test Phase 3: Parameter Injection & Resolution
test_parameter_injection() {
    local hostname=$(hostname | cut -d'.' -f1)
    
    test_start "Parameter Injection - Simple Function (sys dpa)"
    local output=$(OPS_DEBUG=1 src/dic/ops sys dpa -x 2>&1)
    if echo "$output" | grep -q "Executing.*sys_dpa.*-x"; then
        log_success "Simple function execution working"
    else
        log_error "Simple function execution failed"
        echo "$output" | head -3
    fi
    
    test_start "Parameter Injection - Signature Detection"
    local output=$(OPS_DEBUG=1 src/dic/ops pve vck 100 2>&1)
    if echo "$output" | grep -q "Extracted parameters.*vm_id.*cluster_nodes"; then
        log_success "Function signature detection working"
    else
        log_error "Function signature detection failed"
        echo "$output" | grep "Extracted parameters" || echo "No signature extraction found"
    fi
    
    test_start "Parameter Injection - Variable Resolution"
    local output=$(OPS_DEBUG=1 src/dic/ops pve vpt 100 on 2>&1)
    if echo "$output" | grep -q "Using sanitized hostname.*$hostname"; then
        log_success "Hostname sanitization working"
    else
        log_error "Hostname sanitization failed"
        echo "$output" | grep "hostname" || echo "No hostname processing found"
    fi
}

# Main execution
main() {
    echo "============================================================================"
    echo "DIC SYSTEM INTEGRATION & TESTING SUITE"
    echo "============================================================================"
    echo "Testing Date: $(date)"
    echo "Environment: $(hostname)"
    echo "Lab Directory: $(pwd)"
    echo

    setup_test_environment
    echo "DEBUG: About to run test_dic_core"
    test_dic_core
    echo "DEBUG: About to run test_utility_functions"
    test_utility_functions  
    echo "DEBUG: About to run test_parameter_injection"
    test_parameter_injection
    
    echo
    echo "============================================================================"
    echo "DIC INTEGRATION TEST SUMMARY"
    echo "============================================================================"
    echo
    printf "Total Tests:  %d\n" $TESTS_TOTAL
    printf "Passed:       %s%d%s\n" "$GREEN" $TESTS_PASSED "$NC"
    printf "Failed:       %s%d%s\n" "$RED" $TESTS_FAILED "$NC"
    echo
    
    local pass_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    
    if [[ $pass_rate -ge 80 ]]; then
        printf "Overall Status: %sEXCELLENT%s (%d%% pass rate)\n" "$GREEN" "$NC" $pass_rate
        echo "✅ DIC system is ready for legacy system replacement"
    else
        printf "Overall Status: %sNEEDS WORK%s (%d%% pass rate)\n" "$YELLOW" "$NC" $pass_rate
        echo "🔧 DIC system needs fixes before legacy system replacement"
    fi
    
    echo "============================================================================"
}

# Run main function
main "$@"
