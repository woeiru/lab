# Issue #001: GPU Passthrough Hook Trigger Bug

## Summary
VM shutdown hooks fail to trigger when VM is started via `pve_vms` orchestrator, but work correctly when started with direct GPU passthrough commands.

## Affected Components
- `pve_vms` function (lib/ops/pve:1314-1484)
- GPU passthrough hook system (pve_vmd)
- VM shutdown monitoring system

## Problem Description

### Scenario 1: Direct Command (Working)
```bash
./src/dic/ops gpu ptd -d lookup && qm start 111
# VM starts successfully
# VM shutdown from guest triggers hook correctly
# GPU reattaches to host as expected
```

### Scenario 2: Via pve_vms Orchestrator (Bug)
```bash
./src/dic/ops pve vms 111
# VM starts successfully through orchestrator
# VM shutdown from guest does NOT trigger hook
# GPU remains detached from host
```

## Root Cause Analysis

### 1. Environment Context Differences
- **Direct command**: Executes in full user environment with complete lab framework
- **pve_vms**: Runs through orchestrated workflow with different environment setup
- **Hook execution**: Runs in isolated systemd environment

### 2. Hook Setup Dependencies
The hook system requires:
- Proper hook registration via `pve_vmd add <vm_id> <lib_ops_dir>`
- Correct environment variable propagation
- Access to lab framework functions

### 3. State Management Conflicts
- `pve_vms` manages GPU state conditionally based on current attachment status
- Hook system expects specific GPU state transitions
- Timing differences between orchestrated startup and direct startup

## Technical Details

### pve_vms GPU Management (lib/ops/pve:1417-1439)
```bash
# Conditional GPU detachment based on current status
local gpu_status=$("$LAB_DIR/dic/ops" gpu pts 2>/dev/null | grep -o "ATTACHED\|DETACHED" | head -n1)
if [ "$gpu_status" = "ATTACHED" ]; then
    if ! "$LAB_DIR/dic/ops" gpu ptd -d lookup; then
        aux_warn "GPU detach operation failed, VM may not have GPU access"
    fi
fi
```

### Hook System (lib/ops/pve:957-1014)
```bash
# Hook wrapper with environment setup
cd /root/lab
export LAB_DIR=/root/lab
source bin/ini >/dev/null 2>&1
./go >/dev/null 2>&1
source "$LAB_DIR/lib/ops/gpu" && gpu_pta -d lookup
```

## Reproduction Steps
1. Ensure VM 111 exists and has GPU passthrough configured
2. Start VM using `./src/dic/ops pve vms 111`
3. Verify VM starts successfully
4. Shutdown VM from guest OS
5. Check GPU status - hook should trigger but doesn't

## Expected Behavior
- Hook should trigger regardless of startup method
- GPU should reattach to host after VM shutdown
- No difference between direct command and orchestrator startup

## Workaround
Use direct GPU passthrough command instead of pve_vms orchestrator:
```bash
./src/dic/ops gpu ptd -d lookup && qm start 111
```

## Investigation Status
- [x] Analyzed pve_vms function implementation
- [x] Identified environment and state management differences
- [ ] Test hook registration when VM started via pve_vms
- [ ] Verify environment variable propagation to hooks
- [ ] Compare GPU state transitions between methods

## Priority
**High** - Affects core VM management functionality and GPU passthrough reliability

## Labels
- bug
- gpu-passthrough
- vm-management
- hook-system
- pve-orchestrator

---
*Created: 2025-06-16*
*Reporter: System Analysis*
*Assignee: Lab Maintainer*