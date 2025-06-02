# Hyphen to Underscore Function Rename Plan

## Overview
This plan focuses specifically on converting all function names with hyphens (-) to underscores (_) across the entire `/lib` directory structure. This standardization will improve consistency and follows bash naming conventions.

## Current Analysis
Based on function discovery, we have identified **195 functions** across the library system, with approximately **80+ functions** using hyphens that need to be converted to underscores.

## Function Categories to Convert

### Core Libraries (`lib/core/`)
- Functions already use underscores (e.g., `tme_start_timer`, `lo1_debug_log`)
- **Status**: ✅ No changes needed

### Operations Libraries (`lib/ops/`)
**Pattern**: `module-action` → `module_action`
- `aux-*` → `aux_*` functions
- `gpu-*` → `gpu_*` functions  
- `net-*` → `net_*` functions
- `pbs-*` → `pbs_*` functions
- `pve-*` → `pve_*` functions
- `smb-*` → `smb_*` functions
- `srv-*` → `srv_*` functions
- `ssh-*` → `ssh_*` functions
- `sto-*` → `sto_*` functions
- `sys-*` → `sys_*` functions
- `usr-*` → `usr_*` functions

### General Libraries (`lib/gen/`)
**Pattern**: `module-action` → `module_action`
- `aux-*` → `aux_*` functions

## Batch 1: Convert All Hyphens to Underscores

### Target Functions (Sample - Full list auto-generated):
```
# lib/gen/aux
aux-fun → aux_fun
aux-var → aux_var
aux-log → aux_log
aux-ffl → aux_ffl
aux-laf → aux_laf
aux-acu → aux_acu
aux-mev → aux_mev
aux-nos → aux_nos
aux-flc → aux_flc
aux-use → aux_use
aux-lad → aux_lad

# lib/ops/gpu
gpu-fun → gpu_fun
gpu-var → gpu_var
gpu-nds → gpu_nds
gpu-pta → gpu_pta
gpu-ptd → gpu_ptd
gpu-pts → gpu_pts

# lib/ops/sys
sys-fun → sys_fun
sys-var → sys_var
sys-gio → sys_gio
sys-dpa → sys_dpa
sys-upa → sys_upa
sys-ipa → sys_ipa
sys-gst → sys_gst
sys-sst → sys_sst
sys-ust → sys_ust
sys-sdc → sys_sdc
sys-suk → sys_suk
sys-spi → sys_spi
sys-sks → sys_sks
sys-sak → sys_sak
sys-hos → sys_hos
sys-sca → sys_sca
sys-gre → sys_gre
sys-loi → sys_loi

# lib/ops/usr  
usr-fun → usr_fun
usr-var → usr_var
usr-ckp → usr_ckp
usr-vsf → usr_vsf
usr-cff → usr_cff
usr-duc → usr_duc
usr-cif → usr_cif
usr-rsf → usr_rsf
usr-rsd → usr_rsd
usr-swt → usr_swt
usr-adr → usr_adr
usr-cap → usr_cap
usr-rif → usr_rif
usr-ans → usr_ans

# ... (and all other hyphenated functions)
```

## Safety Measures
1. **Complete backup** of entire `/lib` directory before starting
2. **Function dependency mapping** to track all references
3. **Step-by-step validation** after each function rename
4. **Automatic rollback** capability if issues detected
5. **Reference updating** in all calling scripts

## Success Criteria
- All function names use underscores instead of hyphens
- All function calls updated across the entire codebase
- All tests pass after conversion
- No broken dependencies or references
- Git history preserved with clear commit messages

## Estimated Impact
- **~80+ function definitions** to rename
- **~500+ function calls** to update across codebase
- **Files affected**: All `/lib` files, most `/src` files, configuration files, tests
