#!/bin/bash

change_konsole_profile() {
    local profile_number="$1"
    local username
    local konsolerc_path
    local profile_name

    username=$(whoami)
    echo "Changing Konsole profile for user: $username"

    if [ "$username" = "root" ]; then
        konsolerc_path="/root/.config/konsolerc"
    else
        konsolerc_path="$HOME/.config/konsolerc"
    fi

    if [ ! -f "$konsolerc_path" ]; then
        echo "Error: Konsole configuration file not found at $konsolerc_path"
        return 1
    fi

    if ! [[ "$profile_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid profile number. Please provide a positive integer."
        return 1
    fi

    profile_name="Profile $profile_number"
    if ! grep -q "$profile_name" "$konsolerc_path"; then
        echo "Error: Profile $profile_number does not exist in $konsolerc_path"
        return 1
    fi

    if sed -i '/^\[Desktop Entry\]/,/^\[/ s/^DefaultProfile=.*/DefaultProfile=Profile '"$profile_number"'.profile/' "$konsolerc_path"; then
        echo "Konsole default profile updated to Profile $profile_number for user $username."
    else
        echo "Error: Failed to update Konsole profile for user $username."
        return 1
    fi
}

configure_git_ssh_passphrase() {
    local ssh_config="$HOME/.ssh/config"
    local askpass_line="    SetEnv SSH_ASKPASS=''"

    # Set Git configuration
    if git config --global core.askPass ""; then
        echo "Git global configuration updated to disable password prompting."
    else
        echo "Error: Failed to update Git configuration."
        return 1
    fi

    # Update SSH config
    if [ ! -f "$ssh_config" ]; then
        mkdir -p "$HOME/.ssh"
        touch "$ssh_config"
        chmod 600 "$ssh_config"
    fi

    if ! grep -q "^Host \*$" "$ssh_config"; then
        echo -e "\n# Disable SSH_ASKPASS\nHost *" >> "$ssh_config"
    fi

    if ! grep -q "^$askpass_line" "$ssh_config"; then
        sed -i '/^Host \*/a\'"$askpass_line" "$ssh_config"
        echo "SSH configuration updated to disable ASKPASS."
    else
        echo "SSH configuration already contains ASKPASS setting."
    fi

    echo "configure_git_ssh_passphrase: Git and SSH configurations have been updated."
}

# Usage examples:
# change_konsole_profile 2
# configure_git_ssh_passphrase
