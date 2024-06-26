#!/bin/bash

# sourcing
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
file=$(basename "${BASH_SOURCE[0]}")
source "$dir/.up"
setup_source "$dir" "$file"

# call menu structure
setup_main "$@"

# display setup_main menu
setup_display_menu() {
    echo "Choose an option:"
    echo "a......................( include config )"
    echo "a1. install packages"
    echo "a2. setup user"
    echo "a3. setup nfs firewalld"
    echo "b......................( include config )"
    echo "b1. setup nfs"
    echo ""
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
        a)   a_xall;;
        a1)  install_packages;;
        a2)  all-ust;;
        a3)  setup_firewalld;;
        b)   b_xall;;
        b1)  nfs-setup;;
        *) echo "Invalid choice";;
    esac
}

# execute whole section
a_xall() {
    all-ipa "$PMAN" "$PAK1" "$PAK2"
    all-sdc "$SYSD_CHECK"
    all-ust "$USERNAME1" "$PASSWORD1"
}

b_xall() {
    nfs-setup  "$NFS_HEADER_1" "$SHARED_FOLDER_1" "$NFS_OPTIONS_1"
    nfs-setup  "$NFS_HEADER_2" "$SHARED_FOLDER_2" "$NFS_OPTIONS_2"
}
