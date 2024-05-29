#!/bin/bash

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Function to disable repository by commenting out lines starting with "deb" in specified files
disable_repo() {
    local function_name="${FUNCNAME[0]}"
    files=(
        "/etc/apt/sources.list.d/pve-enterprise.list"
        "/etc/apt/sources.list.d/ceph.list"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            sed -i '/^deb/ s/^/#/' "$file"
            notify_status "$function_name" "Changes applied to $file"
        else
            notify_status "$function_name" "File $file not found."
        fi
    done
}

# Function to add a line to sources.list if it doesn't already exist
add_repo() {
    local function_name="${FUNCNAME[0]}"
    line_to_add="deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription"
    file="/etc/apt/sources.list"

    if grep -Fxq "$line_to_add" "$file"; then
        notify_status "$function_name" "Line already exists in $file"
    else
        echo "$line_to_add" >> "$file"
        notify_status "$function_name" "Line added to $file"
    fi
}

# Function to update package lists and upgrade packages
update_upgrade() {
    local function_name="${FUNCNAME[0]}"
    apt update
    apt upgrade -y
    notify_status "$function_name" "Package lists updated and packages upgraded"
}

# Function for installing packages
install_packages() {
    local function_name="${FUNCNAME[0]}"
    apt install -y git vim tree
    notify_status "$function_name" "Additional Packages installed"
}

# Function to remove subscription notice
remove_subscription_notice() {
    local function_name="${FUNCNAME[0]}"
    sed -Ezi.bak "s/(Ext\.Msg\.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

    # Prompt user whether to restart the service
    read -p "Do you want to restart the pveproxy.service now? (y/n): " choice
    case "$choice" in
        y|Y ) systemctl restart pveproxy.service && notify_status "$function_name" "Service restarted successfully.";;
        n|N ) notify_status "$function_name" "Service not restarted.";;
        * ) notify_status "$function_name" "Invalid choice. Service not restarted.";;
    esac
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
    echo "a1. Disable repository"
    echo "a2. Add repository"
    echo "a3. Update and upgrade packages"
    echo "a4. Install packages"
    echo "a5. Remove subscription notice"
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
        a1) disable_repo;;
        a2) add_repo;;
        a3) update_upgrade;;
        a4) install_packages;;
        a5) remove_subscription_notice;;
        a) execute_a_options;;
        b) execute_b_options;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all a options
execute_a_options() {
    disable_repo
    add_repo
    update_upgrade
    install_packages
    remove_subscription_notice
}

# Function to execute all b options
execute_b_options() {
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

