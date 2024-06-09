#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
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
    echo "a.......................( include config )"
    echo "a1 install pakages"
    echo "a2 setup firewall"
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
        a) 	a_xall;;
	a1) 	install_pakages;;
	a2) 	firewall_setup;;
        b) 	b_xall;;
        *) echo "Invalid choice";;
    esac
}

# execute whole section
a_xall() {
    	install_pakages "$PMAN" "$PAK1" "$PAK2" 
	firwall_setup "$FWD_AS_1"
}

# Call the setup_main function with command-line arguments
setup_main "$@"

