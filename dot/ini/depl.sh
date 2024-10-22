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
TARGET_USER=""
FUNCTION_FILE="flow.sh"
BASE_INDENT="          "  # Added for consistent
INJECT_FILE="inject"

print_message() {
    local message="$1"

    # Print to both console and log file
    printf "%s┃ %-68s \n" "$BASE_INDENT" "$message" | tee -a "$DEPLOY_LOG_FILE"
}


# Function to print box-style messages
print_box() {
    local message="$1"
    printf "\n"
    printf "%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n" "$BASE_INDENT"
    printf "%s┃ %-68s ┃\n" "$BASE_INDENT" "$message"
    printf "%s┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n" "$BASE_INDENT"
}

# Function to print section headers
print_section() {
    local message="$1"
    printf "\n"
    printf "%s┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n" "$BASE_INDENT"
    printf "%s┃ %-68s ┃\n" "$BASE_INDENT" "$message"
    printf "%s┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\n" "$BASE_INDENT"
}

# Function to print normal box line
print_boxline() {
    local message="$1"
    printf "%s┃ %-68s \n" "$BASE_INDENT" "$message"
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
                print_message "User argument provided: $TARGET_USER"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                print_message "Config file argument provided: $CONFIG_FILE"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_message "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Function to dynamically execute functions
execute_functions() {
    local functions=($(grep -E '^# [0-9]+\.' "$SCRIPT_DIR/$FUNCTION_FILE" |
                       sed -E 's/^# ([0-9]+)\. .*/\1 /' |
                       paste -d' ' - <(grep -A1 -E '^# [0-9]+\.' "$SCRIPT_DIR/$FUNCTION_FILE" |
                                       grep -E '^[a-z_]+[a-z0-9_-]*\(\)' |
                                       sed 's/().*//') |
                       sort -n |
                       cut -d' ' -f2-))

    if [ ${#functions[@]} -eq 0 ]; then
        print_message "No functions found to execute."
        return 1
    fi

    for func in "${functions[@]}"; do
        local number=$(grep -B1 "^$func()" "$SCRIPT_DIR/$FUNCTION_FILE" | grep -E '^# [0-9]+\.' | sed -E 's/^# ([0-9]+)\..*/\1/')
        local comment=$func
        print_section "Step $number: $comment"
        if declare -f "$func" > /dev/null; then
            if ! $func; then
                print_message "Failed to execute $func."
                return 1
            fi
        else
            print_message "Function $func not found."
            return 1
        fi
    done

    return 0
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

    display_settings

    print_section "The following operations will be performed:"
    grep -E '^# [0-9]+\.' "$SCRIPT_DIR/$FUNCTION_FILE" |
    sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/' |
    while read -r line; do
        print_boxline "$line"
    done
    print_boxfooter

    # Automatically proceed with the deployment
    if ! execute_functions; then
        print_box "ERROR: Deployment failed."
        exit 1
    fi

    print_box "Deployment completed successfully."
    print_message "Changes have been applied. The shell will now restart to apply the changes."
    print_message "Press any key to restart the shell..."
    read -n 1 -s
    exec "$SHELL"
}

# Set up traps and run main function
trap 'exit' EXIT

main "$@"

print_section "Script completed. Exiting..."
print_boxfooter
