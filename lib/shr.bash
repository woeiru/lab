# get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

#  
# overview
#   
shr-fun() {
local file_name="$BASH_SOURCE"
all-laf "$file_name"
}

# Unified function to set up Samba
# samba setup 1
# <smb_header> <shared_folder> <username> <smb_password> <writable_yesno> <guestok_yesno> <browseable_yesno> <create_mask> <dir_mask> <force_user> <force_group>
shr-smb() {
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
    shr-sma "$smb_header" "$shared_folder" "$username" "$smb_password" "$writable_yesno" "$guestok_yesno" "$browseable_yesno" "$create_mask" "$dir_mask" "$force_user" "$force_group"
    all-nos "$function_name" "Samba setup complete"
}

# Helper script for samba setup.
# samba apply config
# <smb_header> <shared_folder> <username> <smb_password> <writable_yesno> <guestok_yesno> <browseable_yesno> <create_mask> <dir_mask> <force_user> <force_group>
shr-sma() {
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

# firewalld add samba service and reload
# firewalld setup samba
# <function_name>
shr-fws() {
    local function_name="${FUNCNAME[0]}"
    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi
   # Open firewall ports
    if command -v firewall-cmd > /dev/null; then
        firewall-cmd --permanent --add-service=samba
        firewall-cmd --reload
        all-nos "$function_name" "Samba firewalld setup complete"
    else
        echo "firewall-cmd not found, skipping firewall configuration."
    fi
}


