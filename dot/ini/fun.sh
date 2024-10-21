#!/bin/bash

# Numbered functions (main workflow)

# Check if deploy_log function is available
if ! command -v deploy_log &> /dev/null; then
    echo "Error: deploy_log function not found. Make sure start.sh is sourcing this file correctly."
    exit 1
fi

# 1. Check shell version - Verify Bash 4+ or Zsh 5+ is being used, exit if requirements not met
check_shell_version() {
    deploy_log "INFO" "Checking shell version compatibility..."
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
    deploy_log "INFO" "Initializing target user and home directory..."
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
    deploy_log "INFO" "Setting appropriate configuration file..."
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
    deploy_log "INFO" "Creating backup of configuration file..."
    local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    if [[ "$DRY_RUN" = false ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        deploy_log "INFO" "Created backup of config file: $backup_file"
    else
        deploy_log "DEBUG" "DRY RUN: Would create backup of config file: $backup_file"
    fi
}

# 5. Inject content into config file - Insert or update content between specific markers in config file
inject_content() {
    deploy_log "INFO" "Injecting content into configuration file..."
    local start_marker="# START inject"
    local end_marker="# END inject"
    local temp_file=$(mktemp)
    local inject_file="$SCRIPT_DIR/inject"

    if [[ ! -f "$inject_file" ]]; then
        deploy_log "ERROR" "Inject file not found: $inject_file"
        exit 1
    fi

    deploy_log "DEBUG" "Checking for existing injection markers in $CONFIG_FILE"
    if grep -q "$start_marker" "$CONFIG_FILE"; then
        deploy_log "INFO" "Existing injection markers found. Updating content."
        # If injection markers exist, replace the content between them
        awk -v start="$start_marker" -v end="$end_marker" -v inject_file="$inject_file" '
            $0 ~ start {print; system("cat " inject_file); f=1; next}
            $0 ~ end {f=0}
            !f
        ' "$CONFIG_FILE" > "$temp_file"

        if [[ "$DRY_RUN" = false ]]; then
            mv "$temp_file" "$CONFIG_FILE"
            deploy_log "INFO" "Updated existing inject content in $CONFIG_FILE"
        else
            deploy_log "DEBUG" "DRY RUN: Would update existing inject content in $CONFIG_FILE"
            rm "$temp_file"
        fi
    else
        deploy_log "INFO" "No existing injection markers found. Appending new content."
        # If no injection markers exist, append the new content
        if [[ "$DRY_RUN" = false ]]; then
            {
                echo ""
                echo "$start_marker"
                cat "$inject_file"
                echo "$end_marker"
            } >> "$CONFIG_FILE"
            deploy_log "INFO" "Added new inject content to $CONFIG_FILE"
        else
            deploy_log "DEBUG" "DRY RUN: Would add new inject content to $CONFIG_FILE"
        fi
    fi
    deploy_log "INFO" "Content injection completed."
}

# 6. Restart shell - Exit script to allow for shell restart, applying the new configuration
restart_shell() {
    if [[ "$DRY_RUN" = false ]]; then
        deploy_log "INFO" "Preparing to restart shell to apply changes..."
        deploy_log "DEBUG" "Exiting current script execution."
        exit 0
    else
        deploy_log "DEBUG" "DRY RUN: Would restart shell to apply changes."
    fi
}

deploy_log "DEBUG" "All functions in fun.sh have been defined with improved logging."
