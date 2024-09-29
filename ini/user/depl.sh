#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LAB_DIR="$( cd "$SCRIPT_DIR/../.." &> /dev/null && pwd )"
TARGET_HOME=""
CONFIG_FILE=""

# 1. Initialize target user and home directory
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

# 2. Source usr.bash and configure environment
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

# 3. Set appropriate config file (.zshrc or .bashrc)
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

# 4. Inject content into config file
inject_content() {
    local start_marker="# START inject"
    local end_marker="# END inject"
    local temp_file=$(mktemp)

    if grep -q "$start_marker" "$CONFIG_FILE"; then
        # If injection markers exist, replace the content between them
        awk -v start="$start_marker" -v end="$end_marker" -v inject_file="$SCRIPT_DIR/inject" '
            $0 ~ start {print; system("cat " inject_file); f=1; next}
            $0 ~ end {f=0}
            !f
        ' "$CONFIG_FILE" > "$temp_file"
        mv "$temp_file" "$CONFIG_FILE"
        echo "Existing inject content in $CONFIG_FILE has been updated."
    else
        # If no injection markers exist, append the new content
        echo "" >> "$CONFIG_FILE"
        echo "$start_marker" >> "$CONFIG_FILE"
        cat "$SCRIPT_DIR/inject" >> "$CONFIG_FILE"
        echo "$end_marker" >> "$CONFIG_FILE"
        echo "New inject content added to $CONFIG_FILE"
    fi

    return 0
}

# Display operations and prompt for confirmation
display_operations() {
    echo "The following operations will be performed:"

    # Dynamically generate operation list from function comments
    grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# [0-9]+\. /• /'

    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
        y|Y ) return 0;;
        * ) return 1;;
    esac
}

# Main execution function
main() {
    local success=true

    if ! display_operations; then
        echo "Operation cancelled by user."
        exit 0
    fi

    # Create an array of function names, sorted by their number
    local functions=($(grep -E '^# [0-9]+\.' "$0" | sed -E 's/^# [0-9]+\. .+/\1/' | awk '{print $NF}'))

    # Loop through the functions and execute them
    for func in "${functions[@]}"; do
        echo "Executing: $func"
        if ! $func; then
            echo "Failed to execute $func."
            success=false
            break
        fi
    done

    if $success; then
        echo "All operations completed successfully."
        echo "Run 'source $CONFIG_FILE' to apply changes in the current session."
    else
        echo "Some operations failed. Please check the output above for details."
    fi
}

# Run the main function
main
