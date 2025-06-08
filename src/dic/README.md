# 🏗️ Dependency Injection Container (`src/dic/`) - Generic Operations Framework

[![Architecture](https://img.shields.io/badge/Pattern-Dependency%20Injection-purple)](#) [![Convention](https://img.shields.io/badge/Convention-Over%20Configuration-orange)](#) [![Metaprogramming](https://img.shields.io/badge/Type-Metaprogramming-blue)](#)

## 🎯 Purpose

The `dic/` (Dependency Injection Container) directory implements a **generic operations framework** that eliminates the need for individual wrapper functions by automatically injecting global variables into pure library functions based on naming conventions and configuration mappings.

## 🏗️ Architecture: Convention-Based Variable Injection

```bash
# Architecture Flow - Generic Injection Pattern
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Command  │ -> │  Generic Engine  │ -> │  Pure Function  │
│   ops pve vpt   │    │   src/dic/ops    │    │  lib/ops/pve    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                v
                       ┌──────────────────┐
                       │  Auto-Injection  │
                       │  • Convention    │
                       │  • Configuration │
                       │  • Introspection │
                       └──────────────────┘
```

## 🎯 Key Architectural Principles

### 1. **Convention over Configuration**
- `local_var` → `LOCAL_VAR` (automatic uppercase mapping)
- `vm_id` → `VM_ID`, `pci0_id` → `PCI0_ID`
- Hostname-specific variables: `${hostname}_NODE_PCI0`

### 2. **Dependency Injection**
- Functions declare their dependencies through parameter names
- Container automatically resolves and injects global variables
- Zero boilerplate for standard cases

### 3. **Metaprogramming**
- Runtime function signature analysis
- Dynamic variable resolution
- Configuration-driven complex mappings

## 📁 Directory Structure

```
src/dic/
├── README.md              # This documentation
├── ops                    # Main generic operations engine
├── config/               # Variable mapping configurations
│   ├── conventions.conf  # Standard naming conventions
│   ├── mappings.conf     # Complex variable mappings
│   └── overrides.conf    # Function-specific overrides
├── lib/                  # DIC supporting libraries
│   ├── injector         # Core injection engine
│   ├── introspector     # Function signature analysis
│   └── resolver         # Variable resolution logic
└── examples/            # Usage examples and demos
    ├── basic.sh         # Basic usage patterns
    ├── complex.sh       # Complex injection scenarios
    └── migration.sh     # Migration from src/mgt/
```

## 🚀 Core Components

### **`src/dic/ops` - Main Engine**
The primary interface that users interact with:

```bash
# Generic operations interface
ops MODULE FUNCTION [ARGS...]

# Examples
ops pve vpt 100 on        # Replaces pve_vpt_w 100 on
ops gpu vck 101           # Replaces gpu_vck_w 101
ops sys sca usr all       # Replaces sys_sca_w usr all
```

### **`src/dic/lib/injector` - Injection Engine**
Core dependency injection logic:

- **Convention-based injection**: Automatic lowercase → UPPERCASE mapping
- **Configuration-driven injection**: Complex mappings from config files
- **Validation**: Ensures required variables are available
- **Error handling**: Clear messages for missing dependencies

### **`src/dic/lib/introspector` - Function Analysis**
Analyzes pure functions to understand their dependencies:

- **Parameter extraction**: Identifies function parameter names
- **Signature caching**: Caches analysis for performance
- **Type detection**: Understands different parameter types (scalars, arrays)

### **`src/dic/lib/resolver` - Variable Resolution**
Resolves global variables using multiple strategies:

- **Direct mapping**: `vm_id` → `VM_ID`
- **Hostname-specific**: `pci0_id` → `${hostname}_NODE_PCI0`
- **Array handling**: Special processing for array variables
- **Fallback chains**: Multiple resolution strategies

## 🎛️ Variable Injection Strategies

### 1. **Convention-Based (80% of cases)**

```bash
# Automatic injection based on naming convention
# Function signature: pve_vck(vm_id, cluster_nodes)
# Auto-injected: VM_ID, CLUSTER_NODES

ops pve vck 100
# Internally becomes: pve_vck "$VM_ID" "$CLUSTER_NODES"
```

### 2. **Configuration-Driven (Complex cases)**

```bash
# src/dic/config/mappings.conf
pve_vpt:vm_id=VM_ID
pve_vpt:pci0_id=${hostname}_NODE_PCI0
pve_vpt:pci1_id=${hostname}_NODE_PCI1
pve_vpt:usb_devices=${hostname}_USB_DEVICES[@]

# Usage remains simple
ops pve vpt 100 on
```

### 3. **Hybrid Approach (Best of both worlds)**

```bash
# Simple functions use convention
ops pve vck 100           # Convention-based

# Complex functions use configuration
ops pve vpt 100 on        # Configuration-driven

# Fallback to specific wrappers for edge cases
pve_custom_complex_w args # Still available if needed
```

## 📋 Configuration Files

### **`conventions.conf` - Standard Patterns**

```bash
# Standard lowercase to uppercase mappings
vm_id=VM_ID
node_id=NODE_ID
cluster_nodes=CLUSTER_NODES
storage_path=STORAGE_PATH
```

### **`mappings.conf` - Complex Mappings**

```bash
# Function-specific variable mappings
[pve_vpt]
pci0_id=${hostname}_NODE_PCI0
pci1_id=${hostname}_NODE_PCI1
core_count_on=${hostname}_CORE_COUNT_ON
usb_devices=${hostname}_USB_DEVICES[@]

[gpu_vck]
gpu_device=${hostname}_GPU_DEVICE
pci_slot=${hostname}_PCI_SLOT
```

### **`overrides.conf` - Special Cases**

```bash
# Functions that need custom injection logic
[pve_ctc]
injection_method=custom
handler=pve_ctc_custom_injector

[ssh_sca]
injection_method=passthrough
# Some functions may need all args passed through
```

## 🔧 Usage Examples

### **Basic Operations**

```bash
# Initialize environment (same as before)
source bin/ini

# Use generic operations interface
ops pve vck 100                    # Check VM location
ops pve vpt 100 on                 # Enable passthrough
ops gpu vck 101                    # Check GPU config
ops sys sca usr all                # System scan all users
```

### **Advanced Scenarios**

```bash
# Debug mode - show variable injection
OPS_DEBUG=1 ops pve vpt 100 on

# Force specific injection method
OPS_METHOD=config ops pve vpt 100 on

# List available operations
ops --list                         # List all modules
ops pve --list                     # List PVE functions
ops pve vpt --help                 # Show function help
```

### **Migration Examples**

```bash
# Old approach (src/mgt/)
source bin/ini
pve_vpt_w 100 on

# New approach (src/dic/)
source bin/ini
ops pve vpt 100 on

# Both work identically, new approach has less code
```

## ⚡ Performance Considerations

### **Caching Strategy**

```bash
# Function signatures cached after first analysis
# Variable resolutions cached per session
# Configuration files loaded once

# Performance modes
OPS_CACHE=1        # Enable caching (default)
OPS_CACHE=0        # Disable for debugging
OPS_PRELOAD=1      # Preload all signatures
```

### **Optimization Features**

- **Lazy loading**: Functions analyzed only when used
- **Signature caching**: Avoid repeated introspection
- **Variable caching**: Cache resolved variables per session
- **Parallel injection**: Resolve multiple variables concurrently

## 🔒 Error Handling & Debugging

### **Validation Levels**

```bash
OPS_VALIDATE=strict    # Fail on any missing variable
OPS_VALIDATE=warn      # Warn but continue with empty values
OPS_VALIDATE=silent    # Silent operation (production mode)
```

### **Debug Information**

```bash
OPS_DEBUG=1 ops pve vpt 100 on
# Output:
# [DIC] Analyzing function: pve_vpt
# [DIC] Required variables: vm_id, action, pci0_id, pci1_id, ...
# [DIC] Injecting: vm_id=100 (from args)
# [DIC] Injecting: pci0_id=0000:01:00.0 (from h1_NODE_PCI0)
# [DIC] Calling: pve_vpt 100 on 0000:01:00.0 0000:01:00.1 ...
```

## 🔄 Integration with Existing System

### **Backward Compatibility**

- **`src/mgt/` preserved**: All existing wrappers remain functional
- **Gradual migration**: Can adopt DIC function by function
- **Hybrid usage**: Mix old and new approaches as needed

### **Configuration Integration**

```bash
# Same configuration sources as src/mgt/
src/dic/*
├── Uses: bin/ini (environment initialization)
├── Uses: cfg/env/* (site configurations) 
├── Sources: lib/ops/* (pure functions)
└── Provides: Generic injection framework
```

## 🎯 Benefits Over `src/mgt/`

| Aspect | `src/mgt/` (Current) | `src/dic/` (Proposed) |
|--------|----------------------|----------------------|
| **Code Volume** | ~50 lines × 50 functions = 2500 lines | ~300 lines total |
| **Maintenance** | Update each wrapper individually | Update injection rules |
| **Consistency** | Manual implementation per function | Automated standardization |
| **Scalability** | Linear growth with functions | Constant infrastructure |
| **Testing** | Test each wrapper separately | Test injection engine once |
| **Documentation** | Document each wrapper | Self-documenting conventions |

## 🚦 Quick Start

### **1. Initialize Environment**

```bash
# Same initialization as always
source bin/ini
```

### **2. Basic Usage**

```bash
# Replace individual wrapper calls
ops pve vck 100        # Instead of pve_vck_w 100
ops gpu vpt 101 on     # Instead of gpu_vpt_w 101 on
```

### **3. Advanced Configuration**

```bash
# Customize injection behavior
echo "custom_var=CUSTOM_GLOBAL" >> src/dic/config/mappings.conf
ops module function args
```

## 🔮 Future Enhancements

### **Planned Features**

- **IDE Integration**: Auto-completion for `ops` commands
- **Type Safety**: Parameter type validation
- **Performance Profiling**: Built-in performance monitoring
- **Configuration UI**: Web interface for managing mappings
- **Migration Tools**: Automated conversion from `src/mgt/`

### **Advanced Capabilities**

- **Conditional Injection**: Variables injected based on conditions
- **Pipeline Support**: Chain operations with automatic variable passing
- **Remote Execution**: DIC-enabled remote operations
- **Audit Trail**: Track all variable injections for security

---

## 📚 Related Documentation

- [**Architecture Overview**](../../doc/man/architecture.md) - Complete system architecture
- [**Current Management Layer**](../mgt/README.md) - Existing wrapper approach
- [**Pure Function Libraries**](../../lib/README.md) - Core functionality modules
- [**Configuration Management**](../../doc/man/configuration.md) - Environment setup

---

**Navigation**: Return to [Source Code Documentation](../README.md)
