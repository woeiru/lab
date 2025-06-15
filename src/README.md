# Source Code Architecture (`src/`)
# Operational Execution Layer - Advanced Infrastructure Management

[![Architecture](https://img.shields.io/badge/Architecture-Dual%20Paradigm-blue)](#) [![Execution](https://img.shields.io/badge/Execution-Production%20Ready-green)](#) [![Integration](https://img.shields.io/badge/Integration-Multi--Site-orange)](#)

## Core Value Proposition

The `src/` directory implements the **operational execution layer** of the infrastructure management system, providing two complementary paradigms that address distinct phases of infrastructure lifecycle management:

- **`dic/`**: **Intelligent Parameter Resolution** - Advanced dependency injection for runtime operations
- **`set/`**: **Section-Based Deployment** - Systematic initial setup and multi-node orchestration

This dual-paradigm architecture ensures both **operational efficiency** through intelligent automation and **deployment consistency** through structured, testable procedures.

## Technical Architecture Overview

### **Operational Paradigms Comparison**

| Aspect | `src/dic/` (Operational) | `src/set/` (Deployment) |
|--------|--------------------------|--------------------------|
| **Purpose** | Runtime operations & administration | Initial setup & batch deployment |
| **Execution Model** | Dependency injection with parameter resolution | Section-based sequential execution |
| **Configuration** | Environment-aware variable resolution | Self-contained configuration loading |
| **Integration** | Pure function composition (`lib/ops/*`) | Direct implementation with menu framework |
| **Use Case** | Daily operations, troubleshooting, maintenance | Infrastructure provisioning, multi-node setup |
| **Dependencies** | DIC container + configuration hierarchy | Self-sufficient with `.menu` framework |

### **System Integration Flow**

```bash
# Operational Execution Layer Architecture
┌─────────────────────────────────────────────────────────────────────┐
│                        src/ - Execution Layer                      │
├─────────────────────────────┬───────────────────────────────────────┤
│        dic/ (Operations)    │         set/ (Deployment)             │
│                             │                                       │
│  ┌─────────────────────┐    │    ┌─────────────────────────────┐    │
│  │   DIC Container     │────┼────│   Section Framework        │    │
│  │   (Parameter        │    │    │   (.menu + hostname        │    │
│  │    Resolution)      │    │    │    scripts)                │    │
│  └─────────────────────┘    │    └─────────────────────────────┘    │
│           │                 │                   │                  │
│           ▼                 │                   ▼                  │
│  ┌─────────────────────┐    │    ┌─────────────────────────────┐    │
│  │  Pure Functions     │    │    │  Direct Implementation     │    │
│  │  (lib/ops/*)        │    │    │  (In-script functions)     │    │
│  └─────────────────────┘    │    └─────────────────────────────┘    │
└─────────────────────────────┴───────────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────────────────┐
                    │    Configuration Layer     │
                    │    (cfg/env/site*)          │
                    └─────────────────────────────┘
```

---

## DIC Operations Architecture (`src/dic/`)
# Intelligent Parameter Resolution Engine

### **Core Innovation: Adaptive Parameter Management**

The Dependency Injection Container (DIC) solves the **operational complexity problem** through intelligent parameter resolution, transforming rigid function calls into adaptive, context-aware operations.

#### **The Parameter Resolution Challenge**

Traditional infrastructure operations suffer from parameter management complexity:

```bash
# Pure Function Reality: All-or-Nothing Parameter Requirements
pve_vpt 100 on 01:00.0 02:00.0 8 4 "device1 device2" /etc/pve/config
#       ^^^ ^^^ ^^^^^^^ ^^^^^^^ ^ ^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^
#       All 8 parameters required - fragile and error-prone
```

#### **DIC Solution: Three-Mode Adaptive Execution**

```bash
# Mode 1: HYBRID - Partial specification + intelligent completion
ops pve vpt 100 on                    # User: 2 params, DIC: 6 params

# Mode 2: INJECTION - Complete environment-based resolution  
ops pve vpt -j                        # User: 0 params, DIC: 8 params

# Mode 3: EXPLICIT - Function-controlled execution
ops gpu pts -x                        # Pass control to function for validation
```

### **Technical Implementation Deep Dive**

#### **1. Function Signature Analysis Engine**

DIC employs sophisticated introspection to understand function requirements:

```bash
# Multi-method signature detection
1. Documentation parsing:    # Parameters: vm_id action pci0_id...
2. Local variable analysis:  local vm_id="$1" action="$2"...  
3. Parameter list scanning:  function_name() { vm_id action... }
4. Signature caching:        Store results for performance optimization
```

#### **2. Four-Tier Parameter Resolution Hierarchy**

```bash
# Resolution priority (highest to lowest)
┌─ 1. USER ARGUMENTS ─────────────────────────────────────────────┐
│   ops pve vpt 100 on [additional_args...]                      │
│   • Direct CLI specification                                   │
│   • Highest priority, no override                              │
└─────────────────────────────────────────────────────────────────┘
┌─ 2. HOSTNAME-SPECIFIC VARIABLES ────────────────────────────────┐
│   ${hostname}_NODE_PCI0="01:00.0"                              │
│   • Environment-aware configuration                            │
│   • Automatic hostname sanitization                            │
└─────────────────────────────────────────────────────────────────┘
┌─ 3. GLOBAL ENVIRONMENT VARIABLES ───────────────────────────────┐
│   VM_ID="100", CORE_COUNT_ON="8"                               │
│   • Cross-environment defaults                                 │
│   • Consistent fallback values                                 │
└─────────────────────────────────────────────────────────────────┘
┌─ 4. FUNCTION DEFAULTS ──────────────────────────────────────────┐
│   Built-in fallbacks within pure functions                     │
│   • Last resort values                                         │
│   • Ensures execution never fails due to missing parameters    │
└─────────────────────────────────────────────────────────────────┘
```

#### **3. Advanced Data Structure Processing**

```bash
# Array-to-String Conversion Engine
server01_USB_DEVICES=("device1" "device2" "device3")
# DIC Processing:
# 1. Detect array variable type
# 2. Convert to space-separated string: "device1 device2 device3"
# 3. Inject as single parameter for function consumption

# Hostname Sanitization Engine  
hostname="server-01.domain.com" → "server01"
# 1. Remove domain suffixes
# 2. Replace hyphens with underscores  
# 3. Convert to uppercase for variable naming
```

### **Execution Modes: Technical Analysis**

#### **Mode 1: Hybrid Execution (Direct Mode)**
*The Operational Sweet Spot*

```bash
ops pve vpt 100 on    # Perfect balance: User control + DIC automation
```

**Technical Flow:**
1. **User Input Capture**: `[100, on]` processed as priority arguments
2. **Signature Analysis**: Function signature reveals 8 required parameters
3. **Hybrid Resolution**: Positions 0-1 from user, positions 2-7 from DIC
4. **Context Application**: Environment-specific values injected seamlessly

**Debug Trace:**
```bash
$ OPS_DEBUG=1 ops pve vpt 100 on
[DIC] Function signature: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
[DIC] User args: [100] [on]
[DIC] server01_NODE_PCI0 → 01:00.0
[DIC] server01_NODE_PCI1 → 02:00.0  
[DIC] CORE_COUNT_ON → 8
[DIC] Final call: pve_vpt 100 on 01:00.0 02:00.0 8 4 "dev1 dev2" /etc/config
```

**Value Proposition:**
- **Interactive Override**: Change specific values while maintaining environment context
- **Progressive Specification**: Start simple, add complexity as needed
- **Debugging Capability**: Test with known values + environment defaults

#### **Mode 2: Injection Execution (`-j` flag)**
*Zero-Configuration Automation*

```bash
ops pve vpt -j    # Complete environment-based resolution
```

**Technical Flow:**
1. **Flag Consumption**: `-j` consumed by DIC, not passed to function
2. **Complete Resolution**: All 8 parameters resolved from environment hierarchy
3. **Clean Execution**: Function receives only resolved parameters
4. **Context Awareness**: Full hostname-specific configuration applied

**Use Cases:**
- **Automation Scripts**: Consistent, environment-aware execution
- **Batch Operations**: No human intervention required
- **Production Deployment**: Reliable, repeatable operations

#### **Mode 3: Explicit Execution (`-x` flag)**
*Function-Controlled Validation*

```bash
ops gpu pts -x    # Function decides execution requirements
```

**Technical Flow:**
1. **Flag Passthrough**: `-x` passed directly to function (not consumed by DIC)
2. **Function Control**: Target function validates its own execution requirements
3. **Standards Compliance**: Functions without parameters require `-x` for execution
4. **Safety Mechanism**: Prevents accidental execution of critical operations

### **Integration Architecture**

#### **Pure Function Integration**

```bash
# DIC to Pure Function Flow
src/dic/ops → Parameter Resolution → lib/ops/* → Business Logic
│              │                      │           │
│              │                      │           └─ No parameter handling
│              │                      └─ Clean function signatures  
│              └─ Environment context application
└─ User interface standardization
```

#### **Configuration Integration**

```bash
# Configuration Hierarchy Access
DIC Container
├── cfg/env/site1 (primary environment)
├── cfg/env/site1-dev (development overrides)  
├── cfg/env/site1-w2 (workstation-specific)
└── Function defaults (built-in fallbacks)
```

#### **Caching and Performance**

```bash
# Signature Analysis Caching
~/.cache/dic_signatures/
├── pve_vpt.sig (cached parameter list)
├── gpu_pts.sig (cached parameter list)
└── net_cfg.sig (cached parameter list)

# Cache Invalidation:
# - Function file modification time changes
# - Manual cache clear: rm -rf ~/.cache/dic_signatures
```

---

## Deployment Architecture (`src/set/`)
# Section-Based Infrastructure Provisioning

### **Core Innovation: Systematic Section-Based Deployment**

The `set/` directory implements a **section-based deployment architecture** designed for systematic infrastructure provisioning, multi-node orchestration, and repeatable deployment procedures.

#### **Deployment Challenge: Infrastructure Complexity**

Traditional infrastructure deployment suffers from procedural complexity and coordination challenges:

```bash
# Traditional Approach: Monolithic, Error-Prone
./deploy_everything.sh    # Black box, no granular control, difficult to debug
```

#### **Section-Based Solution: Modular, Testable, Coordinated**

```bash
# Section-Based Approach: Granular, Debuggable, Coordinated
./src/set/h1 -x a_xall    # Repository setup (specific, testable)
./src/set/h1 -x b_xall    # Package installation (isolated, recoverable)
./src/set/h1 -x c_xall    # Network configuration (targeted, verifiable)
```

### **Technical Implementation Deep Dive**

#### **1. Hostname-Based Script Architecture**

```bash
# File Naming Convention: Matches Infrastructure Topology
src/set/h1    # Hypervisor 1 (primary hypervisor setup)
src/set/c1    # Container 1 (container host configuration)  
src/set/c2    # Container 2 (secondary container host)
src/set/c3    # Container 3 (tertiary container host)
src/set/t1    # Test Node 1 (development/testing setup)
src/set/t2    # Test Node 2 (secondary test node)
```

**Design Principle**: Each script contains the complete deployment logic for its corresponding infrastructure node, enabling **targeted deployment** and **isolated testing**.

#### **2. Section Organization Architecture**

```bash
# Section Function Naming Pattern
a_xall()  # Primary setup (repositories, basic configuration)
b_xall()  # Package installation and services
c_xall()  # Network configuration  
d_xall()  # SSH keys and authentication
i_xall()  # Storage setup (RAID, Btrfs)
j_xall()  # ZFS datasets and configuration
p_xall()  # Container template management
q_xall()  # Container creation and configuration
r_xall()  # Bind mount configuration
s_xall()  # Virtual machine creation and setup
```

**Technical Benefits:**
- **Granular Execution**: Test individual deployment steps
- **Failure Recovery**: Re-run failed sections without full restart
- **Incremental Deployment**: Progressive infrastructure buildout
- **Debugging Capability**: Isolate issues to specific configuration areas

#### **3. Self-Sufficient Framework Integration**

```bash
# Automatic Framework Loading
# Every script sources .menu for complete functionality
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$(realpath "$DIR_SH/.menu")"

# .menu provides:
# 1. Logging functions (lo1_inf, lo1_err, etc.)  
# 2. Configuration loading (cfg/env/site*)
# 3. Interactive menu system (MENU_OPTIONS array)
# 4. Environment validation and setup
```

#### **4. Multi-Node Orchestration Architecture**

```bash
# Integration with sys-sca (System Scale) for coordination
sys-sca usr TYPE SSH_USERS IP_ARRAYS ALIASES "COMMAND"

# Example: Deploy section 'a' across all hypervisor nodes
sys-sca usr hy SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/h1 -x a_xall"

# Deployment Coordination Flow:
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Central Control   │───▶│   sys-sca Engine    │───▶│   Target Nodes      │
│   (Orchestrator)    │    │   (Distribution)    │    │   (Execution)       │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
          │                           │                           │
          │                           │                           │
    Command Definition      SSH Connection Pool      Section Execution
    Target Selection        Error Aggregation        Local Configuration
    Progress Monitoring     Result Collection        Environment Context
```

### **Execution Modes and Integration**

#### **Interactive Mode: Guided Deployment**

```bash
./src/set/h1 -i    # Interactive menu-driven deployment
```

**Technical Flow:**
1. **Menu Presentation**: Display available sections with descriptions
2. **User Selection**: Choose sections for execution
3. **Dependency Validation**: Check prerequisites for selected sections
4. **Sequential Execution**: Run sections in logical order
5. **Progress Reporting**: Real-time status and error handling

#### **Direct Mode: Targeted Execution**

```bash
./src/set/c1 -x a_xall    # Direct section execution
```

**Technical Flow:**
1. **Section Validation**: Verify section exists and is executable
2. **Environment Loading**: Source `.menu` and load configuration
3. **Prerequisite Check**: Validate required variables and dependencies
4. **Function Execution**: Run section function with full context
5. **Result Reporting**: Log success/failure with detailed output

#### **Batch Mode: Multi-Node Coordination**

```bash
sys-sca usr all SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/h1 -x b_xall"
```

**Technical Flow:**
1. **Target Resolution**: Resolve node groups and connection parameters
2. **Parallel Distribution**: Establish SSH connections to all targets
3. **Coordinated Execution**: Run sections simultaneously across nodes
4. **Result Aggregation**: Collect and consolidate results from all nodes
5. **Error Coordination**: Handle failures gracefully across the cluster

### **Configuration Integration and Context**

#### **Environment-Aware Configuration Loading**

```bash
# Configuration Hierarchy (loaded by .menu)
cfg/env/site1       # Primary site configuration
cfg/env/site1-dev   # Development environment overrides
cfg/env/site1-w2    # Workstation-specific configuration

# Automatic Variable Resolution
NODE_IP_ADDRESS="192.168.1.100"     # From site configuration
CONTAINER_TEMPLATES=("ubuntu-22")    # From environment file
ZFS_DATASETS=("data" "backup")       # From deployment specification
```

#### **Dynamic Configuration Processing**

```bash
# Example: Container Creation with Dynamic Configuration
q_xall() {
    for container_name in "${CONTAINER_NAMES[@]}"; do
        container_id="${container_name##*-}"  # Extract ID from name
        container_template="${CONTAINER_TEMPLATES[0]}"  # Default template
        
        # Create with environment-specific parameters
        pct create "$container_id" \
            "$container_template" \
            --hostname "$container_name" \
            --net0 "name=eth0,bridge=vmbr0,ip=${container_base_ip}${container_id}/24,gw=${GATEWAY_IP}" \
            --storage "$STORAGE_POOL"
    done
}
```

---

## Advanced Integration Architecture

### **Cross-Paradigm Integration Patterns**

#### **DIC + Set Integration: Operational Continuity**

```bash
# Deployment Phase (src/set/)
./src/set/h1 -x a_xall    # Initial hypervisor setup
./src/set/h1 -x s_xall    # VM creation and configuration

# Operational Phase (src/dic/)  
source src/dic/ops
ops pve vm start 100      # Start VMs with intelligent parameter resolution
ops gpu passthrough 101   # Configure GPU with environment awareness
```

**Integration Value**: Seamless transition from **deployment** to **operations** with consistent configuration context and parameter management.

#### **Configuration Continuity Architecture**

```bash
# Shared Configuration Foundation
cfg/env/site1
├── HYPERVISOR_IPS=("192.168.1.10" "192.168.1.11")    # Used by set/ for deployment
├── VM_IDS=("100" "101" "102")                         # Used by set/ for creation  
├── NODE_PCI0="01:00.0"                                # Used by dic/ for operations
└── STORAGE_POOLS=("local-zfs" "backup")               # Used by both paradigms

# Result: Consistent Environment Context Across Operational Phases
```

### **Error Handling and Recovery Architecture**

#### **DIC Error Handling: Parameter Resolution Failures**

```bash
# Parameter Resolution Error Flow
ops pve vpt 100 on
│
├─ Parameter Missing → [DIC] Warning: Could not resolve 'pci0_id', using default
├─ Function Not Found → [DIC] Error: Function 'pve_vpt' not found in lib/ops/pve  
├─ Execution Failure → [DIC] Function execution failed, check parameters
└─ Success → [DIC] Executed: pve_vpt 100 on 01:00.0 02:00.0 8 4 "dev1 dev2" /etc/config
```

#### **Set Error Handling: Section Execution Failures**

```bash
# Section Execution Error Flow  
./src/set/h1 -x b_xall
│
├─ Prerequisite Failure → [ERROR] Required configuration missing: PACKAGE_LIST
├─ Network Failure → [ERROR] Could not reach package repository
├─ Permission Error → [ERROR] Insufficient privileges for package installation
└─ Success → [INFO] Package installation completed successfully
```

### **Performance and Optimization**

#### **DIC Performance Optimizations**

```bash
# Signature Caching: ~/.cache/dic_signatures/
# - First call: 50ms (signature analysis)  
# - Cached calls: 5ms (cache lookup)
# - Cache invalidation: Function file modification time

# Parameter Resolution: Environment Variable Lookup
# - Hostname sanitization: 1ms
# - Variable resolution: 2ms per parameter
# - Array processing: 3ms per array
```

#### **Set Performance Considerations**

```bash
# Section Execution Optimization
# - Menu loading: 10ms (.menu source)
# - Configuration loading: 15ms (cfg/env/* files)  
# - Section function: Variable (depends on operations)
# - Multi-node: Parallel SSH execution (sys-sca optimization)
```

---

## Documentation and Diagnostic Architecture

### **Integrated Documentation Strategy**

| Component | Documentation Type | Location | Technical Depth |
|-----------|-------------------|----------|-----------------|
| **DIC Core** | Technical Architecture | [`src/dic/README.md`](dic/README.md) | Deep technical analysis |
| **Set Framework** | Section Documentation | In-script comments | Function-level documentation |
| **Integration** | Architecture Overview | This document | Cross-system integration |
| **Configuration** | Environment Setup | [`cfg/README.md`](../cfg/README.md) | Configuration management |

### **Advanced Debugging and Diagnostics**

#### **DIC Debugging: Parameter Resolution Tracing**

```bash
# Enable comprehensive DIC debugging
export OPS_DEBUG=1
ops pve vpt 100 on

# Output: Complete parameter resolution trace
[DIC] Function signature: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
[DIC] Using user argument for vm_id: 100
[DIC] Using user argument for action: on
[DIC] Resolved pci0_id -> server01_NODE_PCI0 -> 01:00.0
[DIC] Resolved pci1_id -> server01_NODE_PCI1 -> 02:00.0
[DIC] Resolved core_count_on -> CORE_COUNT_ON -> 8
[DIC] Using default for pve_conf_path: /etc/pve/config
[DIC] Final arguments: [100] [on] [01:00.0] [02:00.0] [8] [4] [dev1 dev2] [/etc/config]
```

#### **Set Debugging: Section Execution Tracing**

```bash
# Enable comprehensive section debugging  
export DEBUG=1
./src/set/h1 -x a_xall

# Output: Section execution trace with configuration loading
[DEBUG] Sourcing: /home/es/lab/src/set/.menu
[DEBUG] Loading configuration: cfg/env/site1
[DEBUG] Executing section: a_xall
[INFO] Disabling enterprise repository...
[INFO] Adding community repository...
[SUCCESS] Section a_xall completed successfully
```

---

## Strategic Value and Operational Benefits

### **Operational Excellence Through Dual Paradigms**

#### **DIC Benefits: Intelligent Operations**
- **Adaptive Execution**: Three modes adapt to operational context
- **Environmental Consistency**: Automatic hostname-aware configuration
- **Operational Efficiency**: Reduced command complexity and error rates
- **Debugging Capability**: Complete parameter resolution visibility

#### **Set Benefits: Systematic Deployment** 
- **Procedural Reliability**: Section-based deployment reduces errors
- **Scalability**: Multi-node coordination through `sys-sca` integration
- **Testability**: Granular section testing and validation
- **Recovery Capability**: Failed sections can be re-run independently

### **Combined Architectural Value**

The dual-paradigm approach provides **complete lifecycle coverage**:

1. **Infrastructure Provisioning** (`set/`) → **Operational Management** (`dic/`)
2. **Deployment Consistency** (`set/`) → **Runtime Flexibility** (`dic/`)  
3. **Systematic Setup** (`set/`) → **Intelligent Operations** (`dic/`)
4. **Multi-Node Coordination** (`set/`) → **Context-Aware Administration** (`dic/`)

This creates a **comprehensive infrastructure management ecosystem** that scales from initial deployment through ongoing operations, maintaining consistency while providing the flexibility required for complex infrastructure administration.

---

## Quick Reference

### **DIC Operations Quick Start**

```bash
# Source DIC operations
source src/dic/ops

# List available functions
ops gpu                    # Show GPU functions
ops pve                    # Show Proxmox functions  

# Execute with different modes
ops pve vpt 100 on         # Hybrid: partial specification
ops pve vpt -j             # Injection: full resolution
ops gpu pts -x             # Explicit: function validation
```

### **Set Deployment Quick Start**

```bash
# Interactive deployment
./src/set/h1 -i           # Guided hypervisor setup

# Direct section execution  
./src/set/c1 -x a_xall    # Container NFS setup

# Multi-node deployment
sys-sca usr all SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/h1 -x b_xall"
```

---

## Related Documentation

- [**DIC Technical Architecture**](dic/README.md) - Comprehensive DIC implementation analysis
- [**Configuration Management**](../cfg/README.md) - Environment setup and variable hierarchy
- [**Pure Function Library**](../lib/README.md) - Core operational function documentation  
- [**System Architecture**](../doc/README.md) - Complete system design documentation
- [**Multi-Node Operations**](../lib/ops/README.md) - Scale operations and sys-sca integration

---

**Navigation**: [← Return to Main Documentation](../README.md) | [DIC Technical Details →](dic/README.md)
