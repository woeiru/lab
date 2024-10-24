#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored status
print_status() {
    if [ "$2" = "OK" ]; then
        echo -e "[$GREEN OK $NC] $1"
    elif [ "$2" = "ERROR" ]; then
        echo -e "[${RED}ERROR$NC] $1"
    else
        echo -e "[${YELLOW}WARNING$NC] $1"
    fi
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to disable ZRAM
disable_zram() {
    if lsmod | grep -q zram; then
        print_status "Disabling ZRAM..." "WARNING"

        # Disable all zram devices
        for zram_dev in /dev/zram*; do
            if [[ -b "$zram_dev" ]]; then
                swapoff "$zram_dev" 2>/dev/null || true
                echo 1 > "/sys/block/$(basename "$zram_dev")/reset"
            fi
        done

        # Remove the zram module
        modprobe -r zram

        # Prevent ZRAM from loading on boot
        echo "zram" > /etc/modprobe.d/zram.conf

        print_status "ZRAM has been disabled and will not load on boot" "OK"
    else
        print_status "ZRAM is not currently loaded" "OK"
    fi
}

# Function to update GRUB configuration
update_grub() {
    print_status "Updating GRUB configuration..." "WARNING"

    # Remove zswap.enabled=1 from GRUB_CMDLINE_LINUX if present
    if grep -q "zswap.enabled=1" /etc/default/grub; then
        sed -i 's/zswap.enabled=1 //g' /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
        print_status "Removed zswap.enabled=1 from GRUB configuration" "OK"
    else
        print_status "zswap.enabled=1 not found in GRUB configuration" "OK"
    fi
}

# Main function
main() {
    check_root
    echo "Fedora Disable ZRAM Script"
    echo "=========================="
    echo

    disable_zram
    update_grub

    echo "ZRAM has been disabled. Please reboot your system for changes to take effect."
    read -p "Do you want to reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# Run the main function
main
