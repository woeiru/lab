#!/bin/bash

# Check if this is the first run
if [ ! -f "${HOME}/.lab_initialized" ]; then
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                Welcome to Lab Environment Setup                ║
╚════════════════════════════════════════════════════════════════╝

This script will set up your development environment by:
- Configuring your shell (Bash/Zsh)
- Setting up necessary directories
- Loading required modules

The process is interactive but can be automated with flags:
  -y          Non-interactive mode
  -u USER     Specify target user
  -c FILE     Specify config file
  
For more information, see the README.md in the root directory.

EOF
    read -p "Press Enter to continue..."
    touch "${HOME}/.lab_initialized"
fi

#######################################################################
# Shell Configuration Injector
#######################################################################
# Purpose:
#   Injects system initialization code into user shell configuration files
#   (.bashrc or .zshrc) in a controlled and reversible manner.
#
# Features:
#   - Supports both Bash (4+) and Zsh (5+)
#   - Manages configuration blocks with clear markers
#   - Non-destructive updates with backup capability
#   - Interactive and non-interactive modes
#   - User-specific configuration targeting
#
# Operation:
#   1. Verifies shell compatibility
#   2. Identifies target user and home directory
#   3. Locates or creates appropriate shell config file
#   4. Injects or updates initialization code block
#   5. Manages shell restart for changes to take effect
#
# Usage:
#   ./rc [-y] [-u|--user USER] [-c|--config FILE]
#
#######################################################################

set -eo pipefail

# Script metadata
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_VERSION="1.0.2"
readonly SCRIPT_AUTHOR="woeiru"

# Directory paths
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly BIN_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Default configuration
readonly DEFAULT_CONFIG_FILES=(".zshrc" ".bashrc")
readonly INJECT_MARKER_START="# === BEGIN MANAGED BLOCK: Shell Configuration [source: rc] ==="
readonly INJECT_MARKER_END="# === END MANAGED BLOCK: Shell Configuration ==="
readonly FILEPATH="ini"

# Runtime variables
declare -g YES_FLAG=false
declare -g TARGET_USER=""
declare -g TARGET_HOME=""
declare -g CONFIG_FILE=""

# Function to initialize all runtime configuration
init_config() {
    # SCRIPT_DIR, BIN_DIR, and FILEPATH are the global readonly versions.
    printf "\nInitial SCRIPT_DIR = %s\nInitial BIN_DIR = %s\n\n" "$SCRIPT_DIR" "$BIN_DIR"

    local determined_bin_dir
    # Heuristic to determine the correct bin directory for the init script.

    # Case 1: SCRIPT_DIR is <project_root> (standard execution of entry.sh)
    # Target init script would be at $SCRIPT_DIR/bin/$FILEPATH
    if [[ -f "$SCRIPT_DIR/bin/$FILEPATH" ]]; then
        determined_bin_dir=$(cd "$SCRIPT_DIR/bin" && pwd)
    # Case 2: SCRIPT_DIR is some other location (fallback)
    # Target init script would be at $SCRIPT_DIR/../$FILEPATH
    elif [[ -f "$SCRIPT_DIR/../$FILEPATH" ]]; then
        determined_bin_dir=$(cd "$SCRIPT_DIR/.." && pwd)
    else
        # Fallback to the globally defined BIN_DIR if heuristics fail.
        # This might still lead to the incorrect path in the problematic scenario.
        printf "Warning: Heuristic for determining project bin directory failed. Falling back to default BIN_DIR calculation.\n" >&2
        determined_bin_dir="$BIN_DIR"
    fi

    # Initialize variables
    CONFIG_FILE=""
    TARGET_USER=""
    TARGET_HOME=""
    YES_FLAG=false
    
    # Set the injection content using the determined_bin_dir
    readonly INJECT_CONTENT=". ${determined_bin_dir}/${FILEPATH}"

    # Export the variables
    export CONFIG_FILE TARGET_USER TARGET_HOME YES_FLAG

    printf "Configuration initialized. Determined BIN_DIR for injection: %s\n" "$determined_bin_dir"
    printf "INJECT_CONTENT will be: %s\n" "$INJECT_CONTENT"
    return 0
}

# 1. Check shell version - Verify Bash 4+ or Zsh 5+ is being used
check_shell_version() {
    printf "Checking shell version...\n"
    if [[ -n "${BASH_VERSION:-}" ]]; then
        printf "Detected BASH %s\n" "${BASH_VERSION}"
        [[ "${BASH_VERSION:0:1}" -lt 4 ]] && {
            printf "Error: Unsupported Bash version\n"
            return 1
        }
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        printf "Detected ZSH %s\n" "${ZSH_VERSION}"
        [[ "${ZSH_VERSION:0:1}" -lt 5 ]] && {
            printf "Error: Unsupported Zsh version\n"
            return 1
        }
    else
        printf "Error: Unknown shell detected\n"
        return 1
    fi
    return 0
}

# 2. Initialize target user and home directory
init_target_user() {
    printf "Initializing target user...\n"
    local default_user=$(whoami)

    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Enter target user (default: $default_user): " input_user
        TARGET_USER=${input_user:-$default_user}
    else
        TARGET_USER=$default_user
    fi

    TARGET_HOME=$(eval echo ~$TARGET_USER)
    if [[ ! -d "$TARGET_HOME" ]]; then
        printf "Error: Home directory %s does not exist\n" "$TARGET_HOME"
        return 1
    fi

    printf "Selected user: %s\n" "${TARGET_USER}"
    printf "Home directory: %s\n" "${TARGET_HOME}"
    return 0
}

# 3. Set appropriate config file
set_config_file() {
    printf "Setting configuration file...\n"

    [[ -z "$TARGET_HOME" ]] && TARGET_HOME=$(eval echo ~$(whoami))
    printf "Using home directory: %s\n" "${TARGET_HOME}"

    local default_config=""

    # Check for config files
    for config_file in "${DEFAULT_CONFIG_FILES[@]}"; do
        if [[ -f "$TARGET_HOME/$config_file" ]]; then
            default_config="$TARGET_HOME/$config_file"
            printf "Found %s configuration file\n" "$config_file"
            break
        fi
    done

    # If no config file found, use default .bashrc
    [[ -z "$default_config" ]] && default_config="$TARGET_HOME/.bashrc"

    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Enter config file path (default: $default_config): " input_config
        CONFIG_FILE=${input_config:-$default_config}
    else
        CONFIG_FILE=$default_config
    fi

    # Create config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        local config_dir=$(dirname "$CONFIG_FILE")
        if [[ ! -d "$config_dir" ]]; then
            printf "Error: Directory %s does not exist\n" "$config_dir"
            return 1
        fi
        if [[ ! -w "$config_dir" ]]; then
            printf "Error: Cannot write to directory %s\n" "$config_dir"
            return 1
        fi
        touch "$CONFIG_FILE" || {
            printf "Error: Failed to create config file %s\n" "$CONFIG_FILE"
            return 1
        }
        printf "Created new config file: %s\n" "$CONFIG_FILE"
    fi

    printf "Using config file: %s\n" "${CONFIG_FILE}"
    return 0
}

# 4. Inject content into config file
inject_content() {
    printf "Processing config file '%s' for injection...\n" "$CONFIG_FILE"

    if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
        printf "Error: Invalid config file: %s\n" "${CONFIG_FILE}"
        return 1
    fi

    local temp_new_config
    temp_new_config=$(mktemp)
    if [[ -z "$temp_new_config" || ! -f "$temp_new_config" ]]; then # mktemp can fail
        printf "Error: Failed to create temporary file.\n"
        return 1
    fi

    # The desired block content
    local desired_block
    # Ensure INJECT_MARKER_START, INJECT_CONTENT, INJECT_MARKER_END are correctly formatted for echo -e
    # For this script, they are simple strings, so direct usage is fine.
    printf -v desired_block "%s\n%s\n%s" "$INJECT_MARKER_START" "$INJECT_CONTENT" "$INJECT_MARKER_END"

    # Use awk to filter out old managed blocks and any bare instance of INJECT_CONTENT.
    # The result (original file minus these parts) is written to temp_new_config.
    awk -v sm="$INJECT_MARKER_START" -v em="$INJECT_MARKER_END" -v ic="$INJECT_CONTENT" '
        BEGIN { in_block = 0 }
        # Using exact string comparison for markers and content
        $0 == sm { in_block = 1; next }
        $0 == em { in_block = 0; next }
        !in_block && $0 != ic { print }
    ' "$CONFIG_FILE" > "$temp_new_config"

    # Ensure there's a newline before our block if $temp_new_config is not empty and doesn't end with one
    if [[ -s "$temp_new_config" ]] && [[ $(tail -c1 "$temp_new_config" | wc -l) -eq 0 ]]; then
        echo "" >> "$temp_new_config"
    fi

    # Append the correct, new block to $temp_new_config
    echo -e "$desired_block" >> "$temp_new_config"
    
    # Compare the newly constructed temp file with the original.
    if diff -q "$CONFIG_FILE" "$temp_new_config" >/dev/null; then
        printf "Configuration file '%s' is already correct. No changes made.\n" "$CONFIG_FILE"
        rm "$temp_new_config"
        return 0 
    else
        printf "Updating configuration file '%s'.\n" "$CONFIG_FILE"
        local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$backup_file"
        if [[ $? -ne 0 ]]; then
            printf "Error: Failed to create backup file '%s'. Aborting update.\n" "$backup_file"
            rm "$temp_new_config"
            return 1
        fi
        
        mv "$temp_new_config" "$CONFIG_FILE"
        if [[ $? -ne 0 ]]; then
            printf "Error: Failed to move temporary file to '%s'. Check permissions.\n" "$CONFIG_FILE"
            # Attempt to restore backup if move fails
            cp "$backup_file" "$CONFIG_FILE" 
            rm "$temp_new_config" # Still remove temp if it exists
            return 1
        fi
        printf "Content injection complete. Backup created at '%s'.\n" "$backup_file"
        return 0
    fi
}

# 5. Restart shell
restart_shell() {
    printf "Preparing for shell restart...\n"
    return 0
}

# Script control functions
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [-y] [-u|--user USER] [-c|--config FILE] [-h|--help]
Version: $SCRIPT_VERSION
Author: $SCRIPT_AUTHOR

Options:
  -y          Non-interactive mode (yes to all prompts)
  -u, --user  Specify target user
  -c, --config Specify config file
  -h, --help  Show this help message
EOF
}

parse_arguments() {
    printf "Parsing command line arguments...\n"
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y)
                YES_FLAG=true
                printf "Non-interactive mode enabled\n"
                shift
                ;;
            -u|--user)
                TARGET_USER="$2"
                printf "Target user set to: %s\n" "${TARGET_USER}"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                declare -g CONFIG_FILE
                printf "Config file set to: %s\n" "${CONFIG_FILE}"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                printf "Error: Invalid argument: %s\n" "$1"
                usage
                exit 1
                ;;
        esac
    done
}

execute_functions() {
    printf "Starting function execution sequence...\n"

    # Create an associative array to map functions to their step numbers
    declare -A step_numbers

    # Get both step numbers and function names
    while read -r line; do
        if [[ $line =~ ^#[[:space:]]*([0-9]+)\. ]]; then
            step_num="${BASH_REMATCH[1]}"
            # Get the next line which should be the function name
            read -r func_line
            if [[ $func_line =~ ^([a-z_][a-z0-9_-]*)\(\) ]]; then
                func_name="${BASH_REMATCH[1]}"
                step_numbers[$func_name]=$step_num
            fi
        fi
    done < <(grep -A1 -E '^# [0-9]+\.' "$0")

    # Get the functions in order
    local functions=($(grep -A1 -E '^# [0-9]+\.' "$0" |
                      grep -E '^[a-z_]+[a-z0-9_-]*\(\)' |
                      sed 's/().*//'))

    [[ ${#functions[@]} -eq 0 ]] && {
        printf "Error: No functions found to execute\n"
        return 1
    }

    # Execute each function
    for func in "${functions[@]}"; do
        printf "\nStep %s: %s ...\n" "${step_numbers[$func]}" "${func}"

        if ! declare -F "$func" >/dev/null; then
            printf "Error: Function %s not found\n" "$func"
            continue
        fi

        if ! eval "$func"; then
            printf "\033[31m ✗\033[0m\n"
            return 1
        fi

        printf "\033[32m ✓\033[0m\n"
    done

    printf "\nAll functions executed successfully\n"
    return 0
}

main() {
    init_config
    parse_arguments "$@"

    printf "Starting deployment...\n"
    printf "Script Version: %s\n\n" "$SCRIPT_VERSION"
    printf "The following steps will be performed:\n"
    grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/'
    printf "\n"

    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Continue with these steps? [Y/n] " confirm
        if [[ "${confirm,,}" == "n" ]]; then
            printf "Deployment cancelled by user\n"
            exit 0
        fi
    fi
    printf "\n"

    if ! execute_functions; then
        printf "Deployment failed.\n"
        exit 1
    fi

    printf "\nDeployment completed successfully\n"
    printf "Press any key to restart shell...\n"
    read -n 1 -s
    exec "$SHELL"
}

trap 'printf "Error on line %s\n" "$LINENO"' ERR
main "$@"
