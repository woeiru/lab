# Operations Library Architecture
# lib/ops - Pure Operational Functions with DIC Integration

## Overview

The `lib/ops` library implements a **pure function architecture** designed for seamless integration with the **Dependency Injection Container (DIC)** system. This architecture enables both **automated configuration injection** for production use and **explicit parameterization** for testing and standalone operation.

## Architectural Principles

### Pure Function Design
All functions in `lib/ops` are designed as **stateless, pure functions** that:
- Accept explicit parameters for all required inputs
- Have no hidden dependencies on global variables or environment state
- Produce predictable outputs for given inputs
- Can be tested in isolation with mock parameters

### DIC Integration Pattern
Functions support **dual-mode operation**:

```bash
# DIC Mode (Production) - Configuration injected automatically
src/dic/ops gpu ptd              # Hostname-specific config injected

# Pure Mode (Testing/Standalone) - All parameters explicit  
gpu_ptd "01:00.0" "server01" "/path/config" "01:00.0" "02:00.0" "nvidia"
```

## Architecture Layers

### Layer 1: Pure Functions (`lib/ops/*`)
**Purpose**: Core operational logic without environmental dependencies
**Characteristics**:
- Parameterized helper functions (e.g., `_gpu_get_target_gpus_parameterized`)
- Configuration fallback chains: explicit → hostname-specific → auto-detection
- Comprehensive parameter validation and error handling
- Structured logging integration via `aux_*` functions

**Example**:
```bash
# GPU module provides both modes
_gpu_get_config_pci_ids()              # Hostname-based lookup
_gpu_get_config_pci_ids_parameterized() # Explicit parameters
```

### Layer 2: DIC Injection (`src/dic/ops`)
**Purpose**: Automatic dependency resolution and parameter injection
**Characteristics**:
- Analyzes function signatures to determine required parameters
- Resolves hostname-specific variables (e.g., `${hostname}_NODE_PCI0`)
- Handles array processing and type conversion
- Provides debug output for injection process

**Parameter Resolution Hierarchy**:
1. **Explicit CLI arguments** (highest priority)
2. **Hostname-specific variables** (`${hostname}_VARIABLE_NAME`)
3. **Global configuration variables**
4. **Default values** (lowest priority)

### Layer 3: Configuration Layer (`cfg/env/*`)
**Purpose**: Environment-specific configuration state
**Characteristics**:
- Hostname-specific variable definitions
- Environment separation (dev, staging, prod)
- Hardware-specific configurations (PCI IDs, device mappings)
- Driver preferences and system-specific settings



## DIC Integration Patterns

### Configuration Injection Examples

**GPU Passthrough Configuration**:
```bash
# Configuration (cfg/env/site1)
server01_NODE_PCI0="0000:01:00.0"
server01_NODE_PCI1="0000:02:00.0" 
server01_NVIDIA_DRIVER_PREFERENCE="nvidia"

# DIC automatically injects these when calling:
src/dic/ops gpu ptd
# Resolves to: gpu_ptd "" "server01" "$SITE_CONFIG_FILE" "01:00.0" "02:00.0" "nvidia"
```

**Array Processing**:
```bash
# Configuration with arrays
server01_USB_DEVICES=("dev1" "dev2" "dev3")

# DIC converts arrays to space-separated strings for injection
src/dic/ops pve vck 100
# Processes: usb_devices_str="dev1 dev2 dev3"
```

### Parameterized Helper Pattern

Functions implement **dual configuration support**:

```bash
# Standard configuration-based function
_gpu_get_target_gpus() {
    local hostname="$1"
    # Uses: _gpu_get_config_pci_ids "$hostname"
    # Looks up: ${hostname}_NODE_PCI0, ${hostname}_NODE_PCI1
}

# Parameterized equivalent for DIC integration
_gpu_get_target_gpus_parameterized() {
    local pci0_id="$4"
    local pci1_id="$5" 
    # Uses: _gpu_get_config_pci_ids_parameterized "$pci0_id" "$pci1_id"
    # Direct parameter usage without hostname lookup
}
```

## Module Design Patterns

### Configuration Fallback Chain
All modules implement consistent parameter resolution:

```bash
function_implementation() {
    local target_resource
    
    # 1. Explicit parameter (highest priority)
    if [ -n "$explicit_param" ]; then
        target_resource="$explicit_param"
    
    # 2. Hostname-specific configuration
    elif [ -n "${!hostname_var}" ]; then
        target_resource="${!hostname_var}"
    
    # 3. Auto-detection fallback
    else
        target_resource=$(auto_detect_function)
    fi
}
```

### Error Handling Consistency
All functions follow structured error handling:

```bash
# Parameter validation with structured context
if ! aux_val "$param" "not_empty"; then
    aux_err "Parameter validation failed" "component=module,param=$param"
    return 1
fi

# Dependency checking with clear messaging
if ! aux_chk "command" "required_tool"; then
    aux_err "Required dependency missing" "component=module,dependency=required_tool"
    return 127
fi
```

## Integration Benefits

### Development Benefits
- **Pure functions** enable isolated unit testing
- **Explicit parameters** make dependencies visible
- **Mocking capabilities** for integration testing
- **Debugging clarity** with full parameter visibility

### Production Benefits  
- **Automatic configuration** reduces operational complexity
- **Environment-specific** settings via hostname variables
- **Consistent behavior** across different deployment scenarios
- **Audit trails** via structured logging

### Operational Benefits
- **DIC debug mode** shows complete injection process
- **Parameter tracing** for troubleshooting configuration issues
- **Fallback mechanisms** ensure graceful degradation
- **Validation at injection** prevents runtime configuration errors

## Development Workflow

### Adding New Operations
1. **Design pure function** with explicit parameters
2. **Implement parameterized helpers** for DIC compatibility
3. **Add configuration variables** to environment files
4. **Create DIC integration** with parameter mapping
5. **Write validation tests** for both pure and DIC modes

### Testing Strategy
```bash
# Test pure function directly
gpu_ptd "01:00.0" "testhost" "/test/config" "01:00.0" "02:00.0" "nvidia"

# Test DIC integration with debug
OPS_DEBUG=1 src/dic/ops gpu ptd

# Test configuration fallbacks
unset server01_NODE_PCI0  # Test auto-detection path
```

## Related Documentation

- **`.spec`**: Technical standards and compliance requirements
- **`.guide`**: Implementation best practices and quality standards  
- **`/src/dic/README.md`**: DIC system architecture and usage
- **`/val/lib/ops/`**: Testing frameworks and validation suites

## Architecture Evolution

This architecture represents a **migration to pure functions with DIC integration**. The progression path:

1. **Legacy**: Global variable dependencies, hard to test
2. **Current**: Pure functions with DIC integration for best of both worlds
3. **Future**: Full DIC integration across all operational modules

The result is an architecture that supports both **development agility** (through pure functions) and **operational simplicity** (through automatic configuration injection).
