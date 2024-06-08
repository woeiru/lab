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

# Function to disable repository by commenting out lines starting with "deb" in specified files

setup_gpg() {
    # Download the GPG key
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

    # Verify SHA512 checksum
    sha512_expected="7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87"
    sha512_actual=$(sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | awk '{print $1}')

    if [ "$sha512_actual" == "$sha512_expected" ]; then
        echo "SHA512 checksum verified successfully."
    else
        echo "SHA512 checksum verification failed."
    fi

    # Verify MD5 checksum
    md5_expected="41558dc019ef90bd0f6067644a51cf5b"
    md5_actual=$(md5sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | awk '{print $1}')

    if [ "$md5_actual" == "$md5_expected" ]; then
        echo "MD5 checksum verified successfully."
    else
        echo "MD5 checksum verification failed."
    fi
}

# Function to add a line to sources.list if it doesn't already exist
add_repo() {
    local function_name="${FUNCNAME[0]}"
    line_to_add="deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription"
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
install_packages () {
    local function_name="${FUNCNAME[0]}"
    local pman="$1"
    local pak1="$2"
    local pak2="$3"
   
    "$pman" update
    "$pman" upgrade -y
    "$pman" install -y "$pak1" "$pak2"

    # Check if installation was successful
    if [ $? -eq 0 ]; then
	    notify_status "$function_name" "executed ( $1 $2 $3 )"
    else
        notify_status "$function_name" "Failed to install  ( $1 $2 $3 )"
        return 1
    fi
}

# Function to remove subscription notice
remove_subscription_notice() {
echo "placeholder"
#    local function_name="${FUNCNAME[0]}"
#    # Prompt user whether to restart the service
#    read -p "Do you want to restart the pveproxy.service now? (y/n): " choice
#    case "$choice" in
#        y|Y ) systemctl restart pveproxy.service && notify_status "$function_name" "Service restarted successfully.";;
#        n|N ) notify_status "$function_name" "Service not restarted.";;
#        * ) notify_status "$function_name" "Invalid choice. Service not restarted.";;
#    esac
}

# Function to restore datastore
add_datastore () {
	local datastore_config="$1"
	local datastore_name="$2"
	local datastore_path="$3"

 # Define the file path to the configuration file
    local file="/etc/proxmox-backup/datastore.cfg"
    # Define the combined lines to be checked within the file
    local combined_lines="datastore: $datstore_name\n\tpath $datastore_path"

    # Check if the file exists
    if [[ -f "$file" ]]; then
        echo "$file exists."

        # Check if the combined lines are present in the file in sequence
        if grep -Pzo "(?s)$combined_lines" "$file"; then
            echo "The lines are present in sequence in $file."
        else
            echo "The lines are not present in sequence in $file. Adding the lines."
            # Append the combined lines to the file
            echo -e "$combined_lines" >> "$file"
            echo "Lines added to $file."
        fi
    else
        echo "$file does not exist. Creating the file and adding the lines."
        # Create the file and add the combined lines
        echo -e "$combined_lines" > "$file"
        echo "File created and lines added."
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
    echo "a............................."
    echo "a1. Setup GPG Key"
    echo "a2. Add repository"
    echo "a3. Update and upgrade packages"
    echo "a4. Install packages"
    echo "b............................."
    echo "b1. Restore Datatstore"
}

# Function to read user choice
read_user_choice() {
    read -p "Enter your choice: " choice
    execute_choice "$choice"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
	a1) setup_gpg;;
        a2) add_repo;;
        a3) update_upgrade;;
        a4) install_packages;;
        b1) add_datastore;;
        a) execute_a_options;;
        b) execute_b_options;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all a options
execute_a_options() {
	setup_gpg
    	add_repo
    	update_upgrade
    	install_packages
    	remove_subscription_notice
}

# Function to execute all b options
execute_b_options() {
	add_datastore "$DATASTORE_CONFIG" "$DATASTORE_NAME" "$DATASTORE_PATH"
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

