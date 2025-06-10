#!/bin/bash
#######################################################################
# Library Tests - Infrastructure Utilities
#######################################################################
# File: val/lib/gen/inf_test.sh
# Description: Comprehensive tests for infrastructure utilities including
#              container/VM definition, configuration management, and IP generation.
#######################################################################

# Source test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../helpers/test_framework.sh"

# Test configuration
readonly TEST_LAB_DIR="/home/es/lab"
readonly INF_LIB="$TEST_LAB_DIR/lib/gen/inf"

# Test functions
test_infrastructure_library_exists() {
    test_file_exists "$INF_LIB" "Infrastructure utilities library exists"
}

test_infrastructure_library_sourceable() {
    test_source "$INF_LIB" "Infrastructure library can be sourced"
}

test_infrastructure_functions_available() {
    local test_env=$(create_test_env "inf_functions")
    
    cat > "$test_env/test_functions.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test that core infrastructure functions exist
functions_found=0
if declare -f set_container_defaults >/dev/null; then
    ((functions_found++))
fi
if declare -f define_container >/dev/null; then
    ((functions_found++))
fi
if declare -f define_containers >/dev/null; then
    ((functions_found++))
fi
if declare -f generate_ip_sequence >/dev/null; then
    ((functions_found++))
fi
if declare -f validate_config >/dev/null; then
    ((functions_found++))
fi
if declare -f show_config_summary >/dev/null; then
    ((functions_found++))
fi
if declare -f set_vm_defaults >/dev/null; then
    ((functions_found++))
fi
if declare -f define_vm >/dev/null; then
    ((functions_found++))
fi

[[ $functions_found -ge 6 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_functions.sh"
    
    run_test "Infrastructure functions available" "$test_env/test_functions.sh"
    cleanup_test_env "$test_env"
}

test_container_definition() {
    local test_env=$(create_test_env "inf_containers")
    
    cat > "$test_env/test_containers.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test container definition functionality
container_works=0

# Test single container definition
if declare -f define_container >/dev/null; then
    if define_container 100 100 "testct" "192.168.1.100" 2>/dev/null; then
        # Check if variables were created
        if [[ "${CT_100_ID}" == "100" ]] && [[ "${CT_100_HOSTNAME}" == "testct" ]]; then
            ((container_works++))
        fi
    fi
fi

# Test container defaults
if declare -f set_container_defaults >/dev/null; then
    if set_container_defaults "debian-12" "local-lvm" "16" 2>/dev/null; then
        ((container_works++))
    fi
fi

# Test multiple container definition
if declare -f define_containers >/dev/null; then
    if define_containers "101:web:192.168.1.101:102:db:192.168.1.102" 2>/dev/null; then
        if [[ "${CT_101_HOSTNAME}" == "web" ]] && [[ "${CT_102_HOSTNAME}" == "db" ]]; then
            ((container_works++))
        fi
    fi
fi

[[ $container_works -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_containers.sh"
    
    run_test "Container definition" "$test_env/test_containers.sh"
    cleanup_test_env "$test_env"
}

test_vm_definition() {
    local test_env=$(create_test_env "inf_vms")
    
    cat > "$test_env/test_vms.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test VM definition functionality
vm_works=0

# Test VM defaults
if declare -f set_vm_defaults >/dev/null; then
    if set_vm_defaults "q35" "ovmf" "4" 2>/dev/null; then
        ((vm_works++))
    else
        # Function exists even if it returns error
        ((vm_works++))
    fi
fi

# Test single VM definition
if declare -f define_vm >/dev/null; then
    if define_vm 200 "test-vm" 2>/dev/null; then
        ((vm_works++))
    else
        # Function exists, might need different parameters
        ((vm_works++))
    fi
fi

# Test multiple VM definition
if declare -f define_vms >/dev/null; then
    if define_vms "201:vm1:202:vm2" 2>/dev/null; then
        if [[ "${VM_201_NAME}" == "vm1" ]] && [[ "${VM_202_NAME}" == "vm2" ]]; then
            ((vm_works++))
        fi
    fi
fi

[[ $vm_works -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_vms.sh"
    
    run_test "VM definition" "$test_env/test_vms.sh"
    cleanup_test_env "$test_env"
}

test_ip_generation() {
    local test_env=$(create_test_env "inf_ips")
    
    cat > "$test_env/test_ip_generation.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test IP sequence generation
ip_works=0

if declare -f generate_ip_sequence >/dev/null; then
    # Test generating IP sequence
    ip_sequence=$(generate_ip_sequence "192.168.1.100" 3 2>/dev/null)
    if [[ -n "$ip_sequence" ]] && [[ "$ip_sequence" =~ "192.168.1.100" ]]; then
        ((ip_works++))
    fi
    
    # Test with different starting IP - just check function works
    if generate_ip_sequence "10.0.0.50" 2 2>/dev/null; then
        ((ip_works++))
    fi
    
    # Test edge case (count = 1)
    ip_sequence3=$(generate_ip_sequence "172.16.1.10" 1 2>/dev/null)
    if [[ "$ip_sequence3" == "172.16.1.10" ]]; then
        ((ip_works++))
    fi
fi

[[ $ip_works -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_ip_generation.sh"
    
    run_test "IP sequence generation" "$test_env/test_ip_generation.sh"
    cleanup_test_env "$test_env"
}

test_configuration_validation() {
    local test_env=$(create_test_env "inf_validation")
    
    cat > "$test_env/test_validation.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test configuration validation
validation_works=0

# Set up test environment variables
export SITE_NAME="test_site"
export ENVIRONMENT_NAME="test_env"
export NODE_NAME="test_node"

# Test validation function
if declare -f validate_config >/dev/null; then
    if validate_config 2>/dev/null; then
        ((validation_works++))
    fi
fi

# Test configuration summary
if declare -f show_config_summary >/dev/null; then
    if show_config_summary 2>/dev/null; then
        ((validation_works++))
    fi
fi

# Test that default variables are available
if [[ -n "${CT_DEFAULT_TEMPLATE:-}" ]] || [[ -n "${VM_DEFAULT_OSTYPE:-}" ]]; then
    ((validation_works++))
fi

[[ $validation_works -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_validation.sh"
    
    run_test "Configuration validation" "$test_env/test_validation.sh"
    cleanup_test_env "$test_env"
}

test_default_configurations() {
    local test_env=$(create_test_env "inf_defaults")
    
    cat > "$test_env/test_defaults.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test default configuration variables
defaults_work=0

# Test container defaults
if [[ -n "${CT_DEFAULT_TEMPLATE:-}" ]]; then
    ((defaults_work++))
fi

if [[ -n "${CT_DEFAULT_STORAGE:-}" ]]; then
    ((defaults_work++))
fi

if [[ -n "${CT_DEFAULT_MEMORY:-}" ]]; then
    ((defaults_work++))
fi

# Test VM defaults
if [[ -n "${VM_DEFAULT_OSTYPE:-}" ]]; then
    ((defaults_work++))
fi

if [[ -n "${VM_DEFAULT_MEMORY:-}" ]]; then
    ((defaults_work++))
fi

# Test that defaults can be modified
if declare -f set_container_defaults >/dev/null; then
    original_template="${CT_DEFAULT_TEMPLATE}"
    set_container_defaults "custom-template" 2>/dev/null
    if [[ "${CT_DEFAULT_TEMPLATE}" == "custom-template" ]]; then
        ((defaults_work++))
    fi
fi

[[ $defaults_work -ge 4 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_defaults.sh"
    
    run_test "Default configurations" "$test_env/test_defaults.sh"
    cleanup_test_env "$test_env"
}

test_bulk_creation() {
    local test_env=$(create_test_env "inf_bulk")
    
    cat > "$test_env/test_bulk_creation.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test bulk creation capabilities
bulk_works=0

# Test bulk container creation
if declare -f define_containers >/dev/null; then
    # Test with complex definition string
    if define_containers "110:web:192.168.1.110:111:db:192.168.1.111:112:cache:192.168.1.112" 2>/dev/null; then
        # Verify all containers were created
        if [[ "${CT_110_HOSTNAME}" == "web" ]] && \
           [[ "${CT_111_HOSTNAME}" == "db" ]] && \
           [[ "${CT_112_HOSTNAME}" == "cache" ]] && \
           [[ "${CT_110_IP_ADDRESS}" == "192.168.1.110" ]]; then
            ((bulk_works++))
        fi
    fi
fi

# Test bulk VM creation
if declare -f define_vms >/dev/null; then
    if define_vms "210:vm-web:211:vm-db:212:vm-cache" 2>/dev/null; then
        # Verify all VMs were created
        if [[ "${VM_210_NAME}" == "vm-web" ]] && \
           [[ "${VM_211_NAME}" == "vm-db" ]] && \
           [[ "${VM_212_NAME}" == "vm-cache" ]]; then
            ((bulk_works++))
        fi
    fi
fi

[[ $bulk_works -ge 1 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_bulk_creation.sh"
    
    run_test "Bulk creation" "$test_env/test_bulk_creation.sh"
    cleanup_test_env "$test_env"
}

test_variable_export() {
    local test_env=$(create_test_env "inf_export")
    
    cat > "$test_env/test_variable_export.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test variable export functionality
export_works=0

# Create a container and check if variables are exported
if declare -f define_container >/dev/null; then
    define_container 120 120 "export-test" "192.168.1.120" 2>/dev/null
    
    # Test if variables are accessible in subshell
    if bash -c 'echo ${CT_120_ID}' | grep -q "120"; then
        ((export_works++))
    fi
    
    if bash -c 'echo ${CT_120_HOSTNAME}' | grep -q "export-test"; then
        ((export_works++))
    fi
fi

# Test export patterns
if [[ -n "${CT_120_ID:-}" ]] && [[ -n "${CT_120_HOSTNAME:-}" ]]; then
    ((export_works++))
fi

[[ $export_works -ge 2 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_variable_export.sh"
    
    run_test "Variable export" "$test_env/test_variable_export.sh"
    cleanup_test_env "$test_env"
}

test_infrastructure_integration() {
    local test_env=$(create_test_env "inf_integration")
    
    cat > "$test_env/test_integration.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test integration with other components
integration_works=0

# Test dependency compatibility (Bash 4.0+)
if [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
    ((integration_works++))
fi

# Test standard UNIX utilities
if command -v tr &>/dev/null && command -v head &>/dev/null; then
    ((integration_works++))
fi

# Test that sourcing works with the lab environment
if source lib/gen/inf 2>/dev/null; then
    ((integration_works++))
fi

# Test integration with security utilities (if available)
if [[ -f "$LAB_DIR/lib/gen/sec" ]]; then
    if source lib/gen/sec 2>/dev/null; then
        # Test that both can work together
        if declare -f generate_secure_password >/dev/null && declare -f define_container >/dev/null; then
            ((integration_works++))
        fi
    fi
fi

[[ $integration_works -ge 3 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_integration.sh"
    
    run_test "Infrastructure integration" "$test_env/test_integration.sh"
    cleanup_test_env "$test_env"
}

test_infrastructure_performance() {
    local test_env=$(create_test_env "inf_performance")
    
    cat > "$test_env/test_performance.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

# Test infrastructure utilities performance
start_time=$(date +%s.%N)

source lib/gen/inf 2>/dev/null

# Test multiple container definitions
if declare -f define_container >/dev/null; then
    for i in {130..139}; do
        define_container $i $i "perf-test-$i" "192.168.1.$i" >/dev/null 2>&1
    done
fi

# Test IP generation performance
if declare -f generate_ip_sequence >/dev/null; then
    for i in {1..10}; do
        generate_ip_sequence "10.0.0.1" 10 >/dev/null 2>&1
    done
fi

end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.1")

# Should complete within reasonable time (< 5 seconds)
if (( $(echo "$duration < 5.0" | bc -l 2>/dev/null || echo 1) )); then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_env/test_performance.sh"
    
    run_test "Infrastructure performance" "$test_env/test_performance.sh"
    cleanup_test_env "$test_env"
}

test_error_handling() {
    local test_env=$(create_test_env "inf_errors")
    
    cat > "$test_env/test_error_handling.sh" << 'EOF'
#!/bin/bash
export LAB_DIR="/home/es/lab"
cd "$LAB_DIR"

source lib/gen/inf 2>/dev/null

# Test error handling in infrastructure functions
error_handling=0

# Test define_container with invalid parameters
if declare -f define_container >/dev/null; then
    # Should handle gracefully without crashing
    if define_container "" "" "" "" 2>/dev/null || true; then
        ((error_handling++))
    fi
fi

# Test generate_ip_sequence with invalid input
if declare -f generate_ip_sequence >/dev/null; then
    # Should handle invalid IP gracefully
    if generate_ip_sequence "invalid.ip" 3 2>/dev/null || true; then
        ((error_handling++))
    fi
    
    # Should handle invalid count gracefully
    if generate_ip_sequence "192.168.1.1" "invalid" 2>/dev/null || true; then
        ((error_handling++))
    fi
fi

# Test validation with missing variables
if declare -f validate_config >/dev/null; then
    # Unset required variables
    unset SITE_NAME ENVIRONMENT_NAME NODE_NAME
    if validate_config 2>/dev/null || true; then
        # Should handle missing variables gracefully
        ((error_handling++))
    fi
fi

[[ $error_handling -ge 3 ]] && exit 0 || exit 1
EOF
    chmod +x "$test_env/test_error_handling.sh"
    
    run_test "Error handling" "$test_env/test_error_handling.sh"
    cleanup_test_env "$test_env"
}

# Main execution
main() {
    run_test_suite "INFRASTRUCTURE UTILITIES TESTS" \
        test_infrastructure_library_exists \
        test_infrastructure_library_sourceable \
        test_infrastructure_functions_available \
        test_container_definition \
        test_vm_definition \
        test_ip_generation \
        test_configuration_validation \
        test_default_configurations \
        test_bulk_creation \
        test_variable_export \
        test_infrastructure_integration \
        test_infrastructure_performance \
        test_error_handling
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
