#!/bin/bash

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
    notify_status "$function_name" "Additional Packages installed"
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
    echo "nothing to do"
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

