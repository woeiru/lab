#!/bin/bash

# Sourcing
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"
source "$DIR_SH/.up"
setup_source "$DIR_SH" "$FILE_SH" "$BASE_SH"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"
MENU_OPTIONS[c]="c_xall"
MENU_OPTIONS[d]="d_xall"
MENU_OPTIONS[e]="e_xall"
MENU_OPTIONS[g]="g_xall"

a_xall() {
	pve-dsr
    	pve-adr
    	pve-puu
    	all-ipa "$PMAN" "$PAK1" "$PAK2"
    	pve-rsn
}
b_xall() {
	pve-br1 "$BTRFS_1_DEVICE_1" "$BTRFS_1_DEVICE_2" "$BTRFS_1_MP_1"
}

c_xall() {
	pve-zdm "$ZFS_POOL_NAME1" "$ZFS_DATASET_NAME1" "$ZFS_MOUNTPOINT_NAME1"
	pve-zdm "$ZFS_POOL_NAME2" "$ZFS_DATASET_NAME2" "$ZFS_MOUNTPOINT_NAME2"
	zfs list
}
d_xall() {
   	pve-clu
	pve-cdo "$CT_DL_STO" "$CT_DL_1"
}

e_xall() {
   	pve-cbm "$CT_ID_1" "$CT_MPH_1" "$CT_MPC_1"
   	pve-cbm "$CT_ID_2" "$CT_MPH_2" "$CT_MPC_2"
}
g_xall() {
    	pve-gp1
    	pve-gp2
    	pve-gp3
}

setup_main "$@"
