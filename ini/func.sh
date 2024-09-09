change_konsole_profile() {
    local profile_number="$1"

    # Get the current user
    local username=$(whoami)

    echo "Changing Konsole profile for user: $username"

    # Set the path to the konsolerc file
    local konsolerc_path

    if [ "$username" = "root" ]; then
        konsolerc_path="/root/.config/konsolerc"
    else
        konsolerc_path="$HOME/.config/konsolerc"
    fi

    # Check if the file exists
    if [ ! -f "$konsolerc_path" ]; then
        echo "Error: Konsole configuration file not found at $konsolerc_path"
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

# Usage example:
# change_konsole_profile 2
