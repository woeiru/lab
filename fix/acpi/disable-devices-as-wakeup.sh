#!/bin/bash

declare -a devices=(GPP0) # <-- Add your entries here
for device in "${devices[@]}"; do
    if grep -qw ^$device.*enabled /proc/acpi/wakeup; then
        sudo sh -c "echo $device > /proc/acpi/wakeup"
    fi
done

