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
DEBUG=false

# Numbered functions (main workflow)

# 1. Check shell version
check_shell_version() {
    log_debug "Entering function: ${FUNCNAME[0]}"
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
    log_debug "Entering function: ${FUNCNAME[0]}"
    if [[ -z "${TARGET_USER}" ]]; then
        TARGET_USER=$(whoami)
        log_message "INFO" "No user specified. Using current user: $TARGET_USER"
    else
        log_message "INFO" "User specified via -u/--user argument: $TARGET_USER"
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
    log_message "INFO" "Target user set to: $TARGET_USER"
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

    log_message "INFO" "Using default values:"
    log_message "INFO" "  User: $TARGET_USER"
    log_message "INFO" "  Home: $TARGET_HOME"
    log_message "INFO" "  Config: $CONFIG_FILE"
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
    log_message "INFO" "Cleaning up..."

    # Remove temporary files
    if [[ -f "$temp_file" ]]; then
        rm -f "$temp_file"
        log_message "INFO" "Removed temporary file: $temp_file"
    fi

    # Restore original config file if deployment failed
    if [[ $? -ne 0 && -f "${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)" ]]; then
        mv "${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)" "$CONFIG_FILE"
        log_message "INFO" "Restored original config file due to deployment failure"
    fi

    # Remove old backup files (keeping the last 5)
    find "$(dirname "$CONFIG_FILE")" -maxdepth 1 -name "$(basename "$CONFIG_FILE").bak_*" |
    sort -r |
    tail -n +6 |
    xargs -r rm
    log_message "INFO" "Removed old backup files, keeping the 5 most recent"

    # Reset any environment variables set during the script
    unset SCRIPT_DIR LAB_DIR TARGET_HOME CONFIG_FILE DRY_RUN INTERACTIVE TARGET_USER
    log_message "INFO" "Reset environment variables"

    # Close file descriptors
    exec 3>&- 4>&-
    log_message "INFO" "Closed file descriptors"

    log_message "INFO" "Cleanup completed"
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
        log_message "INFO" "No arguments provided. Using default values."
        set_default_values
    else
        log_message "INFO" "Parsing command-line arguments"
        parse_arguments "$@"
    fi

    if [[ -z "$TARGET_USER" || -z "$CONFIG_FILE" ]]; then
        log_message "INFO" "Some required values are not set. Using defaults for missing values."
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
        if [[ "$DEBUG" = true ]]; then
            log_message "DEBUG" "Testing cleanup function"
            cleanup
        fi
        exec "$SHELL"
    else
        log_message "INFO" "Dry run completed. No changes were made."
    fi
}

# Set up traps for multiple signals
trap cleanup EXIT SIGINT SIGTERM

# Run the main function
main "$@"
