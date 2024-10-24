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

# Installs NFS server packages, enables the NFS service, and creates a user account for NFS management
a_xall() {
    gen-ipa "$NFS_PACKAGES_ALL"
    gen-sdc "$NFS_SYSD_CHECK"
    gen-ust "$NFS_USERNAME_1" "$NFS_PASSWORD_1"
}

# Configures NFS exports by setting up a shared folder with specified access permissions
b_xall() {
    nfs-set  "$NFS_HEADER_1" "$NFS_SHARED_FOLDER_1" "$NFS_OPTIONS_1"
}

# Handle script execution
if [ $# -eq 0 ]; then
    print_usage
    clean_exit 0       # Exit cleanly with status 0
else
    setup_main "$@"
    clean_exit $?
fi
