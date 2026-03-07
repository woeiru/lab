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

## Migration shim (`src/dic/run`)

During the declarative migration, `src/dic/run` provides a compatibility bridge
that compiles a reconciliation artifact via `src/rec/ops compile` and forwards
execution to `src/run/dispatch --plan <artifact>`.

```bash
# compile + dispatch through migration bridge
src/dic/run h1

# pass through normal runbook args
src/dic/run h1 -i
src/dic/run h1 -x a

# pass through strict dispatch enforcement flags
src/dic/run t2 --enforce-deps --completed-target h1 --completed-target c1

# pass through stage-based strict defaults
src/dic/run h1 --enforcement-stage strict --allow-gate gate_network --allow-gate gate_storage

# pass through non-interactive gate evidence artifacts
src/dic/run h1 --enforcement-stage strict --gate-evidence .tmp/rec/h1.gates
```

If `--enforcement-stage` is not supplied, dispatch can still derive stage from
`LAB_RUN_ENFORCEMENT_STAGE` or plan metadata emitted by `src/rec/ops compile`.
In the current `cfg/dcl/site1` rollout, `t1` and `t2` resolve to `guarded`
from plan metadata unless overridden.

This shim is transitional. It keeps current entrypoint ergonomics while
introducing plan-aware execution boundaries.

Gate evidence automation can also be provided through
`LAB_RUN_GATE_EVIDENCE_FILE` when calling `src/dic/run`.

Legacy runbooks can opt into this bridge by setting
`LAB_USE_DIC_RUN_BRIDGE=1` before invoking `src/set/*`.

### Mode 3: Explicit Execution (`-x`)

Passes `-x` through to the target function for functions that require explicit validation flags according to their specification.

```bash
# Passes -x directly to the function
ops gpu pts -x
```

## Runtime Reconcile Flags

`ops` now supports command-scoped runtime overrides so reconcile checks can be
enabled per command without mutating the shell environment.

```bash
# Enable reconcile preflight for a single command
ops --reconcile pve vpt -j

# Force direct mode for a single command
ops --direct pve vpt -j

# Pin reconcile preflight to an explicit target identity
ops --reconcile --rec-target h1 pve vpt -j
```

These flags map to the same runtime behavior as `OPS_EXECUTION_MODE` and
`OPS_REC_TARGET`, but only for the current command invocation.

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
- `OPS_EXECUTION_MODE=reconcile`: run reconcile preflight before operation execution
- `OPS_REC_TARGET=<target>`: override reconcile target identity for preflight

Runtime flags equivalent:
- `--reconcile`: command-scoped reconcile preflight enable
- `--direct`: command-scoped direct-mode override
- `--rec-target <target>`: command-scoped reconcile target override
