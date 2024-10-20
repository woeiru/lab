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

# Displays an overview of specific functions in the script, showing their usage, shortname, and description
# overview functions
#
net-fun() {
    all-laf "$FILEPATH_net" "$@"
}
# Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files
#
net-var() {
    all-acu -o "$CONFIG_net" "$DIR_LIB/.."
}

# Guides the user through renaming a network interface by updating udev rules and network configuration, with an option to reboot the system
# udev network interface
# [interactive]
net-uni() {
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


# Adds a specified service to the firewalld configuration and reloads the firewall. Checks for the presence of firewall-cmd before proceeding
# firewall (add) service (and) reload
# <service>
net-fsr() {
    local function_name="${FUNCNAME[0]}"
    local fw_service="$1"
    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi
   # Open firewall ports
    if command -v firewall-cmd > /dev/null; then
        firewall-cmd --permanent --add-service=$fw_service
        firewall-cmd --reload
	all-nos "$function_name" "executed ( $1 )"
    else
        echo "firewall-cmd not found, skipping firewall configuration."
    fi
}

# Allows a specified service through the firewall using firewall-cmd, making the change permanent and reloading the firewall configuration
# firewall allow service
# <service>
net-fas() {
    local function_name="${FUNCNAME[0]}"
    local fwd_as_1="$1"

    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi

    firewall-cmd --state
    firewall-cmd --add-service="$fwd_as_1" --permanent
    firewall-cmd --reload

    all-nos "$function_name" "executed"
}

# Mounts an NFS share interactively or with provided arguments
# network file share
# [server_ip] [shared_folder] [mount_point] [options]
net-nfs() {
    local function_name="${FUNCNAME[0]}"
    local server_ip=""
    local shared_folder=""
    local mount_point=""
    local options=""

    # If arguments are provided, use them
    if [ $# -eq 4 ]; then
        server_ip="$1"
        shared_folder="$2"
        mount_point="$3"
        options="$4"
    else
        # Use all-mev to prompt for each parameter
        all-mev "server_ip" "Enter NFS server IP" "$STO_NFS_SERVER_IP"
        all-mev "shared_folder" "Enter NFS shared folder" "$STO_NFS_SHARED_FOLDER"
        all-mev "mount_point" "Enter local mount point" "$STO_NFS_MOUNT_POINT"
        all-mev "options" "Enter mount options" "$STO_NFS_MOUNT_OPTIONS"
    fi

    # Create the mount point if it doesn't exist
    if [ ! -d "$mount_point" ]; then
        echo "Creating mount point $mount_point"
        sudo mkdir -p "$mount_point"
    fi

    # Perform the mount
    echo "Mounting NFS share..."
    if sudo mount -t nfs -o "$options" "${server_ip}:${shared_folder}" "$mount_point"; then
        echo "NFS share mounted successfully at $mount_point"
    else
        echo "Failed to mount NFS share"
        return 1
    fi

    # Verify the mount
    if mount | grep -q "$mount_point"; then
        echo "Mount verified successfully"
    else
        echo "Mount verification failed"
        return 1
    fi

    all-nos "$function_name" "NFS mount completed"
}

