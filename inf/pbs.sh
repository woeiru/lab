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

# Downloads and verifies Proxmox Backup Server GPG key, adds repository, and installs PBS packages
a_xall() {
	pbs-dav
    	pbs-adr
    	gen-ipa "$PBS_PACKAGES_ALL"
}

# Configures PBS datastore with specified name and path for backup storage
b_xall() {
	pbs-rda "$PBS_DATASTORE_CONFIG" "$PBS_DATASTORE_NAME" "$PBS_DATASTORE_PATH"
}

# Handle script execution
if [ $# -eq 0 ]; then
    print_usage
    clean_exit 0       # Exit cleanly with status 0
else
    setup_main "$@"
    clean_exit $?
fi
