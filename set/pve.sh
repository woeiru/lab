#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to disable repository by commenting out lines starting with "deb" in specified files
disable_repo() {
    local function_name="${FUNCNAME[0]}"
    files=(
        "/etc/apt/sources.list.d/pve-enterprise.list"
        "/etc/apt/sources.list.d/ceph.list"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            sed -i '/^deb/ s/^/#/' "$file"
            notify_status "$function_name" "Changes applied to $file"
        else
            notify_status "$function_name" "File $file not found."
        fi
    done
}

# Function to add a line to sources.list if it doesn't already exist
add_repo() {
    local function_name="${FUNCNAME[0]}"
    line_to_add="deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription"
    file="/etc/apt/sources.list"

    if grep -Fxq "$line_to_add" "$file"; then
        notify_status "$function_name" "Line already exists in $file"
    else
        echo "$line_to_add" >> "$file"
        notify_status "$function_name" "Line added to $file"
    fi
}

# Function to update package lists and upgrade packages
update_upgrade() {
    local function_name="${FUNCNAME[0]}"
    apt update
    apt upgrade -y
    notify_status "$function_name" "executed"
}

install_packages () {
    local function_name="${FUNCNAME[0]}"
    local pman="$1"
    local pak1="$2"
    local pak2="$3"
   
    "$pman" update
    "$pman" upgrade -y
    "$pman" install -y "$pak1" "$pak2"

    # Check if installation was successful
    if [ $? -eq 0 ]; then
	    notify_status "$function_name" "executed ( $1 $2 $3 )"
    else
        notify_status "$function_name" "Failed to install  ( $1 $2 $3 )"
        return 1
    fi
}

# Function to remove subscription notice
remove_subscription_notice() {
    local function_name="${FUNCNAME[0]}"
    sed -Ezi.bak "s/(Ext\.Msg\.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

    # Prompt user whether to restart the service
    read -p "Do you want to restart the pveproxy.service now? (y/n): " choice
    case "$choice" in
        y|Y ) systemctl restart pveproxy.service && notify_status "$function_name" "Service restarted successfully.";;
        n|N ) notify_status "$function_name" "Service not restarted.";;
        * ) notify_status "$function_name" "Invalid choice. Service not restarted.";;
    esac
}

# BTRFS options
btrfs_setup_raid1() {
    local function_name="${FUNCNAME[0]}"
    local device1="$1"
    local device2="$2"
    local mount_point="$3"

    # Create Btrfs RAID 1 filesystem
    mkfs.btrfs -m raid1 -d raid1 "$device1" "$device2"

    # Create mount point and mount the filesystem
    mkdir -p "$mount_point"
    mount "$device1" "$mount_point"

    # Verify the RAID 1 setup
    btrfs filesystem show "$mount_point"
    btrfs filesystem df "$mount_point"

    # Optionally add to fstab
    local uuid
    uuid=$(sudo blkid -s UUID -o value "$device1")
    local fstab_entry="UUID=$uuid $mount_point btrfs defaults,degraded 0 0"

    echo "The following line will be added to /etc/fstab:"
    echo "$fstab_entry"
    read -p "Do you want to add this line to /etc/fstab? [y/N]: " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$fstab_entry" | sudo tee -a /etc/fstab
        echo "Entry added to /etc/fstab."
    else
        echo "Entry not added to /etc/fstab."
    fi

    notify_status "$function_name" "executed ( $1 $2 $3 )"
}

# ZFS options
zfs_create_mount() {
    local function_name="${FUNCNAME[0]}"
    local pool_name="$1"
    local dataset_name="$2"
    local mountpoint_path="$3"
    local dataset_path="$pool_name/$dataset_name"
    local newly_created=false

    # Check if the dataset exists, create it if not
    if ! zfs list "$dataset_path" &>/dev/null; then
        echo "Creating ZFS dataset '$dataset_path'."
        zfs create "$dataset_path" || { echo "Failed to create ZFS dataset '$dataset_path'"; exit 1; }
        echo "ZFS dataset '$dataset_path' created."
        newly_created=true
    else
        echo "ZFS dataset '$dataset_path' already exists."
    fi

    # Check if the mountpoint directory exists, create it if not
    if [ ! -d "$mountpoint_path" ]; then
        mkdir -p "$mountpoint_path" || { echo "Failed to create mountpoint directory '$mountpoint_path'"; exit 1; }
        echo "Mountpoint directory '$mountpoint_path' created."
    fi

    # Get the current mountpoint and compare with the expected mountpoint
    current_mountpoint=$(zfs get -H -o value mountpoint "$dataset_path")
    expected_mountpoint="$mountpoint_path"

    if [ "$current_mountpoint" != "$expected_mountpoint" ]; then
        zfs set mountpoint="$expected_mountpoint" "$dataset_path" || { echo "Failed to set mountpoint for ZFS dataset '$dataset_path'"; exit 1; }
        echo "ZFS dataset '$dataset_path' mounted at '$expected_mountpoint'."
    elif [ "$newly_created" = true ]; then
        echo "ZFS dataset '$dataset_path' newly mounted at '$expected_mountpoint'."
    else
        echo "ZFS dataset '$dataset_path' is already mounted at '$expected_mountpoint'."
    fi

    notify_status "$function_name" "executed ( $pool_name / $dataset_name )"
}

# Container options 
container_list_update() {
    local function_name="${FUNCNAME[0]}"

    	pveam update

    notify_status "$function_name" "executed"
}

container_download() {
    local function_name="${FUNCNAME[0]}"
    local ct_dl="$1"

    	pveam download local "$ct_dl" 

	notify_status "$function_name" "executed ( $ct_dl )"
}

container_bindmount() {
    local function_name="${FUNCNAME[0]}"
    local vmid="$1"
    local mphost="$2"
    local mpcontainer="$3"

    # Debugging output to check the parameters
    echo "Function: $function_name"
    echo "VMID: $vmid"
    echo "MPHOST: $mphost"
    echo "MPCONTAINER: $mpcontainer"

    # Ensure all arguments are provided
    if [[ -z "$vmid" || -z "$mphost" || -z "$mpcontainer" ]]; then
        echo "Error: Missing arguments."
        return 1
    fi

    # Properly quote the entire argument for -mp0
    pct set "$vmid" -mp0 "$mphost,mp=$mpcontainer"

    notify_status "$function_name" "executed ( $vmid / $mphost / $mpcontainer )"
}


# GPU Passthrough options
gpupt_part_1() {
    local function_name="${FUNCNAME[0]}"
    echo "Executing section 1:"

    # Display EFI boot information
    efibootmgr -v

    # Edit GRUB configuration
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet iommu=pt"/' /etc/default/grub
    update-grub
    update-grug2

    # Install grub-efi-amd64
    apt install grub-efi-amd64 -y

    # Notify status
    notify_status "$function_name" "Completed section 1, system will reboot now."

    # Perform system reboot without prompting
    reboot
}

gpupt_part_2() {
    local function_name="${FUNCNAME[0]}"
    echo "Executing section 2:"

    # Add modules to /etc/modules
    echo "vfio" >> /etc/modules
    echo "vfio_iommu_type1" >> /etc/modules
    echo "vfio_pci" >> /etc/modules

    # Update initramfs
    update-initramfs -u -k all

    # Notify status
    notify_status "$function_name" "Completed section 2, system will reboot now."

    # Perform system reboot without prompting
    reboot
}

gpupt_part_3() {
    local function_name="${FUNCNAME[0]}"
    echo "Executing section 3:"

    # Check for vfio-related logs in kernel messages after reboot
    dmesg | grep -i vfio
    dmesg | grep 'remapping'

    # List NVIDIA and AMD devices after reboot
    lspci -nn | grep 'NVIDIA'
    lspci -nn | grep 'AMD'

    # Check if vfio configuration already exists
    vfio_conf="/etc/modprobe.d/vfio.conf"
    if [ ! -f "$vfio_conf" ]; then
        # Prompt for the IDs input in the format ****:****,****:****
        read -p "Please enter the IDs in the format ****:****,****:****: " ids_input

        # Split the IDs based on comma
        IFS=',' read -ra id_list <<< "$ids_input"

        # Construct the line with the IDs
        options_line="options vfio-pci ids="

        # Build the line for each ID
        for id in "${id_list[@]}"
        do
            options_line+="$(echo "$id" | tr '\n' ',')"
        done

        # Remove the trailing comma
        options_line="${options_line%,}"

        # Append the line into the file
        echo "$options_line" >> "$vfio_conf"
    fi

    # Blacklist GPU
    echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf
    echo "blacklist amdgpu" >> /etc/modprobe.d/blacklist.conf

    # Notify status
    notify_status "$function_name" "Completed section 3, system will reboot now."

    # Perform system reboot without prompting
    reboot
}


# Main function to execute based on command-line arguments or display main menu
main() {
    if [ "$#" -eq 0 ]; then
        display_menu
        read_user_choice
    else
        execute_arguments "$@"
    fi
}

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

# Function to read user choice
read_user_choice() {
    read -p "Enter your choice: " choice
    execute_choice "$choice"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
        a) a_xall;;
        a1) disable_repo;;
        a2) add_repo;;
        a3) update_upgrade;;
        a4) install_packages;;
        a5) remove_subscription_notice;;
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

# Functions for multiple calls

a_xall() {
	disable_repo
    	add_repo
    	update_upgrade
    	install_packages "$PMAN" "$PAK1" "$PAK2"
    	remove_subscription_notice
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

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

