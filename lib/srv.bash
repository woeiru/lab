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

# Displays an overview of specific NFS-related functions in the script, showing their usage, shortname, and description
# overview functions
# 
srv-fun() {
    all-laf "$FILEPATH_srv" "$@"
}
# Displays an overview of NFS-specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
# 
srv-var() {
    all-acu -o "$CONFIG_srv" "$DIR_LIB/.."
}

# Sets up an NFS share by prompting for necessary information (NFS header, shared folder, and options) and applying the configuration
# nfs setup
# <nfs_header> <shared_folder> <nfs_options>
nfs-set() {
    local function_name="${FUNCNAME[0]}"
    local nfs_header="$1"
    local shared_folder="$2"
    local nfs_options="$3"

    # Prompt for missing inputs
    all-mev "nfs_header" "Enter NFS header" "$nfs_header"
    all-mev "shared_folder" "Enter path to shared folder" "$shared_folder"
    all-mev "nfs_options" "Enter NFS options" "$nfs_options"

    # Apply the NFS configuration
    nfs-apl "$nfs_header" "$shared_folder" "$nfs_options"
    all-nos "$function_name" "NFS setup complete"
}

# Applies NFS configuration by creating the shared folder if needed, updating /etc/exports, and restarting the NFS server
# nfs apply config
# <nfs_header> <shared_folder> <nfs_options>
nfs-apl() {
    local function_name="${FUNCNAME[0]}"
    local nfs_header="$1"
    local shared_folder="$2"
    local nfs_options="$3"

    # Check if the shared folder exists, create it if not
    if [ ! -d "$shared_folder" ]; then
        mkdir -p "$shared_folder"
        chmod -R 777 "$shared_folder"
        echo "Shared folder created: $shared_folder"
    fi

    # Check if the NFS export already exists in /etc/exports
    if grep -qF "$shared_folder" /etc/exports; then
        echo "NFS export already exists in /etc/exports. Skipping addition."
    else
        # Append NFS export line to /etc/exports
        echo "$shared_folder $nfs_options" | tee -a /etc/exports > /dev/null
        echo "NFS export added to /etc/exports."
    fi

    # Restart NFS server
    exportfs -ra
    systemctl restart nfs-server

    # Print confirmation message
    echo "NFS server configured. Shared folder: $shared_folder"
    all-nos "$function_name" "NFS configuration applied"
}

# Monitors and displays various aspects of the NFS server
# nfs monitor
# [option]
nfs-mon() {
    local function_name="${FUNCNAME[0]}"
    local option=""

    # If no argument is provided, prompt for option
    if [ $# -eq 0 ]; then
        echo "NFS Monitoring Options:"
        echo "1. Show NFS server status"
        echo "2. Display current NFS exports"
        echo "3. Show active NFS connections"
        echo "4. Display NFS statistics"
        echo "5. Check NFS-related processes"
        echo "6. View recent NFS server logs"
        echo "7. Show NFS mount points"
        echo "8. Display RPC information"
        echo "9. All of the above"
        all-mev "option" "Enter option number" "9"
    else
        option="$1"
    fi

    case "$option" in
        1|"Show NFS server status")
            echo "NFS Server Status:"
            systemctl status nfs-server
            ;;
        2|"Display current NFS exports")
            echo "Current NFS Exports:"
            exportfs -v
            ;;
        3|"Show active NFS connections")
            echo "Active NFS Connections:"
            ss -tna | grep :2049
            ;;
        4|"Display NFS statistics")
            echo "NFS Statistics:"
            nfsstat
            ;;
        5|"Check NFS-related processes")
            echo "NFS-related Processes:"
            ps aux | grep -E 'nfs|rpc'
            ;;
        6|"View recent NFS server logs")
            echo "Recent NFS Server Logs:"
            journalctl -u nfs-server -n 50
            ;;
        7|"Show NFS mount points")
            echo "NFS Mount Points:"
            df -h | grep nfs
            ;;
        8|"Display RPC information")
            echo "RPC Information:"
            rpcinfo -p
            ;;
        9|"All of the above")
            for i in {1..8}; do
                nfs-mon "$i"
                echo "----------------------------------------"
            done
            ;;
        *)
            echo "Invalid option"
            return 1
            ;;
    esac

    all-nos "$function_name" "NFS monitoring completed"
}

# Sets up a Samba share by prompting for missing configuration details and applying the configuration. Handles various share parameters including permissions, guest access, and file masks
# samba setup 1
# <smb_header> <shared_folder> <username> <smb_password> <writable_yesno> <guestok_yesno> <browseable_yesno> <create_mask> <dir_mask> <force_user> <force_group>
smb-set() {
    local function_name="${FUNCNAME[0]}"
	local smb_header="$1"
	local shared_folder="$2"
	local username="$3"
	local smb_password="$4"
	local writable_yesno="$5"
	local guestok_yesno="$6"
	local browseable_yesno="$7"
	local create_mask="$8"
	local dir_mask="$9"
	local force_user="${10}"
	local force_group="${11}"

    # Prompt for missing inputs
    all-mev "smb_header" "Enter Samba header" "$smb_header"
    all-mev "shared_folder" "Enter path to shared folder" "$shared_folder"

    if [ "$smb_header" != "nobody" ]; then
        all-mev "username" "Enter Samba username" "$username"

        while [ -z "$smb_password" ]; do
            all-mev "smb_password" "Enter Samba password (cannot be empty)" "$smb_password"
        done
    fi

    # Apply the Samba configuration
    smb-apl "$smb_header" "$shared_folder" "$username" "$smb_password" "$writable_yesno" "$guestok_yesno" "$browseable_yesno" "$create_mask" "$dir_mask" "$force_user" "$force_group"
    all-nos "$function_name" "Samba setup complete"
}

# Applies Samba configuration by creating the shared folder if needed, updating smb.conf with share details, restarting the Samba service, and setting up user passwords. Supports both user-specific and 'nobody' shares
# samba apply config
# <smb_header> <shared_folder> <username> <smb_password> <writable_yesno> <guestok_yesno> <browseable_yesno> <create_mask> <dir_mask> <force_user> <force_group>
smb-apl() {
    local function_name="${FUNCNAME[0]}"
	local smb_header="$1"
	local shared_folder="$2"
    	local username="$3"
    	local smb_password="$4"
    	local writable_yesno="$5"
    	local guestok_yesno="$6"
    	local browseable_yesno="$7"
	local create_mask="$8"
	local dir_mask="$9"
	local force_user="${10}"
	local force_group="${11}"

    # Check if the shared folder exists, create it if not
    if [ ! -d "$shared_folder" ]; then
        mkdir -p "$shared_folder"
        chmod -R 777 "$shared_folder"
        echo "Shared folder created: $shared_folder"
    fi

    # Check if the Samba configuration block already exists in smb.conf
    if grep -qF "[$smb_header]" /etc/samba/smb.conf; then
        echo "Samba configuration block already exists in smb.conf. Skipping addition."
    else
        # Append Samba configuration lines to smb.conf
        {
            echo "[$smb_header]"
            echo "    path = $shared_folder"
            echo "    writable = $writable_yesno"
            echo "    guest ok = $guestok_yesno"
            echo "    browseable = $browseable_yesno"
            echo "    create mask = $create_mask"
            echo "    dir mask = $dir_mask"
            echo "    force user = $force_user"
            echo "    force group = $force_group"
        } | tee -a /etc/samba/smb.conf > /dev/null
        echo "Samba configuration block added to smb.conf."
    fi

    # Restart Samba
    systemctl restart smb

    # Set Samba user password only if smb_header is not "nobody"
    if [ "$smb_header" != "nobody" ]; then
        if id -u "$username" > /dev/null 2>&1; then
            echo -e "$smb_password\n$smb_password" | smbpasswd -a -s "$username"
        else
            echo "User $username does not exist. Please create the user before setting Samba password."
        fi
    else
        echo "Skipping password setup for the nobody section."
    fi

    # Print confirmation message
    echo "Samba server configured. Shared folder: $shared_folder"
    all-nos "$function_name" "Samba configuration applied"
}

# Monitors and displays various aspects of the SMB server
# smb monitor
# [option]
smb-mon() {
    local function_name="${FUNCNAME[0]}"
    local option=""

    # If no argument is provided, prompt for option
    if [ $# -eq 0 ]; then
        echo "SMB Monitoring Options:"
        echo "1. Show SMB server status"
        echo "2. Display current SMB shares"
        echo "3. Show active SMB connections"
        echo "4. Display SMB server configuration"
        echo "5. Check SMB-related processes"
        echo "6. View recent SMB server logs"
        echo "7. Show SMB version information"
        echo "8. Display SMB user list"
        echo "9. All of the above"
        all-mev "option" "Enter option number" "9"
    else
        option="$1"
    fi

    case "$option" in
        1|"Show SMB server status")
            echo "SMB Server Status:"
            systemctl status smbd
            ;;
        2|"Display current SMB shares")
            echo "Current SMB Shares:"
            smbstatus --shares
            ;;
        3|"Show active SMB connections")
            echo "Active SMB Connections:"
            smbstatus --processes
            ;;
        4|"Display SMB server configuration")
            echo "SMB Server Configuration:"
            testparm -s
            ;;
        5|"Check SMB-related processes")
            echo "SMB-related Processes:"
            ps aux | grep -E 'smb|nmb|winbind'
            ;;
        6|"View recent SMB server logs")
            echo "Recent SMB Server Logs:"
            journalctl -u smbd -n 50
            ;;
        7|"Show SMB version information")
            echo "SMB Version Information:"
            smbd --version
            ;;
        8|"Display SMB user list")
            echo "SMB User List:"
            pdbedit -L -v
            ;;
        9|"All of the above")
            for i in {1..8}; do
                smb-mon "$i"
                echo "----------------------------------------"
            done
            ;;
        *)
            echo "Invalid option"
            return 1
            ;;
    esac

    all-nos "$function_name" "SMB monitoring completed"
}

