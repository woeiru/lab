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

# Numbered functions (main workflow)

# 1. Check shell version
check_shell_version() {
    if [[ -n "${BASH_VERSION:-}" ]]; then
        if [[ "${BASH_VERSION:0:1}" -lt 4 ]]; then
            log_message "ERROR" "This script requires Bash version 4 or higher."
            exit 1
        fi
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        if [[ "${ZSH_VERSION:0:1}" -lt 5 ]]; then
            log_message "ERROR" "This script requires Zsh version 5 or higher."
            exit 1
        fi
    else
        log_message "ERROR" "This script must be run in Bash or Zsh."
        exit 1
    fi
}

# 2. Initialize target user and home directory
init_target_user() {
    if [[ "$EUID" -eq 0 ]]; then
        if [[ -z "${TARGET_USER:-}" ]]; then
            if [[ "$INTERACTIVE" = true ]]; then
                read -p "Enter the target user's username (or 'root' for the root user): " TARGET_USER
            else
                log_message "ERROR" "When running as root, you must specify a target user with -u or --user."
                usage
                exit 1
            fi
        fi
        if [[ "$TARGET_USER" = "root" ]]; then
            TARGET_HOME=$(eval echo ~root)
        else
            TARGET_HOME=$(eval echo ~$TARGET_USER)
        fi

        if [[ ! -d "$TARGET_HOME" ]]; then
            log_message "ERROR" "Home directory for user $TARGET_USER not found."
            exit 1
        fi
    else
        TARGET_HOME="$HOME"
    fi
    log_message "INFO" "Target home directory set to: $TARGET_HOME"
}

# 3. Source usr.bash and configure environment
configure_environment() {
    local USR_BASH_PATH="$LAB_DIR/lib/usr.bash"
    if [[ -f "$USR_BASH_PATH" ]]; then
        source "$USR_BASH_PATH"
        log_message "INFO" "Sourced usr.bash from $USR_BASH_PATH"
        if declare -f usr-cgp > /dev/null; then
            if [[ "$DRY_RUN" = false ]]; then
                usr-cgp
                log_message "INFO" "Configured Git and SSH settings."
            else
                log_message "DRY-RUN" "Would configure Git and SSH settings."
            fi
        else
            log_message "WARNING" "usr-cgp function not found in usr.bash"
        fi
    else
        log_message "WARNING" "$USR_BASH_PATH not found."
    fi
}

# 4. Set appropriate config file (.zshrc or .bashrc)
set_config_file() {
    if [[ -n "${CONFIG_FILE:-}" ]]; then
        if [[ ! -f "$CONFIG_FILE" ]]; then
            log_message "ERROR" "Specified config file $CONFIG_FILE not found."
            exit 1
        fi
    elif [[ -f "$TARGET_HOME/.zshrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.bashrc"
    else
        log_message "ERROR" "Neither .zshrc nor .bashrc found in $TARGET_HOME."
        exit 1
    fi
    log_message "INFO" "Using config file: $CONFIG_FILE"
}

# 5. Create a backup of the config file
backup_config_file() {
    local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    if [[ "$DRY_RUN" = false ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        log_message "INFO" "Created backup of config file: $backup_file"
    else
        log_message "DRY-RUN" "Would create backup of config file: $backup_file"
    fi
}

# 6. Inject content into config file
inject_content() {
    local start_marker="# START inject"
    local end_marker="# END inject"
    local temp_file=$(mktemp)
    local inject_file="$SCRIPT_DIR/inject"

    if [[ ! -f "$inject_file" ]]; then
        log_message "ERROR" "Inject file not found: $inject_file"
        exit 1
    fi

    if grep -q "$start_marker" "$CONFIG_FILE"; then
        # If injection markers exist, replace the content between them
        awk -v start="$start_marker" -v end="$end_marker" -v inject_file="$inject_file" '
            $0 ~ start {print; system("cat " inject_file); f=1; next}
            $0 ~ end {f=0}
            !f
        ' "$CONFIG_FILE" > "$temp_file"

        if [[ "$DRY_RUN" = false ]]; then
            mv "$temp_file" "$CONFIG_FILE"
            log_message "INFO" "Updated existing inject content in $CONFIG_FILE"
        else
            log_message "DRY-RUN" "Would update existing inject content in $CONFIG_FILE"
            rm "$temp_file"
        fi
    else
        # If no injection markers exist, append the new content
        if [[ "$DRY_RUN" = false ]]; then
            echo "" >> "$CONFIG_FILE"
            echo "$start_marker" >> "$CONFIG_FILE"
            cat "$inject_file" >> "$CONFIG_FILE"
            echo "$end_marker" >> "$CONFIG_FILE"
            log_message "INFO" "Added new inject content to $CONFIG_FILE"
        else
            log_message "DRY-RUN" "Would add new inject content to $CONFIG_FILE"
        fi
    fi
}

# 7. Restart shell
restart_shell() {
    if [[ "$DRY_RUN" = false ]]; then
        log_message "INFO" "Restarting shell to apply changes..."
        exec "$SHELL"
    else
        log_message "DRY-RUN" "Would restart shell to apply changes."
    fi
}

# Utility functions

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -u, --user USER    Specify target user (required for root)"
    echo "  -c, --config FILE  Specify config file location"
    echo "  -d, --dry-run      Perform a dry run without making changes"
    echo "  -i, --interactive  Run in interactive mode"
    echo "  -h, --help         Display this help message"
}

# Function to parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--user)
                TARGET_USER="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
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
    log_message "INFO" "Cleaning up..."
    # Add any necessary cleanup tasks here
}

# Function to dynamically execute functions
execute_functions() {
    # Create an array of function names, sorted by their comment number
    local functions=($(grep -E '^# [0-9]+\.' "$0" |
                       sed -E 's/^# ([0-9]+)\. .*/\1 /' |
                       paste -d' ' - <(grep -A1 -E '^# [0-9]+\.' "$0" |
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
    INTERACTIVE=true
    if [[ "$EUID" -eq 0 ]]; then
        read -p "Enter the target user's username (or 'root' for the root user): " TARGET_USER
    fi
    read -p "Enter the config file location (leave blank for default): " CONFIG_FILE
    read -p "Perform a dry run? (y/n): " dry_run_choice
    if [[ "$dry_run_choice" =~ ^[Yy]$ ]]; then
        DRY_RUN=true
    fi
}

# Main execution function
main() {
    if [[ $# -eq 0 ]]; then
        run_interactive_mode
    else
        parse_arguments "$@"
    fi

    log_message "INFO" "Starting deployment script"

    if [[ "$DRY_RUN" = true ]]; then
        log_message "INFO" "Running in dry-run mode. No changes will be made."
    fi

    # Display operations with numbering
    echo "=================================================="
    echo "               DEPLOYMENT SCRIPT"
    echo "=================================================="
    echo "The following operations will be performed:"
    grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/'
    echo "=================================================="

    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) ;;
        * ) log_message "INFO" "Operation cancelled by user."; exit 0;;
    esac

    if ! execute_functions; then
        log_message "ERROR" "Some operations failed. Please check the output above for details."
        exit 1
    fi

    if [[ "$DRY_RUN" = false ]]; then
        log_message "INFO" "Deployment completed successfully."
        echo "Changes have been applied. The shell will now restart to apply the changes."
        exec "$SHELL"
    else
        log_message "INFO" "Dry run completed. No changes were made."
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Run the main function
main "$@"
