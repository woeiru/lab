#!/bin/bash

# Check if correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <path_to_target_file> <path_to_json_file>"
    exit 1
fi

# Path to the file to be modified
target_file="$1"
# Path to the JSON file containing replacements
json_file="$2"

# Get the directory of this script
script_dir="$(dirname "$(readlink -f "$0")")"

# Path to the log file
log_file="$script_dir/replacement.log"

# Clear the log file
> "$log_file"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

# Debug function
debug() {
    log_message "DEBUG: $1"
}

# Function to escape special characters for sed
escape_for_sed() {
    echo "$1" | sed -e 's/[]\/$*.^[]/\\&/g'
}

debug "Starting replacement process"
debug "Target file: $target_file"
debug "JSON file: $json_file"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    log_message "Error: jq is not installed. Please install jq to process JSON files."
    exit 1
fi

# Read the JSON file and perform replacements
jq -c '.replacements[]' "$json_file" | while read -r replacement; do
    function_name=$(echo "$replacement" | jq -r '.function')
    old_text=$(echo "$replacement" | jq -r '.old')
    new_text=$(echo "$replacement" | jq -r '.new')

    debug "Processing: $function_name"

    # Escape special characters for sed
    old_text_escaped=$(escape_for_sed "$old_text")
    new_text_escaped=$(escape_for_sed "$new_text")

    # Perform the replacement
    sed -i "/${function_name}/,/^}/ s/${old_text_escaped}/${new_text_escaped}/" "$target_file"

    if [ $? -eq 0 ]; then
        log_message "Replaced in function $function_name:"
        log_message "  Old: $old_text"
        log_message "  New: $new_text"
    else
        log_message "Failed to replace in function $function_name"
    fi

    log_message "---"
done

log_message "Replacement process completed."

echo "Replacement process completed. Check $log_file for details."
