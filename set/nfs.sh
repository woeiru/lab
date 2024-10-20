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
    gen-ipa "$NFS_PACKAGES_ALL"
    gen-sdc "$NFS_SYSD_CHECK"
    gen-ust "$NFS_USERNAME_1" "$NFS_PASSWORD_1"
}

b_xall() {
    nfs-set  "$NFS_HEADER_1" "$NFS_SHARED_FOLDER_1" "$NFS_OPTIONS_1"
}

setup_main "$@"
