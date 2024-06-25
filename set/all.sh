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
    echo "a.......................( include config )"
    echo "a1. source dotfiles"
    echo "a2. setup git"
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
        a) 	a_xall;;
	a1) 	all-cap;;
	a2) 	all-sst;;
        *) echo "Invalid choice";;
    esac
}

# execute whole section
a_xall() {
	all-cap "$DOT_FILE1" "$DOT_SOURCE1"
    	all-gst "$GIT_USERNAME" "$GIT_USERMAIL"
	exec bash
}

# Call the setup_main function with command-line arguments
setup_main "$@"
