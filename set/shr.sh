#!/bin/bash

# Hardcoded values for LIB_DIR, VAR_DIR, and ALL_BASE
LIB_DIR="../lib"
VAR_DIR="../var"
ALL_BASE="all"

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "${BASH_SOURCE[0]}")
BASE="${FILE%.*}"

# Function to source files
source_file() {
  local file_path="$1"
  if [ -f "$file_path" ]; then
    source "$file_path"
  else
    echo "Error: $file_path not found."
  fi
}

# Array of files to source
files_to_source=(
  "$DIR/$LIB_DIR/${ALL_BASE}.bash"
  "$DIR/$VAR_DIR/${ALL_BASE}.conf"
  "$DIR/$LIB_DIR/${BASE}.bash"
  "$DIR/$VAR_DIR/${BASE}.conf"
)

# Loop through and source files
for file in "${files_to_source[@]}"; do
  source_file "$file"
done

# main setup function
setup_main() {
    if [ "$#" -eq 0 ]; then
        setup_display_menu
        setup_read_choice
    else
        setup_execute_arguments "$@"
    fi
}

# main read choice
setup_read_choice() {
    read -p "Enter your choice: " choice
    setup_execute_choice "$choice"
}

# main execute choice
setup_execute_arguments() {
    for arg in "$@"; do
        setup_execute_choice "$arg"
    done
}

# display setup_main menu
setup_display_menu() {
    echo "Choose an option:"
    echo "a......................( include config )"
    echo "a1. install pakages"
    echo "a2. setup user"
    echo "a3. setup smb firewalld"
    echo "b......................( include config )"
    echo "b1. setup smb"
    echo ""
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
        a) 	a_xall;;
        a1) 	install_pakages;;
        a2) 	all-ust;;
        b) 	b_xall;;
        b1) 	shr-smb;;
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
    	shr-smb  "$SMB_HEADER_1" "$SHARED_FOLDER_1" "$USERNAME_1" "$SMB_PASSWORD_1" "$WRITABLE_YESNO_1" "$GUESTOK_YESNO_1" "$BROWSABLE_YESNO_1" "$CREATE_MASK_1" "$DIR_MASK_1" "$FORCE_USER_1" "$FORCE_GROUP_1"
    	shr-smb  "$SMB_HEADER_2" "$SHARED_FOLDER_2" "$USERNAME_2" "$SMB_PASSWORD_2" "$WRITABLE_YESNO_2" "$GUESTOK_YESNO_2" "$BROWSABLE_YESNO_2" "$CREATE_MASK_2" "$DIR_MASK_2" "$FORCE_USER_2" "$FORCE_GROUP_2"
}

# execute based on command-line arguments
setup_execute_arguments() {
    for arg in "$@"; do
        setup_execute_choice "$arg"
    done
}

# Call the setup_main function with command-line arguments
setup_main "$@"
