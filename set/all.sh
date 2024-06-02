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

check_and_append() {
    local file="$1"
    local line="$2"

    # Check if the line is already present in the file
    if ! grep -Fxq "$line" "$file"; then
        # If not, append the line to the file
        echo "$line" >> "$file"
        echo "Line appended to $file"
    else
        echo "Line already present in $file"
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
    local pm="$1"
    local p2="$2"
    local p3="$3"
   
    "$pm" update
    "$pm" upgrade -y
    "$pm" install -y "$p2" "$p3"

    # Check if installation was successful
    if [ $? -eq 0 ]; then
	    notify_status "$function_name" "executed ( $p2 $p3 )"
    else
        notify_status "$function_name" "Failed to install  ( $p2 $p3 )"
        return 1
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

    echo "a.......................( include config )"
    echo "a1. source dotfiles"
    echo "a2. install pakages"
    echo ""
    echo "git.......................( include config )"
    echo "git1. setup git"
    echo "ssh.......................( include config )"
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
        a1) 	check_and_append;;
        a2) 	install_pakages;;
	git) 	git_xall;;
        git1) 	configure_git;;
        ssh) 	ssh_xall;;
        ssh1) 	setup_sshd;;
        ssh2) 	setup_sshd_firewalld;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all

a_xall() {
	check_and_append "$DOT_FILE1" "$DOT_SOURCE1"
    	install_pakages "$PM1" "$PM1P2" "$PM1P3" 
	exec bash
}

git_xall() {
    	git_setup "$GIT_USERNAME1" "$GIT_USERMAIL1"
}

ssh_xall() {
    	setup_sshd
    	setup_sshd_firewalld
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

