#!/bin/bash
#######################################################################
# Core Tests - TME Module (Timing and Monitoring)
#######################################################################
# File: val/core/modules/tme_test.sh
# Description: Comprehensive tests for the timing and monitoring engine
#              including performance tracking, verbosity controls, and
#              nested output management.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"
readonly TME_LIB="$TEST_LAB_DIR/lib/core/tme"

# Test functions
test_tme_module_exists() {
    test_file_exists "$TME_LIB" "TME module exists"
}

test_tme_module_sourceable() {
    # Try to source TME module, handling verification dependency gracefully
    local test_env=$(create_test_env "tme_source")
    
    cat > "$test_env/test_source.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Define a minimal ver_verify_module function for testing
ver_verify_module() { return 0; }

# Try to source the TME module
if source lib/core/tme 2>/dev/null; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_source.sh"
    
    run_test "TME module can be sourced" "$test_env/test_source.sh"
    cleanup_test_env "$test_env"
}

test_tme_core_functions() {
    local test_env=$(create_test_env "tme_functions")
    
    cat > "$test_env/test_functions.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/core/tme 2>/dev/null

# Test that core TME functions exist
if declare -f tme_start_timer >/dev/null && \
   declare -f tme_end_timer >/dev/null && \
   declare -f tme_print_timing_report >/dev/null && \
   declare -f tme_set_output >/dev/null; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_functions.sh"
    
    run_test "TME core functions are available" "$test_env/test_functions.sh"
    cleanup_test_env "$test_env"
}

test_timing_functionality() {
    local test_env=$(create_test_env "tme_timing")
    
    cat > "$test_env/test_timing.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/core/tme 2>/dev/null

# Test basic timing functionality
tme_start_timer "TEST_OPERATION" 2>/dev/null

# Simulate some work
sleep 0.1

if tme_end_timer "TEST_OPERATION" "success" 2>/dev/null; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_timing.sh"
    
    run_test "Basic timing functionality" "$test_env/test_timing.sh"
    cleanup_test_env "$test_env"
}

test_verbosity_controls() {
    local test_env=$(create_test_env "tme_verbosity")
    
    cat > "$test_env/test_verbosity.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/core/tme 2>/dev/null

# Test verbosity control functions
success=true

# Test setting different verbosity levels
for level in on off; do
    if tme_set_output "timing" "$level" 2>/dev/null; then
        echo "Set timing to $level: OK"
    else
        echo "Set timing to $level: FAIL"
        success=false
    fi
done

$success && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_verbosity.sh"
    
    run_test "Verbosity control functionality" "$test_env/test_verbosity.sh"
    cleanup_test_env "$test_env"
}

test_nested_timing() {
    local test_env=$(create_test_env "tme_nested")
    
    cat > "$test_env/test_nested.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/core/tme 2>/dev/null

# Test nested timing operations
tme_start_timer "OUTER_OPERATION" 2>/dev/null
sleep 0.05

tme_start_timer "INNER_OPERATION" 2>/dev/null
sleep 0.05
tme_end_timer "INNER_OPERATION" "success" 2>/dev/null

tme_end_timer "OUTER_OPERATION" "success" 2>/dev/null

exit 0
EOF
    chmod +x "$test_env/test_nested.sh"
    
    run_test "Nested timing operations" "$test_env/test_nested.sh"
    cleanup_test_env "$test_env"
}

test_timing_report() {
    local test_env=$(create_test_env "tme_report")
    
    cat > "$test_env/test_report.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/core/tme 2>/dev/null

# Create some timing data
tme_start_timer "REPORT_TEST" 2>/dev/null
sleep 0.1
tme_end_timer "REPORT_TEST" "success" 2>/dev/null

# Test that timing report can be generated
if report_output=$(tme_print_timing_report 2>/dev/null); then
    if echo "$report_output" | grep -q "REPORT_TEST"; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_report.sh"
    
    run_test "Timing report generation" "$test_env/test_report.sh"
    cleanup_test_env "$test_env"
}

test_output_categories() {
    local test_env=$(create_test_env "tme_categories")
    
    cat > "$test_env/test_categories.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/core/tme 2>/dev/null

# Test different output categories
categories=("timing" "debug" "status" "report")
success=true

for category in "${categories[@]}"; do
    if tme_set_output "$category" "on" 2>/dev/null; then
        echo "Category $category: OK"
    else
        echo "Category $category: FAIL"
        success=false
    fi
done

$success && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_categories.sh"
    
    run_test "Output category management" "$test_env/test_categories.sh"
    cleanup_test_env "$test_env"
}

test_performance_monitoring() {
    start_performance_test "TME timer operations"
    
    local test_env=$(create_test_env "tme_performance")
    cat > "$test_env/perf_test.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/core/tme 2>/dev/null

# Test performance of multiple timer operations
for i in {1..20}; do
    tme_start_timer "PERF_TEST_$i" >/dev/null 2>&1
    tme_end_timer "PERF_TEST_$i" "success" >/dev/null 2>&1
done
EOF
    chmod +x "$test_env/perf_test.sh"
    
    "$test_env/perf_test.sh"
    cleanup_test_env "$test_env"
    
    end_performance_test "TME timer operations" 1000  # 1 second threshold
}

test_environment_integration() {
    local test_env=$(create_test_env "tme_integration")
    
    cat > "$test_env/test_integration.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test that TME integrates with the initialization system
if source bin/ini 2>/dev/null; then
    # TME should be loaded automatically
    if declare -f tme_start_timer >/dev/null; then
        # Test that it works in the integrated environment
        tme_start_timer "INTEGRATION_TEST" 2>/dev/null
        tme_end_timer "INTEGRATION_TEST" "success" 2>/dev/null
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_integration.sh"
    
    run_test "TME integration with initialization" "$test_env/test_integration.sh"
    cleanup_test_env "$test_env"
}

# Main execution
main() {
    run_test_suite "TME MODULE TESTS" \
        test_tme_module_exists \
        test_tme_module_sourceable \
        test_tme_core_functions \
        test_timing_functionality \
        test_verbosity_controls \
        test_nested_timing \
        test_timing_report \
        test_output_categories \
        test_performance_monitoring \
        test_environment_integration
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
