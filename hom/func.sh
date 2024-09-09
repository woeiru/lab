konsole_profile_diagnostic() {
    echo "Current user: $(whoami)"
    echo "Home directory: $HOME"
    echo "Content of \$1: '$1'"
    echo "Content of \$2: '$2'"
    echo "Result of id command: $(id)"
    echo "Konsolerc file exists: $(test -f "$HOME/.config/konsolerc" && echo "Yes" || echo "No")"
}

# Usage:
# konsole_profile_diagnostic "*" 2

change_konsole_profile() {
    echo "Function started with arguments: $@"
    local username=""
    local profile_number=""
    
    # Parse arguments
    for arg in "$@"; do
        if [[ "$arg" =~ ^[0-9]+$ ]]; then
            profile_number="$arg"
        elif [ -z "$username" ]; then
            username="$arg"
        fi
    done

    echo "Initial username: '$username'"

    # Check if username is empty or was meant to be a wildcard
    if [ -z "$username" ] || [ "$username" = "*" ] || [ "$username" = "Desktop" ]; then
        username=$(whoami)
        echo "Username after whoami: '$username'"
    fi

    echo "Final username: '$username'"
    echo "Profile number: '$profile_number'"

    # Check if the user is root
    if [ "$username" = "root" ]; then
        echo "Error: Cannot change profile for root user."
        return 1
    fi

    # Check if the user exists
    if ! id "$username" &>/dev/null; then
        echo "Error: User $username does not exist."
        echo "Current user: $(whoami)"
        echo "Home directory: $HOME"
        return 1
    fi

    # Set the path to the konsolerc file
    local konsolerc_path="/home/$username/.config/konsolerc"

    echo "Konsolerc path: $konsolerc_path"

    # Check if the file exists
    if [ ! -f "$konsolerc_path" ]; then
        echo "Error: Konsole configuration file not found for user $username."
        return 1
    fi

    # Check if the profile number is valid
    if ! [[ "$profile_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid profile number. Please provide a positive integer."
        return 1
    fi

    # Update the DefaultProfile in the konsolerc file
    if sed -i '/^\[Desktop Entry\]/,/^\[/ s/^DefaultProfile=.*/DefaultProfile=Profile '"$profile_number"'.profile/' "$konsolerc_path"; then
        echo "Konsole default profile updated to Profile $profile_number for user $username."
    else
        echo "Error: Failed to update Konsole profile for user $username."
        return 1
    fi
}

# Usage examples:
# change_konsole_profile * 2
# change_konsole_profile "" 2
# change_konsole_profile username 2
