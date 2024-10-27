#!/bin/bash

set -eo pipefail

# Script metadata
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_VERSION="1.0.1"
readonly SCRIPT_AUTHOR="woeiru"

# Directory paths

readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly LAB_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
readonly BAS_DIR="$LAB_DIR/bas"

# Default configuration
readonly DEFAULT_CONFIG_FILES=(".zshrc" ".bashrc")
readonly INJECT_MARKER_START="# START inject"
readonly INJECT_MARKER_END="# END inject"
readonly INJECT_CONTENT=". ~/lab/com/rc"

# Script behavior flags and settings
[[ -z "$BASE_INDENT" ]] && readonly BASE_INDENT="  "
readonly SCRIPT_LOG_LEVELS=("ERROR" "INFO" "DEBUG" "TRACE")
readonly DEFAULT_LOG_LEVEL="INFO"

# Runtime variables (these will be modified during execution)
declare -g YES_FLAG=false
declare -g TARGET_USER=""
declare -g TARGET_HOME=""
declare -g CONFIG_FILE=""
declare -g SCRIPT_LOG_LEVEL="$DEFAULT_LOG_LEVEL"

# Function to initialize all runtime configuration
init_config() {

    echo
    echo "SCRIPT DIR = $SCRIPT_DIR"
    echo "LAB DIR = $LAB_DIR"
    echo "BAS DIR = $BAS_DIR"
    echo

    # Initialize variables without readonly
    CONFIG_FILE=""
    TARGET_USER=""
    TARGET_HOME=""
    YES_FLAG=false
    LOG_LEVEL="$DEFAULT_LOG_LEVEL"

    # Export the variables
    export CONFIG_FILE
    export TARGET_USER
    export TARGET_HOME
    export YES_FLAG
    export LOG_LEVEL

    echo "Configuration initialized"
    return 0
}

# 1. Check shell version - Verify Bash 4+ or Zsh 5+ is being used
check_shell_version() {
    log "lvl-5" "Checking shell version"
    if [[ -n "${BASH_VERSION:-}" ]]; then
        log "lvl-6" "Detected BASH ${BASH_VERSION}"
        [[ "${BASH_VERSION:0:1}" -lt 4 ]] && {
            log "lvl-5" "Unsupported Bash version"
            return 1
        }
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        log "lvl-6" "Detected ZSH ${ZSH_VERSION}"
        [[ "${ZSH_VERSION:0:1}" -lt 5 ]] && {
            log "lvl-6" "Unsupported Zsh version"
            return 1
        }
    else
        log "lvl-6" "Unknown shell detected"
        return 1
    fi
    return 0
}

# 2. Initialize target user and home directory
init_target_user() {
    log "lvl-5" "Initializing target user"
    local default_user=$(whoami)

    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Enter target user (default: $default_user): " input_user
        TARGET_USER=${input_user:-$default_user}
    else
        TARGET_USER=$default_user
    fi

    TARGET_HOME=$(eval echo ~$TARGET_USER)
    if [[ ! -d "$TARGET_HOME" ]]; then
        log "lvl-6" "Home directory $TARGET_HOME does not exist"
        return 1
    fi

    # Ensure global scope
    declare -g TARGET_USER TARGET_HOME

    log "lvl-6" "Selected user: ${TARGET_USER}"
    log "lvl-6" "Home directory: ${TARGET_HOME}"
    log "lvl-4" "USER=${TARGET_USER}, HOME=${TARGET_HOME}"
    return 0
}

# 3. Set appropriate config file
set_config_file() {
    log "lvl-5" "Setting configuration file"

    [[ -z "$TARGET_HOME" ]] && TARGET_HOME=$(eval echo ~$(whoami))
    log "lvl-6" "Using home directory: ${TARGET_HOME}"

    local default_config=""

    # Check for config files
    for config_file in "${DEFAULT_CONFIG_FILES[@]}"; do
        if [[ -f "$TARGET_HOME/$config_file" ]]; then
            default_config="$TARGET_HOME/$config_file"
            log "lvl-6" "Found $config_file configuration file"
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
            log "lvl-6" "Directory $config_dir does not exist"
            return 1
        fi
        if [[ ! -w "$config_dir" ]]; then
            log "lvl-6" "Cannot write to directory $config_dir"
            return 1
        fi
        touch "$CONFIG_FILE" || {
            log "lvl-6" "Failed to create config file $CONFIG_FILE"
            return 1
        }
        log "lvl-6" "Created new config file: $CONFIG_FILE"
    fi

    # Ensure global scope
    declare -g CONFIG_FILE

    log "lvl-4" "Using config file: ${CONFIG_FILE}"
    log "lvl-4" "CONFIG=${CONFIG_FILE}"
    return 0
}

# 4. Inject content into config file
inject_content() {
    log "lvl-5" "Injecting content into config file"
    log "lvl-6" "CONFIG_FILE value: ${CONFIG_FILE}"

    if [[ -z "$CONFIG_FILE" || ! -f "$CONFIG_FILE" ]]; then
       # Add debug output to see what's happening
       log "lvl-6" "CONFIG_FILE='${CONFIG_FILE}'"
       [[ -z "$CONFIG_FILE" ]] && log "lvl-6" "CONFIG_FILE is empty"
       [[ ! -f "$CONFIG_FILE" ]] && log "lvl-6" "File does not exist"
        log "lvl-6" "Invalid config file: ${CONFIG_FILE}"
        return 1
    fi

    local status="NO_CHANGE"

    if grep -q "$INJECT_MARKER_START" "$CONFIG_FILE"; then
        log "lvl-6" "Found existing inject markers"
        if diff -q <(echo "$INJECT_CONTENT") <(sed -n "/$INJECT_MARKER_START/,/$INJECT_MARKER_END/p" "$CONFIG_FILE" | sed '1d;$d') >/dev/null; then
            log "lvl-7" "Content unchanged"
            echo "STATUS=${status}"
            return 0
        fi
        log "lvl-6" "Updating existing content"
        sed -i "/$INJECT_MARKER_START/,/$INJECT_MARKER_END/d" "$CONFIG_FILE"
        status="UPDATED"
    elif grep -Fxq "$INJECT_CONTENT" "$CONFIG_FILE"; then
        log "lvl-6" "Content already exists without markers"
        echo "STATUS=${status}"
        return 0
    else
        log "lvl-6" "Adding new content"
        status="ADDED"
    fi

    echo -e "\n$INJECT_MARKER_START\n$INJECT_CONTENT\n$INJECT_MARKER_END" >> "$CONFIG_FILE"
    log "lvl-6" "Content injection complete: ${status}"
    log "lvl-4" "STATUS=${status}"
    return 0
}

# 5. Restart shell
restart_shell() {
    log "lvl-5" "Preparing for shell restart"
    log "lvl-4" "STATUS=READY"
    return 0
}

# Script control functions
usage() {
    log "lvl-1" "Displaying usage information"
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
    log "lvl-2" "Parsing command line arguments"
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y)
                YES_FLAG=true
                log "lvl-3" "Non-interactive mode enabled"
                shift
                ;;
            -u|--user)
                TARGET_USER="$2"
                log "lvl-3" "Target user set to: ${TARGET_USER}"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                declare -g CONFIG_FILE
                log "lvl-3" "Config file set to: ${CONFIG_FILE}"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log "lvl-2" "Invalid argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

execute_functions() {
    log "lvl-2" "Starting function execution sequence"

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
        log "lvl-2" "No functions found to execute"
        return 1
    }

    # Ensure global scope for critical variables
    declare -g CONFIG_FILE
    declare -g TARGET_USER
    declare -g TARGET_HOME
    declare -g YES_FLAG
    declare -g LOG_LEVEL

    export CONFIG_FILE
    export TARGET_USER
    export TARGET_HOME
    export YES_FLAG
    export LOG_LEVEL

    for func in "${functions[@]}"; do
        log "lvl-3" "Step ${step_numbers[$func]}: ${func} ..."

        if ! declare -F "$func" >/dev/null; then
            log "lvl-2" "Function $func not found"
            continue
        fi

        # Create a temporary file for output capture
        local temp_output=$(mktemp)

        # Execute function in current shell context and capture output
        if ! eval "$func" > "$temp_output" 2>&1; then
            local ret=$?
            log "lvl-4" "\033[31m ✗\033[0m"
            if [[ -s "$temp_output" ]]; then
                cat "$temp_output"
            else
                echo "Failed with return code $ret"
            fi
            rm "$temp_output"
            return 1
        fi

        # Process output if any exists
        if [[ -s "$temp_output" ]]; then
            # First check for CONFIG= lines and process them
            while IFS= read -r line; do
                if [[ "$line" =~ ^CONFIG=(.*) ]]; then
                    CONFIG_FILE="${BASH_REMATCH[1]}"
                    export CONFIG_FILE
                fi
            done < "$temp_output"

            # Now display the output
            cat "$temp_output"
        fi

        # Clean up temp file
        rm "$temp_output"

        # Mark success
        log "lvl-4" "\033[32m ✓\033[0m"
        echo

    done

    log "lvl-2" "All functions executed successfully"
    return 0
}

source_base() {
    echo "Sourcing base folder: $BAS_DIR"
    echo

    # Get all files in the base directory (excluding directories)
    local base_files=()
    while IFS= read -r -d '' file; do
        # Only include regular files (not directories, symlinks, etc)
        if [[ -f "$file" ]]; then
            base_files+=("$file")
        fi
    done < <(find "$BAS_DIR" -maxdepth 1 -type f -print0)

    # Sort files to ensure consistent loading order
    IFS=$'\n' base_files=($(sort <<<"${base_files[*]}"))
    unset IFS

    # Track if we've successfully sourced at least one file
    local sourced_any=false

    # Source each file
    for file in "${base_files[@]}"; do
        local filename=$(basename "$file")
        if [[ -f "$file" && -r "$file" ]]; then
            source "$file"
            echo ". $file"
            sourced_any=true
            echo "Sourced: $filename"
        else
            echo "Could not source: $filename"
        fi
    done

    echo

    if [[ "$sourced_any" = false ]]; then
        echo "No base files were sourced from $BAS_DIR"
        return 1
    fi

    setup_error_handling
    echo "Base initialization complete"

    return 0
}

main() {
    init_config
    source_base
    setlog on
    setup_error_handling
    parse_arguments "$@"

    log "lvl-1" "Starting deployment process"
    echo "Starting deployment..."
    echo "Script Version: $SCRIPT_VERSION"
    echo
    echo "The following steps will be performed:"
    grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/'
    echo

    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Continue with these steps? [Y/n] " confirm
        if [[ "${confirm,,}" == "n" ]]; then
            log "lvl-1" "Deployment cancelled by user"
            exit 0
        fi
    fi
    echo

    if ! execute_functions; then
        log "lvl-1" "Deployment failed"
        echo "Deployment failed."
        exit 1
    fi

    echo
    log "lvl-1" "Deployment completed successfully"
    echo "Deployment completed. Press any key to restart shell..."
    read -n 1 -s
    exec "$SHELL"
}

trap 'error_handler $LINENO' ERR
trap 'exit' EXIT
main "$@"
