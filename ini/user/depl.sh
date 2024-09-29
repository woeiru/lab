#!/bin/bash

# Check if the user is root
if [ "$EUID" -eq 0 ]; then
    echo "Running as root. Skipping pushing usr.bash to destination folder."
else
    # Source usr.bash from the lib folder
    if [ -f ../lib/usr.bash ]; then
        source ../lib/usr.bash
        echo "Sourced usr.bash from ../lib/usr.bash"

        # Run usr-cgsp() function if it exists
        if declare -f usr-cgsp > /dev/null; then
            usr-cgp
            echo "Configured Git and SSH settings."
        else
            echo "Warning: usr-cgsp function not found in usr.bash"
        fi
    else
        echo "Warning: ../lib/usr.bash not found. Skipping sourcing and git/ssh configuration."
    fi
fi

# Inject content into .bashrc or .zshrc
if [ -f ~/.zshrc ]; then
    config_file=~/.zshrc
elif [ -f ~/.bashrc ]; then
    config_file=~/.bashrc
else
    echo "Neither ~/.zshrc nor ~/.bashrc found. Exiting."
    exit 1
fi

# Check if inject content already exists
if grep -q "# START inject" "$config_file"; then
    echo "inject content already exists in $config_file. Skipping."
else
    echo "" >> "$config_file"
    echo "# START inject" >> "$config_file"
    cat inject >> "$config_file"
    echo "# END inject" >> "$config_file"
    echo "inject content added to $config_file"
fi

echo "Deployment completed. Run 'source $config_file' to apply changes in the current session."
