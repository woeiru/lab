#!/bin/bash
#######################################################################
# Integration Tests - Complete Environment Workflow
#######################################################################
# File: val/integration/complete_workflow_test.sh
# Description: End-to-end integration testing for the complete
#              environment management workflow including system
#              initialization, component loading, and functionality.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"

# Integration test functions
test_complete_initialization() {
    local test_env=$(create_test_env "complete_init")
    
    cat > "$test_env/test_complete_init.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test complete initialization sequence
if source bin/ini 2>/dev/null; then
    # Verify core systems are operational
    if declare -f err_log >/dev/null && \
       declare -f lo1_log >/dev/null && \
       declare -f tme_start_timer >/dev/null && \
       declare -f ver_verify_path >/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_complete_init.sh"
    
    run_test "Complete system initialization" "$test_env/test_complete_init.sh"
    cleanup_test_env "$test_env"
}

test_environment_loading_workflow() {
    local test_env=$(create_test_env "env_workflow")
    
    cat > "$test_env/test_env_workflow.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test environment loading workflow
if source src/aux/set 2>/dev/null; then
    # Check if environment variables are properly set
    if [[ -n "${LAB_ROOT:-}" ]] && [[ -n "${SITE:-}" ]]; then
        # Test that infrastructure utilities are available
        if declare -f define_container >/dev/null; then
            exit 0
        else
            exit 1
        fi
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_env_workflow.sh"
    
    run_test "Environment loading workflow" "$test_env/test_env_workflow.sh"
    cleanup_test_env "$test_env"
}

test_component_integration() {
    local test_env=$(create_test_env "component_integration")
    
    cat > "$test_env/test_integration.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Load full environment
source bin/ini 2>/dev/null

# Test that different components can work together
success=true

# Test infrastructure + security integration
if source lib/gen/inf 2>/dev/null && source lib/gen/sec 2>/dev/null; then
    # Test creating a container definition with password
    if define_container 999 999 "testct" "192.168.1.999" 2>/dev/null; then
        if [[ "${CT_999_HOSTNAME}" == "testct" ]]; then
            echo "Container integration works"
        else
            success=false
        fi
    else
        success=false
    fi
else
    success=false
fi

$success && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_integration.sh"
    
    run_test "Component integration" "$test_env/test_integration.sh"
    cleanup_test_env "$test_env"
}

test_pure_wrapper_integration() {
    local test_env=$(create_test_env "pure_wrapper_integration")
    
    cat > "$test_env/test_pure_wrapper.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Load environment for wrappers
source bin/ini 2>/dev/null

# Test that pure functions and wrappers coexist
pure_available=false
wrapper_available=false

# Check pure functions (from lib/ops/pve)
source lib/ops/pve 2>/dev/null
if declare -f pve-fun >/dev/null; then
    pure_available=true
fi

# Check wrapper functions (loaded via bin/ini)
if declare -f pve-fun-w >/dev/null; then
    wrapper_available=true
fi

if $pure_available && $wrapper_available; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_pure_wrapper.sh"
    
    run_test "Pure function and wrapper integration" "$test_env/test_pure_wrapper.sh"
    cleanup_test_env "$test_env"
}

test_configuration_hierarchy() {
    local test_env=$(create_test_env "config_hierarchy")
    
    cat > "$test_env/test_config_hierarchy.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
export ENVIRONMENT="dev"
export NODE="w2"
cd "$LAB_DIR"

# Test configuration hierarchy loading
if source src/aux/set 2>/dev/null; then
    # Should load site1-dev-w2 configuration if available
    # or fall back appropriately
    if [[ "${ENVIRONMENT}" == "dev" ]] && [[ "${NODE}" == "w2" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_config_hierarchy.sh"
    
    run_test "Configuration hierarchy workflow" "$test_env/test_config_hierarchy.sh"
    cleanup_test_env "$test_env"
}

test_deployment_script_integration() {
    # Test that deployment scripts can work with the environment
    local scripts=("c1" "c2" "c3" "h1" "t1" "t2")
    local working_scripts=0
    
    for script in "${scripts[@]}"; do
        if [[ -f "$TEST_LAB_DIR/src/set/$script" ]] && [[ -x "$TEST_LAB_DIR/src/set/$script" ]]; then
            ((working_scripts++))
        fi
    done
    
    if [[ $working_scripts -ge 3 ]]; then
        test_success "Deployment scripts integration ($working_scripts/${#scripts[@]} scripts available)"
    else
        test_warning "Limited deployment script availability ($working_scripts/${#scripts[@]} scripts)"
    fi
}

test_logging_integration() {
    local test_env=$(create_test_env "logging_integration")
    
    cat > "$test_env/test_logging.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source bin/ini 2>/dev/null

# Test that logging works across components
if lo1_log "test message" "integration_test" 2>/dev/null; then
    if err_log "test error" "integration_test" 2>/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_logging.sh"
    
    run_test "Cross-component logging integration" "$test_env/test_logging.sh"
    cleanup_test_env "$test_env"
}

test_security_integration() {
    local test_env=$(create_test_env "security_integration")
    
    cat > "$test_env/test_security.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/sec 2>/dev/null

# Test password generation and storage integration
temp_dir="/tmp/test_security_$$"
mkdir -p "$temp_dir"
chmod 700 "$temp_dir"

if init_password_management "$temp_dir" 2>/dev/null; then
    if [[ -f "$temp_dir/ct_pbs.pwd" ]]; then
        # Check file permissions
        perm=$(stat -c "%a" "$temp_dir/ct_pbs.pwd")
        if [[ "$perm" == "600" ]]; then
            rm -rf "$temp_dir"
            exit 0
        fi
    fi
fi

rm -rf "$temp_dir"
exit 1
EOF
    chmod +x "$test_env/test_security.sh"
    
    run_test "Security system integration" "$test_env/test_security.sh"
    cleanup_test_env "$test_env"
}

test_performance_integration() {
    start_performance_test "Complete environment loading"
    
    local test_env=$(create_test_env "performance_integration")
    cat > "$test_env/perf_test.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Time complete environment loading
source bin/ini >/dev/null 2>&1
source src/aux/set >/dev/null 2>&1
EOF
    chmod +x "$test_env/perf_test.sh"
    
    "$test_env/perf_test.sh"
    cleanup_test_env "$test_env"
    
    end_performance_test "Complete environment loading" 10000  # 10 second threshold
}

test_error_resilience() {
    local test_env=$(create_test_env "error_resilience")
    
    cat > "$test_env/test_resilience.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test that system handles missing components gracefully
export FAKE_VAR="missing_component"

# Should still load core functionality even with issues
if source bin/ini 2>/dev/null; then
    # Core functions should still be available
    if declare -f ver_verify_path >/dev/null; then
        exit 0
    else
        exit 1
    fi
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_resilience.sh"
    
    run_test "System error resilience" "$test_env/test_resilience.sh"
    cleanup_test_env "$test_env"
}

# Main execution
main() {
    run_test_suite "COMPLETE WORKFLOW INTEGRATION TESTS" \
        test_complete_initialization \
        test_environment_loading_workflow \
        test_component_integration \
        test_pure_wrapper_integration \
        test_configuration_hierarchy \
        test_deployment_script_integration \
        test_logging_integration \
        test_security_integration \
        test_performance_integration \
        test_error_resilience
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
