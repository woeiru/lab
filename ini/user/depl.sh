#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LAB_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
TARGET_HOME=""
CONFIG_FILE=""

init_target_user() {
    if [ "$EUID" -eq 0 ]; then
        echo "Running as root. Please enter the target user's username (or 'root' for the root user):"
        read TARGET_USER
        if [ "$TARGET_USER" = "root" ]; then
            TARGET_HOME=$(eval echo ~root)
        else
            TARGET_HOME=$(eval echo ~$TARGET_USER)
        fi

        if [ ! -d "$TARGET_HOME" ]; then
            echo "Error: Home directory for user $TARGET_USER not found."
            return 1
        fi
    else
        TARGET_HOME="$HOME"
    fi
    echo "Target home directory set to: $TARGET_HOME"
    return 0
}

configure_environment() {
    USR_BASH_PATH="$LAB_DIR/lib/usr.bash"
    if [ -f "$USR_BASH_PATH" ]; then
        source "$USR_BASH_PATH"
        echo "Sourced usr.bash from $USR_BASH_PATH"
        if declare -f usr-cgp > /dev/null; then
            usr-cgp
            echo "Configured Git and SSH settings."
            return 0
        else
            echo "Warning: usr-cgp function not found in usr.bash"
            return 1
        fi
    else
        echo "Warning: $USR_BASH_PATH not found."
        return 1
    fi
}

set_config_file() {
    if [ -f "$TARGET_HOME/.zshrc" ]; then
        CONFIG_FILE="$TARGET_HOME/.zshrc"
    elif [ -f "$TARGET_HOME/.bashrc" ]; then
        CONFIG_FILE="$TARGET_HOME/.bashrc"
    else
        echo "Neither .zshrc nor .bashrc found in $TARGET_HOME."
        return 1
    fi
    return 0
}

inject_content() {
    if grep -q "# START inject" "$CONFIG_FILE"; then
        echo "inject content already exists in $CONFIG_FILE. Skipping."
        return 0
    else
        echo "" >> "$CONFIG_FILE"
        echo "# START inject" >> "$CONFIG_FILE"
        cat "$SCRIPT_DIR/inject" >> "$CONFIG_FILE"
        echo "# END inject" >> "$CONFIG_FILE"
        echo "inject content added to $CONFIG_FILE"
        return 0
    fi
}

display_operations() {
    echo "The following operations will be performed:"
    echo "• Initialize target user and home directory"
    echo "• Source usr.bash and configure environment"
    echo "• Set appropriate config file (.zshrc or .bashrc)"
    echo "• Inject content into config file"

    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) return 0;;
        * ) return 1;;
    esac
}

main() {
    local success=true

    if ! display_operations; then
        echo "Operation cancelled by user."
        exit 0
    fi

    if ! init_target_user; then
        echo "Failed to initialize target user."
        success=false
    fi

    if ! configure_environment; then
        echo "Failed to configure environment."
        success=false
    fi

    if ! set_config_file; then
        echo "Failed to set config file."
        success=false
    fi

    if ! inject_content; then
        echo "Failed to inject content."
        success=false
    fi

    if $success; then
        echo "All operations completed successfully."
        echo "Run 'source $CONFIG_FILE' to apply changes in the current session."
    else
        echo "Some operations failed. Please check the output above for details."
    fi
}

main
