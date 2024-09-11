#!/bin/bash

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Function to check if SELinux is enabled
is_selinux_enabled() {
    if command -v selinuxenabled >/dev/null 2>&1; then
        if selinuxenabled; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Copy service file to systemd directory
cp "$DIR/disable-devices-as-wakeup.service" /etc/systemd/system/

# Copy script file to /usr/local/bin
cp "$DIR/disable-devices-as-wakeup.sh" /usr/local/bin/

# Check if SELinux is enabled
if is_selinux_enabled; then
    echo "SELinux is enabled. Applying SELinux-specific configurations."
    
    # Set correct SELinux context for the script
    chcon -t bin_t /usr/local/bin/disable-devices-as-wakeup.sh

    # Create and load SELinux policy
    checkmodule -M -m -o disable_wakeup.mod "$DIR/disable_wakeup.te"
    semodule_package -o disable_wakeup.pp -m disable_wakeup.mod
    semodule -i disable_wakeup.pp
else
    echo "SELinux is not enabled. Skipping SELinux-specific configurations."
fi

# Reload systemd configuration
systemctl daemon-reload

# Enable and start the service
systemctl enable disable-devices-as-wakeup.service
systemctl start disable-devices-as-wakeup.service

# Check the status of the service
systemctl status disable-devices-as-wakeup.service

