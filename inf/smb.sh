#!/bin/bash

# Define script location
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"

# Source .up which provides logging and other core functionality
source "$DIR_SH/.up"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"

# Installs Samba packages, enables the SMB service, and creates initial user account for Samba access
a_xall() {
    	gen-ipa "$SMB_PACKAGES_ALL"
	gen-sdc "$SMB_SYSD_CHECK"
	gen-ust "$SMB_USERNAME_0" "$SMB_PASSWORD_0"
}

# Sets up multiple Samba shares with different access permissions for regular and guest users
b_xall() {
    	smb-set  "$SMB_HEADER_1" "$SMB_SHARED_FOLDER_1" "$SMB_USERNAME_1" "$SMB_PASSWORD_1" "$SMB_WRITABLE_YESNO_1" "$SMB_GUESTOK_YESNO_1" "$SMB_BROWSABLE_YESNO_1" "$SMB_CREATE_MASK_1" "$SMB_DIR_MASK_1" "$SMB_FORCE_USER_1" "$SMB_FORCE_GROUP_1"
    	smb-set  "$SMB_HEADER_2" "$SMB_SHARED_FOLDER_2" "$SMB_USERNAME_2" "$SMB_PASSWORD_2" "$SMB_WRITABLE_YESNO_2" "$SMB_GUESTOK_YESNO_2" "$SMB_BROWSABLE_YESNO_2" "$SMB_CREATE_MASK_2" "$SMB_DIR_MASK_2" "$SMB_FORCE_USER_2" "$SMB_FORCE_GROUP_2"
}

# Handle script execution
if [ $# -eq 0 ]; then
    print_usage
    clean_exit 0       # Exit cleanly with status 0
else
    setup_main "$@"
    clean_exit $?
fi
