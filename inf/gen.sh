#!/bin/bash

# Define script location
DIR_SH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_SH="$(basename "${BASH_SOURCE[0]}")"
BASE_SH="${FILE_SH%.*}"

# Source .up which provides logging and other core functionality
source "$DIR_SH/.up"

setup_source "$DIR_SH" "$FILE_SH" "$BASE_SH"

# Declare MENU_OPTIONS
declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"
MENU_OPTIONS[x]="x_xall"

# Installs common system packages and configures global Git user credentials
a_xall() {
    gen-ipa "$PACKAGES_ALL"
    gen-gst "$GIT_USERNAME" "$GIT_USERMAIL"
}

# Uploads private SSH key from USB device to system for secure authentication
b_xall() {
    gen-suk \
        "$DEVICE_PATH" \
        "$MOUNT_POINT" \
        "$SUBFOLDER_PATH" \
        "$UPLOAD_PATH" \
        "$PRIVATE_KEY"
}

# Handle script execution
if [ $# -eq 0 ]; then
    print_usage
    clean_exit 0       # Exit cleanly with status 0
else
    setup_main "$@"
    clean_exit $?
fi
