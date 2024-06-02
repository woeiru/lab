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

prompt_for_input() {
    local var_name=$1
    local prompt_message=$2
    local current_value=$3

    read -p "$prompt_message [$current_value]: " input
    if [ -n "$input" ]; then
        eval "$var_name=\"$input\""
    else
        eval "$var_name=\"$current_value\""
    fi
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

    notify_status "$function_name" "executed"
}

setup_sshd_firewalld() {
    local function_name="${FUNCNAME[0]}"

    firewall-cmd --state
    firewall-cmd --add-service=ssh --permanent
    firewall-cmd --reload

    notify_status "$function_name" "executed"
}

install_pakages () {
    local function_name="${FUNCNAME[0]}"
    local pakm="$1"
    local p1="$2"
    local p2="$3"
    local p3="$4"
    
    # Install Samba
    "$pakm" update
    "$pakm" upgrade -y
    "$pakm" install -y "$p1" "$p2" "$p3"

    # Check if installation was successful
    if [ $? -eq 0 ]; then
	    notify_status "$function_name" "executed ( $p1 $p2 $p3 )"
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

# Unified function to set up Samba
setup_smb() {
    local function_name="${FUNCNAME[0]}"
	local smb_header="$1"
	local shared_folder="$2"
	local username="$3"
	local smb_password="$4"
	local writable_yesno="$5"
	local guestok_yesno="$6"
	local browseable_yesno="$7"

    # Prompt for missing inputs
    prompt_for_input "smb_header" "Enter Samba header" "$smb_header"
    prompt_for_input "shared_folder" "Enter path to shared folder" "$shared_folder"

    if [ "$smb_header" != "nobody" ]; then
        prompt_for_input "username" "Enter Samba username" "$username"

        while [ -z "$smb_password" ]; do
            prompt_for_input "smb_password" "Enter Samba password (cannot be empty)" "$smb_password"
        done
    fi

    # Apply the Samba configuration
    setup_smb_apply "$smb_header" "$shared_folder" "$username" "$smb_password" "$writable_yesno" "$guestok_yesno" "$browseable_yesno"
    notify_status "$function_name" "Samba setup complete"
}

# Function to apply Samba configuration
setup_smb_apply() {
    local function_name="${FUNCNAME[0]}"
	local smb_header="$1"
	local shared_folder="$2"
    	local username="$3"
    	local smb_password="$4"
    	local writable_yesno="$5"
    	local guestok_yesno="$6"
    	local browseable_yesno="$7"

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

    echo "a........................"
    echo "a1. install pakages"
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
        a) 	a_xall;;
        a1) 	install_pakages;;
	git) 	git_xall;;
        git1) 	configure_git;;
	user) 	user_xall;;
        user1) 	setup_user;;
        smb) 	smb_xall;;
        smb1) 	setup_smb;;
        smb2) 	setup_smb_firewalld;;
        ssh) 	ssh_xall;;
        ssh1) 	setup_sshd;;
        ssh2) 	setup_sshd_firewalld;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all

a_xall() {
    	install_pakages "$PAKAGE_MANAGER" "$PAKAGE1" "$PAKAGE3" "$PAKAGE2" 
}
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
	install_smb "$PAKAGE_MANAGER"
    	setup_smb  "$SMB_HEADER" "$SHARED_FOLDER" "$USERNAME" "$SMB_PASSWORD" "$WRITABLE_YESNO" "$GUESTOK_YESNO" "$BROWSABLE_YESNO" 
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

