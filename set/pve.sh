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

# Function for installing packages
install_packages() {
    local function_name="${FUNCNAME[0]}"
    apt install -y vim tree corosync-qdevice
    notify_status "$function_name" "executed"
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

# ZFS options
zfs_create_mount() {
    local pool_name="$1"
    local dataset_name="$2"
    # Check if the dataset exists, create it if not
    if ! zfs list "$pool_name/$dataset_name" &>/dev/null; then
        echo "Creating ZFS dataset '$pool_name/$dataset_name'."
        zfs create "$pool_name/$dataset_name" || { echo "Failed to create ZFS dataset '$pool_name/$dataset_name'"; exit 1; }
        echo "ZFS dataset '$pool_name/$dataset_name' created."
    else
        echo "ZFS dataset '$pool_name/$dataset_name' already exists."
    fi

    # Check if the mountpoint directory exists, create it if not
    if [ ! -d "/mnt/$dataset_name" ]; then
        mkdir -p "/mnt/$dataset_name" || { echo "Failed to create mountpoint directory '/mnt/$dataset_name'"; exit 1; }
        echo "Mountpoint directory '/mnt/$dataset_name' created."
    fi

    # Set mountpoint only if it's not already set
    if [ "$(zfs get -H -o value mountpoint "$pool_name/$dataset_name")" != "/mnt/$dataset_name" ]; then
        zfs set mountpoint="/mnt/$dataset_name" "$pool_name/$dataset_name" || { echo "Failed to set mountpoint for ZFS dataset '$pool_name/$dataset_name'"; exit 1; }
        echo "ZFS dataset '$pool_name/$dataset_name' mounted at '/mnt/$dataset_name'."
    else
        echo "ZFS dataset '$pool_name/$dataset_name' is already mounted at '/mnt/$dataset_name'."
    fi
}

# Container options 
container_list_update() {
    local function_name="${FUNCNAME[0]}"

    	pveam update

    notify_status "$function_name" "executed"
}

container_download() {
    local function_name="${FUNCNAME[0]}"

    	pveam download local debian-12-standard_12.2-1_amd64.tar.zst

    notify_status "$function_name" "executed"
}

container_bindmount() {
    local function_name="${FUNCNAME[0]}"

	pct set 112 -mp0 /seta/backup,mp=/backup
	pct set 113 -mp0 /seta/share,mp=/share

    notify_status "$function_name" "executed"
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
    echo "b1. Zfs create and mount dataset"
    echo "c. -------------------"
    echo "c1. Update Containers"
    echo "c2. Install Containers"
    echo "c3. Bindmount Containers"
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
        a) execute_a_options;;
        a1) disable_repo;;
        a2) add_repo;;
        a3) update_upgrade;;
        a4) install_packages;;
        a5) remove_subscription_notice;;
        b) execute_b_options;;
        b1) zfs_create_mount;;
        c) execute_c_options;;
        c1) container_list_update;;
        c2) container_download;;
        c3) container_bindmount;;
        g) execute_g_options;;
        g1) gpupt_part_1;;
        g2) gpupt_part_2;;
        g3) gpupt_part_3;;
        *) echo "Invalid choice";;
    esac
}

# Functions for multiple calls

execute_a_options() {
	disable_repo
    	add_repo
    	update_upgrade
    	install_packages
    	remove_subscription_notice
}
execute_b_options() {
	zfs_create_mount "$ZFS_POOL_NAME1" "$ZFS_DATASET_NAME1"
}
execute_c_options() {
   	container_list_update
	container_download
}

execute_g_options() {
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

