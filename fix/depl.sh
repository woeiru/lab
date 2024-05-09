#!/bin/bash

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Copy service file to systemd directory
cp "$DIR/disable-devices-as-wakeup.service" /etc/systemd/system/

# Copy script file to systemd directory
cp "$DIR/disable-devices-as-wakeup.sh" /etc/systemd/system/

# Enable and start the service
systemctl enable disable-devices-as-wakeup.service
systemctl start disable-devices-as-wakeup.service

# Check the status of the service
systemctl status disable-devices-as-wakeup.service
