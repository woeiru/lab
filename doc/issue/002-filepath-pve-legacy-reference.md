# Issue 002: FILEPATH_pve Legacy Reference Bug

**Date:** June 17, 2025  
**Status:** RESOLVED  
**Severity:** Medium  
**Component:** DIC System / Environment Variables  

## Resolution Update (2025-06-21)

**Root Cause Found:** The `lib/gen/aux` library overwrites the global `DIR_FUN` variable when sourced. Since `lib/ops/pve` calculated `DIR_FUN` *before* sourcing `aux`, but used it *after* to set `FILEPATH_pve`, the variable `FILEPATH_pve` ended up pointing to `lib/gen` (the location of `aux`) instead of `lib/ops`.

**Fix Applied:** `lib/ops/pve` now re-calculates `DIR_FUN` immediately after sourcing `lib/gen/aux` to ensure it points to the correct location.

## Problem Description

The `pve_fun` command was failing with the error:
```
Error: Cannot read file '/home/es/lab/lib/gen/pve'
```

This occurred despite the `pve` file having been moved from `lib/gen/pve` to `lib/ops/pve` approximately 500 commits ago.

## Root Cause Analysis

1. **Variable Pollution**: `lib/gen/aux` sets `DIR_FUN` to its own directory when sourced.
2. **Sourcing Order**: `lib/ops/pve` sourced `aux` and then used the polluted `DIR_FUN`.
3. **Incorrect Path**: `FILEPATH_pve` was constructed using the wrong directory.

## Investigation Steps

1. Confirmed `pve_fun` function definition was correct
2. Verified `/home/es/lab/lib/gen/pve` no longer exists
3. Confirmed `/home/es/lab/lib/ops/pve` exists and is functional
4. Tested `pve_fun` with explicit path argument - worked correctly
5. Identified `FILEPATH_pve` was set to legacy path
6. Found no hardcoded references in core initialization files (bin/ini, bin/orc, cfg/core/*)

## Resolution

**Immediate Fix:**
```bash
export FILEPATH_pve="/home/es/lab/lib/ops/pve"
```

**Permanent Fix:**
Updated `lib/ops/pve` to handle variable pollution from sourced libraries.

**Verification:**
- `pve_fun` command now works correctly
- Function displays proper overview of PVE functions

## Technical Details

- **Failed Command**: `pve_fun` (without arguments)
- **Expected Behavior**: Display PVE function overview
- **Actual Behavior**: Error attempting to read non-existent file
- **Function Flow**: `pve_fun()` → `ana_laf("$FILEPATH_pve")` → file read error

## Recommended Actions

1. **Investigate Persistent Configuration**: Identify the system/process that was setting `FILEPATH_pve` to the legacy path
2. **Update Initialization**: Ensure all initialization scripts use current file locations
3. **Cache Cleanup**: Check for and clear any cached configurations containing old paths
4. **Documentation Update**: Verify all documentation reflects current file structure

## Files Affected

- `/home/es/lab/lib/ops/pve` (moved file, working correctly)
- Environment variable: `FILEPATH_pve` (incorrect value)
- Function: `pve_fun()` (dependent on variable)

## Prevention

- Add validation checks for critical path variables during initialization
- Implement automated tests to verify function accessibility after file moves
- Consider using relative paths or dynamic discovery instead of hardcoded environment variables

## Related Issues

- File migration from `lib/gen/*` to `lib/ops/*` structure
- Potential similar issues with other moved files (gpu, net, etc.)

---
**Resolution Confirmed:** ✅ `pve_fun` command functional  
**Follow-up Required:** Identify and fix persistent configuration source
