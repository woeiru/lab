#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# Function to display main menu
display_menu() {
    echo "Choose an option:"
    echo "a. -------------------"
    echo "a1. Disable repository"
    echo "a2. Add repository"
    echo "a3. Update and upgrade packages"
    echo "a4. Install packages"
    echo "a5. Remove subscription notice"
    echo "b. -------------------"
    echo "b1. Setup Btrfs Raid1"
    echo "c. -------------------"
    echo "c1. Zfs create and mount dataset"
    echo "d. -------------------"
    echo "d1. Update  Container List"
    echo "d2. Download Containers"
    echo "e. -------------------"
    echo "e1. Bindmount Containers"
    echo "g. -------------------"
    echo "g1. Enable gpu-pt Part 1"
    echo "g2. Enable gpu-pt Part 2"
    echo "g3. Enable gpu-pt Part 3"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
        a) a_xall;;
        a1) disable_repo;;
        a2) add_repo;;
        a3) update_upgrade;;
        a4) install_packages;;
        a5) pve-rsn;;
        b) b_xall;;
        b1) btrfs_setup_raid1;;
        c) c_xall;;
        c1) zfs_create_mount;;
        d) d_xall;;
        d1) container_list_update;;
        d2) container_download;;
        e) e_xall;;
        e1) container_bindmount;;
        g) g_xall;;
        g1) gpupt_part_1;;
        g2) gpupt_part_2;;
        g3) gpupt_part_3;;
        *) echo "Invalid choice";;
    esac
}

# Functions for executing whole section
a_xall() {
	disable_repo
    	add_repo
    	update_upgrade
    	install_packages "$PMAN" "$PAK1" "$PAK2"
    	pve-rsn
}
b_xall() {
	btrfs_setup_raid1 "$BTRFS_1_DEVICE_1" "$BTRFS_1_DEVICE_2" "$BTRFS_1_MP_1"
}

c_xall() {
	zfs_create_mount "$ZFS_POOL_NAME1" "$ZFS_DATASET_NAME1" "$ZFS_MOUNTPOINT_NAME1"
	zfs_create_mount "$ZFS_POOL_NAME2" "$ZFS_DATASET_NAME2" "$ZFS_MOUNTPOINT_NAME2"
	zfs list
}
d_xall() {
   	container_list_update
	container_download "$CT_DL_1"
}

e_xall() {
   	container_bindmount "$CT_ID_1" "$CT_MPH_1" "$CT_MPC_1"
   	container_bindmount "$CT_ID_2" "$CT_MPH_2" "$CT_MPC_2"
}
g_xall() {
    	gpupt_part_1
    	gpupt_part_2
    	gpupt_part_3
}

# Call the main function with command-line arguments
main "$@"
