#!/bin/bash

# Sourcing
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE="$(basename "${BASH_SOURCE[0]}")"
echo "Debug: DIR = $DIR"
echo "Debug: FILE = $FILE"
source "$DIR/.up"
setup_source "$DIR" "$FILE"

# Call menu structure
setup_main "$DIR" "$FILE"

# Execute based on user choice
setup_execute_choice() {
    case "$1" in
        a)   a_xall;;
        b)   b_xall;;
        *) echo "Invalid choice";;
    esac
}

declare -A MENU_OPTIONS
MENU_OPTIONS[a]="a_xall"
MENU_OPTIONS[b]="b_xall"

# Execute whole section
a_xall() {
    all_ipa "$PMAN" "$PAK1" "$PAK2"
    all_sdc "$SYSD_CHECK"
    all_ust "$USERNAME1" "$PASSWORD1"
}

b_xall() {
    nfs_setup  "$NFS_HEADER_1" "$SHARED_FOLDER_1" "$NFS_OPTIONS_1"
    nfs_setup  "$NFS_HEADER_2" "$SHARED_FOLDER_2" "$NFS_OPTIONS_2"
}

