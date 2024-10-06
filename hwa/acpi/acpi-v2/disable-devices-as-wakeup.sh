#!/bin/bash

LOGFILE="/var/log/disable-devices-as-wakeup.log"

echo "Script started at $(date)" >> $LOGFILE
declare -a devices=("GPP0" "GPP8" "XHC1") # <-- Add your entries here
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
