#!/bin/bash

# ============================================================================
# DEPENDENCY INJECTION CONTAINER - BASIC USAGE EXAMPLES
# ============================================================================
#
# DESCRIPTION:
#   Basic usage examples for the DIC (Dependency Injection Container) system.
#   This script demonstrates common operations and usage patterns.
#
# PREREQUISITES:
#   - Run 'source bin/ini' to initialize environment
#   - Ensure LIB_OPS_DIR and other globals are set
#
# ============================================================================

# Ensure script is executable
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly."
    echo "Usage: source src/dic/examples/basic.sh"
    exit 1
fi

# Get DIC directory
DIC_EXAMPLES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIC_DIR="$(dirname "$DIC_EXAMPLES_DIR")"

echo "==================================="
echo "DIC Basic Usage Examples"
echo "==================================="
echo ""

# ============================================================================
# EXAMPLE 1: SIMPLE OPERATIONS
# ============================================================================

echo "Example 1: Simple Operations"
echo "-----------------------------"

echo "1.1 Check VM location (convention-based injection):"
echo "Command: ops pve vck 100"
echo "Explanation: vm_id=100 (from args), cluster_nodes=\${CLUSTER_NODES[*]} (from globals)"
echo ""

echo "1.2 List available functions:"
echo "Command: ops pve --list"
echo "Explanation: Shows all functions in the pve module"
echo ""

echo "1.3 Show function help:"
echo "Command: ops pve vck --help"
echo "Explanation: Shows help for the pve_vck function"
echo ""

# ============================================================================
# EXAMPLE 2: GPU PASSTHROUGH OPERATIONS
# ============================================================================

echo "Example 2: GPU Passthrough Operations (Complex Injection)"
echo "---------------------------------------------------------"

echo "2.1 Enable GPU passthrough:"
echo "Command: ops pve vpt 100 on"
echo "Explanation: Complex injection with hostname-specific variables:"
echo "  vm_id=100 (from args)"
echo "  action=on (from args)"
echo "  pci0_id=\${hostname}_NODE_PCI0 (from hostname-specific global)"
echo "  pci1_id=\${hostname}_NODE_PCI1 (from hostname-specific global)"
echo "  core_count_on=\${hostname}_CORE_COUNT_ON (from hostname-specific global)"
echo "  usb_devices_str=\${hostname}_USB_DEVICES[@] (array processing)"
echo ""

echo "2.2 Check GPU configuration:"
echo "Command: ops gpu vck 101"
echo "Explanation: Simpler GPU check with basic injection"
echo ""

# ============================================================================
# EXAMPLE 3: DEBUG MODE
# ============================================================================

echo "Example 3: Debug Mode"
echo "--------------------"

echo "3.1 Enable debug output:"
echo "Command: OPS_DEBUG=1 ops pve vck 100"
echo "Explanation: Shows detailed injection process:"
echo "  [DIC] Analyzing function: pve_vck"
echo "  [DIC] Required variables: vm_id, cluster_nodes"
echo "  [DIC] Injecting: vm_id=100 (from args)"
echo "  [DIC] Injecting: cluster_nodes=node1 node2 node3 (from CLUSTER_NODES)"
echo "  [DIC] Calling: pve_vck 100 \"node1 node2 node3\""
echo ""

echo "3.2 Debug with different injection method:"
echo "Command: OPS_DEBUG=1 OPS_METHOD=config ops pve vpt 100 on"
echo "Explanation: Force configuration-based injection with debug output"
echo ""

# ============================================================================
# EXAMPLE 4: VALIDATION MODES
# ============================================================================

echo "Example 4: Validation Modes"
echo "---------------------------"

echo "4.1 Strict validation (fail on missing variables):"
echo "Command: OPS_VALIDATE=strict ops pve vpt 100 on"
echo "Explanation: Will fail if any required global variable is missing"
echo ""

echo "4.2 Warning validation (warn but continue):"
echo "Command: OPS_VALIDATE=warn ops pve vpt 100 on"
echo "Explanation: Will warn about missing variables but continue execution"
echo ""

echo "4.3 Silent validation (no warnings):"
echo "Command: OPS_VALIDATE=silent ops pve vpt 100 on"
echo "Explanation: No validation messages, suitable for production scripts"
echo ""

# ============================================================================
# EXAMPLE 5: INJECTION METHODS
# ============================================================================

echo "Example 5: Injection Methods"
echo "----------------------------"

echo "5.1 Convention-based injection:"
echo "Command: OPS_METHOD=convention ops pve vck 100"
echo "Explanation: Use only naming conventions (vm_id → VM_ID)"
echo ""

echo "5.2 Configuration-driven injection:"
echo "Command: OPS_METHOD=config ops pve vpt 100 on"
echo "Explanation: Use mappings from src/dic/config/mappings.conf"
echo ""

echo "5.3 Auto injection (default):"
echo "Command: OPS_METHOD=auto ops pve vpt 100 on"
echo "Explanation: Try convention, then config, then custom handlers"
echo ""

# ============================================================================
# EXAMPLE 6: COMPARISON WITH TRADITIONAL WRAPPERS
# ============================================================================

echo "Example 6: Traditional vs DIC Comparison"
echo "----------------------------------------"

echo "6.1 Traditional wrapper approach:"
echo "Command: source bin/ini && pve_vck_w 100"
echo "Explanation: Requires initialization and uses individual wrapper"
echo ""

echo "6.2 DIC approach:"
echo "Command: source bin/ini && ops pve vck 100"
echo "Explanation: Same initialization, but uses generic interface"
echo ""

echo "6.3 Benefits of DIC:"
echo "  - Single interface for all operations"
echo "  - Automatic variable injection"
echo "  - Configurable validation and debugging"
echo "  - Reduced code duplication"
echo "  - Consistent error handling"
echo ""

# ============================================================================
# EXAMPLE 7: COMMON OPERATIONS
# ============================================================================

echo "Example 7: Common Operations"
echo "---------------------------"

echo "7.1 System operations:"
echo "ops sys sca usr all    # System scan all users"
echo ""

echo "7.2 SSH operations:"
echo "ops ssh key create mykey    # Create SSH key"
echo "ops ssh con user@host cmd   # SSH connection"
echo ""

echo "7.3 Storage operations:"
echo "ops sto bak /source /backup    # Storage backup"
echo ""

echo "7.4 Network operations:"
echo "ops net cfg eth0    # Network configuration"
echo ""

# ============================================================================
# UTILITY FUNCTIONS FOR EXAMPLES
# ============================================================================

# Function to demonstrate DIC usage interactively
demo_dic_usage() {
    echo ""
    echo "==================================="
    echo "Interactive DIC Demonstration"
    echo "==================================="
    
    # Check if environment is initialized
    if [[ -z "$LIB_OPS_DIR" ]]; then
        echo "Error: Environment not initialized. Please run 'source bin/ini' first."
        return 1
    fi
    
    echo "Environment initialized successfully."
    echo "LIB_OPS_DIR: $LIB_OPS_DIR"
    echo ""
    
    # Show available modules
    echo "Available modules:"
    "${DIC_DIR}/ops" --list
    echo ""
    
    # Show functions in PVE module
    echo "Functions in PVE module:"
    "${DIC_DIR}/ops" pve --list
    echo ""
    
    # Demonstrate debug mode
    echo "Debug mode demonstration:"
    echo "Command: OPS_DEBUG=1 ${DIC_DIR}/ops pve vck 100"
    echo "Output:"
    OPS_DEBUG=1 "${DIC_DIR}/ops" pve vck 100
    echo ""
}

# Function to test different injection methods
test_injection_methods() {
    local function_name="${1:-pve_vck}"
    local args="${2:-100}"
    
    echo ""
    echo "Testing injection methods for: $function_name $args"
    echo "=================================================="
    
    echo "1. Convention-based:"
    OPS_DEBUG=1 OPS_METHOD=convention "${DIC_DIR}/ops" $function_name $args 2>&1 | head -5
    echo ""
    
    echo "2. Configuration-driven:"
    OPS_DEBUG=1 OPS_METHOD=config "${DIC_DIR}/ops" $function_name $args 2>&1 | head -5
    echo ""
    
    echo "3. Auto (default):"
    OPS_DEBUG=1 OPS_METHOD=auto "${DIC_DIR}/ops" $function_name $args 2>&1 | head -5
    echo ""
}

# Function to show variable resolution details
show_variable_resolution() {
    local param_name="$1"
    local function_context="${2:-pve_vck}"
    
    echo ""
    echo "Variable resolution for: $param_name in $function_context"
    echo "========================================================"
    
    # Source the resolver
    source "${DIC_DIR}/lib/resolver"
    
    # Show resolution debug
    ops_debug_resolution "$param_name" "$function_context"
}

echo ""
echo "Available demonstration functions:"
echo "  demo_dic_usage                 # Interactive demonstration"
echo "  test_injection_methods [func] [args]  # Test injection methods"
echo "  show_variable_resolution param func   # Show resolution details"
echo ""
echo "Example usage:"
echo "  demo_dic_usage"
echo "  test_injection_methods pve_vpt '100 on'"
echo "  show_variable_resolution vm_id pve_vck"
