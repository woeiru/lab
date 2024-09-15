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

# Function to escape special characters for sed
escape_for_sed() {
    echo "$1" | sed -e 's/[]\/$*.^[]/\\&/g'
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    log_message "Error: jq is not installed. Please install jq to process JSON files."
    exit 1
fi

# Read the JSON file and perform replacements
jq -c '.replacements[]' "$json_file" | while read -r replacement; do
    item_name=$(echo "$replacement" | jq -r '.item')
    old_text=$(echo "$replacement" | jq -r '.old')
    new_text=$(echo "$replacement" | jq -r '.new')

    # Escape special characters for sed
    old_text_escaped=$(escape_for_sed "$old_text")
    new_text_escaped=$(escape_for_sed "$new_text")

    # Perform the replacement
    sed -i "s/${old_text_escaped}/${new_text_escaped}/g" "$target_file"

    log_message "Item: $item_name"
    log_message "Old: $old_text"
    log_message "New: $new_text"
    log_message "---"
done

log_message "Replacement process completed."

echo "Replacement process completed. Check $log_file for details."
