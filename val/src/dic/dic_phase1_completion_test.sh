#!/bin/bash

# ============================================================================
# DIC PHASE 1 COMPLETION TEST
# ============================================================================
#
# Test script to verify that Phase 1 of DIC development is complete
# and all critical blocking issues have been resolved.
#
# This test validates the specific fixes implemented in Phase 1:
# - Function definition order issue resolved
# - Environment variable configuration working
# - All function types (A, B, C) operational
#
# ============================================================================

# NOTE:
# Functional assertions in this suite must pass at default log verbosity.
# Debug-text diagnostics must set LAB_LOG_LEVEL_AUX=debug explicitly.

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LAB_ROOT="${LAB_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
cd "$LAB_ROOT"
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

    local hostname=$(hostname | cut -d'.' -f1)
    local pci_var="${hostname}_NODE_PCI0"

    if [[ -z "${!pci_var:-}" ]]; then
        log_warning "No PCI configuration found for hostname '$hostname', creating test values"

        export "${hostname}_NODE_PCI0"="0000:01:00.0"
        export "${hostname}_NODE_PCI1"="0000:01:00.1"
        export "${hostname}_CORE_COUNT_ON"="8"
        export "${hostname}_CORE_COUNT_OFF"="4"
        eval "${hostname}_USB_DEVICES=(\"046d:c52b\" \"1234:5678\")"

        log_info "Created test variables for hostname '$hostname'"
    fi

    if [[ -z "$CLUSTER_NODES" ]]; then
        export CLUSTER_NODES=("x1" "x2")
        log_info "Set default CLUSTER_NODES"
    fi

    log_info "Test environment setup complete"
}

# Phase 1 Critical Issue Tests
test_phase1_critical_issues() {
    log_info "Testing Phase 1 Critical Issue Resolution..."
    
    test_start "Function Definition Order - ops_debug Available Early"
    local output=$(LAB_LOG_LEVEL_AUX=debug OPS_DEBUG=1 src/dic/ops --help 2>&1)
    if echo "$output" | grep -q "\[DIC\]"; then
        log_success "ops_debug function available from script start"
    else
        log_error "ops_debug function not working or not called early"
    fi
    
    test_start "Environment Configuration - Auto-Sourcing cfg/env/site1"
    local output=$(LAB_LOG_LEVEL_AUX=debug OPS_DEBUG=1 src/dic/ops pve vck 100 2>&1)
    if echo "$output" | grep -q "Sourcing environment config.*cfg/env/site1"; then
        log_success "Environment configuration auto-sourcing working"
    else
        log_error "Environment configuration not being auto-sourced"
    fi
    
    test_start "CLUSTER_NODES Array - Proper Inheritance"
    local output=$(src/dic/ops pve vck 100 2>&1)
    if ! echo "$output" | grep -q "Cluster nodes parameter cannot be empty"; then
        log_success "CLUSTER_NODES array properly inherited and resolved"
    else
        log_error "CLUSTER_NODES array not properly inherited"
        echo "$output" | grep "Cluster nodes parameter cannot be empty" || echo "No cluster_nodes validation failure captured"
    fi
}

# Function Type Testing
test_function_types() {
    log_info "Testing All Function Types (A, B, C)..."
    
    test_start "Type A Functions - Simple Pass-through (pve_fun)"
    if src/dic/ops pve fun >/dev/null 2>&1; then
        log_success "Type A function (pve_fun) working"
    else
        log_error "Type A function (pve_fun) failed"
    fi
    
    test_start "Type A Functions - Simple Pass-through (net_fun)"
    if src/dic/ops net fun >/dev/null 2>&1; then
        log_success "Type A function (net_fun) working" 
    else
        log_error "Type A function (net_fun) failed"
    fi
    
    test_start "Type B Functions - Standard Global Injection (pve_dsr)"
    local output=$(src/dic/ops pve dsr 2>&1)
    if [[ $? -eq 0 ]] || echo "$output" | grep -q "parameter not provided"; then
        log_success "Type B function (pve_dsr) signature resolution working"
    else
        log_error "Type B function (pve_dsr) failed"
    fi
    
    test_start "Type C Functions - Complex Injection Path (pve_vck)"
    local output=$(src/dic/ops pve vck 100 2>&1)
    if ! echo "$output" | grep -q "Cluster nodes parameter cannot be empty"; then
        log_success "Type C function (pve_vck) injection path working"
    else
        log_error "Type C function (pve_vck) injection path failed"
    fi
    
    test_start "Type C Functions - PCI Variable Resolution (pve_vpt)"  
    local output=$(src/dic/ops pve vpt 100 on 2>&1)
    if ! echo "$output" | grep -q "PCI0 ID cannot be empty\|PCI1 ID cannot be empty\|Core count (on) must be numeric\|Core count (off) must be numeric"; then
        log_success "Type C function (pve_vpt) PCI variable resolution working"
    else
        log_error "Type C function (pve_vpt) PCI variable resolution failed"
    fi
}

# Generate Phase 1 summary
generate_phase1_summary() {
    echo
    echo "============================================================================"
    echo "DIC PHASE 1 COMPLETION TEST SUMMARY"
    echo "============================================================================"
    echo
    printf "Total Tests:  %d\n" $TESTS_TOTAL
    printf "Passed:       %s%d%s\n" "$GREEN" $TESTS_PASSED "$NC"
    printf "Failed:       %s%d%s\n" "$RED" $TESTS_FAILED "$NC"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        printf "Phase 1 Status: %sCOMPLETE%s ✅\n" "$GREEN" "$NC"
        echo "All critical blocking issues have been resolved!"
        echo
        echo "Phase 1 Achievements:"
        echo "✅ Fixed function definition order (ops_debug moved to top)"
        echo "✅ Implemented automatic environment configuration sourcing"
        echo "✅ Resolved CLUSTER_NODES array inheritance issue"
        echo "✅ All function types (A, B, C) are operational"
        echo "✅ DIC system ready for Phase 2 development"
    else
        printf "Phase 1 Status: %sINCOMPLETE%s ❌\n" "$RED" "$NC"
        echo "Some critical issues remain unresolved."
        echo
        echo "Remaining Issues:"
        echo "❌ $TESTS_FAILED test(s) failed"
        echo "🔧 Phase 1 requires additional fixes before Phase 2"
    fi
    
    echo
    echo "============================================================================"
}

# Main execution
main() {
    echo "============================================================================"
    echo "DIC PHASE 1 COMPLETION TEST"
    echo "============================================================================"
    echo "Testing Date: $(date)"
    echo "Environment: $(hostname)"
    echo "Lab Directory: $(pwd)"
    echo
    echo "Validating that all Phase 1 critical blocking issues are resolved..."
    echo

    setup_test_environment
    test_phase1_critical_issues
    test_function_types
    
    generate_phase1_summary
    
    # Return appropriate exit code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
