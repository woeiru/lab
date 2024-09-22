# Define directory and file variables
DIR_LIB="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_LIB=$(basename "$BASH_SOURCE")
BASE_LIB="${FILE_LIB%.*}"
FILEPATH_LIB="${DIR_LIB}/${FILE_LIB}"
CONFIG_LIB="$DIR_LIB/../var/${BASE_LIB}.conf"

# Dynamically create variables based on the base name
eval "FILEPATH_${BASE_LIB}=\$FILEPATH_LIB"
eval "FILE_${BASE_LIB}=\$FILE_LIB"
eval "BASE_${BASE_LIB}=\$BASE_LIB"
eval "CONFIG_${BASE_LIB}=\$CONFIG_LIB"

# Source the configuration file
if [ -f "$CONFIG_LIB" ]; then
    source "$CONFIG_LIB"
else
    echo "Configuration file $CONFIG_LIB not found!"
    exit 1
fi

# Displays an overview of specific Proxmox Virtual Environment (PVE) related functions in the script, showing their usage, shortname, and description
# overview functions
#  
pve-fun() {
    all-laf "$FILEPATH_pve" "$@"
}
# Displays an overview of PVE-specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
# 
pve-var() {
    all-acu -o "$CONFIG_pve" "$DIR_LIB/.."
}

# Guides the user through renaming a network interface by updating udev rules and network configuration, with an option to reboot the system
# udev network interface
# [interactive]
pve-uni() {
    # Prompt user for the new interface name
    read -p "Enter the new interface name (e.g., nic1): " INTERFACE_NAME

    # Get the list of available network interfaces and their MAC addresses
    echo "Available network interfaces and their MAC addresses:"
    ip addr

    # Prompt user to enter the NIC name from the list
    read -p "Enter the network interface name whose MAC address you want to associate with the new name: " SELECTED_INTERFACE

    # Retrieve MAC address for the selected interface
    MAC_ADDRESS=$(ip addr show dev "$SELECTED_INTERFACE" | awk '/ether/{print $2}')
    echo "MAC address for $SELECTED_INTERFACE: $MAC_ADDRESS"

    # Create or edit the udev rule file
    echo 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="'"$MAC_ADDRESS"'", NAME="'"$INTERFACE_NAME"'"' > /etc/udev/rules.d/70-persistent-net.rules

    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger

    echo "Udev rule applied. The interface name '$INTERFACE_NAME' has been assigned to MAC address '$MAC_ADDRESS'."

    # Make changes in the network configuration file
    sed -i 's/'"$SELECTED_INTERFACE"'/'"$INTERFACE_NAME"'/g' /etc/network/interfaces

    echo "Network configuration updated. The interface name has been replaced in the configuration file."

    # Perform system reboot
    read -p "Do you want to reboot the system now? (y/n): " REBOOT_CONFIRM
    if [ "$REBOOT_CONFIRM" = "y" ]; then
        reboot
    else
        echo "System reboot was not executed. Please manually restart the system to apply the changes."
    fi
}

# Displays the contents of all .notes files found in a specified directory or the current directory, useful for viewing backup notes 
# show backup notes
# [folder: optional]
pve-sbn() {
    # Get the absolute path of the specified folder or use the current directory if no argument is provided
    local folder="${1:-.}"
    local abs_path=$(realpath "$folder")

    # Check if the folder exists
    if [ ! -d "$abs_path" ]; then
        echo "Error: Directory '$folder' not found."
        return 1
    fi

    # Find all .notes files in the specified folder
    local note_files=$(find "$abs_path" -type f -name "*.notes")

    # If no .notes files are found, print a message and return
    if [ -z "$note_files" ]; then
        echo "No .notes files found in the specified directory."
        return
    fi

    # Iterate over each .notes file, print its contents followed by the filename
    while IFS= read -r note_file; do
        echo "----------"
        cat "$note_file"
        echo "File: $note_file"
        done <<< "$note_files"
}


# Disables specified Proxmox repository files by commenting out 'deb' lines, typically used to manage repository sources 
# disable repository
#  
pve-dsr() {
    local function_name="${FUNCNAME[0]}"
    files=(
        "/etc/apt/sources.list.d/pve-enterprise.list"
        "/etc/apt/sources.list.d/ceph.list"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            sed -i '/^deb/ s/^/#/' "$file"
            all-nos "$function_name" "Changes applied to $file"
        else
            all-nos "$function_name" "File $file not found."
        fi
    done
}

# Adds a specific Proxmox VE no-subscription repository line to /etc/apt/sources.list if not already present 
# setup sources.list
#   
pve-adr() {
    local function_name="${FUNCNAME[0]}"
    line_to_add="deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription"
    file="/etc/apt/sources.list"

    if grep -Fxq "$line_to_add" "$file"; then
        all-nos "$function_name" "Line already exists in $file"
    else
        echo "$line_to_add" >> "$file"
        all-nos "$function_name" "Line added to $file"
    fi
}

# Updates package lists and upgrades all installed packages on the Proxmox system
# packages update upgrade
#   
pve-puu() {
    local function_name="${FUNCNAME[0]}"
    apt update
    apt upgrade -y
    all-nos "$function_name" "executed"
}

# Removes the Proxmox subscription notice by modifying the web interface JavaScript file, with an option to restart the pveproxy service 
# remove sub notice
#   
pve-rsn() {
    local function_name="${FUNCNAME[0]}"
    sed -Ezi.bak "s/(Ext\.Msg\.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

    # Prompt user whether to restart the service
    read -p "Do you want to restart the pveproxy.service now? (y/n): " choice
    case "$choice" in
        y|Y ) systemctl restart pveproxy.service && all-nos "$function_name" "Service restarted successfully.";;
        n|N ) all-nos "$function_name" "Service not restarted.";;
        * ) all-nos "$function_name" "Invalid choice. Service not restarted.";;
    esac
}


# Creates a Btrfs RAID 1 filesystem on two specified devices, mounts it, and optionally adds an entry to /etc/fstab
# btrfs raid 1
# <device1> <device2> <mount_point>
pve-br1() {
    local function_name="${FUNCNAME[0]}"
    local device1="$1"
    local device2="$2"
    local mount_point="$3"
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

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

    all-nos "$function_name" "executed ( $1 $2 $3 )"
}

# Creates a new ZFS dataset or uses an existing one, sets its mountpoint, and ensures it's mounted at the specified path
# zfs directory mount
# <pool_name> <dataset_name> <mountpoint_path>
pve-zdm() {
    local function_name="${FUNCNAME[0]}"
    local pool_name="$1"
    local dataset_name="$2"
    local mountpoint_path="$3"
    local dataset_path="$pool_name/$dataset_name"
    local newly_created=false
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

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

    all-nos "$function_name" "executed ( $pool_name / $dataset_name )"
}

# Updates the Proxmox VE Appliance Manager (pveam) container template list
# container list update
#  
pve-clu() {
    local function_name="${FUNCNAME[0]}"

    	pveam update

    all-nos "$function_name" "executed"
}

# Downloads a specified container template to a given storage location, with error handling and options to list available templates
# container downloads
#   
pve-cdo() {
    local function_name="${FUNCNAME[0]}"
    local ct_dl_sto="$1"
    local ct_dl="$2"

    # Attempt to download the template
    if ! pveam download "$ct_dl_sto" "$ct_dl" 2>/dev/null; then
        echo "Error: Unable to download template '$ct_dl'."
        
        # Ask user if they want to see available templates
        read -p "Would you like to see a list of available templates? (y/n): " answer
        
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo "Available templates:"
            pveam available
            
            # Ask user if they want to try downloading a different template
            read -p "Would you like to try downloading a different template? (y/n): " retry_answer
            
            if [[ "$retry_answer" =~ ^[Yy]$ ]]; then
                read -p "Enter the name of the template you'd like to download: " new_ct_dl
                pve-cdo "$ct_dl_sto" "$new_ct_dl"
                return
            fi
        fi
        
        echo "$function_name: Failed to download template ( $ct_dl )"
    else
        echo "$function_name: Successfully downloaded template ( $ct_dl )"
    fi
}

# Updates the container template reference in the Proxmox configuration file, prompting for user confirmation and new template name
# config update containertemplate
# [interactive]
pve-cuc() {
    # Check if CONFIG_pve is set
    if [ -z "$CONFIG_pve" ]; then
        echo "Error: CONFIG_pve is not set. Please ensure it's defined before calling this function."
        return 1
    fi

    local current_template
    local new_template

    # Prompt user if they want to update the config file
    read -p "Do you want to update the container config file ($CONFIG_pve)? (y/n): " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Config update cancelled."
        return 0
    fi

    # Find the current template
    current_template=$(grep -oP 'CT_DL_1="\K[^"]+' "$CONFIG_pve")
    if [ -z "$current_template" ]; then
        echo "Error: Couldn't find the current template in the config file."
        return 1
    fi

    # Prompt for the new template
    read -p "Enter the new template name (current: $current_template): " new_template
    if [ -z "$new_template" ]; then
        echo "No new template provided. Config update cancelled."
        return 0
    fi

    # Update the config file
    if sed -i "s|$current_template|$new_template|g" "$CONFIG_pve"; then
        echo "Config file updated successfully."
        echo "Changed template from '$current_template' to '$new_template' in:"
        grep -n "$new_template" "$CONFIG_pve"
    else
        echo "Error: Failed to update the config file."
        echo "The original file is unchanged. You can find a backup at ${CONFIG_pve}.bak"
        return 1
    fi
}

# Configures a bind mount for a specified Proxmox container, linking a host directory to a container directory
# container bindmount
# <vmid> <mphost> <mpcontainer>
pve-cbm() {
    local function_name="${FUNCNAME[0]}"
    local vmid="$1"
    local mphost="$2"
    local mpcontainer="$3"
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

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

    all-nos "$function_name" "executed ( $vmid / $mphost / $mpcontainer )"
}

# Setting up different containers specified in pve.conf
# container create
# <passed global variables>
pve-ctc() {
    local id="$1"
    local template="$2"
    local hostname="$3"
    local storage="$4"
    local rootfs_size="$5"
    local memory="$6"
    local swap="$7"
    local nameserver="$8"
    local searchdomain="$9"
    local password="${10}"
    local cpus="${11}"
    local privileged="${12}"
    local ip_address="${13}"
    local cidr="${14}"
    local gateway="${15}"
    local ssh_key_file="${16}"
    local net_bridge="${17}"
    local net_nic="${18}"

    if [ ! -f "$ssh_key_file" ]; then
        echo "SSH key file $ssh_key_file does not exist. Aborting."
        return 1
    fi

    # Correcting the parameters passed to pct create
    pct create "$id" "$template" \
        --hostname "$hostname" \
        --storage "$storage" \
        --rootfs "$storage:$rootfs_size" \
        --memory "$memory" \
        --swap "$swap" \
        --net0 "name=$net_nic,bridge=$net_bridge,ip=$ip_address/$cidr,gw=$gateway" \
        --nameserver "$nameserver" \
        --searchdomain "$searchdomain" \
        --password "$password" \
        --cores "$cpus" \
        --features "keyctl=1,nesting=1" \
        $(if [ "$privileged" == "no" ]; then echo "--unprivileged"; fi) \
        --ssh-public-keys "$ssh_key_file"
}

# Manages multiple Proxmox containers by starting, stopping, enabling, or disabling them, supporting individual IDs, ranges, or all containers
# container toggle
# <start|stop|enable|disable> <containers|all>
pve-cto() {
    local action=$1
    shift
    
    if [[ $action != "start" && $action != "stop" && $action != "enable" && $action != "disable" ]]; then
        echo "Invalid action: $action"
        echo "Usage: pve-cto <start|stop|enable|disable> <containers|all>"
        return 1
    fi
    
    handle_action() {
        local vmid=$1
        local config_file="/etc/pve/lxc/${vmid}.conf"
        
        if [[ ! -f "$config_file" ]]; then
            echo "ERROR: Config file for container $vmid does not exist"
            return 1
        fi
        
        case $action in
            start)
                echo "Starting container $vmid"
                pct start "$vmid"
                ;;
            stop)
                echo "Stopping container $vmid"
                pct stop "$vmid"
                ;;
            enable|disable)
                local onboot_value=$([[ $action == "enable" ]] && echo 1 || echo 0)
                echo "Setting onboot to $onboot_value for container $vmid"
                
                sed -i '/^onboot:/d' "$config_file"
                echo "onboot: $onboot_value" >> "$config_file"
                
                echo "Container $vmid configuration updated:"
                grep '^onboot:' "$config_file" || echo "ERROR: onboot entry not found after modification"
                ;;
        esac
    }
    
    if [[ $1 == "all" ]]; then
        echo "Processing all containers"
        container_ids=$(pct list | awk 'NR>1 {print $1}')
        for vmid in $container_ids; do
            handle_action "$vmid"
        done
    else
        for arg in "$@"; do
            if [[ $arg == *-* ]]; then
                IFS='-' read -r start end <<< "$arg"
                for (( vmid=start; vmid<=end; vmid++ )); do
                    handle_action "$vmid"
                done
            else
                handle_action "$arg"
            fi
        done
    fi
    
    if [[ $action == "start" || $action == "stop" ]]; then
        echo "Current container status:"
        pct list
    fi
}

# Configures initial GRUB and EFI settings for GPU passthrough, installs necessary packages, and reboots the system
# gpu passthrough step 1
#  
pve-gp1() {
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
    all-nos "$function_name" "Completed section 1, system will reboot now."

    # Perform system reboot without prompting
    reboot
}

# Adds necessary kernel modules for GPU passthrough to /etc/modules, updates initramfs, and reboots the system
# gpu passthrough step 2
#   
pve-gp2() {
    local function_name="${FUNCNAME[0]}"
    echo "Executing section 2:"

    # Add modules to /etc/modules
    echo "vfio" >> /etc/modules
    echo "vfio_iommu_type1" >> /etc/modules
    echo "vfio_pci" >> /etc/modules

    # Update initramfs
    update-initramfs -u -k all

    # Notify status
    all-nos "$function_name" "Completed section 2, system will reboot now."

    # Perform system reboot without prompting
    reboot
}

# Finalizes GPU passthrough setup by configuring VFIO-PCI IDs, blacklisting specific GPU drivers, and rebooting the system
# gpu passthrough step 3
#   
pve-gp3() {
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
    all-nos "$function_name" "Completed section 3, system will reboot now."

    # Perform system reboot without prompting
    reboot
}

# Detaches the GPU from the host system, making it available for VM passthrough
# gpu passthrough detach
#
pve-gpd() {
    local function_name="${FUNCNAME[0]}"
    
    echo "Current GPU driver and IOMMU group:"
    lspci -nnk | grep -A3 "VGA compatible controller"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done
    
    # Unload Nouveau if it's loaded
    if lsmod | grep -q nouveau; then
        echo "Unloading Nouveau driver"
        if ! modprobe -r nouveau; then
            all-nos "$function_name" "Warning: Failed to unload Nouveau driver. Continuing anyway."
        fi
    else
        echo "Nouveau driver not loaded."
    fi
    
    # Load VFIO driver
    if ! modprobe vfio-pci; then
        all-nos "$function_name" "Error: Failed to load VFIO-PCI driver. GPU detachment may fail."
        return 1
    fi
    
    # Get GPU PCI IDs
    local gpu_ids=$(lspci -nn | grep -i "VGA compatible controller" | awk '{print $1}')
    
    if [ -z "$gpu_ids" ]; then
        all-nos "$function_name" "Error: No GPU found."
        return 1
    fi
    
    for id in $gpu_ids; do
        if [ -e "/sys/bus/pci/devices/0000:$id/driver" ]; then
            echo "0000:$id" > /sys/bus/pci/devices/0000:$id/driver/unbind
        fi
        echo "vfio-pci" > /sys/bus/pci/devices/0000:$id/driver_override
        if ! echo "0000:$id" > /sys/bus/pci/drivers/vfio-pci/bind; then
            all-nos "$function_name" "Warning: Failed to bind GPU $id to VFIO-PCI."
        fi
    done
    
    echo "GPU driver and IOMMU group after detachment:"
    lspci -nnk | grep -A3 "VGA compatible controller"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done
    
    all-nos "$function_name" "GPU detachment process completed. Check above output for details."
}

# Attaches the GPU back to the host system
# gpu passthrough attach
#
pve-gpa() {
    local function_name="${FUNCNAME[0]}"
    
    echo "Current GPU driver and IOMMU group:"
    lspci -nnk | grep -A3 "VGA compatible controller"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done
    
    # Get GPU PCI IDs
    local gpu_ids=$(lspci -nn | grep -i "VGA compatible controller" | awk '{print $1}')
    
    if [ -z "$gpu_ids" ]; then
        all-nos "$function_name" "Error: No GPU found."
        return 1
    fi
    
    for id in $gpu_ids; do
        if [ -e "/sys/bus/pci/devices/0000:$id/driver" ]; then
            echo "0000:$id" > /sys/bus/pci/devices/0000:$id/driver/unbind
        fi
        echo > /sys/bus/pci/devices/0000:$id/driver_override
        echo "0000:$id" > /sys/bus/pci/drivers_probe
    done
    
    # Try to load the Nouveau driver if it's not already loaded
    if ! lsmod | grep -q nouveau; then
        echo "Loading Nouveau driver"
        if ! modprobe nouveau; then
            all-nos "$function_name" "Warning: Failed to load Nouveau driver. You may need to install it."
        fi
    else
        echo "Nouveau driver already loaded."
    fi
    
    echo "GPU driver and IOMMU group after reattachment:"
    lspci -nnk | grep -A3 "VGA compatible controller"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done
    
    all-nos "$function_name" "GPU reattachment process completed. Check above output for details."
}

# Checks the current status of the GPU
# gpu passthrough status
#
pve-gps() {
    local function_name="${FUNCNAME[0]}"
    
    echo "GPU Status:"
    echo "==========="
    
    # Check loaded GPU-related modules
    echo "Loaded GPU modules:"
    lsmod | grep -E "nvidia|vfio" || echo "No NVIDIA or VFIO modules loaded."
    
    # Check GPU PCI devices
    echo -e "\nGPU PCI devices:"
    lspci -nnk | grep -A3 "VGA compatible controller"
    
    # Check IOMMU groups
    echo -e "\nIOMMU Groups:"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done
    
    all-nos "$function_name" "GPU status check completed."
}

# Setting up different virtual machines specified in pve.conf
# virtual machine create
# <passed global variables>
pve-vmc() {
    local id="$1"
    local name="$2"
    local ostype="$3"
    local machine="$4"
    local iso="$5"
    local boot="$6"
    local bios="$7"
    local efidisk="$8"
    local scsihw="$9"
    local agent="${10}"
    local disk="${11}"
    local sockets="${12}"
    local cores="${13}"
    local cpu="${14}"
    local memory="${15}"
    local balloon="${16}"
    local net="${17}"

    qm create "$id" \
        --name "$name" \
        --ostype "$ostype" \
        --machine "$machine" \
        --ide2 "$iso,media=cdrom" \
        --boot "$boot" \
        --bios "$bios" \
        --efidisk0 "$efidisk" \
        --scsihw "$scsihw" \
        --agent "$agent" \
        --scsi0 "$disk" \
        --sockets "$sockets" \
        --cores "$cores" \
        --cpu "$cpu" \
        --memory "$memory" \
        --balloon "$balloon" \
        --net0 "$net"
}

# Starts a VM on the current node or migrates it from another node, with an option to shut down the source node after migration
# vm start get shutdown
# <vm_id> [s: optional, shutdown other node]
pve-vms() {
    # Retrieve and store hostname
    local hostname=$(hostname)

    # Check if vm_id argument is provided
    if [ -z "$1" ]; then
        all-use
        return 1
    fi

    # Assign vm_id to a variable
    local vm_id=$1

    # Call pve-vck function to get node_id
    local node_id=$(pve-vck "$vm_id")

    # Check if node_id is empty
    if [ -z "$node_id" ]; then
        echo "Node ID is empty. Cannot proceed."
        return 1
    fi

    # Main logic
    if [ "$hostname" = "$node_id" ]; then
        qm start "$vm_id"
        if [ "$2" = "s" ]; then
            # Shutdown the other node
            echo "Shutting down node $node_id"
            ssh "root@$node_id" "shutdown now"
        fi 
    else
        pve-vmg "$vm_id"
        qm start "$vm_id"
        if [ "$2" = "s" ]; then
            # Shutdown the other node
            echo "Shutting down node $node_id"
            ssh "root@$node_id" "shutdown now"
        fi
    fi
}

# Migrates a VM from a remote node to the current node, handling PCIe passthrough disable/enable during the process
# vm get start
# <vm_id>
pve-vmg() {
    local vm_id="$1"
    if [ $# -ne 1 ]; then
        all-use
        return 1
    fi

    # Call pve-vck to check if VM exists and get the node
    local node=$(pve-vck "$vm_id")
    if [ -n "$node" ]; then
        echo "VM found on node: $node"

        # Disable PCIe passthrough for the VM on the remote node
        if ! ssh "$node" "pve-vpt $vm_id off"; then
            echo "Failed to disable PCIe passthrough for VM on $node." >&2
            return 1
        fi

        # Migrate the VM to the current node
        if ! ssh "$node" "qm migrate $vm_id $(hostname)"; then
            echo "Failed to migrate VM from $node to $(hostname)." >&2
            return 1
        fi

        # Enable PCIe passthrough for the VM on the current node
        if ! pve-vpt "$vm_id" on; then
            echo "Failed to enable PCIe passthrough for VM on $(hostname)." >&2
            return 1
        fi

        echo "VM migrated and PCIe passthrough enabled."
        return 0  # Return success once VM is found and migrated
    fi

    echo "VM not found on any other node."
    return 1  # Return failure if VM is not found
}

# Toggles PCIe passthrough configuration for a specified VM, modifying its configuration file to enable or disable passthrough devices
# vm passthrough toggle
# <vm_id> <on|off>
pve-vpt() {
    local vm_id="$1"
    local action="$2"
    local vm_conf="$CONF_PATH_QEMU/$vm_id.conf"
    if [ $# -ne 2 ]; then
        all-use
        return 1
    fi

    # Get hostname for variable names
    local hostname=$(hostname)
    local node_pci0="${hostname}_node_pci0"
    local node_pci1="${hostname}_node_pci1"
    local core_count_on="${hostname}_core_count_on"
    local core_count_off="${hostname}_core_count_off"
    local usb_devices_var="${hostname}_usb_devices[@]"

    # Find the starting line of the VM configuration section
    local section_start=$(awk '/^\[/{print NR-1; exit}' "$vm_conf")

    # Action based on the parameter
    case "$action" in
        on)
            # Set core count based on configuration when toggled on
            sed -i "s/cores:.*/cores: ${!core_count_on}/" "$vm_conf"

            # Add passthrough lines
            if [ -z "$section_start" ]; then
                # If no section found, append passthrough lines at the end of the file
                for usb_device in "${!usb_devices_var}"; do
                    echo "$usb_device" >> "$vm_conf"
                done
                echo "hostpci0: ${!node_pci0},pcie=1,x-vga=1" >> "$vm_conf"
                echo "hostpci1: ${!node_pci1},pcie=1" >> "$vm_conf"
            else
                # If a section is found, insert passthrough lines at the appropriate position
                for usb_device in "${!usb_devices_var}"; do
                    sed -i "${section_start}a\\${usb_device}" "$vm_conf"
                    ((section_start++))
                done
                sed -i "${section_start}a\\hostpci0: ${!node_pci0},pcie=1,x-vga=1" "$vm_conf"
                ((section_start++))
                sed -i "${section_start}a\\hostpci1: ${!node_pci1},pcie=1" "$vm_conf"
            fi

            echo "Passthrough lines added to $vm_conf."
            ;;
        off)
            # Set default core count when toggled off
            sed -i "s/cores:.*/cores: ${!core_count_off}/" "$vm_conf"

            # Remove passthrough lines
            sed -i '/^usb[0-9]*:/d; /^hostpci[0-9]*:/d' "$vm_conf"

            echo "Passthrough lines removed from $vm_conf."
            ;;
        *)
            echo "Invalid parameter. Usage: pve-vpt <VM_ID> <on|off>"
            exit 1
            ;;
    esac
}

# Checks and reports which node in the Proxmox cluster is currently hosting a specified VM
# vm check node
# <vm_id>
pve-vck() {
    local vm_id="$1"
    local found_node=""
    if [ $# -ne 1 ]; then
        all-use
        return 1
    fi

    # Check if cluster_nodes array is populated
    if [ ${#cluster_nodes[@]} -eq 0 ]; then
        echo "Error: cluster_nodes array is empty"
        return 1
    fi

    for node in "${cluster_nodes[@]}"; do
        # Skip SSH for the local node
        if [ "$node" != "$(hostname)" ]; then
            ssh_output=$(ssh "$node" "qm list" 2>&1)
            ssh_exit_status=$?
            if [ $ssh_exit_status -eq 0 ] && echo "$ssh_output" | grep -q "\<$vm_id\>"; then
                found_node="$node"
                break
            fi
        else
            local_output=$(qm list 2>&1)
            local_exit_status=$?
            if [ $local_exit_status -eq 0 ] && echo "$local_output" | grep -q "\<$vm_id\>"; then
                found_node="$node"
                break
            fi
        fi
    done

    if [ -n "$found_node" ]; then
        echo "$found_node"
        return 0
    else
        return 1
    fi
}

