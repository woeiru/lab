#!/bin/bash

# Sourcing
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"
echo "Variable ( *.sh ) DIR_SH = $DIR_SH"
echo "Variable ( *.sh ) FILE_SH = $FILE_SH"
echo "Variable ( *.sh ) BASE_SH = $BASE_SH"
source "$DIR_SH/.up"
setup_source "$DIR_SH" "$FILE_SH" "$BASE_SH"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"

a_xall() {
    	all-ipa "$PMAN" "$PAK1" "$PAK2"
	all-sdc "$SYSD_CHECK"
    	all-ust "$USERNAME1" "$PASSWORD1"
}

b_xall() {
    	shr-smb  "$SMB_HEADER_1" "$SHARED_FOLDER_1" "$USERNAME_1" "$SMB_PASSWORD_1" "$WRITABLE_YESNO_1" "$GUESTOK_YESNO_1" "$BROWSABLE_YESNO_1" "$CREATE_MASK_1" "$DIR_MASK_1" "$FORCE_USER_1" "$FORCE_GROUP_1"
    	shr-smb  "$SMB_HEADER_2" "$SHARED_FOLDER_2" "$USERNAME_2" "$SMB_PASSWORD_2" "$WRITABLE_YESNO_2" "$GUESTOK_YESNO_2" "$BROWSABLE_YESNO_2" "$CREATE_MASK_2" "$DIR_MASK_2" "$FORCE_USER_2" "$FORCE_GROUP_2"
}

setup_main "$@"
