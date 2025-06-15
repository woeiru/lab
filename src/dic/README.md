# Dependency Injection Container (DIC)
# Intelligent Parameter Resolution and Execution Engine

## Core Value Proposition

The DIC transforms operational complexity through **intelligent parameter management**, providing three distinct execution modes that adapt to different operational contexts while maintaining function purity and environmental consistency.

### **The Parameter Management Problem**

Traditional operational tools force users into rigid parameter patterns:

```bash
# Pure Function Approach: All-or-Nothing
pve_vpt 100 on 01:00.0 02:00.0 8 4 "dev1 dev2" /etc/pve/config    # ✅ All 8 parameters
pve_vpt 100 on                                                     # ❌ Missing parameters - fails

# Legacy Wrapper Approach: Hidden Dependencies  
arc_pve_vpt_enable 100    # ✅ Works but hides configuration, hard to debug
```

### **The DIC Solution: Adaptive Parameter Intelligence**

DIC provides **three execution modes** that adapt to operational context:

```bash
# 1. HYBRID MODE: Partial specification + Auto-completion
ops pve vpt 100 on              # ✅ User provides 2, DIC injects 6 parameters

# 2. INJECTION MODE: Zero-configuration automation  
ops pve vpt -j                  # ✅ DIC resolves all 8 parameters automatically

# 3. EXPLICIT MODE: Function-controlled execution
ops gpu pts -x                  # ✅ Passes -x to function for validation
```

## Technical Architecture Deep Dive

### 1. **Function Signature Analysis Engine**

DIC employs sophisticated signature analysis to understand function requirements:

```bash
$ OPS_DEBUG=1 ops pve vpt 100 on
[DIC] Analyzing signature for: pve_vpt
[DIC] Extracted parameters (method 1): vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
[DIC] Cached signature: pve_vpt -> vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
```

**Analysis Methods:**
1. **Comment Block Parsing**: Extracts parameters from function documentation
2. **Local Variable Detection**: Analyzes function body for parameter assignments  
3. **Signature Caching**: Stores results for performance optimization

### 2. **Parameter Resolution Hierarchy**

DIC implements a **four-tier resolution system** with intelligent fallbacks:

```bash
# Resolution Priority (highest to lowest):
1. USER ARGUMENTS:     ops pve vpt 100 on [...]          # Direct CLI specification
2. HOSTNAME-SPECIFIC:  ${hostname}_NODE_PCI0="01:00.0"   # Environment-aware variables
3. GLOBAL VARIABLES:   VM_ID="100"                       # Cross-environment defaults  
4. FUNCTION DEFAULTS:  nvidia_driver_preference="nvidia"  # Built-in fallbacks
```

**Resolution Process:**
```bash
$ OPS_DEBUG=1 ops pve vpt 100
[DIC] Using user argument for vm_id: 100
[DIC] Using sanitized hostname: server01
[DIC] Resolved pci0_id -> server01_NODE_PCI0 -> 01:00.0
[DIC] Resolved core_count_on -> CORE_COUNT_ON -> 8
[DIC] Using default for pve_conf_path: /etc/pve/config
```

### 3. **Array Processing and Type Conversion**

DIC automatically handles complex data structures:

```bash
# Configuration with arrays
server01_USB_DEVICES=("device1" "device2" "device3")

# DIC conversion process
[DIC] Found array variable: server01_USB_DEVICES
[DIC] Converting array to space-separated string: "device1 device2 device3"  
[DIC] Injected variable for usb_devices_str: device1 device2 device3
```

**Supported Conversions:**
- **Array → String**: `("a" "b" "c")` → `"a b c"`
- **Hostname Sanitization**: `server-01.domain.com` → `server01`
- **Variable Name Mapping**: `pci0_id` → `${hostname}_NODE_PCI0`

## Execution Modes: Deep Technical Analysis

### **Mode 1: Hybrid Execution (Direct Mode)**
*Partial Specification + Intelligent Auto-Completion*

```bash
ops pve vpt 100 on    # User provides 2 parameters, DIC completes remaining 6
```

**Technical Flow:**
1. **User Input Processing**: `[100, on]` captured as user arguments
2. **Signature Analysis**: Function requires 8 parameters total
3. **Hybrid Resolution**: User args fill positions 0-1, DIC resolves positions 2-7
4. **Parameter Completion**: Final array `[100, on, "01:00.0", "02:00.0", 8, 4, "dev1 dev2", "/etc/config"]`

**Debug Trace Example:**
```bash
$ OPS_DEBUG=1 ops pve vpt 100 on
[DIC] Function signature: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
[DIC] Using user argument for vm_id: 100
[DIC] Using user argument for action: on  
[DIC] Injected variable for pci0_id: 01:00.0
[DIC] Injected variable for pci1_id: 02:00.0
[DIC] Final arguments array: [100] [on] [01:00.0] [02:00.0] [8] [4] [dev1 dev2] [/etc/config]
```

**Use Cases:**
- **Interactive Override**: `ops pve vpt 101 off` (change VM and action, keep environment)
- **Progressive Specification**: `ops pve vpt 100 on 02:00.0` (override specific hardware)
- **Development Testing**: Mix known values with environment defaults

### **Mode 2: Injection Execution (`-j` flag)**
*Zero-Configuration Automation*

```bash
ops pve vpt -j    # DIC resolves all parameters from environment
```

**Technical Flow:**
1. **Flag Processing**: `-j` flag detected and consumed by DIC
2. **Complete Resolution**: All parameters resolved from environment hierarchy
3. **Clean Execution**: Function receives only resolved parameters
4. **Environment Context**: Full hostname-specific configuration applied

**Resolution Strategy:**
```bash
$ OPS_DEBUG=1 ops pve vpt -j
[DIC] Injecting dependencies for: pve_vpt
[DIC] Resolved vm_id -> VM_ID -> 100
[DIC] Resolved action -> PVE_ACTION -> on  
[DIC] Resolved pci0_id -> server01_NODE_PCI0 -> 01:00.0
[DIC] Resolved usb_devices_str -> server01_USB_DEVICES -> dev1 dev2 dev3
[DIC] Executing: pve_vpt 100 on 01:00.0 02:00.0 8 4 "dev1 dev2 dev3" /etc/config
```

**Use Cases:**
- **Production Automation**: Full environment-aware execution
- **Batch Operations**: Consistent configuration across multiple calls
- **CI/CD Integration**: Environment-specific deployments

### **Mode 3: Explicit Execution (`-x` flag)**
*Function-Controlled Validation*

```bash
ops gpu pts -x    # Passes -x through to function for spec-compliant validation
```

**Technical Flow:**
1. **Flag Pass-Through**: `-x` flag preserved and sent to function
2. **Function Validation**: Target function handles `-x` according to .spec requirements  
3. **No DIC Injection**: DIC acts as transparent proxy
4. **Spec Compliance**: Supports functions requiring explicit execution flags

**Implementation Details:**
```bash
# DIC Logic
if [[ "$1" == "-x" ]]; then
    # Pass -x directly to function - no injection
    ops_execute "$module" "$function" "$@"
fi

# Function receives exactly: gpu_pts -x
# Function validates: [ $# -ne 1 ] || [ "$1" != "-x" ] -> show usage
```

**Use Cases:**
- **Spec-Compliant Functions**: Functions requiring `-x` for safety
- **Action Functions**: Destructive operations needing explicit confirmation
- **Legacy Compatibility**: Maintains compatibility with .spec standards

## Advanced Operational Features

### **Parameter Preview System**
*Pre-execution Analysis and Validation*

The parameter preview system provides **complete transparency** into DIC's resolution process:

```bash
$ ops pve vpt
Function: pve_vpt
Parameter injection preview:

  Parameters and available injections:
    vm_id          → <vm_id:100>           # Resolved from VM_ID global  
    action         → <action>              # Missing - no default available
    pci0_id        → <pci0_id:01:00.0>     # Resolved from server01_NODE_PCI0
    pci1_id        → <pci1_id:02:00.0>     # Resolved from server01_NODE_PCI1  
    core_count_on  → <core_count_on:8>     # Resolved from CORE_COUNT_ON
    core_count_off → <core_count_off:4>    # Resolved from CORE_COUNT_OFF
    usb_devices    → <usb_devices:dev1 dev2 dev3>  # Array conversion from server01_USB_DEVICES
    pve_conf_path  → <pve_conf_path:/etc/pve/config>  # Default value

Legend: <param:value> shows injected values, <param> shows missing variables
```

**Preview Analysis:**
- **Green Parameters**: Successfully resolved with source identification
- **Red Parameters**: Missing variables requiring attention  
- **Source Tracing**: Shows exactly where each value originates
- **Type Information**: Indicates array conversions and defaults

### **Debug Mode: Complete Resolution Tracing**

```bash
$ OPS_DEBUG=1 ops pve vpt -j
[DIC] ============ EXECUTION START ============
[DIC] Sourcing utility libraries from: /home/es/lab/lib/gen
[DIC] Sourcing environment config: /home/es/lab/cfg/env/site1
[DIC] Executing: pve_vpt with args: 
[DIC] ============ SIGNATURE ANALYSIS ============
[DIC] Analyzing signature for: pve_vpt
[DIC] Signature analysis method: comment_parsing
[DIC] Raw signature: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
[DIC] Cached signature: pve_vpt -> vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
[DIC] ============ PARAMETER RESOLUTION ============
[DIC] Processing parameter 1/8: vm_id
[DIC] Using sanitized hostname: server01
[DIC] Checking hostname-specific: server01_VM_ID
[DIC] Checking global variable: VM_ID
[DIC] Resolved vm_id -> VM_ID -> 100
[DIC] Processing parameter 2/8: action
[DIC] Checking hostname-specific: server01_ACTION  
[DIC] Checking global variable: ACTION
[DIC] Checking global variable: PVE_ACTION
[DIC] Resolved action -> PVE_ACTION -> on
[DIC] ============ ARRAY PROCESSING ============
[DIC] Processing parameter 7/8: usb_devices_str
[DIC] Found array variable: server01_USB_DEVICES
[DIC] Array contents: [dev1] [dev2] [dev3]
[DIC] Converting to string: dev1 dev2 dev3
[DIC] ============ EXECUTION ============
[DIC] Final arguments count: 8
[DIC] Final arguments array: [100] [on] [01:00.0] [02:00.0] [8] [4] [dev1 dev2 dev3] [/etc/pve/config]
[DIC] Executing: pve_vpt with 8 arguments
```

### **Environment Validation and Health Checks**

DIC provides comprehensive environment validation:

```bash
$ ops --validate=strict pve vpt -j
[VALIDATION] Environment configuration: /home/es/lab/cfg/env/site1 ✓
[VALIDATION] Library modules: /home/es/lab/lib/ops ✓  
[VALIDATION] Function existence: pve_vpt ✓
[VALIDATION] Required variables check:
  ✓ VM_ID=100 (global)
  ✓ server01_NODE_PCI0=01:00.0 (hostname-specific)  
  ✓ server01_NODE_PCI1=02:00.0 (hostname-specific)
  ⚠ PVE_ACTION not set, no default available
  ✓ server01_USB_DEVICES array (3 elements)
[VALIDATION] Missing dependencies: 1 warning, 0 errors
[RECOMMENDATION] Set PVE_ACTION=on or provide as argument: ops pve vpt 100 on -j
```

### **Performance Optimization and Caching**

DIC implements **multi-level caching** for production performance:

```bash
# Signature Analysis Caching
[DIC] Cache HIT: pve_vpt signature (0.001s vs 0.045s analysis)
[DIC] Cache statistics: 47 hits, 3 misses, 94% hit rate

# Variable Resolution Caching  
[DIC] Cache HIT: server01_NODE_PCI0 -> 01:00.0 (0.000s vs 0.012s resolution)
[DIC] Environment cache: 127 variables cached, 2.3MB memory usage

# Performance Metrics
[DIC] Total execution time: 0.156s (0.089s injection + 0.067s function)
[DIC] Cache savings: 0.234s (60% performance improvement)
```

**Cache Management:**
```bash
export OPS_CACHE=1                    # Enable caching (default)
export OPS_CACHE_SIZE=1000            # Maximum cached entries
export OPS_CACHE_TTL=3600             # Cache expiration (seconds)

# Cache control
ops --cache-clear                     # Clear all caches
ops --cache-stats                     # Show cache statistics
```

## Complex Integration Scenarios

### **Multi-Environment Deployment Patterns**

DIC supports sophisticated deployment scenarios through **environment-aware resolution**:

```bash
# Development Environment
SITE_CONFIG=/home/dev/cfg/env/dev ops gpu pts -j
[DIC] Environment: dev, Hostname: dev-server01
[DIC] Resolved: dev-server01_NODE_PCI0 -> 01:00.0 (development GPU)

# Staging Environment  
SITE_CONFIG=/home/stage/cfg/env/staging ops gpu pts -j
[DIC] Environment: staging, Hostname: stage-server01  
[DIC] Resolved: stage-server01_NODE_PCI0 -> 02:00.0 (staging GPU)

# Production Environment
SITE_CONFIG=/home/prod/cfg/env/production ops gpu pts -j
[DIC] Environment: production, Hostname: prod-server01
[DIC] Resolved: prod-server01_NODE_PCI0 -> 03:00.0 (production GPU)
```

### **Cross-Function Dependency Chains**

DIC enables **function composition** with automatic dependency propagation:

```bash
# Step 1: GPU detection feeds into VM configuration
ops gpu detect -j > /tmp/gpu_config
[DIC] Auto-detected: server01_NODE_PCI0=01:00.0, server01_NODE_PCI1=02:00.0

# Step 2: VM configuration uses detected GPU values  
source /tmp/gpu_config && ops pve vpt -j
[DIC] Using detected: pci0_id=01:00.0, pci1_id=02:00.0
[DIC] VM passthrough configured with auto-detected GPUs
```

### **Conditional Resolution Logic**

DIC implements **context-aware parameter resolution**:

```bash
# GPU-specific logic in DIC resolution
if [[ "$function_name" =~ ^gpu_(ptd|pta)$ ]]; then
    # Auto-inject driver preference for GPU functions
    if [[ ${#user_args[@]} -eq 0 ]] || [[ "${user_args[0]}" != "-d" ]]; then
        local driver_pref="${GPU_DRIVER_PREFERENCE:-lookup}"
        final_args+=("-d" "$driver_pref")
        ops_debug "Auto-injected -d flag for GPU function: -d $driver_pref"
    fi
fi
```

**Smart Injection Results:**
```bash
$ ops gpu ptd -j
[DIC] GPU function detected: gpu_ptd
[DIC] Auto-injecting driver preference: -d nvidia
[DIC] Final call: gpu_ptd -d nvidia server01 /etc/config 01:00.0 02:00.0 nvidia
```

## Error Handling and Recovery Strategies

### **Graceful Degradation Patterns**

DIC implements **intelligent fallback** strategies when dependencies are missing:

```bash
$ ops pve vpt -j
[DIC] Resolution attempt: vm_id
  ├─ server01_VM_ID: ❌ not found
  ├─ VM_ID: ❌ not found  
  ├─ DEFAULT_VM_ID: ❌ not found
  └─ FALLBACK: Request user input or show usage

[ERROR] VM ID cannot be empty
Description: Toggles PCIe passthrough configuration for a specified VM
Usage: pve_vpt <vm_id> <on|off> <pci0_id> <pci1_id> <core_count_on> <core_count_off> <usb_devices_str> <pve_conf_path>

RESOLUTION SUGGESTIONS:
  1. Set environment variable: export VM_ID=100
  2. Use direct mode: ops pve vpt 100 on -j  
  3. Use hybrid mode: ops pve vpt 100 on
```

### **Dependency Validation and Repair**

```bash
$ ops --doctor pve vpt
[DOCTOR] Analyzing dependencies for: pve_vpt
[DOCTOR] ============ CONFIGURATION HEALTH ============
✓ Environment file: /home/es/lab/cfg/env/site1 (loaded)
✓ Library module: /home/es/lab/lib/ops/pve (sourced)  
✓ Function exists: pve_vpt (8 parameters required)

[DOCTOR] ============ PARAMETER RESOLUTION ============
✓ vm_id: Multiple sources available
  ├─ VM_ID=100 (global) ✓
  └─ server01_VM_ID (hostname-specific) ❌ missing
⚠ action: No defaults configured
  └─ RECOMMENDATION: Set PVE_ACTION=on in environment
✓ pci0_id: server01_NODE_PCI0=01:00.0 ✓
✓ pci1_id: server01_NODE_PCI1=02:00.0 ✓

[DOCTOR] ============ REPAIR SUGGESTIONS ============
1. Missing variables (1): 
   echo 'export PVE_ACTION=on' >> cfg/env/site1
2. Redundant variables (0): none
3. Hostname consistency: ✓ server01 format valid

[DOCTOR] Run with --fix to automatically apply repairs
```

### **Runtime Error Recovery**

DIC provides **intelligent error recovery** during execution:

```bash
$ ops pve vpt -j
[DIC] Starting parameter resolution...
[ERROR] Configuration file not found: /home/es/lab/cfg/env/site1
[DIC] RECOVERY: Searching for alternative configuration files...
[DIC] Found: /home/es/lab/cfg/env/site1-backup ✓
[DIC] RECOVERY: Using backup configuration
[WARNING] Using backup configuration - verify settings before production use
[DIC] Continuing with backup environment...
```

## Advanced Use Cases and Patterns

### **Infrastructure as Code Integration**

DIC enables **seamless IaC integration** through environment variable mapping:

```bash
# Terraform → DIC Environment Variables
terraform output -json | jq -r '.gpu_config.value | to_entries[] | "export \(.key)=\(.value)"' > /tmp/tf_env
source /tmp/tf_env

# DIC automatically picks up Terraform-generated configuration
ops gpu pts -j
[DIC] Resolved pci0_id -> TF_GPU_PRIMARY -> 01:00.0 (from terraform)
[DIC] Resolved pci1_id -> TF_GPU_SECONDARY -> 02:00.0 (from terraform)
```

### **CI/CD Pipeline Integration**

```bash
# GitLab CI/CD Pipeline with DIC
deploy:
  script:
    - source cfg/env/${CI_ENVIRONMENT_NAME}
    - export VM_ID=${CI_PIPELINE_ID}
    - ops pve vpt -j  # Environment-aware deployment
  environment:
    name: ${CI_COMMIT_REF_NAME}
```

### **Monitoring and Observability**

DIC provides **comprehensive execution telemetry**:

```bash
$ OPS_TELEMETRY=1 ops pve vpt -j
[TELEMETRY] execution_start: 2025-06-15T19:30:15Z
[TELEMETRY] function: pve_vpt
[TELEMETRY] mode: injection
[TELEMETRY] signature_analysis_time: 0.045s
[TELEMETRY] parameter_resolution_time: 0.089s  
[TELEMETRY] parameters_resolved: 8/8
[TELEMETRY] cache_hits: 6/8 (75%)
[TELEMETRY] environment: site1
[TELEMETRY] hostname: server01
[TELEMETRY] execution_time: 2.341s
[TELEMETRY] exit_code: 0
[TELEMETRY] execution_end: 2025-06-15T19:30:17Z
```

## Performance Analysis and Optimization

### **Execution Time Breakdown**

DIC provides **detailed performance profiling** for optimization:

```bash
$ OPS_PROFILE=1 ops pve vpt -j
[PROFILE] ============ PERFORMANCE BREAKDOWN ============
[PROFILE] Environment loading: 0.012s
  ├─ Utility libraries: 0.003s  
  ├─ Configuration files: 0.007s
  └─ Variable parsing: 0.002s
[PROFILE] Signature analysis: 0.045s
  ├─ Function discovery: 0.008s
  ├─ Comment parsing: 0.032s  
  └─ Caching: 0.005s
[PROFILE] Parameter resolution: 0.089s
  ├─ Variable lookup: 0.067s
  ├─ Array processing: 0.018s
  └─ Type conversion: 0.004s
[PROFILE] Function execution: 2.341s
[PROFILE] ============ TOTAL: 2.487s ============
[PROFILE] DIC overhead: 0.146s (5.9% of total execution)
```

### **Memory Usage Optimization**

```bash
$ OPS_MEMORY=1 ops pve vpt -j
[MEMORY] DIC process memory usage:
[MEMORY] Signature cache: 2.3MB (1,247 entries)
[MEMORY] Variable cache: 4.1MB (3,891 variables)  
[MEMORY] Environment state: 1.2MB
[MEMORY] Working memory: 0.8MB
[MEMORY] Total DIC overhead: 8.4MB
[MEMORY] Peak function memory: 45.2MB
[MEMORY] Total process memory: 53.6MB
```

### **Scalability Metrics**

DIC performance scales efficiently with system complexity:

```bash
# Single function call
ops pve vpt -j                    # 0.146s DIC overhead

# Batch operations (100 calls)  
for i in {1..100}; do
    ops pve vpt $i on -j
done                              # 0.008s average DIC overhead (95% cache hit rate)

# Complex environment (500+ variables)
ops gpu pts -j                    # 0.203s DIC overhead (2.8MB cache)
```

## Integration Architecture

### **Library Integration Depth Analysis**

DIC integrates with multiple system layers through **well-defined interfaces**:

```
┌─────────────────────────────────────────────────────────────┐
│                    DIC Integration Stack                    │
├─────────────────────────────────────────────────────────────┤
│ CLI Layer: ops MODULE FUNCTION [ARGS|FLAGS]                │
├─────────────────────────────────────────────────────────────┤
│ DIC Engine: Signature Analysis + Parameter Resolution      │
│   ├─ Execution Modes: -j (inject), -x (explicit), direct  │  
│   ├─ Caching Layer: Signatures + Variables + Environment  │
│   └─ Debug/Telemetry: Tracing + Performance + Validation  │
├─────────────────────────────────────────────────────────────┤
│ Pure Functions: lib/ops/* (stateless, testable)           │
│   ├─ Parameter Validation: aux_val, aux_use, aux_tec      │
│   ├─ Structured Logging: aux_info, aux_warn, aux_err      │
│   └─ Business Logic: GPU, PVE, System Operations          │
├─────────────────────────────────────────────────────────────┤
│ Configuration Layer: cfg/env/* (environment-specific)      │
│   ├─ Hostname Variables: ${hostname}_VARIABLE_NAME        │
│   ├─ Global Variables: VARIABLE_NAME                      │
│   └─ Array Support: VARIABLE=("val1" "val2" "val3")       │
├─────────────────────────────────────────────────────────────┤
│ System Layer: Hardware, Services, File System             │
└─────────────────────────────────────────────────────────────┘
```

### **Legacy System Migration Strategy**

DIC provides **seamless migration** from legacy wrapper approaches:

```bash
# Phase 1: Legacy Wrapper (arc/mgt approach)
arc_pve_vpt_enable 100            # Hidden configuration, hard to debug

# Phase 2: DIC Hybrid (gradual migration)  
ops pve vpt 100 on -j            # Partial specification + auto-completion

# Phase 3: Full DIC (pure automation)
ops pve vpt -j                   # Complete environment-aware automation

# Phase 4: Pure Function (testing/development)
pve_vpt 100 on 01:00.0 02:00.0 8 4 "dev1 dev2" /etc/config  # Full control
```

**Migration Benefits:**
- **Zero Breaking Changes**: Existing scripts continue working
- **Progressive Adoption**: Teams can migrate function-by-function  
- **Backward Compatibility**: DIC supports all legacy patterns
- **Training Efficiency**: Familiar function names with enhanced capabilities

## Troubleshooting and Diagnostics

### **Comprehensive Diagnostic Suite**

```bash
# Complete system health check
$ ops --diagnose pve vpt
[DIAGNOSTIC] ============ SYSTEM HEALTH ============
✓ Environment initialization: bin/ini sourced correctly
✓ Library paths: LIB_OPS_DIR=/home/es/lab/lib/ops  
✓ Configuration: SITE_CONFIG_FILE=/home/es/lab/cfg/env/site1
✓ Hostname detection: server01 (sanitized from server-01.domain.com)

[DIAGNOSTIC] ============ FUNCTION ANALYSIS ============
✓ Module exists: /home/es/lab/lib/ops/pve
✓ Function exists: pve_vpt (line 1342)
✓ Signature cached: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
✓ Parameter count: 8 (matches function definition)

[DIAGNOSTIC] ============ DEPENDENCY CHECK ============
✓ Required commands: systemctl, virsh, lspci
✓ File permissions: /etc/pve/ (read/write access)
✓ Network connectivity: PVE cluster reachable
⚠ Optional dependencies: 
  └─ nvidia-smi: not found (GPU operations may be limited)

[DIAGNOSTIC] ============ CONFIGURATION VALIDATION ============
✓ vm_id resolution chain: VM_ID=100
✓ pci0_id resolution chain: server01_NODE_PCI0=01:00.0
✓ pci1_id resolution chain: server01_NODE_PCI1=02:00.0  
⚠ action resolution chain: no defaults configured
  └─ SUGGESTION: export PVE_ACTION=on

[DIAGNOSTIC] ============ PERFORMANCE CHECK ============
✓ Cache performance: 94% hit rate, 2.3MB usage
✓ Resolution speed: 0.089s average (target: <0.100s)
✓ Memory usage: 8.4MB DIC overhead (healthy)

[DIAGNOSTIC] Status: HEALTHY (1 warning, 0 errors)
```

### **Interactive Debugging Session**

```bash
$ ops --debug-interactive pve vpt
DIC Interactive Debug Session
> Available commands: resolve, cache, env, signature, execute, help

[DEBUG] > resolve vm_id
[RESOLVE] Parameter: vm_id
[RESOLVE] ├─ Checking hostname-specific: server01_VM_ID ❌
[RESOLVE] ├─ Checking global: VM_ID ✓ = 100  
[RESOLVE] ├─ Checking environment: PVE_VM_ID ❌
[RESOLVE] └─ Resolution: VM_ID=100 (source: global)

[DEBUG] > signature pve_vpt  
[SIGNATURE] Function: pve_vpt
[SIGNATURE] Analysis method: comment_parsing
[SIGNATURE] Raw signature: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
[SIGNATURE] Cached: yes (generated 2 minutes ago)

[DEBUG] > execute dry-run
[EXECUTE] Dry-run mode: showing what would be executed
[EXECUTE] Final command: pve_vpt 100 ${PVE_ACTION} 01:00.0 02:00.0 8 4 "dev1 dev2 dev3" /etc/pve/config  
[EXECUTE] Missing variables: PVE_ACTION
[EXECUTE] Ready for execution: NO (1 missing dependency)
```

---

## Summary: DIC's Technical Excellence

The Dependency Injection Container represents a **paradigm shift** from traditional operational tooling through:

### **Intelligent Automation**
- **Multi-mode execution** adapting to operational context
- **Intelligent parameter completion** bridging manual and automated workflows  
- **Environment-aware resolution** enabling seamless multi-environment operation

### **Operational Excellence**  
- **Zero-configuration production** with comprehensive debugging capabilities
- **Performance optimization** through sophisticated caching and profiling
- **Error resilience** with graceful degradation and recovery strategies

### **Developer Experience**
- **Function purity preservation** maintaining testability and maintainability
- **Progressive disclosure** from simple automation to complete control
- **Comprehensive diagnostics** enabling rapid troubleshooting and optimization

The DIC eliminates the traditional trade-off between operational simplicity and technical flexibility, enabling both **automated production workflows** and **precise development control** through a single, sophisticated interface that scales from simple operations to complex multi-environment deployments.
