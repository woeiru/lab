#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Source config.sh using the absolute path
source "$DIR/../var/pmox.conf"

#list all Functions in a given File
o() {
    local file_name="${1:-${BASH_SOURCE[0]}}"
    printf "%-20s | %-10s | %-10s | %-20s\n" "Function Name" "Size" "Header" "Comment"
    printf "%-20s | %-10s | %-10s | %-20s\n" "--------------------" "----------" "----------" "-------"

    # Initialize variables
    local last_comment_line=0
    local line_number=0
    declare -a comments=()

    # Read all comments into an array
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            comments[$line_number]="$line"
        fi
    done < "$file_name"

    # Loop through all lines in the file again
    line_number=0
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_-]*\(\) ]]; then
            # Extract function name
            func_name=$(echo "$line" | awk '{print $1}')
            # Calculate function size
            func_start_line=$line_number
            func_size=0
            while IFS= read -r func_line; do
                ((func_size++))
                if [[ $func_line == *} ]]; then
                    break
                fi
            done < <(tail -n +$func_start_line "$file_name")
            # Print function name, function size, comment line number, and comment
            printf "%-20s | %-10s | %-10s | %s\n" "$func_name" "$func_size" "${last_comment_line:-N/A}" "${comments[$last_comment_line]:-N/A}"
        elif [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            last_comment_line=$line_number
        fi
    done < "$file_name"
}

# transforming a folder to a subvolume
o-trans() {
    if [ $# -ne 3 ]; then
        echo "Usage: o-trans <folder_name> <user_name> <C>"
        return 1
    fi

    local folder_name="$1"
    local user_name="$2"
    local attr_cow="$3"
    local old_swap="${folder_name}-old"

    # Move current folder to .folder_name-old
    cmd1="mv $folder_name $old_swap"
    read -p "$cmd1"
    eval "$cmd1"

    # Create new subvolume
    cmd2="sudo btrfs subvolume create $folder_name"
    read -p "$cmd2"
    eval "$cmd2"

    # Change ownership to specified user
    cmd3="sudo chown $user_name: $folder_name"
    read -p "$cmd3"
    eval "$cmd3"

    # Disable copy-on-write on new target
    if [ "$attr_cow" = "C" ]; then  # corrected the condition
        cmd4="sudo chattr +C $folder_name"  # added 'sudo' for privilege elevation
        read -p "$cmd4"
        eval "$cmd4"
    else
        echo "COW Stays Enabled"
    fi

    # Move contents from old folder to new one
    cmd5="mv $old_swap/* $folder_name"
    read -p "$cmd5"
    eval "$cmd5"

    # Remove old folder
    cmd6="rm -r $old_swap"
    read -p "$cmd6"
    eval "$cmd6"
}

