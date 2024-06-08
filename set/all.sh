#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# Function to display main menu
display_menu() {
    echo "Choose an option:"
    echo "a.......................( include config )"
    echo "dot1. source dotfiles"
    echo "ins1. install pakages"
    echo "git1. setup git"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
        a) 	a_xall;;
	a1) 	check_and_append;;
	a2) 	install_pakages;;
	t1) 	setup_sysstat;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute whole section
a_xall() {
	check_and_append "$DOT_FILE1" "$DOT_SOURCE1"
    	git_setup "$GIT_USERNAME" "$GIT_USERMAIL"
    	install_packages "$PMAN" "$PAK1" "$PAK2" 
	exec bash
}

# Call the main function with command-line arguments
main "$@"
