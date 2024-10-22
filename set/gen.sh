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

a_xall() {
    gen-ipa "$PACKAGES_ALL"
    gen-gst "$GIT_USERNAME" "$GIT_USERMAIL"
}

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
    setup_main
    clean_exit $?  # Handle the return value from setup_main
else
    setup_main "$@"
    clean_exit $?  # Handle the return value from setup_main
fi
