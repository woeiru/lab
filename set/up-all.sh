#!/bin/bash

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to set global git configurations
configure_git() {
    local function_name="${FUNCNAME[0]}"
    git config --global user.name "woeiru"
    git config --global user.email "169383590+woeiru@users.noreply.github.com"
    notify_status "$function_name" "Git configurations set"
}

setup_sshd() {
    local function_name="${FUNCNAME[0]}"
    # Enable the sshd service to start at boot
    sudo systemctl enable sshd
    # Start the sshd service
    sudo systemctl start sshd
    # Check the status of the sshd service
    sudo systemctl status sshd
    notify_status "$function_name" "SSHD setup complete"
}

setup_sshd_firewalld() {
    local function_name="${FUNCNAME[0]}"
    # Check the current firewall state
    sudo firewall-cmd --state
    # Allow SSH service in the active zone
    sudo firewall-cmd --add-service=ssh --permanent
    # Reload the firewall to apply changes
    sudo firewall-cmd --reload
    notify_status "$function_name" "SSHD firewalld setup complete"
}

# Function to configure Samba
setup_smb() {
    local function_name="${FUNCNAME[0]}"
    # Prompt for missing inputs
    prompt_for_input "SMB_HEADER" "Enter Samba header" "$SMB_HEADER"
    prompt_for_input "SHARED_FOLDER" "Enter path to shared folder" "$SHARED_FOLDER"

    if [ "$SMB_HEADER" != "nobody" ]; then
        prompt_for_input "USERNAME" "Enter Samba username" "$USERNAME"
        while [ -z "$SMB_PASSWORD" ]; do
            prompt_for_input "SMB_PASSWORD" "Enter Samba password (cannot be empty)" "$SMB_PASSWORD"
        done
    fi

    # Apply the Samba configuration
    setup_smb_apply "$SMB_HEADER" "$SHARED_FOLDER" "$USERNAME" "$SMB_PASSWORD" "$WRITABLE_YESNO" "$GUESTOK_YESNO" "$BROWSABLE_YESNO"
    notify_status "$function_name" "Samba setup complete"
}

install_smb() {
    local function_name="${FUNCNAME[0]}"
    
    # Install Samba
    sudo apt update
    sudo apt install -y samba

    # Check if installation was successful
    if [ $? -eq 0 ]; then
        notify_status "$function_name" "Samba installed successfully"
    else
        notify_status "$function_name" "Failed to install Samba"
        return 1
    fi
}

# Function to apply Samba configuration
setup_smb_apply() {
    local function_name="${FUNCNAME[0]}"
    local SMB_HEADER="$1"
    local SHARED_FOLDER="$2"
    local username="$3"
    local smb_password="$4"
    local WRITABLE_YESNO="$5"
    local GUESTOK_YESNO="$6"
    local BROWSABLE_YESNO="$7"

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
        {
            echo "[$SMB_HEADER]"
            echo "    path = $SHARED_FOLDER"
            echo "    writable = $WRITABLE_YESNO"
            echo "    guest ok = $GUESTOK_YESNO"
            echo "    browseable = $BROWSABLE_YESNO"
        } | sudo tee -a /etc/samba/smb.conf > /dev/null
        echo "Samba configuration block added to smb.conf."
    fi

    # Restart Samba
    sudo systemctl restart smb

    # Set Samba user password only if SMB_HEADER is not "nobody"
    if [ "$SMB_HEADER" != "nobody" ]; then
        if id -u "$username" > /dev/null 2>&1; then
            echo -e "$smb_password\n$smb_password" | sudo smbpasswd -a -s "$username"
        else
            echo "User $username does not exist. Please create the user before setting Samba password."
        fi
    else
        echo "Skipping password setup for the nobody section."
    fi

    # Print confirmation message
    echo "Samba server configured. Shared folder: $SHARED_FOLDER"
    notify_status "$function_name" "Samba configuration applied"
}

# Function to setup Samba firewall rules
setup_smb_firewalld() {
    local function_name="${FUNCNAME[0]}"
    # Open firewall ports
    if command -v firewall-cmd > /dev/null; then
        sudo firewall-cmd --permanent --add-service=samba
        sudo firewall-cmd --reload
        notify_status "$function_name" "Samba firewalld setup complete"
    else
        echo "firewall-cmd not found, skipping firewall configuration."
    fi
}

# Function to prompt for input if not already set
prompt_for_input() {
    local var_name="$1"
    local prompt_message="$2"
    local current_value="$3"

    if [ -z "$current_value"] ; then
        read -p "$prompt_message: " input
        eval "$var_name=\$input"
    else
        eval "$var_name=\$current_value"
    fi
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
    echo "git. Run all"
    echo "git1. Configure git"
    echo "ssh. Run all"
    echo "ssh1. setup sshd"
    echo "ssh2. setup sshd firewalld"
    echo "smb. Run all"
    echo "smb1. setup smb"
    echo "smb2. setup smb firewalld"
}

# Function to read user choice
read_user_choice() {
    read -p "Enter your choice: " choice
    execute_choice "$choice"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
	git) exe_all_git;;
        git1) configure_git;;
        ssh) exe_all_ssh;;
        ssh1) setup_sshd;;
        ssh2) setup_sshd_firewalld;;
        smb) exe_all_smb;;
        smb1) install_smb;;
        smb2) setup_smb;;
        smb2) setup_smb_firewalld;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all git options
exe_all_git() {
    	configure_git
}

# Function to execute all ssh options
exe_all_ssh() {
    	setup_sshd
    	setup_sshd_firewalld
}

# Function to execute all smb options
exe_all_smb() {
	install_smb
    	setup_smb
    	setup_smb_firewalld
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

