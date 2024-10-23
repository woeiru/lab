#!/bin/bash

set -eo pipefail

# Initialize script variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_VERSION:-}" )" &> /dev/null && pwd )"
LAB_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
[[ -z "$BASE_INDENT" ]] && BASE_INDENT="  "

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

# 2. Initialize target user and home directory
init_target_user() {
    [[ -z "${TARGET_USER}" ]] && TARGET_USER=$(whoami)
    TARGET_HOME=$(eval echo ~$TARGET_USER)
    echo "USER=${TARGET_USER}, HOME=${TARGET_HOME}"
    [[ ! -d "$TARGET_HOME" ]] && return 1
    return 0
}

# 3. Set appropriate config file
set_config_file() {
    if [[ -n "${CONFIG_FILE:-}" ]]; then
        [[ ! -f "$CONFIG_FILE" ]] && return 1
    elif [[ -f "$TARGET_HOME/.zshrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.bashrc"
    else
        return 1
    fi
    echo "CONFIG=${CONFIG_FILE}"
    return 0
}

# 4. Create a backup of the config file
backup_config_file() {
    local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file" || return 1
    echo "BACKUP=${backup_file}"
    return 0
}

# 5. Inject content into config file
inject_content() {
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

# 6. Restart shell
restart_shell() {
    echo "STATUS=READY"
    return 0
}

# Script control functions
usage() {
    echo "Usage: $0 [-u|--user USER] [-c|--config FILE] [-h|--help]"
}

set_default_values() {
    TARGET_USER=$(whoami)
    TARGET_HOME=$(eval echo ~$TARGET_USER)

    if [[ -f "$TARGET_HOME/.zshrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
    else
        CONFIG_FILE="$TARGET_HOME/.bashrc"
    fi
}

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

    local comments=($(grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# [0-9]+\. //'))
    local i=0

    for func in "${functions[@]}"; do
        echo -n "Step $((i+1)): ${comments[$i]} ... "

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
            echo "  └─ Failed with return code $ret"
            return 1
        fi
        ((i++))
    done
    return 0
}

main() {
    [[ $# -eq 0 ]] && set_default_values || parse_arguments "$@"
    [[ -z "$TARGET_USER" || -z "$CONFIG_FILE" ]] && set_default_values

    echo "Starting deployment..."
    echo "The following steps will be performed:"
    grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# ([0-9]+)\. (.+)/\1. \2/'
    echo

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
