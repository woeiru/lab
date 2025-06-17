# Issue 002: FILEPATH_pve Legacy Reference Bug

**Date:** June 17, 2025  
**Status:** RESOLVED  
**Severity:** Medium  
**Component:** DIC System / Environment Variables  

## Problem Description

The `pve_fun` command was failing with the error:
```
Error: Cannot read file '/home/es/lab/lib/gen/pve'
```

This occurred despite the `pve` file having been moved from `lib/gen/pve` to `lib/ops/pve` approximately 500 commits ago.

## Root Cause Analysis

1. **Legacy Path Reference**: The `FILEPATH_pve` environment variable was persistently set to the old path `/home/es/lab/lib/gen/pve`
2. **Function Dependency**: The `pve_fun()` function relies on `${FILEPATH_pve}` as a fallback when no explicit path is provided:
   ```bash
   local script_path="${1:-$FILEPATH_pve}"
   ```
3. **Persistent Configuration**: Some initialization system or cached configuration was setting `FILEPATH_pve` to the obsolete path, causing the function to fail even though the file structure was correctly updated

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
