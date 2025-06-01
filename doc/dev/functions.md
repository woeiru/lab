<!-- 
    This documentation focuses exclusively on generic pure functions from the lib/ folder.
    Pure functions are stateless, parameterized, and environment-independent.
    They provide predictable behavior and are fully testable with explicit inputs.
    
    The lib/ folder contains three categories of pure functions:
    - lib/core/  : Core system utilities (error handling, logging, timing)
    - lib/ops/   : Operations functions (infrastructure management)
    - lib/gen/   : General utilities (environment, security, infrastructure)
-->

# Pure Functions Reference

Generic pure functions available in the Lab Environment Management System.

## 📚 Library Structure

The `lib/` folder contains three categories of pure functions:

### Core Utilities (`lib/core/`)
- **err**: Error handling and stack traces
- **lo1**: Module-specific debug logging
- **tme**: Performance timing and monitoring
- **ver**: Module version verification

### Operations Functions (`lib/ops/`)
- **aux**: Auxiliary operations and utilities
- **gpu**: GPU passthrough management
- **net**: Network configuration and management
- **pbs**: Proxmox Backup Server operations
- **pve**: Proxmox VE cluster management
- **srv**: System service operations
- **sto**: Storage and filesystem management
- **sys**: System-level operations
- **usr**: User account management

### General Utilities (`lib/gen/`)
- **env**: Environment configuration utilities
- **inf**: Infrastructure deployment utilities
- **sec**: Security and credential management
- **ssh**: SSH key and connection management

## 🔍 Function Metadata Table

<!-- AUTO-GENERATED SECTION: DO NOT EDIT MANUALLY -->
<!-- This section is automatically populated by utl/doc-func -->
<!-- Command: aux-ffl aux-laf "" "$LIB_CORE_DIR" & aux-ffl aux-laf "" "$LIB_OPS_DIR" & aux-ffl aux-laf "" "$LIB_GEN_DIR" -->

```
[Automated function metadata table will be inserted here by utl/doc-func]
```

<!-- END AUTO-GENERATED SECTION -->

## 🎯 Pure Function Characteristics

### Design Principles
- **Stateless**: No global state dependencies
- **Parameterized**: All inputs via explicit parameters
- **Predictable**: Same inputs always produce same outputs
- **Testable**: Can be tested in isolation

### Usage Pattern
```bash
# Pure function call
function_name "param1" "param2" "param3"

# No environment variables required
# No side effects on global state
# Fully deterministic behavior
```

## 🔧 Integration

To use pure functions in your scripts:

```bash
# Source the required library modules
source "$LIB_CORE_DIR/err"
source "$LIB_OPS_DIR/pve"
source "$LIB_GEN_DIR/inf"

# Call functions with explicit parameters
pve-vmc "101" "node1,node2,node3"
handle_error "component" "message" "ERROR"
```

## 📖 Related Documentation

- **[System Architecture](architecture.md)** - Complete system design
- **[Logging System](logging.md)** - Debug and logging frameworks
- **[Verbosity Controls](verbosity.md)** - Output control mechanisms
