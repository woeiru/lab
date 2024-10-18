#!/bin/bash

LOGFILE="/var/log/post-wake-usb-reset.log"

log_message() {
    echo "$(date): $1" >> $LOGFILE
}

log_message "Post-wake USB reset script started"

# Reset USB devices
for usb_dev in /sys/bus/usb/devices/*/authorized; do
    if [ -f "$usb_dev" ]; then
        echo 0 > "$usb_dev"
        echo 1 > "$usb_dev"
        log_message "Reset USB device: $usb_dev"
    fi
done

# Re-enable USB autosuspend
for usb_dev in /sys/bus/usb/devices/*/power/control; do
    if [ -f "$usb_dev" ]; then
        echo auto > "$usb_dev"
        log_message "Set $usb_dev to 'auto'"
    fi
done

log_message "Post-wake USB reset script finished"
