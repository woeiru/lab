# get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# overview
pve() {
local file_name="$BASH_SOURCE"
all-laf "$file_name"
}

# if vm on node qm start if not vm-get before optional shutdown of other node
# <vm_id> [s: optional, shutdown other node]
vm() {
    # Retrieve and store hostname
    local hostname=$(hostname)

    # Check if vm_id argument is provided
    if [ -z "$1" ]; then
	all-gfa
        return 1
    fi

    # Assign vm_id to a variable
    local vm_id=$1

    # Call vm-chk function to get node_id
    local node_id=$(vm-chk "$vm_id")

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
        vm-get "$vm_id"
        qm start "$vm_id"
        if [ "$2" = "s" ]; then
            # Shutdown the other node
            echo "Shutting down node $node_id"
            ssh "root@$node_id" "shutdown now"
        fi
    fi
}

# remote vm-pth, migration, local vm-pth
# <vm_id>
vm-get() {
    local vm_id="$1"
    if [ $# -ne 1 ]; then
	all-gfa
        return 1
    fi

    # Call vm-chk to check if VM exists and get the node
    local node=$(vm-chk "$vm_id")
    if [ -n "$node" ]; then
        echo "VM found on node: $node"

        # Disable PCIe passthrough for the VM on the remote node
        if ! ssh "$node" "vm-pth $vm_id off"; then
            echo "Failed to disable PCIe passthrough for VM on $node." >&2
            return 1
        fi

        # Migrate the VM to the current node
        if ! ssh "$node" "qm migrate $vm_id $(hostname)"; then
            echo "Failed to migrate VM from $node to $(hostname)." >&2
            return 1
        fi

        # Enable PCIe passthrough for the VM on the current node
        if ! vm-pth "$vm_id" on; then
            echo "Failed to enable PCIe passthrough for VM on $(hostname)." >&2
            return 1
        fi

        echo "VM migrated and PCIe passthrough enabled."
        return 0  # Return success once VM is found and migrated
    fi

    echo "VM not found on any other node."
    return 1  # Return failure if VM is not found
}

# toggle Passthrough lines in the VM Config ON or OFF
# <VM_ID> <on|off>
vm-pth() {
    local vm_id="$1"
    local action="$2"
    local vm_conf="$CONF_PATH_QEMU/$vm_id.conf"
    if [ $# -ne 2 ]; then
	all-gfa
        return 1
    fi

    # Get hostname for variable names
    local hostname=$(hostname)
    local node_pci0="${hostname}_node_pci0"
    local node_pci1="${hostname}_node_pci1"
    local core_count_on="${hostname}_core_count_on"
    local core_count_off="${hostname}_core_count_off"

    # Find the starting line of the VM configuration section
    local section_start=$(awk '/^\[/{print NR-1; exit}' "$vm_conf")

    # Action based on the parameter
    case "$action" in
        on)
            # Set core count based on configuration when toggled on
            sed -i "s/cores:.*/cores: ${!core_count_on}/" "$vm_conf"

            # Add passthrough lines
            if [ -z "$section_start" ]; then
                # If no section found, append passthrough lines at the end of the file using a here document
                cat <<EOF >> "$vm_conf"
usb1: host=3-1
usb2: host=3-2
usb3: host=3-3
usb4: host=3-4
usb5: host=5-1
usb6: host=5-2
usb7: host=5-3
usb8: host=5-4
usb9: host=4-4
hostpci0: ${!node_pci0},pcie=1,x-vga=1
hostpci1: ${!node_pci1},pcie=1
EOF
            else
                # If a section is found, insert passthrough lines at the appropriate position in the file using sed
                sed -i "${section_start}a\\
usb1: host=3-1\n\
usb2: host=3-2\n\
usb3: host=3-3\n\
usb4: host=3-4\n\
usb5: host=5-1\n\
usb6: host=5-2\n\
usb7: host=5-3\n\
usb8: host=5-4\n\
usb9: host=4-4\n\
hostpci0: ${!node_pci0},pcie=1,x-vga=1\n\
hostpci1: ${!node_pci1},pcie=1" "$vm_conf"
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
            echo "Invalid parameter. Usage: vm-tog-pass <VM_ID> <on|off>"
            exit 1
            ;;
    esac
}

# check if the VM exists on any node and return the node ID where it is found
# <vm_id>
vm-chk() {
    local vm_id="$1"
    local found_node=""
    if [ $# -ne 1 ]; then
	all-gfa
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

# rysnc to an external location
# <storage_name>
pve-rsy() {
    if [ $# -ne 1 ]; then
	all-gfa
        return 1
    fi

    local storage_name="$1"
    local destination_path="$sy_vlv_destination/$storage_name"

    # Check if destination path exists
    if [ ! -d "$destination_path" ]; then
        echo "Destination path $destination_path does not exist."
        exit 1
    fi

    # Display files to be transferred
    echo "Files to be transferred from $sy_vlv_source to $destination_path:"
    rsync -avhn "$sy_vlv_source/" "$destination_path/"

    # Ask for confirmation
    read -p "Do you want to proceed with the transfer? (y/n): " confirm
    case $confirm in
        [Yy])   # Proceed with the transfer
                # Perform the transfer
                rsync -avh --human-readable "$sy_vlv_source/" "$destination_path/"
                echo "Transfer completed successfully."
                ;;
        [Nn])   # Abort the transfer
                echo "Transfer aborted."
                ;;
        *)      # Invalid input
                echo "Invalid input. Please enter 'y' or 'n'."
                ;;
    esac
}

# udev network interface
# [interaction with user]
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

# disable repository by commenting out lines starting with "deb" in specified files
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

# add a line to sources.list if it doesn't already exist
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

# update package lists and upgrade packages
#   
pve-uup() {
    local function_name="${FUNCNAME[0]}"
    apt update
    apt upgrade -y
    all-nos "$function_name" "executed"
}

# remove subscription notice
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

# BTRFS options
# <device1> <device2> <mount_point>
pve-br1() {
    local function_name="${FUNCNAME[0]}"
    local device1="$1"
    local device2="$2"
    local mount_point="$3"
    if [ $# -ne 3 ]; then
	all-gfa
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
	all-gfa
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

# container list update
#  
pve-clu() {
    local function_name="${FUNCNAME[0]}"

    	pveam update

    all-nos "$function_name" "executed"
}

# container downloads
#   
pve-cdo() {
    local function_name="${FUNCNAME[0]}"
    local ct_dl="$1"

    	pveam download local "$ct_dl" 

	all-nos "$function_name" "executed ( $ct_dl )"
}

# container bindmount
# <vmid> <mphost> <mpcontainer>
pve-cbm() {
    local function_name="${FUNCNAME[0]}"
    local vmid="$1"
    local mphost="$2"
    local mpcontainer="$3"
    if [ $# -ne 3 ]; then
	all-gfa
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
