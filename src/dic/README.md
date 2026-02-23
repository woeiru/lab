# Dependency Injection Container (DIC)

The DIC is the intelligent parameter resolution and execution engine for operations. It adapts to different operational contexts while maintaining function purity and environmental consistency.

It serves as the execution engine for the `src/set/` deployment framework. Set scripts orchestrate DIC operations to execute together as coordinated deployment sections, rather than calling pure functions directly.

```bash
# INCORRECT: Direct pure function calls in src/set/
a_xall() {
    pve-dsr
    usr-adr "$file" "$line"
}

# CORRECT: DIC operation orchestration in src/set/
a_xall() {
    ops pve dsr -j
    ops usr adr -j
}
```

## Technical Architecture

### 1. Function Signature Analysis Engine

DIC uses signature analysis to understand function requirements:

```bash
$ OPS_DEBUG=1 ops pve vpt 100 on
[DIC] Analyzing signature for: pve_vpt
[DIC] Extracted parameters: vm_id action pci0_id pci1_id core_count_on core_count_off usb_devices_str pve_conf_path
```

Analysis Methods:
1. Comment Block Parsing: Extracts parameters from function documentation
2. Local Variable Detection: Analyzes function body for parameter assignments
3. Signature Caching: Stores results for performance optimization

### 2. Parameter Resolution Hierarchy

DIC implements a four-tier resolution system:

1. **User Arguments**: `ops pve vpt 100 on` (Direct CLI specification)
2. **Hostname-Specific**: `${hostname}_NODE_PCI0="01:00.0"` (Environment-aware variables)
3. **Global Variables**: `VM_ID="100"` (Cross-environment defaults)
4. **Function Defaults**: Built-in fallbacks

### 3. Array Processing and Type Conversion

DIC automatically handles complex data structures, such as converting bash arrays into space-separated strings required by function arguments:

```bash
# Configuration with arrays
server01_USB_DEVICES=("device1" "device2")

# DIC conversion process
[DIC] Found array variable: server01_USB_DEVICES
[DIC] Converting array to space-separated string: "device1 device2"
```

## Execution Modes

### Mode 1: Hybrid Execution

Provide necessary arguments manually; DIC intelligently completes the rest.

```bash
# User provides 2, DIC injects the remaining 6 parameters
ops pve vpt 100 on
```

Resolution Process:
1. **User Arguments**: Fill positions 1-2 (`vm_id`, `action`) with provided values.
2. **Smart Resolution**: DIC resolves positions 3-8 using the environment hierarchy.
   - `pci0_id` -> `${hostname}_NODE_PCI0` -> `01:00.0`
   - `core_count_on` -> `${hostname}_CORE_COUNT_ON` -> `8`

### Mode 2: Injection Execution (`-j`)

Zero-configuration automation where all parameters are resolved from the environment.

```bash
# DIC resolves all parameters from environment
ops pve vpt -j
```

This is the primary mode used in CI/CD integration and deployment scripts (`src/set/`).

### Mode 3: Explicit Execution (`-x`)

Passes `-x` through to the target function for functions that require explicit validation flags according to their specification.

```bash
# Passes -x directly to the function
ops gpu pts -x
```

## Parameter Preview System

The parameter preview system provides complete transparency into DIC's resolution process when invoked with no arguments:

```bash
$ ops pve vpt
Usage preview with variable injection:

Function: pve_vpt
Location: /home/es/lab/lib/ops/pve:123

  vm_id          → <vm_id:100>
  action         → <action>
  pci0_id        → <pci0_id:01:00.0>

Legend:
  <param:value> → Parameter will be auto-injected with shown value
  <param>       → Parameter requires manual input (no global variable found)
```

## Debugging and Optimization

Enable debug mode to trace the complete resolution and execution pipeline:

```bash
$ OPS_DEBUG=1 ops pve vpt -j
[DIC] Executing: pve_vpt with args:
[DIC] Analyzing signature for: pve_vpt
[DIC] Processing parameter 1/8: vm_id
```

Control caching and validation behavior with environment variables:
- `OPS_CACHE=1`: Enable caching (default)
- `OPS_VALIDATE=strict`: Validation level (`strict`, `warn`, `silent`)
- `OPS_METHOD=auto`: Injection method (`auto`, `convention`, `config`)
