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
    echo "a......................( include config )"
    echo "a1. install pakages"
    echo "a2. setup user"
    echo "a3. setup smb firewalld"
    echo "b......................( include config )"
    echo "b1. setup smb"
    echo ""
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
        a) 	a_xall;;
        a1) 	install_pakages;;
        a2) 	user_setup;;
        a3) 	setup_smb_firewalld;;
        b) 	b_xall;;
        b1) 	setup_smb;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute whole section
a_xall() {
    	install_packages "$PMAN" "$PAK1" "$PAK2"
	systemd_check "$SYSD_CHECK"
    	user_setup "$USERNAME1" "$PASSWORD1"
    	setup_smb_firewalld
}

b_xall() {
    	setup_smb  "$SMB_HEADER_1" "$SHARED_FOLDER_1" "$USERNAME_1" "$SMB_PASSWORD_1" "$WRITABLE_YESNO_1" "$GUESTOK_YESNO_1" "$BROWSABLE_YESNO_1" "$CREATE_MASK_1" "$DIR_MASK_1" "$FORCE_USER_1" "$FORCE_GROUP_1"
    	setup_smb  "$SMB_HEADER_2" "$SHARED_FOLDER_2" "$USERNAME_2" "$SMB_PASSWORD_2" "$WRITABLE_YESNO_2" "$GUESTOK_YESNO_2" "$BROWSABLE_YESNO_2" "$CREATE_MASK_2" "$DIR_MASK_2" "$FORCE_USER_2" "$FORCE_GROUP_2"
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"
