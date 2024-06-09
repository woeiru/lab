#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source lib and var
source "$DIR/../lib/all.bash"
source "$DIR/../var/all.conf"
source "$DIR/../lib/${BASE}.bash"
source "$DIR/../var/${BASE}.conf"

# main setup function
setup_main() {
    if [ "$#" -eq 0 ]; then
        setup_display_menu
        setup_read_choice
    else
        setup_execute_arguments "$@"
    fi
}

# main read choice
setup_read_choice() {
    read -p "Enter your choice: " choice
    setup_execute_choice "$choice"
}

# main execute choice
setup_execute_arguments() {
    for arg in "$@"; do
        setup_execute_choice "$arg"
    done
}

# display setup_main menu
setup_display_menu() {
    echo "Choose an option:"
    echo "a............................."
    echo "a1. Setup GPG Key"
    echo "a2. Add repository"
    echo "a3. Update and upgrade packages"
    echo "a4. Install packages"
    echo "b............................."
    echo "b1. Restore Datatstore"
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
	a1) pbs-sgp;;
        a2) pbs-adr;;
        a3) pbs-uup;;
        a4) all-ipa;;
        b1) add_datastore;;
        a) execute_a_options;;
        b) execute_b_options;;
        *) echo "Invalid choice";;
    esac
}

# execute all a options
execute_a_options() {
	pbs-sgp
    	pbs-adr
    	pbs-uup
    	all-ipa
    	pve-rsn
}

# execute all b options
execute_b_options() {
	add_datastore "$DATASTORE_CONFIG" "$DATASTORE_NAME" "$DATASTORE_PATH"
}

# Call the setup_main function with command-line arguments
setup_main "$@"
