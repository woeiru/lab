#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to set global git configurations
git_setup() {
    local function_name="${FUNCNAME[0]}"
    local username="$1"
    local usermail="$2"

    git config --global user.name "$username"
    git config --global user.email "$usermail"

    notify_status "$function_name" "executed ( $username / $usermail )"
}

# Function to setup user
setup_user() {
    local function_name="${FUNCNAME[0]}"
    local username="$1"
    local password="$2"

    # Prompt for user details
    prompt_for_input "username" "Enter new username" "$username"
    while [ -z "$password" ]; do
        prompt_for_input "password" "Enter password for $username" "$password"
    done

    # Create the user
    useradd -m "$username"
    echo "$username:$password" | chpasswd

    # Check if user creation was successful
    if id -u "$username" > /dev/null 2>&1; then
        notify_status "$function_name" "User $username created successfully"
    else
        notify_status "$function_name" "Failed to create user $username"
        return 1
    fi
}
  
setup_sshd() {
    local function_name="${FUNCNAME[0]}"

    systemctl enable sshd
    systemctl start sshd
    systemctl status sshd

    notify_status "$function_name" "SSHD setup complete"
}

setup_sshd_firewalld() {
    local function_name="${FUNCNAME[0]}"

    firewall-cmd --state
    firewall-cmd --add-service=ssh --permanent
    firewall-cmd --reload

    notify_status "$function_name" "SSHD firewalld setup complete"
}

install_smb() {
    local function_name="${FUNCNAME[0]}"
    
    # Install Samba
    apt update
    apt install -y samba

    # Check if installation was successful
    if [ $? -eq 0 ]; then
        notify_status "$function_name" "Samba installed successfully"
    else
        notify_status "$function_name" "Failed to install Samba"
        return 1
    fi
}
   
systemd_smb() {
    local function_name="${FUNCNAME[0]}"
    
    # Enable and start smbd service
    systemctl enable smbd
    systemctl start smbd
    
    # Check if service is active
    systemctl is-active --quiet smbd
    if [ $? -eq 0 ]; then
        notify_status "$function_name" "Samba service is active"
    else
        read -p "Samba service is not active. Do you want to continue anyway? [Y/n] " choice
        case "$choice" in 
            [yY]|[yY][eE][sS])
                notify_status "$function_name" "Samba service is not active"
                ;;
            *)
                notify_status "$function_name" "Samba service is not active. Exiting."
                return 1
                ;;
        esac
    fi
}


setup_smb() {
    local function_name="${FUNCNAME[0]}"
    # Read config file into variables
    source /path/to/config_file.conf

    # Prompt for missing inputs
    prompt_for_input "SMB_HEADER" "Enter Samba header" "$SMB_HEADER"
    if [ -z "$SMB_HEADER" ]; then
        SMB_HEADER="$DEFAULT_SMB_HEADER"  # Set default from config if not provided
    fi
    
    prompt_for_input "SHARED_FOLDER" "Enter path to shared folder" "$SHARED_FOLDER"
    if [ -z "$SHARED_FOLDER" ]; then
        SHARED_FOLDER="$DEFAULT_SHARED_FOLDER"  # Set default from config if not provided
    fi

    if [ "$SMB_HEADER" != "nobody" ]; then
        prompt_for_input "USERNAME" "Enter Samba username" "$USERNAME"
        if [ -z "$USERNAME" ]; then
            USERNAME="$DEFAULT_USERNAME"  # Set default from config if not provided
        fi

        while [ -z "$SMB_PASSWORD" ]; do
            prompt_for_input "SMB_PASSWORD" "Enter Samba password (cannot be empty)" "$SMB_PASSWORD"
        done
    fi

    # Apply the Samba configuration
    setup_smb_apply "$SMB_HEADER" "$SHARED_FOLDER" "$USERNAME" "$SMB_PASSWORD" "$WRITABLE_YESNO" "$GUESTOK_YESNO" "$BROWSABLE_YESNO"
    notify_status "$function_name" "Samba setup complete"
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
        mkdir -p "$SHARED_FOLDER"
        chmod -R 777 "$SHARED_FOLDER"
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
        } | tee -a /etc/samba/smb.conf > /dev/null
        echo "Samba configuration block added to smb.conf."
    fi

    # Restart Samba
    systemctl restart smb

    # Set Samba user password only if SMB_HEADER is not "nobody"
    if [ "$SMB_HEADER" != "nobody" ]; then
        if id -u "$username" > /dev/null 2>&1; then
            echo -e "$smb_password\n$smb_password" | smbpasswd -a -s "$username"
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
        firewall-cmd --permanent --add-service=samba
        firewall-cmd --reload
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
    echo "git........................"
    echo "git1. setup git"
    echo "user......................."
    echo "user1. setup user"
    echo "smb........................"
    echo "smb1. setup smb"
    echo "smb2. setup smb firewalld"
    echo "ssh........................"
    echo "ssh1. setup sshd"
    echo "ssh2. setup sshd firewalld"
}

# Function to read user choice
read_user_choice() {
    read -p "Enter your choice: " choice
    execute_choice "$choice"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
	git) 	git_xall;;
        git1) 	configure_git;;
	user) 	user_xall;;
        user1) 	setup_user;;
        smb) 	smb_xall;;
        smb1) 	install_smb;;
        smb2) 	setup_smb;;
        smb2) 	setup_smb_firewalld;;
        ssh) 	ssh_xall;;
        ssh1) 	setup_sshd;;
        ssh2) 	setup_sshd_firewalld;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all

git_xall() {
    	git_setup "$GIT_USERNAME1" "$GIT_USERMAIL1"
}

user_xall() {
    	setup_user "$USERNAME1" "$PASSWORD1"
}

ssh_xall() {
    	setup_sshd
    	setup_sshd_firewalld
}

smb_xall() {
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

