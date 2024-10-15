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
    echo "Warning: Configuration file $CONFIG_LIB not found!"
    # Don't exit, just continue
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

# Logging function
all-log() {
    local log_level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$log_level] $message"
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
    local file="$1"
    local line_to_add="$2"
    local temp_file=$(mktemp)

    # Check if both arguments were provided
    if [ -z "$file" ] || [ -z "$line_to_add" ]; then
        all-nos "$function_name" "Error: Both file path and line to add must be provided"
        return 1
    fi

    # Check if the file exists and is writable
    if [ ! -w "$file" ]; then
        all-nos "$function_name" "Error: $file does not exist or is not writable"
        return 1
    fi

    # Check if the line already exists in the file
    if grep -Fxq "$line_to_add" "$file"; then
        all-nos "$function_name" "Line already exists in $file"
        return 0
    fi

    # Create a temporary file with the new content
    cat "$file" > "$temp_file"
    echo "$line_to_add" >> "$temp_file"

    # Use mv to atomically replace the original file
    if mv "$temp_file" "$file"; then
        all-nos "$function_name" "Line added to $file"
        return 0
    else
        all-nos "$function_name" "Error: Failed to update $file"
        rm -f "$temp_file"
        return 1
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

# Creates and sends ZFS snapshots from a source pool to a destination pool. Supports initial full sends and incremental sends for efficiency
# zfs dataset backup
# <sourcepoolname> <destinationpoolname> <datasetname>
pve-zdb() {
    local sourcepoolname="$1"
    local destinationpoolname="$2"
    local datasetname="$3"

     if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

    # Generate a unique snapshot name based on the current date and hour
    local snapshot_name="$(date +%Y%m%d_%H)"
    local full_snapshot_name="${sourcepoolname}/${datasetname}@${snapshot_name}"

    # Check if the snapshot already exists
    if zfs list -t snapshot -o name | grep -q "^${full_snapshot_name}$"; then
        echo "Snapshot ${full_snapshot_name} already exists."
        read -p "Do you want to delete the existing snapshot? [y/N]: " delete_snapshot

        if [[ "$delete_snapshot" =~ ^[Yy]$ ]]; then
            # Delete the existing snapshot
            local delete_snapshot_cmd="zfs destroy ${full_snapshot_name}"
            echo "Deleting snapshot: ${delete_snapshot_cmd}"
            eval "${delete_snapshot_cmd}"
        else
            echo "Aborting backup to avoid overwriting existing snapshot."
            return 1
        fi
    fi

    # Create the snapshot
    local create_snapshot_cmd="zfs snapshot ${full_snapshot_name}"
    echo "Creating snapshot: ${create_snapshot_cmd}"
    eval "${create_snapshot_cmd}"

    # Determine the correct send and receive commands
    if zfs list -H -t snapshot -o name | grep -q "^${destinationpoolname}/${datasetname}@"; then
        # Get the name of the most recent snapshot in the destination pool
        local last_snapshot=$(zfs list -H -t snapshot -o name | grep "^${destinationpoolname}/${datasetname}@" | tail -1)

        # Prepare the incremental send and receive commands
        local send_cmd="zfs send -i ${last_snapshot} ${full_snapshot_name}"
        local receive_cmd="zfs receive ${destinationpoolname}/${datasetname}"

        echo "Incremental send command: ${send_cmd} | ${receive_cmd}"
    else
        # Prepare the initial full send and receive commands
        local send_cmd="zfs send ${full_snapshot_name}"
        local receive_cmd="zfs receive ${destinationpoolname}/${datasetname}"

        echo "Initial send command: ${send_cmd} | ${receive_cmd}"
    fi

    # Wait for user confirmation before executing the commands
    read -p "Press enter to execute the above command..."

    # Execute the send and receive commands
    eval "${send_cmd} | ${receive_cmd}"
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

# Finalizes or reverts GPU passthrough setup by configuring or removing VFIO-PCI IDs and blacklisting specific GPU drivers
# gpu passthrough step 3
# <enable|disable>
pve-gp3() {
    local function_name="${FUNCNAME[0]}"
    local action="$1"

    if [ "$action" != "enable" ] && [ "$action" != "disable" ]; then
        echo "Usage: $function_name <enable|disable>"
        return 1
    fi

    echo "Executing section 3 ($action mode):"

    vfio_conf="/etc/modprobe.d/vfio.conf"
    blacklist_conf="/etc/modprobe.d/blacklist.conf"

    if [ "$action" == "enable" ]; then
        # Enable GPU passthrough

        # Check for vfio-related logs in kernel messages
        dmesg | grep -i vfio
        dmesg | grep 'remapping'

        # List NVIDIA and AMD devices
        lspci -nn | grep 'NVIDIA'
        lspci -nn | grep 'AMD'

        # Configure VFIO
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

        # Blacklist GPU drivers
        echo "blacklist radeon" >> "$blacklist_conf"
        echo "blacklist amdgpu" >> "$blacklist_conf"

        all-nos "$function_name" "Completed section 3 (enable mode), system will reboot now."
    else
        # Disable GPU passthrough

        # Remove VFIO configuration
        if [ -f "$vfio_conf" ]; then
            rm "$vfio_conf"
            echo "Removed VFIO configuration file."
        else
            echo "VFIO configuration file not found. Skipping removal."
        fi

        # Remove GPU driver blacklisting
        if [ -f "$blacklist_conf" ]; then
            sed -i '/blacklist radeon/d' "$blacklist_conf"
            sed -i '/blacklist amdgpu/d' "$blacklist_conf"
            echo "Removed GPU driver blacklisting from $blacklist_conf."
        else
            echo "Blacklist configuration file not found. Skipping modification."
        fi

        all-nos "$function_name" "Completed section 3 (disable mode), system will reboot now."
    fi

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

    # Unload NVIDIA or AMD drivers if loaded
    for driver in nouveau nvidia amdgpu radeon; do
        if lsmod | grep -q $driver; then
            echo "Unloading $driver driver"
            if ! modprobe -r $driver; then
                all-nos "$function_name" "Warning: Failed to unload $driver driver. Continuing anyway."
            fi
        else
            echo "$driver driver not loaded."
        fi
    done

    # Load VFIO driver
    if ! modprobe vfio-pci; then
        all-nos "$function_name" "Error: Failed to load VFIO-PCI driver. GPU detachment may fail."
        return 1
    fi

    # Get GPU PCI IDs (including both NVIDIA and AMD)
    local gpu_ids=$(lspci -nn | grep -iE "VGA compatible controller|3D controller" | awk '{print $1}')

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
    
    all-log "INFO" "Starting GPU reattachment process"
    
    all-log "INFO" "Current GPU driver and IOMMU group:"
    lspci -nnk | grep -A3 "VGA compatible controller" | while read -r line; do
        all-log "INFO" "$line"
    done
    
    # Get GPU PCI IDs
    local gpu_ids=$(lspci -nn | grep -i "VGA compatible controller" | awk '{print $1}')
    
    if [ -z "$gpu_ids" ]; then
        all-log "ERROR" "No GPU found."
        all-nos "$function_name" "Error: No GPU found."
        return 1
    fi
    
    all-log "INFO" "Found GPU(s) with PCI ID(s): $gpu_ids"
    
    for id in $gpu_ids; do
        all-log "INFO" "Processing GPU with PCI ID: $id"
        if [ -e "/sys/bus/pci/devices/0000:$id/driver" ]; then
            all-log "INFO" "Unbinding GPU $id from current driver"
            echo "0000:$id" > /sys/bus/pci/devices/0000:$id/driver/unbind
            if [ $? -eq 0 ]; then
                all-log "INFO" "Successfully unbound GPU $id"
            else
                all-log "WARNING" "Failed to unbind GPU $id"
            fi
        else
            all-log "INFO" "GPU $id is not bound to any driver"
        fi
        
        all-log "INFO" "Resetting driver_override for GPU $id"
        echo > /sys/bus/pci/devices/0000:$id/driver_override
        
        # Determine the correct driver based on the GPU vendor
        local vendor_id=$(lspci -n -s "$id" | awk '{print $3}' | cut -d':' -f1)
        local driver
        case "$vendor_id" in
            1002)
                driver="amdgpu"
                ;;
            10de)
                driver="nouveau"
                ;;
            *)
                all-log "ERROR" "Unknown GPU vendor: $vendor_id. Cannot proceed with reattachment."
                all-nos "$function_name" "Error: Unknown GPU vendor: $vendor_id. Cannot proceed with reattachment."
                return 1
                ;;
        esac
        
        all-log "INFO" "Attempting to load $driver driver"
        if ! modprobe "$driver"; then
            all-log "ERROR" "Failed to load $driver driver. You may need to install it."
            all-nos "$function_name" "Error: Failed to load $driver driver. You may need to install it."
            return 1
        else
            all-log "INFO" "$driver driver loaded successfully."
        fi
        
        all-log "INFO" "Probing for new driver for GPU $id"
        echo "0000:$id" > /sys/bus/pci/drivers_probe
        if [ $? -eq 0 ]; then
            all-log "INFO" "Successfully probed for new driver for GPU $id"
        else
            all-log "WARNING" "Failed to probe for new driver for GPU $id"
        fi
        
        # Explicitly bind the driver if it's not automatically bound
        if [ ! -e "/sys/bus/pci/devices/0000:$id/driver" ]; then
            all-log "INFO" "Attempting to explicitly bind $driver to GPU $id"
            echo "0000:$id" > /sys/bus/pci/drivers/$driver/bind
            if [ $? -eq 0 ]; then
                all-log "INFO" "Successfully bound $driver to GPU $id"
            else
                all-log "ERROR" "Failed to bind $driver to GPU $id"
                all-nos "$function_name" "Error: Failed to bind $driver to GPU $id"
                return 1
            fi
        fi
    done
    
    all-log "INFO" "GPU driver and IOMMU group after reattachment:"
    lspci -nnk | grep -A3 "VGA compatible controller" | while read -r line; do
        all-log "INFO" "$line"
    done
    
    all-log "INFO" "GPU reattachment process completed."
    all-nos "$function_name" "GPU reattachment process completed. Check logs for details."
}

# Checks the current status of the GPU
# gpu passthrough status
#
pve-gps() {
    local function_name="${FUNCNAME[0]}"
    
    echo "GPU Status:"
    echo "==========="
        
    # Check IOMMU groups
    echo -e "\nIOMMU Groups:"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done

    # Check loaded GPU-related modules
    echo "Loaded GPU modules:"
    lsmod | grep -E "nvidia|vfio" || echo "No NVIDIA or VFIO modules loaded."
    
    # Check GPU PCI devices
    echo -e "\nGPU PCI devices:"
    lspci -nnk | grep -A3 "VGA compatible controller"

    all-nos "$function_name" "GPU status check completed."
}

# Deploys or modifies the VM shutdown hook for GPU reattachment
# Usage: pve-vmd <operation> <vm_id> [<vm_id2> ...]
# Operations: add, remove, debug
pve-vmd() {
    local function_name="${FUNCNAME[0]}"
    local hook_script="/var/lib/vz/snippets/gpu-reattach-hook.pl"
    local operation="$1"
    local vm_id="$2"

    echo "Debug: Operation: $operation, VM ID: $vm_id"

    # Validate operation
    if [[ ! "$operation" =~ ^(add|remove|debug)$ ]]; then
        echo "Error: Invalid operation. Use 'add', 'remove', or 'debug'."
        return 1
    fi

    # Check if /var/lib/vz/snippets exists, create if not
    if [ ! -d "/var/lib/vz/snippets" ]; then
        echo "Creating /var/lib/vz/snippets directory..."
        if ! mkdir -p "/var/lib/vz/snippets"; then
            echo "Error: Failed to create /var/lib/vz/snippets directory. Aborting."
            return 1
        fi
    fi

    # Function to create or update hook script
    create_or_update_hook_script() {
        if ! cat > "$hook_script" << EOL
#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);

my \$vmid = shift;
my \$phase = shift;

my \$log_file = '/var/log/gpu-reattach-hook.log';

open(my \$log, '>>', \$log_file) or die "Could not open log file: \$!";
print \$log strftime("%Y-%m-%d %H:%M:%S", localtime) . " - VM \$vmid, Phase: \$phase\n";

if (\$phase eq 'post-stop') {
    print \$log "Attempting to reattach GPU for VM \$vmid\n";
    my \$result = system("bash -c 'source /root/lab/lib/pve.bash && pve-gpa'");
    print \$log "pve-gpa execution result: \$result\n";
}

close(\$log);
EOL
        then
            echo "Error: Failed to create or update hook script. Aborting."
            return 1
        fi

        if ! chmod 755 "$hook_script"; then
            echo "Error: Failed to set permissions on hook script. Aborting."
            return 1
        fi
        echo "Hook script created/updated and made executable."
    }

    # Create or update hook script
    if ! create_or_update_hook_script; then
        return 1
    fi

    if [ "$operation" = "debug" ]; then
        echo "Debugging hook setup:"
        echo "1. Checking hook script existence and permissions:"
        ls -l "$hook_script"
        echo "2. Checking hook script content:"
        cat "$hook_script"
        echo "3. Checking Proxmox VM configurations for hook references:"
        grep -r "hookscript" /etc/pve/qemu-server/
        echo "4. Manually triggering hook script:"
        perl "$hook_script" "$vm_id" "post-stop"
        echo "5. Checking log file:"
        cat /var/log/gpu-reattach-hook.log
        return 0
    fi

    # Perform operation
    case "$operation" in
        add)
            if qm set "$vm_id" -hookscript "local:snippets/$(basename "$hook_script")"; then
                echo "Hook applied to VM $vm_id"
            else
                echo "Failed to apply hook to VM $vm_id"
                return 1
            fi
            ;;
        remove)
            if qm set "$vm_id" -delete hookscript; then
                echo "Hook removed from VM $vm_id"
            else
                echo "Failed to remove hook from VM $vm_id"
                return 1
            fi
            ;;
    esac

    all-nos "$function_name" "Hook $operation completed for VM $vm_id"
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

