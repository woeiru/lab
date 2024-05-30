#!/bin/bash

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to set global git configurations
configure_git() {
    local function_name="configure_git"
    git config --global user.name "woeiru"
    git config --global user.email "169383590+woeiru@users.noreply.github.com"
    notify_status "$function_name" "Git configurations set"
}

setup_sshd() {
    # Enable the sshd service to start at boot
    sudo systemctl enable sshd

    # Start the sshd service
    sudo systemctl start sshd

    # Check the status of the sshd service
    sudo systemctl status sshd

    # Check the current firewall state
    sudo firewall-cmd --state

    # Get the active zones
    active_zones=$(sudo firewall-cmd --get-active-zones | awk 'NR==1{print $1}')

    # Allow SSH service in the active zone
    sudo firewall-cmd --zone=$active_zones --add-service=ssh --permanent

    # Reload the firewall to apply changes
    sudo firewall-cmd --reload

    # Verify that SSH is allowed
    sudo firewall-cmd --zone=$active_zones --list-all
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
    echo "a1. Configure git"
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
        a1) configure_git;;
        b1) configure_git;;
        a) execute_a_options;;
        b) execute_b_options;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all a options
execute_a_options() {
    configure_git
}

# Function to execute all b options
execute_b_options() {
    setup_sshd
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

