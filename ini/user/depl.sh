#!/bin/bash

# Copy func.sh to the user's home directory
cp func.sh ~/func.sh

# Source func.sh to make configure_git_ssh_passphrase() available
source ~/func.sh

# Run configure_git_ssh_passphrase() function
configure_git_ssh_passphrase

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
