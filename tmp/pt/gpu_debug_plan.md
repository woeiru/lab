# GPU Passthrough Display Issue Debug Plan

## Problem Summary
- **Working Combination**: `gpu-ptd` (old) → `gpu-pta` (old) ✅ Display works
- **Broken Combination**: `gpu_ptd_w` (new) → `gpu_pta_w` (new) ❌ Black screen
- **System**: Node x2, GTX 1650, nouveau driver

## Root Cause Analysis
The new enhanced functions include improvements (hardware reset + VGA console restoration) but something in the implementation changes is breaking display restoration. Need to isolate whether the issue is in:
1. **gpu_ptd_w** (detach process) 
2. **gpu_pta_w** (attach process)
3. **Combination of both**

## Debug Strategy: Isolation Testing

### Phase 1: Mixed Function Testing (CRITICAL)

**Test A: Old Detach + New Attach**
```bash
# Step 1: Reboot system (clean state)
reboot

# Step 2: Test mixed combination
gpu-ptd "0a:00.0"  # OLD detach function
# Run VM, then stop VM
gpu_pta_w "0a:00.0"  # NEW attach function

# Expected Result:
# - If display works: Problem is in gpu_ptd_w (new detach)
# - If display fails: Problem is in gpu_pta_w (new attach)
```

**Test B: New Detach + Old Attach**
```bash
# Step 1: Reboot system (clean state)
reboot

# Step 2: Test mixed combination  
gpu_ptd_w "0a:00.0"  # NEW detach function
# Run VM, then stop VM
gpu-pta "0a:00.0"   # OLD attach function

# Expected Result:
# - If display works: Problem is definitely in gpu_pta_w
# - If display fails: Problem is definitely in gpu_ptd_w
```

### Phase 2: Driver Selection Analysis

**Check Driver Differences**:
```bash
# What driver does old gpu-pta use?
grep -A10 -B5 "10de.*nouveau" /root/lab/tmp/pt/gpuold

# What driver does new gpu_pta_w use?
grep -A10 -B5 "_gpu_get_host_driver" /root/lab/lib/ops/gpu

# Force nouveau in new function if needed
```

### Phase 3: Implementation Comparison

**Key Differences to Investigate**:
1. **Driver Selection**: Old always uses `nouveau`, new has complex logic
2. **Binding Method**: Old uses direct bind, new uses `drivers_probe` + fallback
3. **Timing**: New has sleep statements, hardware reset delays
4. **Error Handling**: New has more validation steps

### Phase 4: Detailed Tracing (If Needed)

**Add Debug Output**:
```bash
# Modify gpu_pta_w to show exactly what driver it selects
# Add printf statements before each critical operation
# Compare exact sequence with working old version
```

## Expected Outcomes

### Scenario 1: Test A Works, Test B Fails
- **Root Cause**: `gpu_ptd_w` (new detach) is the problem
- **Investigation**: Compare old vs new detach sequences
- **Likely Issues**: Driver unloading, binding method, device state

### Scenario 2: Test A Fails, Test B Works  
- **Root Cause**: `gpu_pta_w` (new attach) is the problem
- **Investigation**: Compare old vs new attach sequences
- **Likely Issues**: Driver selection, VGA console timing, hardware reset timing

### Scenario 3: Both Tests Fail
- **Root Cause**: Both functions have issues, or interaction problem
- **Investigation**: Systematic comparison of each function step-by-step

### Scenario 4: Both Tests Work
- **Root Cause**: Combination-specific issue when both new functions used together
- **Investigation**: Function interaction, shared state, timing conflicts

## Recovery Commands

**After Any Failed Test**:
```bash
# Manual VGA console restoration attempt
echo 0 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null
sleep 1  
echo 1 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null

# Manual PCI reset attempt
echo 1 > /sys/bus/pci/devices/0000:0a:00.0/reset

# If all fails: reboot to restore clean state
reboot
```

## Critical Test Commands

**Current Function Locations**:
- **Old Functions**: `/root/lab/tmp/pt/gpuold` (gpu-ptd, gpu-pta)  
- **New Functions**: `/root/lab/lib/ops/gpu` (gpu_ptd_w, gpu_pta_w)

**VM Management**:
```bash
# Start VM: qm start 111
# Stop VM: qm stop 111  
# Check VM status: qm status 111
```

**Status Monitoring**:
```bash
# Check GPU driver: lspci -nnk -s 0a:00.0
# Check VGA arbitration: cat /sys/bus/pci/devices/0000:0a:00.0/boot_vga
# Check display: ls /dev/fb*
```

## Action Items After Reboot

1. ✅ **Reboot system** (clean state)
2. 🔄 **Run Test A** (old detach + new attach)
3. 📝 **Document results** in this file
4. 🔄 **Run Test B** (new detach + old attach) 
5. 📝 **Document results** and determine root cause
6. 🔧 **Implement targeted fix** based on isolation results

## Notes Section (Fill After Testing)

### Test A Results (gpu-ptd + gpu_pta_w):
```
Date: 2025-06-09 17:28  
Result: FAIL ❌
Display Status: Black screen - vtcon0 unbound, console not displaying
Driver Status: nouveau driver bound correctly, /dev/fb0 exists
Notes: New attach function (gpu_pta_w) has display restoration issues
      - GPU binding works (nouveau active, boot_vga=1)
      - But VGA console restoration is incomplete
      - Problem is in gpu_pta_w VGA console logic
```

### Test B Results (gpu_ptd_w + gpu-pta):  
```
Date: 2025-06-09 17:38
Result: PASS ✅
Display Status: Working perfectly - vtcon0 rebound, console displaying
Driver Status: nouveau driver bound correctly, /dev/fb0 exists, boot_vga=1
Notes: New detach function (gpu_ptd_w) works fine with old attach
      - GPU binding works correctly
      - VGA console restoration is complete
      - Display is fully functional
```

### Root Cause Identified:
```
Problem Function: gpu_pta_w (new attach function)
Specific Issue: VGA console restoration logic in gpu_pta_w is incomplete
               - GPU binding works (nouveau loads, boot_vga=1, /dev/fb0 exists)
               - But vtcon0 remains unbound (stays at 0 instead of 1)
               - Old gpu-pta function properly restores VGA console
Fix Required: Compare VGA console restoration between old gpu-pta and new gpu_pta_w
             Focus on vtcon0/vtcon1 binding sequence and timing
```