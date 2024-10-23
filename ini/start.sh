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
    if [[ -n "${BASH_VERSION:-}" ]]; then
        echo "BASH ${BASH_VERSION}"
        [[ "${BASH_VERSION:0:1}" -lt 4 ]] && return 1
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "ZSH ${ZSH_VERSION}"
        [[ "${ZSH_VERSION:0:1}" -lt 5 ]] && return 1
    else
        echo "UNKNOWN SHELL"
        return 1
    fi
    return 0
}

# 1. Source environment files
source_environment() {
    local env_dir="$LAB_DIR/env"  # Use env directory at same level as dot
    echo "Sourcing environment folder: $env_dir"

    if [ -d "$env_dir" ]; then
        # Source all files in env directory
        for file in "$env_dir"/*; do
            if [ -f "$file" ]; then
                if [[ -f "$file" ]]; then
                    source "$file"
                    echo "Source $file"
                else
                    echo "Warning: File $file not found." >&2
                fi
            fi
        done
    else
        # Log warning if env folder is missing
        echo "Folder $env_dir not found. Skipping."
    fi
    return 0
}

# 2. Initialize target user and home directory
init_target_user() {
    local default_user=$(whoami)

    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Enter target user (default: $default_user): " input_user
        TARGET_USER=${input_user:-$default_user}
    else
        TARGET_USER=$default_user
    fi

    TARGET_HOME=$(eval echo ~$TARGET_USER)
    [[ ! -d "$TARGET_HOME" ]] && {
        echo "Error: Home directory $TARGET_HOME does not exist"
        return 1
    }
    echo "USER=${TARGET_USER}, HOME=${TARGET_HOME}"
    return 0
}

# 3. Set appropriate config file
set_config_file() {
    # Ensure TARGET_HOME is set
    if [[ -z "$TARGET_HOME" ]]; then
        TARGET_HOME=$(eval echo ~$(whoami))
    fi

    local default_config=""

    # Check for config files
    if [[ -f "$TARGET_HOME/.zshrc" ]]; then
        default_config="$TARGET_HOME/.zshrc"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        default_config="$TARGET_HOME/.bashrc"
    else
        default_config="$TARGET_HOME/.bashrc"
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
            echo "Error: Directory $config_dir does not exist"
            return 1
        fi
        if [[ ! -w "$config_dir" ]]; then
            echo "Error: Cannot write to directory $config_dir"
            return 1
        fi
        # Create empty config file
        touch "$CONFIG_FILE" || {
            echo "Error: Failed to create config file $CONFIG_FILE"
            return 1
        }
        echo "Created new config file: $CONFIG_FILE"
    fi

    # Export CONFIG_FILE for other functions to use
    export CONFIG_FILE
    echo "CONFIG=${CONFIG_FILE}"
    return 0
}

# 4. Inject content into config file
inject_content() {
    # Read CONFIG_FILE from environment
    if [[ -z "$CONFIG_FILE" ]]; then
        echo "Error: No config file specified"
        return 1
    fi

    local start_marker="# START inject"
    local end_marker="# END inject"
    local inject_content=". ~/lab/dot/rc"
    local status="NO_CHANGE"

    if grep -q "$start_marker" "$CONFIG_FILE"; then
        if diff -q <(echo "$inject_content") <(sed -n "/$start_marker/,/$end_marker/p" "$CONFIG_FILE" | sed '1d;$d') >/dev/null; then
            echo "STATUS=${status}"
            return 0
        fi
        sed -i "/$start_marker/,/$end_marker/d" "$CONFIG_FILE"
        status="UPDATED"
    elif grep -Fxq "$inject_content" "$CONFIG_FILE"; then
        echo "STATUS=${status}"
        return 0
    else
        status="ADDED"
    fi

    echo -e "\n$start_marker\n$inject_content\n$end_marker" >> "$CONFIG_FILE"
    echo "STATUS=${status}"
    return 0
}

# 5. Restart shell
restart_shell() {
    echo "STATUS=READY"
    return 0
}

# Script control functions
usage() {
    echo "Usage: $0 [-y] [-u|--user USER] [-c|--config FILE] [-h|--help]"
    echo "  -y          Non-interactive mode (yes to all prompts)"
    echo "  -u, --user  Specify target user"
    echo "  -c, --config Specify config file"
    echo "  -h, --help  Show this help message"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y)
                YES_FLAG=true
                shift
                ;;
            -u|--user)
                TARGET_USER="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                export CONFIG_FILE
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                usage
                exit 1
                ;;
        esac
    done
}

execute_functions() {
    local functions=($(grep -E '^# [0-9]+\.' "$0" |
                      sed -E 's/^# ([0-9]+)\. .*/\1 /' |
                      paste -d' ' - <(grep -A1 -E '^# [0-9]+\.' "$0" |
                                    grep -E '^[a-z_]+[a-z0-9_-]*\(\)' |
                                    sed 's/().*//') |
                      sort -n |
                      cut -d' ' -f2-))

    local i=0

    for func in "${functions[@]}"; do
        echo -n "Step $((i+1)): ${func} ... "

        # Capture both output and return value
        local output
        output=$(eval "$func")
        local ret=$?

        if [ $ret -eq 0 ]; then
            echo -e "\033[32m✓\033[0m"  # Green checkmark
            if [ -n "$output" ]; then
                echo "  └─ $output"
            fi
        else
            echo -e "\033[31m✗\033[0m"  # Red X
            if [ -n "$output" ]; then
                echo "  └─ $output"
            else
                echo "  └─ Failed with return code $ret"
            fi
            return 1
        fi
        ((i++))
    done
    return 0
}

main() {
    parse_arguments "$@"

    echo "Starting deployment..."
    echo "The following steps will be performed:"
    grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/'
    echo

    # Early continuation prompt if not in -y mode
    if [[ "$YES_FLAG" == "false" ]]; then
        read -p "Continue with these steps? [Y/n] " confirm
        [[ "${confirm,,}" == "n" ]] && exit 0
    fi

    if ! execute_functions; then
        echo "Deployment failed."
        exit 1
    fi

    echo "Deployment completed. Press any key to restart shell..."
    read -n 1 -s
    exec "$SHELL"
}

trap 'exit' EXIT
main "$@"
