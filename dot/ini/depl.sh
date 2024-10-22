#!/bin/bash

# depl.sh

# Set strict mode
set -eo pipefail

# Global variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LAB_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
TARGET_HOME=""
CONFIG_FILE=""
DEPLOY_LOG_FILE="/tmp/deployment_$(date +%Y%m%d_%H%M%S).log"
INTERACTIVE=false
TARGET_USER=""
DEPLOY_DEBUG=${DEPLOY_DEBUG:-false}
FUNCTION_FILE="flow.sh"
INJECT_FILE="inject"
BASE_INDENT="          "  # Added for consistent indentation

# Printf wrapper function for consistent formatting
print_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y%m%d%H%M%S')
    local color_code=""

    # Only print DEBUG messages if DEPLOY_DEBUG is true
    if [[ "$level" == "DEBUG" && "$DEPLOY_DEBUG" != true ]]; then
        return
    fi

    case "$level" in
        "ERROR")
            color_code="\033[0;31m"  # Red
            ;;
        "DEBUG")
            color_code="\033[0;33m"  # Yellow
            ;;
        "INFO")
            color_code="\033[0;32m"  # Green
            ;;
        *)
            color_code="\033[0m"  # Default
            ;;
    esac

    printf "%s[$timestamp][$level]%s %s\n" "$color_code" "\033[0m" "$message" | tee -a "$DEPLOY_LOG_FILE"
}

# Function to print box-style messages
print_box() {
    local message="$1"
    printf "\n"
    printf "%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n" "$BASE_INDENT"
    printf "%s┃ %-75s ┃\n" "$BASE_INDENT" "$message"
    printf "%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n" "$BASE_INDENT"
}

# Function to print section headers
print_section() {
    local message="$1"
    printf "\n"
    printf "%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n" "$BASE_INDENT"
    printf "%s┃ %-75s ┃\n" "$BASE_INDENT" "$message"
    printf "%s┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\n" "$BASE_INDENT"
}

# Function to print normal box line
print_boxline() {
    local message="$1"
    printf "%s┃ %-75s ┃\n" "$BASE_INDENT" "$message"
}

# Function to print box footer
print_boxfooter() {
    printf "%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n" "$BASE_INDENT"
}

# Function to display usage information
usage() {
    print_box "Usage: $0 [OPTIONS]"
    print_boxline "Options:"
    print_boxline "  -u, --user USER    Specify target user (default: current user)"
    print_boxline "  -c, --config FILE  Specify config file location"
    print_boxline "  -i, --interactive  Run in interactive mode"
    print_boxline "  -h, --help         Display this help message"
    print_boxfooter
}

# Function to display current settings
display_settings() {
    print_section "Current Settings"
    print_boxline "User: ${TARGET_USER:-Current user ($(whoami))}"
    print_boxline "Config file: ${CONFIG_FILE:-Default}"
    print_boxfooter
}

# Source the function file containing numbered functions
source "$SCRIPT_DIR/$FUNCTION_FILE"

# Function to display usage information
usage() {
    print_box "Usage: $0 [OPTIONS]"
    printf "┃ Options:\n"
    printf "┃   -u, --user USER    Specify target user (default: current user)\n"
    printf "┃   -c, --config FILE  Specify config file location\n"
    printf "┃   -i, --interactive  Run in interactive mode\n"
    printf "┃   -h, --help         Display this help message\n"
    printf "┗━%s━┛\n" "$(printf '%*s' 71 | tr ' ' '━')"
}

# Function to set default values
set_default_values() {
    TARGET_USER=$(whoami)
    if [[ "$TARGET_USER" = "root" ]]; then
        TARGET_HOME=$(eval echo ~root)
    else
        TARGET_HOME=$(eval echo ~$TARGET_USER)
    fi

    if [[ -f "$TARGET_HOME/.zshrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.bashrc"
    else
        CONFIG_FILE="$TARGET_HOME/.bashrc"  # Default to .bashrc if neither exists
    fi
}

# Function to parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--user)
                TARGET_USER="$2"
                print_message "INFO" "User argument provided: $TARGET_USER"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                print_message "INFO" "Config file argument provided: $CONFIG_FILE"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE=true
                print_message "INFO" "Interactive mode enabled"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                DEPLOY_DEBUG=true
                print_message "INFO" "Verbose mode enabled"
                shift
                ;;
            *)
                print_message "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Function to handle cleanup on exit
cleanup() {
    print_message "DEBUG" "Cleaning up..."

    # Remove temporary files
    local temp_files=($(find /tmp -name "temp_*" -user "$(whoami)" -mmin -5))
    if [[ ${#temp_files[@]} -gt 0 ]]; then
        for temp_file in "${temp_files[@]}"; do
            rm -f "$temp_file"
            print_message "DEBUG" "Removed temporary file: $temp_file"
        done
    else
        print_message "DEBUG" "No temporary files found"
    fi

    # Restore original config file if deployment failed
    local latest_backup=$(find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" | sort -r | head -n 1)
    if [[ $? -ne 0 && -n "$latest_backup" ]]; then
        mv "$latest_backup" "$CONFIG_FILE"
        print_message "DEBUG" "Restored original config file due to deployment failure"
    else
        print_message "DEBUG" "No need to restore config file"
    fi

    # Remove old backup files (keeping only the 2 most recent)
    find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" |
    sort -r |
    tail -n +3 |
    xargs -r rm
    print_message "DEBUG" "Removed old backup files, keeping the 2 most recent"

    # Reset any environment variables set during the script
    unset SCRIPT_DIR LAB_DIR TARGET_HOME CONFIG_FILE INTERACTIVE TARGET_USER
    print_message "DEBUG" "Reset environment variables"

    # Close file descriptors
    exec 3>&- 4>&-
    print_message "DEBUG" "Closed file descriptors"

    print_message "DEBUG" "Cleanup completed"
}

# Function to dynamically execute functions
execute_functions() {
    # Create an array of function names, sorted by their comment number
    local functions=($(grep -E '^# [0-9]+\.' "$SCRIPT_DIR/$FUNCTION_FILE" |
                       sed -E 's/^# ([0-9]+)\. .*/\1 /' |
                       paste -d' ' - <(grep -A1 -E '^# [0-9]+\.' "$SCRIPT_DIR/$FUNCTION_FILE" |
                                       grep -E '^[a-z_]+[a-z0-9_-]*\(\)' |
                                       sed 's/().*//') |
                       sort -n |
                       cut -d' ' -f2-))

    # Check if the functions array is empty
    if [ ${#functions[@]} -eq 0 ]; then
        print_message "ERROR" "No functions found to execute."
        return 1
    fi

    # Loop through the functions array and execute each function
    for func in "${functions[@]}"; do
        local number=$(grep -B1 "^$func()" "$SCRIPT_DIR/$FUNCTION_FILE" | grep -E '^# [0-9]+\.' | sed -E 's/^# ([0-9]+)\..*/\1/')
        local comment=$(grep -B1 "^$func()" "$SCRIPT_DIR/$FUNCTION_FILE" | grep -E '^# [0-9]+\.' | sed -E 's/^# [0-9]+\. //')
        print_section "Step $number: $comment"
        print_message "DEBUG" "Executing: $func"
        if declare -f "$func" > /dev/null; then
            if ! $func; then
                print_message "ERROR" "Failed to execute $func."
                return 1
            fi
        else
            print_message "ERROR" "Function $func not found."
            return 1
        fi
    done

    return 0
}

# Interactive mode function
run_interactive_mode() {
    print_box "Interactive Mode"
    print_section "Current settings:"
    printf "┃   User: ${TARGET_USER:-Current user ($(whoami))}\n"
    printf "┃   Config file: ${CONFIG_FILE:-Default}\n"
    printf "┗━%s━┛\n" "$(printf '%*s' 71 | tr ' ' '━')"

    read -p "Enter the target user (leave blank for current user: $(whoami)): " user_input
    if [[ -n "$user_input" ]]; then
        TARGET_USER="$user_input"
        print_message "INFO" "User set interactively to: $TARGET_USER"
    else
        print_message "INFO" "Using current user: $(whoami)"
    fi

    read -p "Enter the config file location (leave blank for default): " config_input
    if [[ -n "$config_input" ]]; then
        CONFIG_FILE="$config_input"
        print_message "INFO" "Config file set interactively to: $CONFIG_FILE"
    else
        print_message "INFO" "Using default config file location"
    fi
}

# Main execution function
main() {
    print_box "Starting deployment script with PID: $$"

    if [[ $# -eq 0 ]]; then
        set_default_values
    else
        parse_arguments "$@"
    fi

    if [[ -z "$TARGET_USER" || -z "$CONFIG_FILE" ]]; then
        set_default_values
    fi

    if [[ "$INTERACTIVE" = true ]]; then
        print_box "Entering interactive mode"
        run_interactive_mode
    fi

    display_settings

    # Display operations with numbering
    print_section "The following operations will be performed:"
    grep -E '^# [0-9]+\.' "$SCRIPT_DIR/$FUNCTION_FILE" |
    sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/' |
    while read -r line; do
        print_boxline "$line"
    done
    print_boxfooter

    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) ;;
        * ) print_message "INFO" "Operation cancelled by user."; exit 0;;
    esac

    if ! execute_functions; then
        print_box "ERROR: Deployment failed."
        exit 1
    fi

    print_box "Deployment completed successfully."
    print_message "INFO" "Changes have been applied. The shell will now restart to apply the changes."
    if [[ "$DEPLOY_DEBUG" = true ]]; then
        print_message "DEBUG" "Testing cleanup function"
        cleanup
    fi
    print_message "INFO" "Press any key to restart the shell..."
    read -n 1 -s
    print_message "INFO" "About to exec new shell..."
    exec "$SHELL"
}

# Set up traps and run main function as before
trap 'debug_trap EXIT' EXIT
trap 'debug_trap SIGINT' SIGINT
trap 'debug_trap SIGTERM' SIGTERM

main "$@"

print_section "Script completed. Exiting..."
print_boxfooter
