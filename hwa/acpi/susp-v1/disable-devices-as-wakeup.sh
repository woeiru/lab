#!/bin/bash

LOGFILE="/var/log/disable-devices-as-wakeup.log"

log_message() {
    echo "$(date): $1" >> $LOGFILE
}

log_message "Script started"

# Log initial USB device status
log_message "Initial USB device status:"
lsusb >> $LOGFILE
log_message "Initial USB power management status:"
for usb_dev in /sys/bus/usb/devices/usb*/power/control; do
    if [ -f "$usb_dev" ]; then
        echo "$usb_dev: $(cat $usb_dev)" >> $LOGFILE
    fi
done

# Set USB power management to "on"
log_message "Setting USB power management to 'on'"
for usb_dev in /sys/bus/usb/devices/usb*/power/control; do
    if [ -f "$usb_dev" ]; then
        echo on > "$usb_dev"
        log_message "Set $usb_dev to 'on'"
    fi
done

# Disable specific ACPI wakeup devices
declare -a devices=("GPP0") # <-- Add your entries here
for device in "${devices[@]}"; do
    if grep -qw ^$device /proc/acpi/wakeup; then
        status=$(grep -w ^$device /proc/acpi/wakeup | awk '{print $3}')
        log_message "Device $device found with status $status"
        if [ "$status" == "*enabled" ]; then
            echo $device > /proc/acpi/wakeup
            log_message "Device $device disabled"
        else
            log_message "Device $device was already disabled"
        fi
    else
        log_message "Device $device not found"
    fi
done

# Log final USB device status
log_message "Final USB device status:"
lsusb >> $LOGFILE
log_message "Final USB power management status:"
for usb_dev in /sys/bus/usb/devices/usb*/power/control; do
    if [ -f "$usb_dev" ]; then
        echo "$usb_dev: $(cat $usb_dev)" >> $LOGFILE
    fi
done

log_message "Script finished"
