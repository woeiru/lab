# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

#list all Functions in a given File
p() {
    local file_name="${1:-${BASH_SOURCE[0]}}"
    printf "%-20s | %-10s | %-10s | %-20s\n" "Function Name" "Size" "Header" "Comment"
    printf "%-20s | %-10s | %-10s | %-20s\n" "--------------------" "----------" "----------" "-------"

    # Initialize variables
    local last_comment_line=0
    local line_number=0
    declare -a comments=()

    # Read all comments into an array
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            comments[$line_number]="$line"
        fi
    done < "$file_name"

    # Loop through all lines in the file again
    line_number=0
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_-]*\(\) ]]; then
            # Extract function name
            func_name=$(echo "$line" | awk '{print $1}')
            # Calculate function size
            func_start_line=$line_number
            func_size=0
            while IFS= read -r func_line; do
                ((func_size++))
                if [[ $func_line == *} ]]; then
                    break
                fi
            done < <(tail -n +$func_start_line "$file_name")
            # Print function name, function size, comment line number, and comment
            printf "%-20s | %-10s | %-10s | %s\n" "$func_name" "$func_size" "${last_comment_line:-N/A}" "${comments[$last_comment_line]:-N/A}"
        elif [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            last_comment_line=$line_number
        fi
    done < "$file_name"
}

# if vm on node qm start if not vm-get before optional shutdown of other node
vm() {
    # Retrieve and store hostname
    local hostname=$(hostname)

    # Check if vm_id argument is provided
    if [ -z "$1" ]; then
        echo "Usage: vm <vm_id> [s]"
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

# remote vm-pt, migration, local vm-pt
vm-get() {
    local vm_id="$1"

    # Call vm-chk to check if VM exists and get the node
    local node=$(vm-chk "$vm_id")
    if [ -n "$node" ]; then
        echo "VM found on node: $node"

        # Disable PCIe passthrough for the VM on the remote node
        if ! ssh "$node" "vm-pt $vm_id off"; then
            echo "Failed to disable PCIe passthrough for VM on $node." >&2
            return 1
        fi

        # Migrate the VM to the current node
        if ! ssh "$node" "qm migrate $vm_id $(hostname)"; then
            echo "Failed to migrate VM from $node to $(hostname)." >&2
            return 1
        fi

        # Enable PCIe passthrough for the VM on the current node
        if ! vm-pt "$vm_id" on; then
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
vm-pt() {
    local vm_id="$1"
    local action="$2"
    local vm_conf="$CONF_PATH_QEMU/$vm_id.conf"

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
vm-chk() {
    local vm_id="$1"
    local found_node=""

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

# rysnc /var/lib/vz to an external location
p-rv() {
    # Check if the argument is provided
    if [ $# -eq 0 ]; then
        echo "Please provide the storage name as an argument."
        exit 1
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
    rsync -avhn --human-readable "$sy_vlv_source/" "$destination_path/"

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


# add nfs remote
p-an() {

    # Prompt user for storage ID
    read -p "Enter storage ID [$storage_id]: " new_storage_id
    storage_id=${new_storage_id:-$storage_id}

    # Prompt user for path
    read -p "Enter path [$path]: " new_path
    path=${new_path:-$path}

    # Prompt user for server
    read -p "Enter server [$server]: " new_server
    server=${new_server:-$server}

    # Prompt user for export
    read -p "Enter export [$nfs_export]: " new_nfs_export
    nfs_export=${new_nfs_export:-$nfs_export}

    # Add the NFS storage with user-provided parameters
    pvesm add nfs "$storage_id" --path "$path" --server "$server" --export "$nfs_export"

    # Set the content types for the NFS storage
    pvesm set "$storage_id" --content backup,snippets,iso,images,rootdir,vztmpl
}

# automount usb
p-au() {
    # Perform blkid and filter entries with sd*
    blkid_output=$(blkid | grep '/dev/sd*')

    # Display filtered results
    echo "Filtered entries with sd*:"
    echo "$blkid_output"

    # Prompt for the line number
    read -p "Enter the line number to retrieve the UUID: " line_number

    # Retrieve UUID based on the chosen line number
    chosen_line=$(echo "$blkid_output" | sed -n "${line_number}p")

    # Extract UUID from the chosen line
    TARGET_UUID=$(echo "$chosen_line" | grep -oP ' UUID="\K[^"]*')

    echo "The selected UUID is: $TARGET_UUID"

    # Check if the device's UUID is already present in /etc/fstab
    if grep -q "UUID=$TARGET_UUID" /etc/fstab; then
        echo "This UUID is already present in /etc/fstab."
    else
        # Check if the script is run as root
        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script as root to modify /etc/fstab."
            exit 1
        fi

        # Append entry to /etc/fstab for auto-mounting
        echo "UUID=$TARGET_UUID /mnt/local-usb auto defaults 0 2" >> /etc/fstab
        echo "Entry added to /etc/fstab for auto-mounting."
    fi

    # Perform system reboot
    read -p "Do you want to reboot the system now? (y/n): " REBOOT_CONFIRM
    if [ "$REBOOT_CONFIRM" = "y" ]; then
        reboot
    else
        echo "System reboot was not executed. Please manually restart the system to apply the changes."
    fi
}

# udev network interface
p-uni() {
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
p-sbn() {
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



