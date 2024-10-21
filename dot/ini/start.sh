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
        "DRY-RUN")
            color_code="\033[0;32m"  # Green
            ;;
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
                log "INFO" "User argument provided: $TARGET_USER"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                log "INFO" "Config file argument provided: $CONFIG_FILE"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                log "INFO" "Dry run mode enabled"
                shift
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
                echo "Unknown option: $1"
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
    unset SCRIPT_DIR LAB_DIR TARGET_HOME CONFIG_FILE DRY_RUN INTERACTIVE TARGET_USER
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
        echo "=================================================="
        echo "Step $number: $comment"
        echo "=================================================="
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
        echo
    done

    return 0
}

# Interactive mode function
run_interactive_mode() {
    echo "<===> Interactive Mode <===>"
    echo "Current settings:"
    echo "  User: ${TARGET_USER:-Current user ($(whoami))}"
    echo "  Config file: ${CONFIG_FILE:-Default}"
    echo "  Dry run: ${DRY_RUN}"
    echo

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

    read -p "Perform a dry run? (y/n): " dry_run_choice
    if [[ "$dry_run_choice" =~ ^[Yy]$ ]]; then
        DRY_RUN=true
        log "INFO" "Dry run mode enabled interactively"
    else
        DRY_RUN=false
        log "INFO" "Dry run mode disabled interactively"
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

    if [[ "$DRY_RUN" = true ]]; then
        log "INFO" "Running in dry-run mode. No changes will be made."
    fi

    # Display operations with numbering
    echo "=================================================="
    echo "The following operations will be performed:"
    grep -E '^# [0-9]+\.' "$SCRIPT_DIR/fun.sh" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/'
    echo "=================================================="

    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) ;;
        * ) log "INFO" "Operation cancelled by user."; exit 0;;
    esac

    if ! execute_functions; then
        log "ERROR" "Deployment failed."
        exit 1
    fi

    if [[ "$DRY_RUN" = false ]]; then
        log "INFO" "Deployment completed successfully."
        echo "Changes have been applied. The shell will now restart to apply the changes."
        if [[ "$DEBUG" = true ]]; then
            log "DEBUG" "Testing cleanup function"
            cleanup
        fi
        echo "Press any key to restart the shell..."
        read -n 1 -s
        echo "About to exec new shell..."
        exec "$SHELL"
    else
        log "DRY-RUN" "Dry run completed. No changes were made."
    fi
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
echo "=================================================="
echo "Script completed. Exiting..."
echo "=================================================="