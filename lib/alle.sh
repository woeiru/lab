#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Source config.sh using the absolute path
source "$DIR/../var/alle.conf"

# list all Functions in a given File
a() {
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


# count files in parent folder
a-count() {
    if [ $# -ne 2 ]; then
        echo "Usage: a-count <path> <1|2|3>"
        return 1
    fi

    local path="$1"
    local folder_type="$2"
    
    # Function to count files in a directory
    count_files() {
        local dir="$1"
        find "$dir" -type f | wc -l
    }
    
    # Function to print directory information
    print_directory_info() {
        local dir="$1"
        local file_count=$(count_files "$dir")
        printf "%-20s %5s\n" "$dir" "$file_count"
    }
    
    # Main function logic
    case "$folder_type" in
        1)
            find "$path" -mindepth 1 -maxdepth 1 -type d -name '[^.]*' | while read -r dir; do
                print_directory_info "$dir"
            done
            ;;
        2)
            find "$path" -mindepth 1 -maxdepth 1 -type d -name '.*' | while read -r dir; do
                print_directory_info "$dir"
            done
            ;;
        3)
            find "$path" -mindepth 1 -maxdepth 1 -type d \( -name '[^.]*' -o -name '.*' \) | while read -r dir; do
                print_directory_info "$dir"
            done
            ;;
        *)
            echo "Invalid folder type. Please provide either 1, 2, or 3."
            ;;
    esac | sort
}

# selects a file in current folder and saves it as var 'sel'
a-select() {
    files=($(ls))
    echo "Select a file by entering its index:"
    for i in "${!files[@]}"; do
        echo "$i: ${files[$i]}"
    done
    read -p "Enter the index of the file you want: " index
    sel="${files[$index]}"
    echo "$selected_file"
}


# optimal Git
go() {
    # Navigate to the git folder
    cd "$DIR/.." || return

    # Define commit message
    local commit_message="$commit_message"

    # Display the current status of the repository
    git status

    # Check if the branch is ahead of the remote
    git status | grep "Your branch is ahead" > /dev/null
    if [ $? -eq 0 ]; then
        # If there are staged changes ahead of the master branch, push them
        git add . && git commit -m "$commit_message" && git push origin master || return
    else
        # Check if there are changes not staged for commit
        git status | grep "Changes not staged for commit" > /dev/null
        if [ $? -eq 0 ]; then
            # If there are unstaged changes, stage them, commit, and push
            echo "Changes not staged for commit. Staging changes..."
            git add . && git commit -m "$commit_message" && git push origin master || return
        else
            # If there are no staged changes and no unstaged changes, pull changes from remote
            git pull || return
        fi
    fi

    # Return to the previous directory
    cd - || return
}

# modular Git
gm() {
    if [ $# -eq 0 ]; then
        git status
    elif [ $# -eq 1 ]; then
        local commit_message="$commit_message"  # Use default commit message if not provided
        git status && git add "$1" && git commit -m "$commit_message"
    elif [ $# -eq 2 ]; then
        local commit_message="$2"  # Use provided commit message
        git status && git add "$1" && git commit -m "$commit_message"
    elif [ $# -eq 3 ]; then
        local commit_message="$2"  # Use provided commit message
        git status && git add "$1" && git commit -m "$commit_message" && git push origin master
    else
        echo "Usage: g [file/folder] [commit message]"
    fi
}

