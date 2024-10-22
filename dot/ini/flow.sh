#!/bin/bash

# flow.sh

# Numbered functions (main workflow)

# Check if print functions are available
if ! declare -F print_message >/dev/null || ! declare -F print_box >/dev/null; then
    echo "Error: print functions not found. Make sure depl.sh is sourcing this file correctly."
    exit 1
fi

# Check if INJECT_FILE is set
if [[ -z "$INJECT_FILE" ]]; then
    echo "Error: INJECT_FILE is not set. Make sure depl.sh is exporting this variable."
    exit 1
fi

# Check if BASE_INDENT is set, if not set a default
if [[ -z "$BASE_INDENT" ]]; then
    BASE_INDENT="          "  # 10 spaces to match the output
fi

# 1. Check shell version - Verify Bash 4+ or Zsh 5+ is being used, exit if requirements not met
check_shell_version() {
    print_message "Checking shell version..."
    if [[ -n "${BASH_VERSION:-}" ]]; then
        print_message "Detected Bash version: $BASH_VERSION"
        if [[ "${BASH_VERSION:0:1}" -lt 4 ]]; then
            print_message "This script requires Bash version 4 or higher. Current version: $BASH_VERSION"
            return 1
        fi
        print_message "Bash version $BASH_VERSION is compatible with this script."
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        print_message "Detected Zsh version: $ZSH_VERSION"
        if [[ "${ZSH_VERSION:0:1}" -lt 5 ]]; then
            print_message "This script requires Zsh version 5 or higher. Current version: $ZSH_VERSION"
            return 1
        fi
        print_message "Zsh version $ZSH_VERSION is compatible with this script."
    else
        print_message "Unsupported shell detected. This script must be run in Bash or Zsh."
        return 1
    fi
    print_message "Shell version check completed successfully."
    return 0
}

# 2. Initialize target user and home directory - Set TARGET_USER and TARGET_HOME, handle root user case
init_target_user() {
    print_message "Initializing target user..."
    if [[ -z "${TARGET_USER}" ]]; then
        TARGET_USER=$(whoami)
        print_message "No user specified. Using current user: $TARGET_USER"
    else
        print_message "User specified via argument: $TARGET_USER"
    fi

    if [[ "$TARGET_USER" = "root" ]]; then
        TARGET_HOME=$(eval echo ~root)
        print_message "Root user detected. Setting TARGET_HOME to: $TARGET_HOME"
    else
        TARGET_HOME=$(eval echo ~$TARGET_USER)
        print_message "Non-root user detected. Setting TARGET_HOME to: $TARGET_HOME"
    fi

    if [[ ! -d "$TARGET_HOME" ]]; then
        print_message "Home directory for user $TARGET_USER not found: $TARGET_HOME"
        return 1
    fi
    print_message "Target user set to: $TARGET_USER"
    print_message "Target home directory set to: $TARGET_HOME"
    return 0
}

# 3. Set appropriate config file - Determine whether to use .zshrc or .bashrc based on availability
set_config_file() {
    print_message "Setting appropriate config file..."
    if [[ -n "${CONFIG_FILE:-}" ]]; then
        if [[ ! -f "$CONFIG_FILE" ]]; then
            print_message "Specified config file not found: $CONFIG_FILE"
            return 1
        fi
        print_message "Using specified config file: $CONFIG_FILE"
    elif [[ -f "$TARGET_HOME/.zshrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
        print_message "Found .zshrc, using as config file: $CONFIG_FILE"
    elif [[ -f "$TARGET_HOME/.bashrc" ]]; then
        CONFIG_FILE="$TARGET_HOME/.bashrc"
        print_message "Found .bashrc, using as config file: $CONFIG_FILE"
    else
        print_message "No suitable configuration file found in $TARGET_HOME"
        return 1
    fi
    print_message "Configuration file set to: $CONFIG_FILE"
    return 0
}

# 4. Create a backup of the config file - Generate timestamped backup before making changes
backup_config_file() {
    print_message "Creating a backup of the config file..."
    local backup_file="${CONFIG_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
    if ! cp "$CONFIG_FILE" "$backup_file"; then
        print_message "Failed to create backup file: $backup_file"
        return 1
    fi
    print_message "Created backup of config file: $backup_file"
    return 0
}

# 5. Inject content into config file - Insert or update content between specific markers in config file
inject_content() {
    print_message "Injecting content into the config file..."
    local start_marker="# START inject"
    local end_marker="# END inject"
    local temp_file=$(mktemp)
    local inject_file="$SCRIPT_DIR/$INJECT_FILE"

    if [[ ! -f "$inject_file" ]]; then
        print_message "Inject file not found: $inject_file"
        return 1
    fi

    print_message "Checking for existing injection markers in $CONFIG_FILE"
    if grep -q "$start_marker" "$CONFIG_FILE"; then
        print_message "Existing injection markers found. Checking for changes..."
        sed -n "/$start_marker/,/$end_marker/p" "$CONFIG_FILE" > "$temp_file"

        if diff -q <(sed '1d;$d' "$temp_file") "$inject_file" >/dev/null; then
            print_message "No changes detected. Skipping injection."
            rm "$temp_file"
            return 0
        fi

        print_message "Changes detected. Updating content."
        sed -i "/$start_marker/,/$end_marker/d" "$CONFIG_FILE"
        print_message "Updated existing inject content in $CONFIG_FILE"
    else
        print_message "No existing injection markers found. Checking for duplicate content..."
        if grep -Fxq "$(cat "$inject_file")" "$CONFIG_FILE"; then
            print_message "Content already exists. Skipping injection."
            return 0
        fi
        print_message "Appending new content."
    fi

    {
        echo ""
        echo "$start_marker"
        cat "$inject_file"
        echo "$end_marker"
    } >> "$CONFIG_FILE"

    rm "$temp_file"
    print_message "Content injection completed successfully."
    return 0
}

# 6. Restart shell - Exit script to allow for shell restart, applying the new configuration
restart_shell() {
    print_message "Shell restart initiated."
    return 0
}
