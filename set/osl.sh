#!/bin/bash

# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# Function to display status notification
notify_status() {
    local function_name="$1"
    local status="$2"

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

prompt_for_input() {
    local var_name=$1
    local prompt_message=$2
    local current_value=$3

    read -p "$prompt_message [$current_value]: " input
    if [ -n "$input" ]; then
        eval "$var_name=\"$input\""
    else
        eval "$var_name=\"$current_value\""
    fi
}

check_and_append() {
    local file="$1"
    local line="$2"

    # Check if the line is already present in the file
    if ! grep -Fxq "$line" "$file"; then
        # If not, append the line to the file
        echo "$line" >> "$file"
        echo "Line appended to $file"
    else
        echo "Line already present in $file"
    fi
}

install_pakages () {
    local function_name="${FUNCNAME[0]}"
    local pman="$1"
    local pak1="$2"
    local pak2="$3"
   
    "$pman" update
    "$pman" upgrade -y
    "$pman" install -y "$pak1" "$pak2"

    # Check if installation was successful
    if [ $? -eq 0 ]; then
	    notify_status "$function_name" "executed ( $1 $2 $3 )"
    else
        notify_status "$function_name" "Failed to install  ( $1 $2 $3 )"
        return 1
    fi
}

 setup_firewalld() {
    local function_name="${FUNCNAME[0]}" 
    local fwd_as_1="$1"

    firewall-cmd --state
    firewall-cmd --add-service="$fwd_as_1" --permanent
    firewall-cmd --reload

    notify_status "$function_name" "executed"
}

# Main function to execute based on command-line arguments or display main menu
main() {
    if [ "$#" -eq 0 ]; then
        display_menu
        read_user_choice
    else
        execute_arguments "$@"
    fi
}

# Function to display main menu
display_menu() {
    echo "Choose an option:"
    echo "a.......................( include config )"
    echo "a1 install pakages"
    echo "a2 setup firewall"
}

# Function to read user choice
read_user_choice() {
    read -p "Enter your choice: " choice
    execute_choice "$choice"
}

# Function to execute based on user choice
execute_choice() {
    case "$1" in
        a) 	a_xall;;
	a1) 	install_pakages;;
	a2) 	firewall_setup;;
        b) 	b_xall;;
        *) echo "Invalid choice";;
    esac
}

# Function to execute all

a_xall() {
    	install_pakages "$PMAN" "$PAK1" "$PAK2" 
	firwall_setup "$FWD_AS_1"
}

# Function to execute based on command-line arguments
execute_arguments() {
    for arg in "$@"; do
        execute_choice "$arg"
    done
}

# Call the main function with command-line arguments
main "$@"

