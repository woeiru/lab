#!/bin/bash

# Set strict mode
set -euo pipefail

# Global variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LAB_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
TARGET_HOME=""
CONFIG_FILE=""
LOG_FILE="/tmp/deployment_$(date +%Y%m%d_%H%M%S).log"
DRY_RUN=false
INTERACTIVE=false
TARGET_USER=""
DEBUG=${DEBUG:-false}

# Source the fun.sh file containing numbered functions
source "$SCRIPT_DIR/fun.sh"

echo "Script started with PID: $$"

# Utility functions

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}
log_debug() {
    if [[ "$DEBUG" = true ]]; then
        log_message "DEBUG" "$1"
    fi
}

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -u, --user USER    Specify target user (default: current user)"
    echo "  -c, --config FILE  Specify config file location"
    echo "  -d, --dry-run      Perform a dry run without making changes"
    echo "  -i, --interactive  Run in interactive mode"
    echo "  -h, --help         Display this help message"
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
                log_message "INFO" "User argument provided: $TARGET_USER"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                log_message "INFO" "Config file argument provided: $CONFIG_FILE"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                log_message "INFO" "Dry run mode enabled"
                shift
                ;;
            -i|--interactive)
                INTERACTIVE=true
                log_message "INFO" "Interactive mode enabled"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                DEBUG=true
                log_message "INFO" "Verbose mode enabled"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Function to handle cleanup on exit
cleanup() {
    echo "Cleanup function called"
    log_message "INFO" "Cleaning up..."

    # Remove temporary files
    local temp_files=($(find /tmp -name "temp_*" -user "$(whoami)" -mmin -5))
    if [[ ${#temp_files[@]} -gt 0 ]]; then
        for temp_file in "${temp_files[@]}"; do
            rm -f "$temp_file"
            log_message "INFO" "Removed temporary file: $temp_file"
        done
    else
        log_message "DEBUG" "No temporary files found"
    fi

    # Restore original config file if deployment failed
    local latest_backup=$(find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" | sort -r | head -n 1)
    if [[ $? -ne 0 && -n "$latest_backup" ]]; then
        mv "$latest_backup" "$CONFIG_FILE"
        log_message "INFO" "Restored original config file due to deployment failure"
    else
        log_message "DEBUG" "No need to restore config file"
    fi

    # Remove old backup files (keeping only the 2 most recent)
    find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" |
    sort -r |
    tail -n +3 |
    xargs -r rm
    log_message "INFO" "Removed old backup files, keeping the 2 most recent"

    # Reset any environment variables set during the script
    unset SCRIPT_DIR LAB_DIR TARGET_HOME CONFIG_FILE DRY_RUN INTERACTIVE TARGET_USER
    log_message "INFO" "Reset environment variables"

    # Close file descriptors
    exec 3>&- 4>&-
    log_message "INFO" "Closed file descriptors"

    log_message "INFO" "Cleanup completed"
    echo "Cleanup function finished"
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
        log_message "ERROR" "No functions found to execute."
        return 1
    fi

    # Loop through the functions array and execute each function
    for func in "${functions[@]}"; do
        log_message "INFO" "Executing: $func"
        # Check if the function exists
        if declare -f "$func" > /dev/null; then
            # Execute the function and check its return status
            if ! $func; then
                log_message "ERROR" "Failed to execute $func."
                return 1
            fi
        else
            # If the function doesn't exist, print an error and return 1
            log_message "ERROR" "Function $func not found."
            return 1
        fi
    done

    return 0
}

# Interactive mode function
run_interactive_mode() {
    echo "=== Interactive Mode ==="
    echo "Current settings:"
    echo "  User: ${TARGET_USER:-Current user ($(whoami))}"
    echo "  Config file: ${CONFIG_FILE:-Default}"
    echo "  Dry run: ${DRY_RUN}"
    echo

    read -p "Enter the target user (leave blank for current user: $(whoami)): " user_input
    if [[ -n "$user_input" ]]; then
        TARGET_USER="$user_input"
        log_message "INFO" "User set interactively to: $TARGET_USER"
    else
        log_message "INFO" "Using current user: $(whoami)"
    fi

    read -p "Enter the config file location (leave blank for default): " config_input
    if [[ -n "$config_input" ]]; then
        CONFIG_FILE="$config_input"
        log_message "INFO" "Config file set interactively to: $CONFIG_FILE"
    else
        log_message "INFO" "Using default config file location"
    fi

    read -p "Perform a dry run? (y/n): " dry_run_choice
    if [[ "$dry_run_choice" =~ ^[Yy]$ ]]; then
        DRY_RUN=true
        log_message "INFO" "Dry run mode enabled interactively"
    else
        DRY_RUN=false
        log_message "INFO" "Dry run mode disabled interactively"
    fi
}

# Function to display current settings
display_settings() {
    echo "=== Current Settings ==="
    echo "  User: ${TARGET_USER:-Current user ($(whoami))}"
    echo "  Config file: ${CONFIG_FILE:-Default}"
    echo "  Dry run: ${DRY_RUN}"
    echo "========================"
}

# Main execution function
main() {
    log_message "INFO" "Starting deployment script"

    if [[ $# -eq 0 ]]; then
        set_default_values
    else
        parse_arguments "$@"
    fi

    if [[ -z "$TARGET_USER" || -z "$CONFIG_FILE" ]]; then
        set_default_values
    fi

    if [[ "$INTERACTIVE" = true ]]; then
        log_message "INFO" "Entering interactive mode"
        run_interactive_mode
    fi

    display_settings

    if [[ "$DRY_RUN" = true ]]; then
        log_message "INFO" "Running in dry-run mode. No changes will be made."
    fi

    # Display operations with numbering
    echo "=================================================="
    echo "The following operations will be performed:"
    grep -E '^# [0-9]+\.' "$SCRIPT_DIR/fun.sh" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/'
    echo "=================================================="

    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) ;;
        * ) log_message "INFO" "Operation cancelled by user."; exit 0;;
    esac

    # Execute functions with numbered output
      local functions=($(grep -E '^[a-z_]+[a-z0-9_-]*\(\)' "$SCRIPT_DIR/fun.sh" | sed 's/().*//'))

    echo "DEBUG: Functions found: ${functions[*]}" >&2

    for func in "${functions[@]}"; do
        echo "DEBUG: Processing function: $func" >&2
        local number=$(grep -B1 "^$func()" "$SCRIPT_DIR/fun.sh" | grep -E '^# [0-9]+\.' | sed -E 's/^# ([0-9]+)\..*/\1/')
        local comment=$(grep -B1 "^$func()" "$SCRIPT_DIR/fun.sh" | grep -E '^# [0-9]+\.' | sed -E 's/^# [0-9]+\. //')
        echo "DEBUG: number=$number, comment=$comment" >&2
        echo "=================================================="
        echo "Step $number: $comment"
        echo "=================================================="
        log_message "INFO" "Executing: $func"
        if declare -f "$func" > /dev/null; then
            if ! $func; then
                log_message "ERROR" "Failed to execute $func."
                exit 1
            fi
        else
            log_message "ERROR" "Function $func not found."
            exit 1
        fi
        echo
    done

    if [[ "$DRY_RUN" = false ]]; then
        log_message "INFO" "Deployment completed successfully."
        echo "Changes have been applied. The shell will now restart to apply the changes."
        if [[ "$DEBUG" = true ]]; then
            log_message "DEBUG" "Testing cleanup function"
            cleanup
        fi
        echo "Press any key to restart the shell..."
        read -n 1 -s
        echo "About to exec new shell..."
        exec "$SHELL"
    else
        log_message "INFO" "Dry run completed. No changes were made."
    fi
    echo "This line should not be reached due to exec"
}

debug_trap() {
    echo "Trap triggered with signal: $1"
    cleanup
}

# Set up traps for multiple signals with debugging
trap 'debug_trap EXIT' EXIT
trap 'debug_trap SIGINT' SIGINT
trap 'debug_trap SIGTERM' SIGTERM

# Run the main function
main "$@"
echo "Script completed. Exiting..."
