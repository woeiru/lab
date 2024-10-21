#!/bin/bash

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
FUNCTION_FILE="flow.sh"  # Variable for the function file name
INJECT_FILE="inject"  # New variable for the inject file name

# Improved logging function (renamed to avoid conflicts)
deploy_log() {
    local level="$1"
    local message="$2"
    local color_code=""

    # Only log DEBUG messages if DEPLOY_DEBUG is true
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
            color_code="\033[0m"  # Default (no color)
            ;;
    esac

    # Compact timestamp format
    local timestamp=$(date '+%Y%m%d%H%M%S')

    echo -e "${color_code}[$timestamp][$level]\033[0m $message" | tee -a "$DEPLOY_LOG_FILE"
}

# Export the deploy_log function and INJECT_FILE variable so they're available to sourced scripts
export -f deploy_log
export INJECT_FILE

# Source the function file containing numbered functions
source "$SCRIPT_DIR/$FUNCTION_FILE"

# Function to display usage information
usage() {
    deploy_log "INFO" "Usage: $0 [OPTIONS]"
    deploy_log "INFO" "Options:"
    deploy_log "INFO" "  -u, --user USER    Specify target user (default: current user)"
    deploy_log "INFO" "  -c, --config FILE  Specify config file location"
    deploy_log "INFO" "  -i, --interactive  Run in interactive mode"
    deploy_log "INFO" "  -h, --help         Display this help message"
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
                deploy_log "INFO" "User argument provided: $TARGET_USER"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                deploy_log "INFO" "Config file argument provided: $CONFIG_FILE"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE=true
                deploy_log "INFO" "Interactive mode enabled"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                DEPLOY_DEBUG=true
                deploy_log "INFO" "Verbose mode enabled"
                shift
                ;;
            *)
                deploy_log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Function to handle cleanup on exit
cleanup() {
    deploy_log "DEBUG" "Cleaning up..."

    # Remove temporary files
    local temp_files=($(find /tmp -name "temp_*" -user "$(whoami)" -mmin -5))
    if [[ ${#temp_files[@]} -gt 0 ]]; then
        for temp_file in "${temp_files[@]}"; do
            rm -f "$temp_file"
            deploy_log "DEBUG" "Removed temporary file: $temp_file"
        done
    else
        deploy_log "DEBUG" "No temporary files found"
    fi

    # Restore original config file if deployment failed
    local latest_backup=$(find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" | sort -r | head -n 1)
    if [[ $? -ne 0 && -n "$latest_backup" ]]; then
        mv "$latest_backup" "$CONFIG_FILE"
        deploy_log "DEBUG" "Restored original config file due to deployment failure"
    else
        deploy_log "DEBUG" "No need to restore config file"
    fi

    # Remove old backup files (keeping only the 2 most recent)
    find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" |
    sort -r |
    tail -n +3 |
    xargs -r rm
    deploy_log "DEBUG" "Removed old backup files, keeping the 2 most recent"

    # Reset any environment variables set during the script
    unset SCRIPT_DIR LAB_DIR TARGET_HOME CONFIG_FILE INTERACTIVE TARGET_USER
    deploy_log "DEBUG" "Reset environment variables"

    # Close file descriptors
    exec 3>&- 4>&-
    deploy_log "DEBUG" "Closed file descriptors"

    deploy_log "DEBUG" "Cleanup completed"
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
        deploy_log "ERROR" "No functions found to execute."
        return 1
    fi

    # Loop through the functions array and execute each function
    for func in "${functions[@]}"; do
        local number=$(grep -B1 "^$func()" "$SCRIPT_DIR/$FUNCTION_FILE" | grep -E '^# [0-9]+\.' | sed -E 's/^# ([0-9]+)\..*/\1/')
        local comment=$(grep -B1 "^$func()" "$SCRIPT_DIR/$FUNCTION_FILE" | grep -E '^# [0-9]+\.' | sed -E 's/^# [0-9]+\. //')
        deploy_log "INFO" "=================================================="
        deploy_log "INFO" "Step $number: $comment"
        deploy_log "INFO" "=================================================="
        deploy_log "DEBUG" "Executing: $func"
        if declare -f "$func" > /dev/null; then
            if ! $func; then
                deploy_log "ERROR" "Failed to execute $func."
                return 1
            fi
        else
            deploy_log "ERROR" "Function $func not found."
            return 1
        fi
    done

    return 0
}

# Interactive mode function
run_interactive_mode() {
    deploy_log "INFO" "<===> Interactive Mode <===>"
    deploy_log "INFO" "Current settings:"
    deploy_log "INFO" "  User: ${TARGET_USER:-Current user ($(whoami))}"
    deploy_log "INFO" "  Config file: ${CONFIG_FILE:-Default}"

    read -p "Enter the target user (leave blank for current user: $(whoami)): " user_input
    if [[ -n "$user_input" ]]; then
        TARGET_USER="$user_input"
        deploy_log "INFO" "User set interactively to: $TARGET_USER"
    else
        deploy_log "INFO" "Using current user: $(whoami)"
    fi

    read -p "Enter the config file location (leave blank for default): " config_input
    if [[ -n "$config_input" ]]; then
        CONFIG_FILE="$config_input"
        deploy_log "INFO" "Config file set interactively to: $CONFIG_FILE"
    else
        deploy_log "INFO" "Using default config file location"
    fi
}

# Function to display current settings
display_settings() {
    deploy_log "INFO" "=== Current Settings ==="
    deploy_log "INFO" "  User: ${TARGET_USER:-Current user ($(whoami))}"
    deploy_log "INFO" "  Config file: ${CONFIG_FILE:-Default}"
    deploy_log "INFO" "========================"
}

# Main execution function
main() {
    deploy_log "INFO" "Starting deployment script with PID: $$"

    if [[ $# -eq 0 ]]; then
        set_default_values
    else
        parse_arguments "$@"
    fi

    if [[ -z "$TARGET_USER" || -z "$CONFIG_FILE" ]]; then
        set_default_values
    fi

    if [[ "$INTERACTIVE" = true ]]; then
        deploy_log "INFO" "Entering interactive mode"
        run_interactive_mode
    fi

    display_settings

    # Display operations with numbering
    deploy_log "INFO" "=================================================="
    deploy_log "INFO" "The following operations will be performed:"
    grep -E '^# [0-9]+\.' "$SCRIPT_DIR/$FUNCTION_FILE" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/' | while read -r line; do
        deploy_log "INFO" "$line"
    done
    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) ;;
        * ) deploy_log "INFO" "Operation cancelled by user."; exit 0;;
    esac

    if ! execute_functions; then
        deploy_log "ERROR" "Deployment failed."
        exit 1
    fi

    deploy_log "INFO" "Deployment completed successfully."
    deploy_log "INFO" "Changes have been applied. The shell will now restart to apply the changes."
    if [[ "$DEPLOY_DEBUG" = true ]]; then
        deploy_log "DEBUG" "Testing cleanup function"
        cleanup
    fi
    deploy_log "INFO" "Press any key to restart the shell..."
    read -n 1 -s
    deploy_log "INFO" "About to exec new shell..."
    exec "$SHELL"
}

debug_trap() {
    deploy_log "DEBUG" "Trap triggered with signal: $1"
    cleanup
}

# Set up traps for multiple signals with debugging
trap 'debug_trap EXIT' EXIT
trap 'debug_trap SIGINT' SIGINT
trap 'debug_trap SIGTERM' SIGTERM

# Run the main function
main "$@"
deploy_log "INFO" "=================================================="
deploy_log "INFO" "Script completed. Exiting..."
deploy_log "INFO" "=================================================="
