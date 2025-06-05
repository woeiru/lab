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
aux_fun → aux_fun
aux_var → aux_var
aux_log → aux_log
aux_ffl → aux_ffl
ana_laf → ana_laf
ana_acu → ana_acu
aux_mev → aux_mev
aux_nos → aux_nos
aux_flc → aux_flc
aux_use → aux_use
ana_lad → ana_lad

# lib/ops/gpu
gpu-fun → gpu_fun
gpu_var → gpu_var
gpu-nds → gpu_nds
gpu_pta → gpu_pta
gpu_ptd → gpu_ptd
gpu_pts → gpu_pts

# lib/ops/sys
sys-fun → sys_fun
sys-var → sys_var
sys-gio → sys_gio
sys-dpa → sys_dpa
sys-upa → sys_upa
sys-ipa → sys_ipa
sys-gst → sys_gst
sys-sst → sys_sst
sys_ust → sys_ust
sys_sdc → sys_sdc
sys-suk → ssh_suk
ssh_spi → ssh_spi
sys-sks → ssh_sks
ssh_sak → ssh_sak
sys-hos → net_hos
sys-sca → ssh_sca
sys-gre → sys_gre
sys-loi → ssh_loi

# lib/ops/usr  
usr-fun → usr_fun
usr_var → usr_var
usr_ckp → usr_ckp
usr_vsf → usr_vsf
usr_cff → usr_cff
usr-duc → usr_duc
usr-cif → usr_cif
usr_rsf → usr_rsf
usr_rsd → usr_rsd
usr_swt → usr_swt
usr-adr → usr_adr
usr_cap → usr_cap
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
