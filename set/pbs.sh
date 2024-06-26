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
    echo "a............................."
    echo "a1. Setup GPG Key"
    echo "a2. Add repository"
    echo "a3. Update and upgrade packages"
    echo "a4. Install packages"
    echo "b............................."
    echo "b1. Restore Datatstore"
}

# execute based on user choice
setup_execute_choice() {
    case "$1" in
	a1) pbs-sgp;;
        a2) pbs-adr;;
        a3) pbs-puu;;
        a4) all-ipa;;
        b1) add_datastore;;
        a) execute_a_options;;
        b) execute_b_options;;
        *) echo "Invalid choice";;
    esac
}

# execute all a options
execute_a_options() {
	pbs-sgp
    	pbs-adr
    	pbs-puu
    	all-ipa "$PMAN" "$PAK1" "$PAK2"
    	pve-rsn
}

# execute all b options
execute_b_options() {
	add_datastore "$DATASTORE_CONFIG" "$DATASTORE_NAME" "$DATASTORE_PATH"
}

# Call the setup_main function with command-line arguments
setup_main "$@"
