#!/bin/bash

# Numbered functions (main workflow)

# Check if deploy_log function is available
if ! command -v deploy_log &> /dev/null; then
    echo "Error: deploy_log function not found. Make sure depl.sh is sourcing this file correctly."
    exit 1
fi

# Check if INJECT_FILE is set
if [[ -z "$INJECT_FILE" ]]; then
    echo "Error: INJECT_FILE is not set. Make sure depl.sh is exporting this variable."
    exit 1
fi

# 1. Check shell version - Verify Bash 4+ or Zsh 5+ is being used, exit if requirements not met
check_shell_version() {
    if [[ -n "${BASH_VERSION:-}" ]]; then
        deploy_log "DEBUG" "Detected Bash version: $BASH_VERSION"
        if [[ "${BASH_VERSION:0:1}" -lt 4 ]]; then
            deploy_log "ERROR" "This script requires Bash version 4 or higher. Current version: $BASH_VERSION"
            exit 1
        else
            deploy_log "INFO" "Bash version $BASH_VERSION is compatible with this script."
        fi
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        deploy_log "DEBUG" "Detected Zsh version: $ZSH_VERSION"
        if [[ "${ZSH_VERSION:0:1}" -lt 5 ]]; then
            deploy_log "ERROR" "This script requires Zsh version 5 or higher. Current version: $ZSH_VERSION"
            exit 1
        else
            deploy_log "INFO" "Zsh version $ZSH_VERSION is compatible with this script."
        fi
    else
        deploy_log "ERROR" "Unsupported shell detected. This script must be run in Bash or Zsh."
        exit 1
    fi
    deploy_log "INFO" "Shell version check completed successfully."
}

# 2. Initialize target user and home directory - Set TARGET_USER and TARGET_HOME, handle root user case
init_target_user() {
    if [[ -z "${TARGET_USER}" ]]; then
        TARGET_USER=$(whoami)
        deploy_log "INFO" "No user specified. Using current user: $TARGET_USER"
    else
        deploy_log "INFO" "User specified via argument: $TARGET_USER"
    fi

    if [[ "$TARGET_USER" = "root" ]]; then
        TARGET_HOME=$(eval echo ~root)
        deploy_log "DEBUG" "Root user detected. Setting TARGET_HOME to: $TARGET_HOME"
    else
        TARGET_HOME=$(eval echo ~$TARGET_USER)
        deploy_log "DEBUG" "Non-root user detected. Setting TARGET_HOME to: $TARGET_HOME"
    fi

    if [[ ! -d "$TARGET_HOME" ]]; then
        deploy_log "ERROR" "Home directory for user $TARGET_USER not found: $TARGET_HOME"
        exit 1
    fi
    deploy_log "INFO" "Target user set to: $TARGET_USER"
    deploy_log "INFO" "Target home directory set to: $TARGET_HOME"
}

# 3. Set appropriate config file - Determine whether to use .zshrc or .bashrc based on availability
set_config_file() {
    if [[ -n "${CONFIG_FILE:-}" ]]; then
        if [[ ! -f "$CONFIG_FILE" ]]; then
            deploy_log "ERROR" "Specified config file not found: $CONFIG_FILE"
            exit 1
        fi
        deploy_log "INFO" "Using specified config file: $CONFIG_FILE"
    elif [[ -f "$TARGET_HOME/.zshrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
        deploy_log "INFO" "Found .zshrc, using as config file: $CONFIG_FILE"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.bashrc"
        deploy_log "INFO" "Found .bashrc, using as config file: $CONFIG_FILE"
    else
        deploy_log "ERROR" "No suitable configuration file found in $TARGET_HOME"
        exit 1
    fi
    deploy_log "INFO" "Configuration file set to: $CONFIG_FILE"
}

# 4. Create a backup of the config file - Generate timestamped backup before making changes
backup_config_file() {
    local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    deploy_log "INFO" "Created backup of config file: $backup_file"
}

# 5. Inject content into config file - Insert or update content between specific markers in config file
inject_content() {
    local start_marker="# START inject"
    local end_marker="# END inject"
    local temp_file=$(mktemp)
    local inject_file="$SCRIPT_DIR/$INJECT_FILE"

    if [[ ! -f "$inject_file" ]]; then
        deploy_log "ERROR" "Inject file not found: $inject_file"
        exit 1
    fi

    deploy_log "DEBUG" "Checking for existing injection markers in $CONFIG_FILE"
    if grep -q "$start_marker" "$CONFIG_FILE"; then
        deploy_log "INFO" "Existing injection markers found. Checking for changes..."
        # Extract existing content between markers
        sed -n "/$start_marker/,/$end_marker/p" "$CONFIG_FILE" > "$temp_file"

        # Compare existing content with new content
        if diff -q <(sed '1d;$d' "$temp_file") "$inject_file" >/dev/null; then
            deploy_log "INFO" "No changes detected. Skipping injection."
            rm "$temp_file"
            return 0
        else
            deploy_log "INFO" "Changes detected. Updating content."
            # Replace content between markers
            sed -i "/$start_marker/,/$end_marker/d" "$CONFIG_FILE"
            sed -i "/$start_marker/r $inject_file" "$CONFIG_FILE"
            deploy_log "INFO" "Updated existing inject content in $CONFIG_FILE"
        fi
    else
        deploy_log "INFO" "No existing injection markers found. Checking for duplicate content..."
        if grep -Fxq "$(cat "$inject_file")" "$CONFIG_FILE"; then
            deploy_log "INFO" "Content already exists. Skipping injection."
            return 0
        else
            deploy_log "INFO" "Appending new content."
            # Append new content with markers
            {
                echo ""
                echo "$start_marker"
                cat "$inject_file"
                echo "$end_marker"
            } >> "$CONFIG_FILE"
            deploy_log "INFO" "Added new inject content to $CONFIG_FILE"
        fi
    fi

    rm "$temp_file"
    deploy_log "INFO" "Content injection completed."
}

# 6. Restart shell - Exit script to allow for shell restart, applying the new configuration
restart_shell() {
    deploy_log "DEBUG" "Exiting current script execution."
    exit 0
}
