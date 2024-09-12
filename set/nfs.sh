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
    all-ipa "$PACKAGES_ALL"
    all-sdc "$SYSD_CHECK_NFS"
    all-ust "$USERNAME1_NFS" "$PASSWORD1_NFS"
}

b_xall() {
    nfs-set  "$HEADER_1_NFS" "$SHARED_FOLDER_1_NFS" "$OPTIONS_1_NFS"
}

setup_main "$@"
