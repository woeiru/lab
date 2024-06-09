#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source lib and var
source "$DIR/../lib/all.bash"
source "$DIR/../var/all.bash"
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
    echo "a......................( include config )"
    echo "a1. install pakages"
    echo "a2. setup user"
    echo "a3. setup smb firewalld"
    echo "b......................( include config )"
    echo "b1. setup smb"
    echo ""
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
        a) 	a_xall;;
        a1) 	install_pakages;;
        a2) 	all-ust;;
        a3) 	shr-fws;;
        b) 	b_xall;;
        b1) 	shr-smb;;
        *) echo "Invalid choice";;
    esac
}

# execute whole section
a_xall() {
    	all-ipa "$PMAN" "$PAK1" "$PAK2"
	all-sdc "$SYSD_CHECK"
    	all-ust "$USERNAME1" "$PASSWORD1"
    	shr-fws
}

b_xall() {
    	shr-smb  "$SMB_HEADER_1" "$SHARED_FOLDER_1" "$USERNAME_1" "$SMB_PASSWORD_1" "$WRITABLE_YESNO_1" "$GUESTOK_YESNO_1" "$BROWSABLE_YESNO_1" "$CREATE_MASK_1" "$DIR_MASK_1" "$FORCE_USER_1" "$FORCE_GROUP_1"
    	shr-smb  "$SMB_HEADER_2" "$SHARED_FOLDER_2" "$USERNAME_2" "$SMB_PASSWORD_2" "$WRITABLE_YESNO_2" "$GUESTOK_YESNO_2" "$BROWSABLE_YESNO_2" "$CREATE_MASK_2" "$DIR_MASK_2" "$FORCE_USER_2" "$FORCE_GROUP_2"
}

# execute based on command-line arguments
setup_execute_arguments() {
    for arg in "$@"; do
        setup_execute_choice "$arg"
    done
}

# Call the setup_main function with command-line arguments
setup_main "$@"
