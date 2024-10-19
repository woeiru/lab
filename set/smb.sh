#!/bin/bash

# Sourcing
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"
source "$DIR_SH/.up"
setup_source "$DIR_SH" "$FILE_SH" "$BASE_SH"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"

a_xall() {
    	gen-ipa "$PACKAGES_ALL"
	gen-sdc "$SYSD_CHECK"
    	gen-ust "$USERNAME1" "$PASSWORD1"
}

b_xall() {
    	smb-set  "$SMB_HEADER_1" "$SMB_SHARED_FOLDER_1" "$SMB_USERNAME_1" "$SMB_PASSWORD_1" "$SMB_WRITABLE_YESNO_1" "$SMB_GUESTOK_YESNO_1" "$SMB_BROWSABLE_YESNO_1" "$SMB_CREATE_MASK_1" "$SMB_DIR_MASK_1" "$SMB_FORCE_USER_1" "$SMB_FORCE_GROUP_1"
    	smb-set  "$SMB_HEADER_2" "$SMB_SHARED_FOLDER_2" "$SMB_USERNAME_2" "$SMB_PASSWORD_2" "$SMB_WRITABLE_YESNO_2" "$SMB_GUESTOK_YESNO_2" "$SMB_BROWSABLE_YESNO_2" "$SMB_CREATE_MASK_2" "$SMB_DIR_MASK_2" "$SMB_FORCE_USER_2" "$SMB_FORCE_GROUP_2"
}

setup_main "$@"
