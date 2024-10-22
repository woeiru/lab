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
MENU_OPTIONS[j]="j_xall"
MENU_OPTIONS[k]="k_xall"
MENU_OPTIONS[l]="l_xall"
MENU_OPTIONS[m]="m_xall"
MENU_OPTIONS[n]="n_xall"
MENU_OPTIONS[o]="o_xall"
MENU_OPTIONS[p]="p_xall"
MENU_OPTIONS[q]="q_xall"
MENU_OPTIONS[r]="r_xall"
MENU_OPTIONS[s]="s_xall"
MENU_OPTIONS[t]="t_xall"
MENU_OPTIONS[u]="u_xall"
MENU_OPTIONS[v]="v_xall"
MENU_OPTIONS[w]="w_xall"
MENU_OPTIONS[x]="x_xall"
MENU_OPTIONS[y]="y_xall"
MENU_OPTIONS[z]="z_xall"

# Disables enterprise repository, adds community repository, and removes subscription notice from Proxmox web interface
a_xall() {
    pve-dsr
    usr-adr "$PVE_ADR_FILE" "$PVE_ADR_LINE"
    pve-rsn
}

# Installs required system packages including corosync-qdevice for cluster management
b_xall() {
    gen-ipa "$PACKAGES_ALL"
}

# Uploads public SSH key from USB device and adds it to the authorized keys for secure remote access
c_xall() {
    gen-suk \
        "$DEVICE_PATH" \
        "$MOUNT_POINT" \
        "$SUBFOLDER_PATH" \
        "$UPLOAD_PATH" \
        "$PUBLIC_KEY"

    gen-sak -s "$UPLOAD_PATH" "$PUBLIC_KEY"
}

# Generates and distributes SSH keys for secure communication between client and server nodes
d_xall() {
    gen-sks -s root@"${CL_IPS[t1]}" "$KEY_NAME"

    gen-sak -s "$UPLOAD_PATH" "$PUBLIC_KEY"
}

# Creates a RAID 1 Btrfs filesystem across two devices with the specified mount point
i_xall() {
    bfs-ra1 "$BTRFS_1_DEVICE_1" "$BTRFS_1_DEVICE_2" "$BTRFS_1_MP_1"
}

# Creates and configures multiple ZFS datasets with their respective mount points based on configuration
j_xall() {
    local i=1
    while true; do
        pool_var="ZFS_POOL_NAME$i"
        dataset_var="ZFS_DATASET_NAME$i"
        mountpoint_var="ZFS_MOUNTPOINT_NAME$i"
        
        if [ -n "${!pool_var}" ] && [ -n "${!dataset_var}" ] && [ -n "${!mountpoint_var}" ]; then
            zfs-dim "${!pool_var}" "${!dataset_var}" "${!mountpoint_var}"
        else
            break
        fi
        
        ((i++))
    done
    
    zfs list
}

# Updates container template list, downloads specified template, and updates container configuration
p_xall() {
    pve-clu
    pve-cdo "$CT_DL_STO" "$CT_DL_1"
    usr-cuc
}

# Creates multiple Proxmox containers using configuration parameters from site.conf
q_xall() {
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

# Configures bind mounts for all defined containers to link host and container directories
r_xall() {
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

# Creates multiple virtual machines using the specifications defined in site.conf
s_xall() {
    local i=1
    while true; do
        id_var="VM_${i}_ID"
        name_var="VM_${i}_NAME"
        ostype_var="VM_${i}_OSTYPE"
        machine_var="VM_${i}_MACHINE"
        iso_var="VM_${i}_ISO"
        boot_var="VM_${i}_BOOT"
        bios_var="VM_${i}_BIOS"
        efidisk_var="VM_${i}_EFIDISK"
        scsihw_var="VM_${i}_SCSIHW"
        agent_var="VM_${i}_AGENT"
        disk_var="VM_${i}_DISK"
        sockets_var="VM_${i}_SOCKETS"
        cores_var="VM_${i}_CORES"
        cpu_var="VM_${i}_CPU"
        memory_var="VM_${i}_MEMORY"
        balloon_var="VM_${i}_BALLOON"
        net_var="VM_${i}_NET"

        if [ -n "${!id_var}" ] && [ -n "${!name_var}" ] && [ -n "${!ostype_var}" ]; then
            # Check if the VM with the given ID already exists
            if qm status "${!id_var}" &>/dev/null; then
                echo "VM with ID ${!id_var} already exists. Skipping..."
            else
                pve-vmc \
                    "${!id_var}" \
                    "${!name_var}" \
                    "${!ostype_var}" \
                    "${!machine_var}" \
                    "${!iso_var}" \
                    "${!boot_var}" \
                    "${!bios_var}" \
                    "${!efidisk_var}" \
                    "${!scsihw_var}" \
                    "${!agent_var}" \
                    "${!disk_var}" \
                    "${!sockets_var}" \
                    "${!cores_var}" \
                    "${!cpu_var}" \
                    "${!memory_var}" \
                    "${!balloon_var}" \
                    "${!net_var}"
            fi
        else
            break
        fi

        ((i++))
    done
}

# Handle script execution
if [ $# -eq 0 ]; then
    print_usage
    clean_exit 0       # Exit cleanly with status 0
else
    setup_main "$@"
    clean_exit $?
fi
