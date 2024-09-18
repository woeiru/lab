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
MENU_OPTIONS[f]="f_xall"
MENU_OPTIONS[g]="g_xall"
MENU_OPTIONS[h]="h_xall"
MENU_OPTIONS[i]="i_xall"

a_xall() {
    pve-dsr
    pve-adr
    pve-puu
    pve-rsn
}

b_xall() {
    all-ipa "$PACKAGES_ALL"
}

c_xall() {
    all-usk \
        "$DEVICE_PATH" \
        "$MOUNT_POINT" \
        "$SUBFOLDER_PATH" \
        "$UPLOAD_PATH" \
        "$PUBLIC_KEY"

    all-aak "$UPLOAD_PATH" "$PUBLIC_KEY"
}

d_xall() {
    pve-br1 "$BTRFS_1_DEVICE_1" "$BTRFS_1_DEVICE_2" "$BTRFS_1_MP_1"
}

e_xall() {
    local i=1
    while true; do
        pool_var="ZFS_POOL_NAME$i"
        dataset_var="ZFS_DATASET_NAME$i"
        mountpoint_var="ZFS_MOUNTPOINT_NAME$i"
        
        if [ -n "${!pool_var}" ] && [ -n "${!dataset_var}" ] && [ -n "${!mountpoint_var}" ]; then
            pve-zdm "${!pool_var}" "${!dataset_var}" "${!mountpoint_var}"
        else
            break
        fi
        
        ((i++))
    done
    
    zfs list
}

f_xall() {
    pve-clu
    pve-cdo "$CT_DL_STO" "$CT_DL_1"
    pve-cuc
}

g_xall() {
    pve-ctc create all
}

h_xall() {
    local i=1
    while true; do
        eval CT_ID=\$CT_ID_$i
        eval CT_MPH=\$CT_MPH_$i
        eval CT_MPC=\$CT_MPC_$i

        if [ -n "$CT_ID" ] && [ -n "$CT_MPH" ] && [ -n "$CT_MPC" ]; then
            pve-cbm "$CT_ID" "$CT_MPH" "$CT_MPC"
        else
            break
        fi

        ((i++))
    done
}

i_xall() {
    pve-vmc create all
}

# Call the main setup function
setup_main "$@"
