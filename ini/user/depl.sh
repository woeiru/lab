#!/bin/bash

# Determine which file to modify
if [ -f ~/.zshrc ]; then
    config_file=~/.zshrc
elif [ -f ~/.bashrc ]; then
    config_file=~/.bashrc
else
    echo "Neither ~/.zshrc nor ~/.bashrc found. Exiting."
    exit 1
fi

# Check if the lines already exist in the file
if grep -q "^\[ -n \"\$SSH_CONNECTION\" \] && unset SSH_ASKPASS" "$config_file" && \
   grep -q "^export GIT_ASKPASS=" "$config_file"; then
    echo "The required lines already exist in $config_file. No changes made."
    exit 0
fi

# Add the lines to the file
echo "" >> "$config_file"
echo "# Git configuration" >> "$config_file"
echo '[ -n "$SSH_CONNECTION" ] && unset SSH_ASKPASS' >> "$config_file"
echo "export GIT_ASKPASS=" >> "$config_file"

echo "Lines added successfully to $config_file"
