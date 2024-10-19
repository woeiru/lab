#!/bin/bash

# Numbered functions (main workflow)

# 1. Check shell version - Verify Bash 4+ or Zsh 5+ is being used, exit if requirements not met
check_shell_version() {
    log "DEBUG" "Entering function: ${FUNCNAME[0]}"
    if [[ -n "${BASH_VERSION:-}" ]]; then
        if [[ "${BASH_VERSION:0:1}" -lt 4 ]]; then
            log "ERROR" "This script requires Bash version 4 or higher."
            exit 1
        fi
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        if [[ "${ZSH_VERSION:0:1}" -lt 5 ]]; then
            log "ERROR" "This script requires Zsh version 5 or higher."
            exit 1
        fi
    else
        log "ERROR" "This script must be run in Bash or Zsh."
        exit 1
    fi
}

# 2. Initialize target user and home directory - Set TARGET_USER and TARGET_HOME, handle root user case
init_target_user() {
    log "DEBUG" "Entering function: ${FUNCNAME[0]}"
    if [[ -z "${TARGET_USER}" ]]; then
        TARGET_USER=$(whoami)
        log "INFO" "No user specified. Using current user: $TARGET_USER"
    else
        log "INFO" "User specified via -u/--user argument: $TARGET_USER"
    fi

    if [[ "$TARGET_USER" = "root" ]]; then
        TARGET_HOME=$(eval echo ~root)
    else
        TARGET_HOME=$(eval echo ~$TARGET_USER)
    fi

    if [[ ! -d "$TARGET_HOME" ]]; then
        log "ERROR" "Home directory for user $TARGET_USER not found."
        exit 1
    fi
    log "INFO" "Target user set to: $TARGET_USER"
    log "INFO" "Target home directory set to: $TARGET_HOME"
}

# 3. Source usr.bash and configure environment - Load user settings, set up Git and SSH if applicable
configure_environment() {
    log "DEBUG" "Entering function: ${FUNCNAME[0]}"
    local USR_BASH_PATH="$LAB_DIR/lib/usr.bash"
    if [[ -f "$USR_BASH_PATH" ]]; then
        source "$USR_BASH_PATH"
        log "INFO" "Sourced usr.bash from $USR_BASH_PATH"
        if declare -f usr-cgp > /dev/null; then
            if [[ "$DRY_RUN" = false ]]; then
                usr-cgp
                log "INFO" "Configured Git and SSH settings."
            else
                log "DRY-RUN" "Would configure Git and SSH settings."
            fi
        else
            log "ERROR" "usr-cgp function not found in usr.bash"
        fi
    else
        log "ERROR" "$USR_BASH_PATH not found."
    fi
    log "INFO" "Git global configuration updated to disable password prompting."
    log "INFO" "SSH configuration already contains ASKPASS setting."
    log "INFO" "configure_git_ssh_passphrase: Git and SSH configurations have been updated."
}

# 4. Set appropriate config file - Determine whether to use .zshrc or .bashrc based on availability
set_config_file() {
    log "DEBUG" "Entering function: ${FUNCNAME[0]}"
    if [[ -n "${CONFIG_FILE:-}" ]]; then
        if [[ ! -f "$CONFIG_FILE" ]]; then
            log "ERROR" "Specified config file $CONFIG_FILE not found."
            exit 1
        fi
    elif [[ -f "$TARGET_HOME/.zshrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.bashrc"
    else
        log "ERROR" "Neither .zshrc nor .bashrc found in $TARGET_HOME."
        exit 1
    fi
    log "INFO" "Using config file: $CONFIG_FILE"
}

# 5. Create a backup of the config file - Generate timestamped backup before making changes
backup_config_file() {
    log "DEBUG" "Entering function: ${FUNCNAME[0]}"
    local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    if [[ "$DRY_RUN" = false ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        log "INFO" "Created backup of config file: $backup_file"
    else
        log "DRY-RUN" "Would create backup of config file: $backup_file"
    fi
}

# 6. Inject content into config file - Insert or update content between specific markers in config file
inject_content() {
    log "DEBUG" "Entering function: ${FUNCNAME[0]}"
    local start_marker="# START inject"
    local end_marker="# END inject"
    local temp_file=$(mktemp)
    local inject_file="$SCRIPT_DIR/inject"

    if [[ ! -f "$inject_file" ]]; then
        log "ERROR" "Inject file not found: $inject_file"
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
            log "INFO" "Updated existing inject content in $CONFIG_FILE"
        else
            log "DRY-RUN" "Would update existing inject content in $CONFIG_FILE"
            rm "$temp_file"
        fi
    else
        # If no injection markers exist, append the new content
        if [[ "$DRY_RUN" = false ]]; then
            echo "" >> "$CONFIG_FILE"
            echo "$start_marker" >> "$CONFIG_FILE"
            cat "$inject_file" >> "$CONFIG_FILE"
            echo "$end_marker" >> "$CONFIG_FILE"
            log "INFO" "Added new inject content to $CONFIG_FILE"
        else
            log "DRY-RUN" "Would add new inject content to $CONFIG_FILE"
        fi
    fi
}

# 7. Restart shell - Exit script to allow for shell restart, applying the new configuration
restart_shell() {
    log "DEBUG" "Entering function: ${FUNCNAME[0]}"
    if [[ "$DRY_RUN" = false ]]; then
        log "INFO" "Restarting shell to apply changes..."
        log "INFO" "Shell will be restarted. Script is about to exit."
        exit 0
    else
        log "DRY-RUN" "Would restart shell to apply changes."
    fi
}
