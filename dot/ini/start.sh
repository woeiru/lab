#!/bin/bash

# Set strict mode
set -eo pipefail

# Global variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LAB_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
TARGET_HOME=""
CONFIG_FILE=""
LOG_FILE="/tmp/deployment_$(date +%Y%m%d_%H%M%S).log"
INTERACTIVE=false
TARGET_USER=""
DEBUG=${DEBUG:-true}

# Source the fun.sh file containing numbered functions
source "$SCRIPT_DIR/fun.sh"

# Improved logging function
log() {
    local level="$1"
    local message="$2"
    local color_code=""

    # Only log DEBUG messages if DEBUG is true
    if [[ "$level" == "DEBUG" && "$DEBUG" != true ]]; then
        return
    fi

    case "$level" in
        "DEBUG")
            color_code="\033[0;33m"  # Yellow
            ;;
        "ERROR")
            color_code="\033[0;31m"  # Red
            ;;
        "INFO")
            color_code="\033[0;34m"  # Blue
            ;;
        *)
            color_code="\033[0m"  # Default (no color)
            ;;
    esac

    echo -e "${color_code}[$(date '+%Y-%m-%d %H:%M:%S')] [$level]\033[0m $message" | tee -a "$LOG_FILE"
}

# Function to display usage information
usage() {
    log "INFO" "Usage: $0 [OPTIONS]"
    log "INFO" "Options:"
    log "INFO" "  -u, --user USER    Specify target user (default: current user)"
    log "INFO" "  -c, --config FILE  Specify config file location"
    log "INFO" "  -i, --interactive  Run in interactive mode"
    log "INFO" "  -h, --help         Display this help message"
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
                log "INFO" "User argument provided: $TARGET_USER"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                log "INFO" "Config file argument provided: $CONFIG_FILE"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE=true
                log "INFO" "Interactive mode enabled"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                DEBUG=true
                log "INFO" "Verbose mode enabled"
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Function to handle cleanup on exit
cleanup() {
    log "DEBUG" "Cleaning up..."

    # Remove temporary files
    local temp_files=($(find /tmp -name "temp_*" -user "$(whoami)" -mmin -5))
    if [[ ${#temp_files[@]} -gt 0 ]]; then
        for temp_file in "${temp_files[@]}"; do
            rm -f "$temp_file"
            log "DEBUG" "Removed temporary file: $temp_file"
        done
    else
        log "DEBUG" "No temporary files found"
    fi

    # Restore original config file if deployment failed
    local latest_backup=$(find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" | sort -r | head -n 1)
    if [[ $? -ne 0 && -n "$latest_backup" ]]; then
        mv "$latest_backup" "$CONFIG_FILE"
        log "DEBUG" "Restored original config file due to deployment failure"
    else
        log "DEBUG" "No need to restore config file"
    fi

    # Remove old backup files (keeping only the 2 most recent)
    find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" |
    sort -r |
    tail -n +3 |
    xargs -r rm
    log "DEBUG" "Removed old backup files, keeping the 2 most recent"

    # Reset any environment variables set during the script
    unset SCRIPT_DIR LAB_DIR TARGET_HOME CONFIG_FILE INTERACTIVE TARGET_USER
    log "DEBUG" "Reset environment variables"

    # Close file descriptors
    exec 3>&- 4>&-
    log "DEBUG" "Closed file descriptors"

    log "DEBUG" "Cleanup completed"
}

# Function to dynamically execute functions
execute_functions() {
    # Create an array of function names, sorted by their comment number
    local functions=($(grep -E '^# [0-9]+\.' "$SCRIPT_DIR/fun.sh" |
                       sed -E 's/^# ([0-9]+)\. .*/\1 /' |
                       paste -d' ' - <(grep -A1 -E '^# [0-9]+\.' "$SCRIPT_DIR/fun.sh" |
                                       grep -E '^[a-z_]+[a-z0-9_-]*\(\)' |
                                       sed 's/().*//') |
                       sort -n |
                       cut -d' ' -f2-))

    # Check if the functions array is empty
    if [ ${#functions[@]} -eq 0 ]; then
        log "ERROR" "No functions found to execute."
        return 1
    fi

    # Loop through the functions array and execute each function
    for func in "${functions[@]}"; do
        local number=$(grep -B1 "^$func()" "$SCRIPT_DIR/fun.sh" | grep -E '^# [0-9]+\.' | sed -E 's/^# ([0-9]+)\..*/\1/')
        local comment=$(grep -B1 "^$func()" "$SCRIPT_DIR/fun.sh" | grep -E '^# [0-9]+\.' | sed -E 's/^# [0-9]+\. //')
        log "INFO" "=================================================="
        log "INFO" "Step $number: $comment"
        log "INFO" "=================================================="
        log "DEBUG" "Executing: $func"
        if declare -f "$func" > /dev/null; then
            if ! $func; then
                log "ERROR" "Failed to execute $func."
                return 1
            fi
        else
            log "ERROR" "Function $func not found."
            return 1
        fi
    done

    return 0
}

# Interactive mode function
run_interactive_mode() {
    log "INFO" "<===> Interactive Mode <===>"
    log "INFO" "Current settings:"
    log "INFO" "  User: ${TARGET_USER:-Current user ($(whoami))}"
    log "INFO" "  Config file: ${CONFIG_FILE:-Default}"

    read -p "Enter the target user (leave blank for current user: $(whoami)): " user_input
    if [[ -n "$user_input" ]]; then
        TARGET_USER="$user_input"
        log "INFO" "User set interactively to: $TARGET_USER"
    else
        log "INFO" "Using current user: $(whoami)"
    fi

    read -p "Enter the config file location (leave blank for default): " config_input
    if [[ -n "$config_input" ]]; then
        CONFIG_FILE="$config_input"
        log "INFO" "Config file set interactively to: $CONFIG_FILE"
    else
        log "INFO" "Using default config file location"
    fi
}

# Function to display current settings
display_settings() {
    log "INFO" "=== Current Settings ==="
    log "INFO" "  User: ${TARGET_USER:-Current user ($(whoami))}"
    log "INFO" "  Config file: ${CONFIG_FILE:-Default}"
    log "INFO" "========================"
}

# Main execution function
main() {
    log "INFO" "Starting deployment script with PID: $$"

    if [[ $# -eq 0 ]]; then
        set_default_values
    else
        parse_arguments "$@"
    fi

    if [[ -z "$TARGET_USER" || -z "$CONFIG_FILE" ]]; then
        set_default_values
    fi

    if [[ "$INTERACTIVE" = true ]]; then
        log "INFO" "Entering interactive mode"
        run_interactive_mode
    fi

    display_settings

    # Display operations with numbering
    log "INFO" "=================================================="
    log "INFO" "The following operations will be performed:"
    grep -E '^# [0-9]+\.' "$SCRIPT_DIR/fun.sh" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/' | while read -r line; do
        log "INFO" "$line"
    done
    log "INFO" "=================================================="

    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) ;;
        * ) log "INFO" "Operation cancelled by user."; exit 0;;
    esac

    if ! execute_functions; then
        log "ERROR" "Deployment failed."
        exit 1
    fi

    log "INFO" "Deployment completed successfully."
    log "INFO" "Changes have been applied. The shell will now restart to apply the changes."
    if [[ "$DEBUG" = true ]]; then
        log "DEBUG" "Testing cleanup function"
        cleanup
    fi
    log "INFO" "Press any key to restart the shell..."
    read -n 1 -s
    log "INFO" "About to exec new shell..."
    exec "$SHELL"
}

debug_trap() {
    log "DEBUG" "Trap triggered with signal: $1"
    cleanup
}

# Set up traps for multiple signals with debugging
trap 'debug_trap EXIT' EXIT
trap 'debug_trap SIGINT' SIGINT
trap 'debug_trap SIGTERM' SIGTERM

# Run the main function
main "$@"
log "INFO" "=================================================="
log "INFO" "Script completed. Exiting..."
log "INFO" "=================================================="
