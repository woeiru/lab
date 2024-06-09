#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source lib and var
source "$DIR/../lib/all.bash"
source "$DIR/../var/all.conf"
source "$DIR/../lib/${BASE}.bash"
source "$DIR/../var/${BASE}.conf"

# main setup function
setup_main() {
    if [ "$#" -eq 0 ]; then
        setup_display_menu
        setup_read_choice
    else
        setup_execute_arguments "$@"
    fi
}

# main read choice
setup_read_choice() {
    read -p "Enter your choice: " choice
    setup_execute_choice "$choice"
}

# main execute choice
setup_execute_arguments() {
    for arg in "$@"; do
        setup_execute_choice "$arg"
    done
}

# display setup_main menu
setup_display_menu() {
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

# execute based on user choice
setup_execute_choice() {
    case "$1" in
        a) a_xall;;
        a1) pve-dsr;;
        a2) pve-adr;;
        a3) pve-uup;;
        a4) all-ipa;;
        a5) pve-rsn;;
        b) b_xall;;
        b1) pve-br1;;
        c) c_xall;;
        c1) pve-zdm;;
        d) d_xall;;
        d1) pve-clu;;
        d2) pve-cdo;;
        e) e_xall;;
        e1) pve-cbm;;
        g) g_xall;;
        g1) pve-gp1;;
        g2) pve-gp2;;
        g3) pve-gp3;;
        *) echo "Invalid choice";;
    esac
}

# Functions for executing whole section
a_xall() {
	pve-dsr
    	pve-adr
    	pve-uup
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
	pve-cdo "$CT_DL_1"
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

# Call the setup_main function with command-line arguments
setup_main "$@"
