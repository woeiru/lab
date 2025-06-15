# Dependency Injection Container (DIC)
# Automated Parameter Resolution for Pure Operations

## Core Value Proposition

The DIC transforms **manual parameter management** into **automatic dependency resolution**, eliminating the complexity of configuration tracking while maintaining the flexibility of pure functions.

**Before DIC** (Manual Configuration Management):
```bash
# User must know and provide all parameters
gpu_pts "server01" "/path/config" "01:00.0" "02:00.0" "nvidia"
pve_vpt "100" "on" "01:00.0" "02:00.0" "8" "4" "dev1 dev2" "/etc/pve/config"
```

**With DIC** (Automatic Resolution):
```bash
# DIC resolves parameters from environment and configuration
ops gpu pts -j    # All parameters injected automatically
ops pve vpt -j     # Environment-aware execution
```

## Architecture Benefits

### 1. **Zero-Configuration Operation**
- **Automatic hostname detection** and environment-specific variable resolution
- **Configuration hierarchy** with intelligent fallbacks
- **Type conversion** and array processing handled transparently

### 2. **Development-Production Parity**
- **Same functions** work in both manual and automated modes
- **Consistent behavior** across environments
- **Easy testing** with explicit parameters, **easy production** with injection

### 3. **Operational Intelligence**
- **Parameter preview** shows exactly what will be injected before execution
- **Debug tracing** reveals the complete resolution process
- **Environment validation** ensures all dependencies are available

## DIC Workflow

### 1. Function Signature Analysis
```bash
# DIC analyzes function requirements automatically
ops pve vpt -j

# Internally resolves:
# - vm_id → VM_ID global variable
# - pci0_id → server01_NODE_PCI0 (hostname-specific)
# - usb_devices → server01_USB_DEVICES (array conversion)
```

### 2. Parameter Resolution Hierarchy
```
1. Environment Variables (hostname-specific)
   ${hostname}_NODE_PCI0 → "01:00.0"

2. Global Configuration Variables  
   VM_ID → "100"

3. Configuration File Variables
   source $SITE_CONFIG_FILE

4. Default Values (function-specific)
   nvidia_driver_preference → "nvidia"
```

### 3. Execution Modes

#### **Injection Mode (`-j`)**
```bash
ops pve vpt -j
# DIC removes -j, injects parameters, calls: pve_vpt resolved_params...
```

#### **Explicit Mode (`-x`)**  
```bash
ops gpu pts -x
# DIC passes -x through to function for spec-compliant validation
```

#### **Direct Mode**
```bash
ops pve vpt 100 on 01:00.0 02:00.0 8 4 "dev1 dev2" /etc/config
# DIC passes parameters directly without modification
```

## Operational Features

### Parameter Preview
```bash
$ ops pve vpt
Function: pve_vpt
Parameter injection preview:

  Parameters and available injections:
    vm_id          → <vm_id:100>
    action         → <action>
    pci0_id        → <pci0_id:01:00.0>
    pci1_id        → <pci1_id:02:00.0>
    core_count_on  → <core_count_on:8>
    usb_devices    → <usb_devices:dev1 dev2 dev3>

Legend: <param:value> shows injected values, <param> shows missing variables

Usage examples:
  ops pve vpt -j      # Execute with dependency injection
  ops pve vpt -x      # Execute with explicit flag (if function requires it)
  ops pve vpt --help  # Show function help
```

### Debug Mode
```bash
$ OPS_DEBUG=1 ops pve vpt -j
[DEBUG] Function signature: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices pve_conf_path
[DEBUG] Resolving vm_id: found VM_ID=100
[DEBUG] Resolving pci0_id: found server01_NODE_PCI0=01:00.0
[DEBUG] Converting array server01_USB_DEVICES to string: dev1 dev2 dev3
[DEBUG] Executing: pve_vpt 100 on 01:00.0 02:00.0 8 4 "dev1 dev2 dev3" /etc/pve/config
```

## Configuration Integration

### Environment-Specific Variables
```bash
# cfg/env/site1 (loaded automatically)
VM_ID="100"
PVE_ACTION="on"
server01_NODE_PCI0="01:00.0"
server01_NODE_PCI1="02:00.0"
server01_USB_DEVICES=("dev1" "dev2" "dev3")
```

### Hostname-Specific Resolution
```bash
# For hostname "server01", DIC automatically resolves:
pci0_id → server01_NODE_PCI0
pci1_id → server01_NODE_PCI1
usb_devices → server01_USB_DEVICES (converted to string)
```

### Array Processing
```bash
# Configuration arrays are automatically converted
server01_USB_DEVICES=("device1" "device2" "device3")
# Becomes: "device1 device2 device3" when injected as usb_devices_str
```

## Use Cases

### 1. **Production Operations**
```bash
# Simple execution with full environment awareness
ops gpu pts -j     # Hardware-aware GPU passthrough status
ops pve vpt -j      # VM configuration with current environment settings
ops sys sdc -j      # System service management with proper context
```

### 2. **Development & Testing**
```bash
# Full control with explicit parameters
ops pve vpt 101 off 01:00.0 02:00.0 4 8 "testdev1" /tmp/test.conf

# Mixed mode - some injected, some explicit
VM_ID=101 ops pve vpt -j  # Override specific variables
```

### 3. **Infrastructure Automation**
```bash
# Environment-aware batch operations
for action in enable disable; do
    PVE_ACTION=$action ops pve vpt -j
done

# Cross-environment deployment
SITE_CONFIG=/path/env/prod ops gpu pts -j
```

## Error Handling & Validation

### Missing Dependencies
```bash
$ ops pve vpt -j
[ERROR] VM ID cannot be empty
Description: Toggles PCIe passthrough configuration for a specified VM
Usage: pve_vpt <vm_id> <action> <pci0_id> <pci1_id> ...
# Clear indication of what's missing with function help
```

### Environment Validation
```bash
$ ops --validate=strict pve vpt -j
[WARN] Missing hostname-specific variable: server01_NODE_PCI1
[INFO] Using fallback: PCI1_ID=02:00.0
[DEBUG] All required dependencies resolved
```

## Integration Points

### With `lib/ops` Functions
- **Pure functions** remain testable and maintainable
- **DIC layer** adds convenience without changing function logic
- **Dual mode support** enables both automated and manual operation

### With Configuration System
- **Automatic discovery** of configuration files
- **Environment separation** through cfg/env structure  
- **Variable hierarchy** with intelligent fallbacks

### With Legacy Systems
- **Backward compatibility** with direct parameter execution
- **Migration path** from manual to automated configuration
- **Interoperability** with existing scripts and workflows

## Performance & Caching

### Function Signature Caching
```bash
# First call analyzes and caches function signature
ops pve vpt -j  # Signature analysis + execution

# Subsequent calls use cached signature
ops pve vpt -j  # Cached signature + execution (faster)
```

### Variable Resolution Caching
```bash
# Environment variables cached for session
export OPS_CACHE=1  # Enable caching (default)
```

## Troubleshooting

### Common Issues

**Missing Environment Variables**:
```bash
# Check what DIC would inject
ops function_name    # Shows parameter preview

# Enable debug mode
OPS_DEBUG=1 ops function_name -j
```

**Configuration File Issues**:
```bash
# Verify configuration loading
ops --debug gpu pts -j

# Check environment setup
echo $SITE_CONFIG_FILE
echo $LIB_OPS_DIR
```

**Function Signature Issues**:
```bash
# Clear signature cache
unset FUNCTION_SIGNATURE_CACHE
unset VARIABLE_RESOLUTION_CACHE

# Reanalyze function
ops function_name
```

---

The DIC eliminates operational complexity while preserving the flexibility and testability of pure functions, enabling both automated production workflows and precise development control through a single, consistent interface.
