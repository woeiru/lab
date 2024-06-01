#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"


# Load configuration from file
load_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        echo "Configuration file not found: $config_file"
        exit 1
    fi
}

# Invoke load_config directly under its definition
load_config "$(dirname "$0")/../var/osus.conf"

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to update package lists and upgrade packages
update_upgrade() {
    local function_name="update_upgrade"
    zypper update
    zypper upgrade -y
    notify_status "$function_name" "Package lists updated and packages upgraded"
}

# Function to install git and vim
install_packages() {
    local function_name="install_packages"
    zypper install -y git vim tree podman corosync-qnetd
    notify_status "$function_name" "Additional packages installed"
}

# Function to prompt for input if a variable is not set
prompt_for_input() {
    local var_name="$1"
    local prompt_message="$2"
    local default_value="$3"
    read -p "$prompt_message [$default_value]: " input_value
    eval "$var_name=${input_value:-$default_value}"
}

# Function to apply Samba configuration
apply_samba_config() {
    local SMB_HEADER="$1"
    local SHARED_FOLDER="$2"
    local username="$3"
    local smb_password="$4"

    # Check if the shared folder exists, create it if not
    if [ ! -d "$SHARED_FOLDER" ]; then
        sudo mkdir -p "$SHARED_FOLDER"
        sudo chmod -R 777 "$SHARED_FOLDER"
        echo "Shared folder created: $SHARED_FOLDER"
    fi

    # Check if the Samba configuration block already exists in smb.conf
    if grep -qF "[$SMB_HEADER]" /etc/samba/smb.conf; then
        echo "Samba configuration block already exists in smb.conf. Skipping addition."
    else
        # Append Samba configuration lines to smb.conf
        echo "[$SMB_HEADER]" | sudo tee -a /etc/samba/smb.conf > /dev/null
        echo "    path = $SHARED_FOLDER" | sudo tee -a /etc/samba/smb.conf > /dev/null
        echo "    writable = $WRITABLE_YESNO" | sudo tee -a /etc/samba/smb.conf > /dev/null
        echo "    guest ok = $GUESTOK_YESNO" | sudo tee -a /etc/samba/smb.conf > /dev/null
        echo "    browseable = $BROWSABLE_YESNO" | sudo tee -a /etc/samba/smb.conf > /dev/null
        echo "Samba configuration block added to smb.conf."
    fi

    # Restart Samba
    sudo systemctl restart smb

    # Open firewall ports
    sudo firewall-cmd --permanent --add-service=samba
    sudo firewall-cmd --reload

    # Set Samba user password only if SMB_HEADER is not "nobody"
    if [ "$SMB_HEADER" != "nobody" ]; then
        echo -e "$smb_password\n$smb_password" | sudo smbpasswd -a -s "$username"
    else
        echo "Skipping password setup for the nobody section."
    fi

    # Print confirmation message
    echo "Samba server configured. Shared folder: $SHARED_FOLDER"
}

# Function to configure Samba
setup_samba() {
    # Prompt for missing inputs
    prompt_for_input "SMB_HEADER" "Enter Samba header" "$SMB_HEADER"
    prompt_for_input "SHARED_FOLDER" "Enter path to shared folder" "$SHARED_FOLDER"
    
    # Prompt for password only if SMB_HEADER is not "nobody"
    if [ "$SMB_HEADER" != "nobody" ]; then
    		prompt_for_input "USERNAME" "Enter Samba username" "$USERNAME"
        while [ -z "$SMB_PASSWORD" ]; do
            prompt_for_input "SMB_PASSWORD" "Enter Samba password (cannot be empty)" "$SMB_PASSWORD"
        done
    fi

    # Apply the Samba configuration
    apply_samba_config "$SMB_HEADER" "$SHARED_FOLDER" "$USERNAME" "$SMB_PASSWORD" 
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
    echo "a1. Update and upgrade packages"
    echo "a2. Install packages"
    echo "a. Run all a options"
    echo "b1. Configure Samba server"
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
        a1) update_upgrade;;
        a2) install_packages;;
        a) execute_a_options;;
        b1) setup_samba;;
        b) execute_b_options;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all a options
execute_a_options() {
    update_upgrade
    install_packages
}

# Function to execute all b options
execute_b_options() {
    setup_samba
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

