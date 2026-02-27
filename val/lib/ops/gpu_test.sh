#!/bin/bash
#######################################################################
# Library Tests - GPU Operations
#######################################################################
# File: val/lib/ops/gpu_test.sh
# Description: Comprehensive tests for GPU operations library focused on
#              sourceability, function availability, parameter validation,
#              and non-destructive surface behavior.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="$LAB_ROOT"
readonly GPU_LIB="$TEST_LAB_DIR/lib/ops/gpu"
readonly GPU_DIC="$TEST_LAB_DIR/src/dic/ops"

# Setup for tests
setup_gpu_environment() {
    export LAB_DIR="$TEST_LAB_DIR"
    cd "$LAB_DIR"
    
    # Source initialization to get environment
    if ! source bin/ini 2>/dev/null; then
        test_warning "Could not load full environment for GPU tests"
        return 1
    fi
    return 0
}

# Core function tests
test_gpu_library_exists() {
    test_file_exists "$GPU_LIB" "GPU operations library exists"
}

test_gpu_library_sourceable() {
    test_source "$GPU_LIB" "GPU library can be sourced"
}

test_gpu_pure_functions() {
    local test_env=$(create_test_env "gpu_pure_functions")
    
    cat > "$test_env/test_pure.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

# Source the pure GPU library
source lib/ops/gpu 2>/dev/null

# Test core GPU functions exist
if declare -f gpu_fun >/dev/null && \
   declare -f gpu_var >/dev/null && \
   declare -f gpu_pts >/dev/null; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_pure.sh"
    
    run_test "GPU pure functions are available" "$test_env/test_pure.sh"
    cleanup_test_env "$test_env"
}

test_gpu_function_parameters() {
    # Test that functions accept explicit parameters
    local test_env=$(create_test_env "gpu_parameters")
    
cat > "$test_env/test_params.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

source bin/ini 2>/dev/null

# Test gpu_var with explicit execution flag
if gpu_var -x >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_params.sh"
    
    run_test "GPU functions accept explicit parameters" "$test_env/test_params.sh"
    cleanup_test_env "$test_env"
}

# Extended availability checks
test_gpu_management_exists() {
    test_file_exists "$GPU_DIC" "GPU DIC operations exists"
}

test_gpu_core_functions_available() {
    if ! setup_gpu_environment; then
        test_skip "GPU core function availability tests (environment not available)"
        return
    fi
    
    test_function_exists "gpu_fun" "GPU function overview exists"
    test_function_exists "gpu_var" "GPU variable overview exists"
    test_function_exists "gpu_pts" "GPU status function exists"
}

test_gpu_non_destructive_execution() {
    if ! setup_gpu_environment; then
        test_skip "GPU non-destructive execution tests (environment not available)"
        return
    fi
    
    local test_env=$(create_test_env "gpu_wrapper_exec")
    
cat > "$test_env/test_surface.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

source bin/ini 2>/dev/null

# Test that non-destructive functions can execute
if gpu_fun >/dev/null 2>&1 && \
   gpu_var -x >/dev/null 2>&1 && \
   gpu_pts --help >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_surface.sh"
    
    run_test "GPU non-destructive functions execute successfully" "$test_env/test_surface.sh"
    cleanup_test_env "$test_env"
}

test_gpu_status_functionality() {
    if ! setup_gpu_environment; then
        test_skip "GPU status functionality tests (environment not available)"
        return
    fi
    
    # Test that gpu_pts provides meaningful status information
    local output
    if output=$(gpu_pts --help 2>/dev/null); then
        if echo "$output" | grep -q -E "(GPU|Status|PCI|Device)"; then
            test_success "GPU status provides meaningful output"
        else
            test_warning "GPU status output may be empty (no GPU hardware?)"
        fi
    else
        test_warning "GPU status function execution failed"
    fi
}

test_gpu_configuration_access() {
    if ! setup_gpu_environment; then
        test_skip "GPU configuration access tests (environment not available)"
        return
    fi
    
    # Test that GPU configuration can be accessed
    local output
    if output=$(gpu_var --help 2>/dev/null); then
        if [[ -n "$output" ]]; then
            test_success "GPU configuration is accessible"
        else
            test_info "GPU configuration is empty (may be normal)"
        fi
    else
        test_warning "GPU configuration access failed"
    fi
}

test_gpu_refactoring_compliance() {
    # Test that the refactoring pattern is followed correctly
    local test_env=$(create_test_env "gpu_refactoring")
    
    cat > "$test_env/test_refactoring.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

# Source pure library
source lib/ops/gpu 2>/dev/null

# Source initialization for wrappers
source bin/ini 2>/dev/null

# Test that core functions exist
pure_functions_exist=false
if declare -f gpu_fun >/dev/null && declare -f gpu_var >/dev/null; then
    pure_functions_exist=true
fi

if $pure_functions_exist; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_refactoring.sh"
    
    run_test "GPU refactoring pattern compliance" "$test_env/test_refactoring.sh"
    cleanup_test_env "$test_env"
}

test_gpu_performance() {
    if ! setup_gpu_environment; then
        test_skip "GPU performance tests (environment not available)"
        return
    fi
    
    start_performance_test "GPU wrapper execution"
    gpu_pts --help >/dev/null 2>&1
    end_performance_test "GPU wrapper execution" 3000  # 3 second threshold
}

# Error handling tests
test_gpu_error_handling() {
    local test_env=$(create_test_env "gpu_error_handling")
    
    cat > "$test_env/test_errors.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="$LAB_ROOT"
cd "$LAB_DIR"

source lib/ops/gpu 2>/dev/null

# Test that functions handle invalid parameters gracefully
if gpu_var "" 2>/dev/null; then
    # Should not succeed with empty parameter
    exit 1
else
    # Should fail gracefully
    exit 0
fi
EOF
    chmod +x "$test_env/test_errors.sh"
    
    run_test "GPU functions handle errors gracefully" "$test_env/test_errors.sh"
    cleanup_test_env "$test_env"
}

# Main execution
main() {
    run_test_suite "GPU OPERATIONS LIBRARY TESTS" \
        test_gpu_library_exists \
        test_gpu_library_sourceable \
        test_gpu_pure_functions \
        test_gpu_function_parameters \
        test_gpu_management_exists \
        test_gpu_core_functions_available \
        test_gpu_non_destructive_execution \
        test_gpu_status_functionality \
        test_gpu_configuration_access \
        test_gpu_refactoring_compliance \
        test_gpu_performance \
        test_gpu_error_handling
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
