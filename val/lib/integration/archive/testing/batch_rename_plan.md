# Function Rename Batch Plan

## Current Naming Patterns Analysis

Based on function discovery, we have these patterns:

### Core Libraries (`lib/core/`)
- **Pattern**: `module_action_object` (underscores)
- **Examples**: `err_process_error`, `lo1_debug_log`, `tme_start_timer`
- **Status**: ✅ Already consistent

### Operations Libraries (`lib/ops/`)
- **Pattern**: `module-action` (dashes) 
- **Examples**: `gpu-fun`, `pve-vpt`, `sys-gio`
- **Status**: ✅ Already consistent

### General Libraries (`lib/gen/`)
- **Pattern**: `module-action` (dashes)
- **Examples**: `ana_laf`, `aux_ffl`, `env-switch`
- **Status**: ✅ Already consistent

## Proposed Standardization Strategy

After analysis, the current naming conventions are actually quite good:

1. **Core system functions** → Keep underscores (system convention)
2. **User-facing functions** → Keep dashes (CLI-friendly)
3. **Internal/private functions** → Keep underscore prefix: `_gpu_init_colors`

## Batch Rename Scenarios for Testing

### Batch 1: Standardize Core Function Prefixes
**Goal**: Ensure all core functions use consistent module prefixes

**Changes**:
- `err_process_error` → `core_err_process_error`
- `lo1_debug_log` → `core_lo1_debug_log`  
- `tme_start_timer` → `core_tme_start_timer`
- `ver_log` → `core_ver_log`

### Batch 2: Standardize Operations Function Suffixes
**Goal**: Ensure consistent action suffixes

**Changes**:
- `gpu_pt1` → `gpu-passthrough-enable`
- `gpu_pt2` → `gpu-passthrough-disable`
- `pve-vpt` → `pve-vm-passthrough-toggle`
- `sys-gio` → `sys-git-operations`

### Batch 3: Modernize Auxiliary Functions
**Goal**: More descriptive auxiliary function names

**Changes**:
- `ana_laf` → `aux-list-all-functions`
- `aux_ffl` → `aux-foreach-file-list`
- `ana_acu` → `aux-analyze-config-usage`
- `aux_nos` → `aux-notify-operation-status`

## Implementation Strategy

### Phase 1: Pre-Rename Validation ✅
- [x] Run comprehensive baseline tests
- [x] Generate function inventory
- [x] Map all references

### Phase 2: Batch 1 Execution
1. **Test Scenario**: Core function prefix standardization
2. **Validation**: Run post-rename tests
3. **Rollback Plan**: Revert if issues found

### Phase 3: Batch 2 Execution  
1. **Test Scenario**: Operations function modernization
2. **Validation**: Run post-rename tests
3. **Rollback Plan**: Revert if issues found

### Phase 4: Batch 3 Execution
1. **Test Scenario**: Auxiliary function descriptive names
2. **Validation**: Run post-rename tests
3. **Rollback Plan**: Revert if issues found

## Safety Measures

1. **Comprehensive Testing**: Pre and post validation for each batch
2. **Git Tracking**: Commit after each successful batch
3. **Automated Fixes**: Generate fix scripts for common issues
4. **CI/CD Integration**: JSON/YAML reports for build systems

## Success Criteria

- ✅ All function references updated
- ✅ No orphaned function calls
- ✅ Wrapper functions maintain linkage
- ✅ Configuration files updated
- ✅ Documentation updated
- ✅ All tests pass

This plan provides a safe, incremental approach to function renaming with comprehensive validation at each step.
