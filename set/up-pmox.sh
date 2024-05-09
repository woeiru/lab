#!/bin/bash

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to disable repository by commenting out lines starting with "deb" in specified files
disable_repo() {
    local function_name="disable_repo"
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
    local function_name="add_repo"
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
    local function_name="update_upgrade"
    apt update
    apt upgrade -y
    notify_status "$function_name" "Package lists updated and packages upgraded"
}

# Function to install git and vim
install_packages() {
    local function_name="install_packages"
    apt install -y git vim tree corosync-qdevice
    notify_status "$function_name" "Additional Packages installed"
}

# Function to set global git configurations
configure_git() {
    local function_name="configure_git"
    git config --global user.name "maxwagne"
    git config --global user.email "maxwagne@outlook.de"
    notify_status "$function_name" "Git configurations set"
}

# Function to remove subscription notice
remove_subscription_notice() {
    local function_name="remove_subscription_notice"
    sed -Ezi.bak "s/(Ext\.Msg\.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

    # Prompt user whether to restart the service
    read -p "Do you want to restart the pveproxy.service now? (y/n): " choice
    case "$choice" in
        y|Y ) systemctl restart pveproxy.service && notify_status "$function_name" "Service restarted successfully.";;
        n|N ) notify_status "$function_name" "Service not restarted.";;
        * ) notify_status "$function_name" "Invalid choice. Service not restarted.";;
    esac
}

notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to execute Section 1
gpupt_part_1() {
    echo "Executing section 1:"

    # Display EFI boot information
    efibootmgr -v

    # Edit GRUB configuration
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet iommu=pt"/' /etc/default/grub
    update-grub
    update-grub2

    # Install grub-efi-amd64
    apt install grub-efi-amd64 -y

    # Perform system reboot without prompting
    reboot
}

# Function to execute Section 2
gpupt_part_2() {
    echo "Executing section 2:"

    # Add modules to /etc/modules
    echo "vfio" >> /etc/modules
    echo "vfio_iommu_type1" >> /etc/modules
    echo "vfio_pci" >> /etc/modules

    # Update initramfs
    update-initramfs -u -k all

    # Perform system reboot without prompting
    reboot
}

# Function to execute Section 3
gpupt_part_3() {
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
    echo "a1. Disable repository"
    echo "a2. Add repository"
    echo "a3. Update and upgrade packages"
    echo "a4. Install git and vim"
    echo "a5. Configure git"
    echo "a6. Remove subscription notice"
    echo "b1. Enable gpu-pt Part 1"
    echo "b2. Enable gpu-pt Part 2"
    echo "b3. Enable gpu-pt Part 3"
    echo "a. Run all a options"
    echo "b. Run all b options"
}

# Function to read user choice
read_user_choice() {
    read -p "Enter your choice: " choice
    execute_choice "$choice"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
        a1) disable_repo;;
        a2) add_repo;;
        a3) update_upgrade;;
        a4) install_packages;;
        a5) configure_git;;
        a6) remove_subscription_notice;;
        b1) gpupt_part_1;;
        b2) gpupt_part_2;;
        b3) gpupt_part_3;;
        a) execute_a_options;;
        b) execute_b_options;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all a options
execute_a_options() {
    disable_repo
    add_repo
    update_upgrade
    install_packages
    configure_git
    remove_subscription_notice
}

# Function to execute all b options
execute_b_options() {
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

