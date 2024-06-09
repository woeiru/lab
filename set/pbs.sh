#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# Function to display all-main menu
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
    	pve-rsn
}

# Function to execute all b options
execute_b_options() {
	add_datastore "$DATASTORE_CONFIG" "$DATASTORE_NAME" "$DATASTORE_PATH"
}

# Call the all-main function with command-line arguments
all-main "$@"
