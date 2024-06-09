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
    echo "a.......................( include config )"
    echo "a1. source dotfiles"
    echo "a2. setup git"
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
        a) 	a_xall;;
	a1) 	all-cap;;
	a2) 	all-sst;;
        *) echo "Invalid choice";;
    esac
}

# execute whole section
a_xall() {
	all-cap "$DOT_FILE1" "$DOT_SOURCE1"
    	all-gst "$GIT_USERNAME" "$GIT_USERMAIL"
	exec bash
}

# Call the setup_main function with command-line arguments
setup_main "$@"
