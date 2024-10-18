#!/bin/bash

LOGFILE="/var/log/disable-devices-as-wakeup.log"

echo "Script started at $(date)" >> $LOGFILE

# Set USB power management to "on"
echo "Setting USB power management to 'on'" >> $LOGFILE
for usb_dev in /sys/bus/usb/devices/usb*/power/control; do
    if [ -f "$usb_dev" ]; then
        echo on > "$usb_dev"
        echo "Set $usb_dev to 'on'" >> $LOGFILE
    fi
done

# Disable specific ACPI wakeup devices
declare -a devices=("GPP0") # <-- Add your entries here
for device in "${devices[@]}"; do
    if grep -qw ^$device /proc/acpi/wakeup; then
        status=$(grep -w ^$device /proc/acpi/wakeup | awk '{print $3}')
        echo "Device $device found with status $status" >> $LOGFILE
        if [ "$status" == "*enabled" ]; then
            echo $device > /proc/acpi/wakeup
            echo "Device $device disabled" >> $LOGFILE
        else
            echo "Device $device was already disabled" >> $LOGFILE
        fi
    else
        echo "Device $device not found" >> $LOGFILE
    fi
done

echo "Script finished at $(date)" >> $LOGFILE
