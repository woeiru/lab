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

a_xall() {
	pve-dsr
    	pve-adr
    	pve-puu
    	all-ipa "$PMAN_PVE" "$PAK1_PVE" "$PAK2_PVE"
    	pve-rsn
}

b_xall() {
	all-usk \
    		"$DEVICE_PATH" \
    		"$MOUNT_POINT" \
    		"$SUBFOLDER_PATH" \
    		"$UPLOAD_PATH" \
    		"$PUBLIC_KEY"

	all-aak "$UPLOAD_PATH" "$PUBLIC_KEY"
}

c_xall() {
	pve-br1 "$BTRFS_1_DEVICE_1" "$BTRFS_1_DEVICE_2" "$BTRFS_1_MP_1"
}

d_xall() {
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
e_xall() {
   	pve-clu
	pve-cdo "$CT_DL_STO" "$CT_DL_1"
}

f_xall() {
    local i=1
    while true; do
        id_var="CT_${i}_ID"
        template_var="CT_${i}_TEMPLATE"
        hostname_var="CT_${i}_HOSTNAME"
        storage_var="CT_${i}_STORAGE"
        rootfs_size_var="CT_${i}_ROOTFS_SIZE"
        memory_var="CT_${i}_MEMORY"
        swap_var="CT_${i}_SWAP"
        nameserver_var="CT_${i}_NAMESERVER"
        searchdomain_var="CT_${i}_SEARCHDOMAIN"
        password_var="CT_${i}_PASSWORD"
        cpus_var="CT_${i}_CPUS"
        privileged_var="CT_${i}_PRIVILEGED"
        ip_address_var="CT_${i}_IP_ADDRESS"
        cidr_var="CT_${i}_CIDR"
        gateway_var="CT_${i}_GATEWAY"
        ssh_key_file_var="CT_${i}_SSH_KEY_FILE"
        net_bridge_var="CT_${i}_NET_BRIDGE"
        net_nic_var="CT_${i}_NET_NIC"

        if [ -n "${!id_var}" ] && [ -n "${!template_var}" ] && [ -n "${!hostname_var}" ] && [ -n "${!storage_var}" ]; then
            # Check if the container with the given ID already exists
            if pct status "${!id_var}" &>/dev/null; then
                echo "Container with ID ${!id_var} already exists. Skipping..."
            else
                pve-ctc \
                    "${!id_var}" \
                    "${!template_var}" \
                    "${!hostname_var}" \
                    "${!storage_var}" \
                    "${!rootfs_size_var}" \
                    "${!memory_var}" \
                    "${!swap_var}" \
                    "${!nameserver_var}" \
                    "${!searchdomain_var}" \
                    "${!password_var}" \
                    "${!cpus_var}" \
                    "${!privileged_var}" \
                    "${!ip_address_var}" \
                    "${!cidr_var}" \
                    "${!gateway_var}" \
                    "${!ssh_key_file_var}" \
                    "${!net_bridge_var}" \
                    "${!net_nic_var}"
            fi
        else
            break
        fi

        ((i++))
    done
}

g_xall() {
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

h_xall() {
    	pve-gp1
    	pve-gp2
    	pve-gp3
}

setup_main "$@"
