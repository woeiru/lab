#!/bin/bash

set -eo pipefail


# Initialize script variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_VERSION:-}" )" &> /dev/null && pwd )"
LAB_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
[[ -z "$BASE_INDENT" ]] && BASE_INDENT="  "
YES_FLAG=false
TARGET_USER=""
TARGET_HOME=""
CONFIG_FILE=""

# 1. Check shell version - Verify Bash 4+ or Zsh 5+ is being used
check_shell_version() {
    log "lvl-1" "Checking shell version"
    if [[ -n "${BASH_VERSION:-}" ]]; then
        log "lvl-2" "Detected BASH ${BASH_VERSION}"
        [[ "${BASH_VERSION:0:1}" -lt 4 ]] && {
            log "lvl-1" "Unsupported Bash version"
            return 1
        }
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        log "lvl-2" "Detected ZSH ${ZSH_VERSION}"
        [[ "${ZSH_VERSION:0:1}" -lt 5 ]] && {
            log "lvl-1" "Unsupported Zsh version"
            return 1
        }
    else
        log "lvl-1" "Unknown shell detected"
        return 1
    fi
    return 0
}

# 2. Initialize target user and home directory
init_target_user() {
    local default_user=$(whoami)
    log "lvl-1" "Initializing target user"

    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Enter target user (default: $default_user): " input_user
        TARGET_USER=${input_user:-$default_user}
    else
        TARGET_USER=$default_user
    fi

    TARGET_HOME=$(eval echo ~$TARGET_USER)
    if [[ ! -d "$TARGET_HOME" ]]; then
        log "lvl-1" "Home directory $TARGET_HOME does not exist"
        return 1
    fi
    log "lvl-2" "Selected user: ${TARGET_USER}"
    log "lvl-2" "Home directory: ${TARGET_HOME}"
    echo "USER=${TARGET_USER}, HOME=${TARGET_HOME}"
    return 0
}

# 3. Set appropriate config file
set_config_file() {
    log "lvl-1" "Setting configuration file"
    if [[ -z "$TARGET_HOME" ]]; then
        TARGET_HOME=$(eval echo ~$(whoami))
        log "lvl-2" "Using default home directory: ${TARGET_HOME}"
    fi

    local default_config=""

    # Check for config files
    if [[ -f "$TARGET_HOME/.zshrc" ]]; then
        default_config="$TARGET_HOME/.zshrc"
        log "lvl-3" "Found .zshrc configuration file"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        default_config="$TARGET_HOME/.bashrc"
        log "lvl-3" "Found .bashrc configuration file"
    else
        default_config="$TARGET_HOME/.bashrc"
        log "lvl-3" "Using default .bashrc configuration file"
    fi

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
            log "lvl-1" "Directory $config_dir does not exist"
            return 1
        fi
        if [[ ! -w "$config_dir" ]]; then
            log "lvl-1" "Cannot write to directory $config_dir"
            return 1
        fi
        # Create empty config file
        if ! touch "$CONFIG_FILE"; then
            log "lvl-1" "Failed to create config file $CONFIG_FILE"
            return 1
        fi
        log "lvl-2" "Created new config file: $CONFIG_FILE"
    fi

    export CONFIG_FILE
    log "lvl-2" "Using config file: ${CONFIG_FILE}"
    echo "CONFIG=${CONFIG_FILE}"
    return 0
}

# 4. Inject content into config file
inject_content() {
    log "lvl-1" "Injecting content into config file"
    if [[ -z "$CONFIG_FILE" ]]; then
        log "lvl-1" "No config file specified"
        return 1
    fi

    local start_marker="# START inject"
    local end_marker="# END inject"
    local inject_content=". ~/lab/dot/rc"
    local status="NO_CHANGE"

    if grep -q "$start_marker" "$CONFIG_FILE"; then
        log "lvl-2" "Found existing inject markers"
        if diff -q <(echo "$inject_content") <(sed -n "/$start_marker/,/$end_marker/p" "$CONFIG_FILE" | sed '1d;$d') >/dev/null; then
            log "lvl-3" "Content unchanged"
            echo "STATUS=${status}"
            return 0
        fi
        log "lvl-2" "Updating existing content"
        sed -i "/$start_marker/,/$end_marker/d" "$CONFIG_FILE"
        status="UPDATED"
    elif grep -Fxq "$inject_content" "$CONFIG_FILE"; then
        log "lvl-2" "Content already exists without markers"
        echo "STATUS=${status}"
        return 0
    else
        log "lvl-2" "Adding new content"
        status="ADDED"
    fi

    echo -e "\n$start_marker\n$inject_content\n$end_marker" >> "$CONFIG_FILE"
    log "lvl-2" "Content injection complete: ${status}"
    echo "STATUS=${status}"
    return 0
}

# 5. Restart shell
restart_shell() {
    log "lvl-1" "Preparing for shell restart"
    echo "STATUS=READY"
    return 0
}

# Script control functions
usage() {
    log "lvl-1" "Displaying usage information"
    echo "Usage: $0 [-y] [-u|--user USER] [-c|--config FILE] [-h|--help]"
    echo "  -y          Non-interactive mode (yes to all prompts)"
    echo "  -u, --user  Specify target user"
    echo "  -c, --config Specify config file"
    echo "  -h, --help  Show this help message"
}

parse_arguments() {
    log "lvl-1" "Parsing command line arguments"
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y)
                YES_FLAG=true
                log "lvl-2" "Non-interactive mode enabled"
                shift
                ;;
            -u|--user)
                TARGET_USER="$2"
                log "lvl-2" "Target user set to: ${TARGET_USER}"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                export CONFIG_FILE
                log "lvl-2" "Config file set to: ${CONFIG_FILE}"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log "lvl-1" "Invalid argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

execute_functions() {
    log "lvl-1" "Starting function execution sequence"
    local functions=($(grep -E '^# [0-9]+\.' "$0" |
                      sed -E 's/^# ([0-9]+)\. .*/\1 /' |
                      paste -d' ' - <(grep -A1 -E '^# [0-9]+\.' "$0" |
                                    grep -E '^[a-z_]+[a-z0-9_-]*\(\)' |
                                    sed 's/().*//') |
                      sort -n |
                      cut -d' ' -f2-))

    local i=0

    for func in "${functions[@]}"; do
        log "lvl-2" "Executing function: ${func}"
        echo -n "Step $((i+1)): ${func} ... "

        local output
        output=$(eval "$func")
        local ret=$?

        if [ $ret -eq 0 ]; then
            echo -e "\033[32m✓\033[0m"
            log "lvl-3" "Function ${func} completed successfully"
            if [ -n "$output" ]; then
                echo "  └─ $output"
                log "lvl-4" "Output: ${output}"
            fi
        else
            echo -e "\033[31m✗\033[0m"
            log "lvl-1" "Function ${func} failed with return code ${ret}"
            if [ -n "$output" ]; then
                echo "  └─ $output"
                log "lvl-2" "Error output: ${output}"
            else
                echo "  └─ Failed with return code $ret"
            fi
            return 1
        fi
        ((i++))
    done
    log "lvl-1" "All functions executed successfully"
    return 0
}

# Source error and logging handlers
source_environment() {
    local env_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../env" &> /dev/null && pwd)"
    echo "Sourcing environment folder: $env_dir"

    # First source error and log handlers specifically
    if [ -f "$env_dir/err" ]; then
        source "$env_dir/err"
        echo ". $env_dir/err"
    else
        echo "Error handler not found at $env_dir/err"
        return 1
    fi

    if [ -f "$env_dir/log" ]; then
        source "$env_dir/log"
        echo ". $env_dir/log"
    else
        echo "Logger not found at $env_dir/log"
        return 1
    fi

    # Now we can use logging and error handling
    setup_error_handling
    log "lvl-1" "Error handling and logging initialized"

    return 0
}

# Main function
main() {
    # First source the environment to get error and logging functions
    source_environment

    # Enable all logging levels
    setlog on

    # Now we can set up error handling and use logging
    setup_error_handling

    parse_arguments "$@"

    log "lvl-1" "Starting deployment process"
    echo "Starting deployment..."
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

    if ! execute_functions; then
        log "lvl-1" "Deployment failed"
        echo "Deployment failed."
        exit 1
    fi

    log "lvl-1" "Deployment completed successfully"
    echo "Deployment completed. Press any key to restart shell..."
    read -n 1 -s
    exec "$SHELL"
}

trap 'error_handler $LINENO' ERR
trap 'exit' EXIT
main "$@"
