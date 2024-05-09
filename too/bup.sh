#!/bin/bash

read_config() {
    source "../../con/suse"
}

# Function to write parameters to config file
write_config() {
    # Read the existing config file and store it in a temporary file
    tmp_file=$(mktemp)
    cp "$config_file" "$tmp_file"

    # Replace the values in the temporary file
    sed -i "s|^source_path_cifs=.*|source_path_cifs=\"$source_path_cifs\"|g" "$tmp_file"
    sed -i "s|^destination_path_cifs=.*|destination_path_cifs=\"$destination_path_cifs\"|g" "$tmp_file"
    sed -i "s|^username_cifs=.*|username_cifs=\"$username_cifs\"|g" "$tmp_file"
    sed -i "s|^source_path_rsync=.*|source_path_rsync=\"$source_path_rsync\"|g" "$tmp_file"

    # Move the temporary file back to the original config file
    mv "$tmp_file" "$config_file"
}

# Function to check if a directory exists and create it if it doesn't
ensure_directory_exists() {
    if [ ! -d "$1" ]; then
        echo "Destination path $1 does not exist. Creating..."
        mkdir -p "$1"
    fi
}

# Function to prompt for input
prompt_input() {
    read -p "$1 (default: $2): " value
    value="${value:-$2}"
}

# Function to mount CIFS share
mount_cifs() {
    # Construct the CIFS mount command
    if [ -n "$password_cifs" ]; then
        cifs_mount_command="sudo mount -t cifs $source_path_cifs $destination_path_cifs -o username=$username_cifs,password=$password_cifs"
    else
        cifs_mount_command="sudo mount -t cifs $source_path_cifs $destination_path_cifs -o username=$username_cifs"
    fi

    # Prompt for confirmation to mount CIFS share
    read -p "Command to mount CIFS share: $cifs_mount_command. Proceed? [Y/n] " confirm_cifs
    confirm_cifs=${confirm_cifs:-Y}

    # Execute the CIFS mount command if confirmed
    if [[ $confirm_cifs =~ ^[Yy]$ ]]; then
        echo "Mounting CIFS share..."
        $cifs_mount_command
    else
        echo "CIFS share mount operation cancelled."
        exit 1
    fi
}

# Function to execute Rsync
execute_rsync() {
    # Construct the Rsync command
    rsync_command="sudo rsync -av --delete $source_path_rsync/ $destination_path_rsync"

    # Prompt for confirmation to execute Rsync
    read -p "Command to execute Rsync: $rsync_command. Proceed? [Y/n] " confirm_rsync
    confirm_rsync=${confirm_rsync:-Y}

    # Execute the Rsync command if confirmed
    if [[ $confirm_rsync =~ ^[Yy]$ ]]; then
        echo "Executing Rsync command..."
        $rsync_command
    else
        echo "Rsync operation cancelled."
    fi
}

# Main function
main() {
    # Read parameters from config file
    read_config

    # Prompt for CIFS mount parameters
    prompt_input "Enter source path for CIFS mount" "$default_source_path_cifs"
    source_path_cifs="$value"

    prompt_input "Enter destination path for CIFS mount" "$default_destination_path_cifs"
    destination_path_cifs="$value"

    prompt_input "Enter username for CIFS mount" "$default_username_cifs"
    username_cifs="$value"

    read -s -p "Enter password for CIFS mount (leave blank if none): " password_cifs
    echo ""

    # Ensure destination path exists for CIFS mount
    ensure_directory_exists "$destination_path_cifs"

    # Mount CIFS share
    mount_cifs

    # Prompt for Rsync parameters
    prompt_input "Enter source path for Rsync" "$default_source_path_rsync"
    source_path_rsync="$value"

    prompt_input "Enter destination path for Rsync" "$destination_path_cifs"
    destination_path_rsync="$value"

    # Ensure destination path exists for Rsync
    ensure_directory_exists "$destination_path_rsync"

    # Write parameters to config file
    write_config

    # Execute Rsync
    execute_rsync
}

# Call the main function
main

