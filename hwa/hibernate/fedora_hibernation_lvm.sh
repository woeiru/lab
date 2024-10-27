#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored status
print_status() {
    if [ "$2" = "OK" ]; then
        echo -e "[$GREEN OK $NC] $1"
    elif [ "$2" = "MISSING" ]; then
        echo -e "[${RED}MISSING$NC] $1"
    elif [ "$2" = "WARNING" ]; then
        echo -e "[${YELLOW}WARNING$NC] $1"
    elif [ "$2" = "ERROR" ]; then
        echo -e "[${RED}ERROR$NC] $1"
    elif [ "$2" = "DEBUG" ]; then
        echo -e "[${BLUE}DEBUG$NC] $1"
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

# Function to configure swap
configure_swap() {
    print_status "Configuring swap..." "DEBUG"

    # Check if swap is already active
    if swapon -s | grep -q "/dev/mapper/fedora-swap00"; then
        print_status "Swap is already active" "OK"
        return 0
    fi

    # Activate swap
    if ! swapon /dev/mapper/fedora-swap00; then
        print_status "Failed to activate swap" "ERROR"
        return 1
    fi

    print_status "Swap activated successfully" "OK"
}

# Function to update GRUB configuration
update_grub() {
    print_status "Updating GRUB configuration..." "DEBUG"
    local swap_uuid=$(blkid -s UUID -o value /dev/fedora/swap00)
    if ! grep -q "resume=UUID=$swap_uuid" /etc/default/grub; then
        sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"resume=UUID=$swap_uuid /" /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
        print_status "Updated GRUB configuration" "OK"
    else
        print_status "GRUB configuration already updated" "OK"
    fi
}

# Function to configure dracut
configure_dracut() {
    if [ ! -f "/etc/dracut.conf.d/resume.conf" ]; then
        echo 'add_dracutmodules+=" resume "' > /etc/dracut.conf.d/resume.conf
        print_status "Created dracut resume configuration" "OK"
    else
        print_status "Dracut resume configuration already exists" "OK"
    fi
    print_status "Rebuilding initramfs..." "DEBUG"
    dracut -f
    print_status "Rebuilt initramfs" "OK"
}

# Function to create systemd units
create_systemd_units() {
    local services=("hibernate-preparation" "hibernate-resume")
    for service in "${services[@]}"; do
        if [ ! -f "/etc/systemd/system/${service}.service" ]; then
            print_status "Creating ${service}.service..." "DEBUG"
            case $service in
                hibernate-preparation)
                    cat <<EOF > /etc/systemd/system/${service}.service
[Unit]
Description=Prepare system for hibernation
Before=systemd-hibernate.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo platform > /sys/power/disk; echo disk > /sys/power/state'

[Install]
WantedBy=systemd-hibernate.service
EOF
                    ;;
                hibernate-resume)
                    cat <<EOF > /etc/systemd/system/${service}.service
[Unit]
Description=Resume system after hibernation
After=hibernate.target

[Service]
Type=oneshot
ExecStart=/bin/true

[Install]
WantedBy=hibernate.target
EOF
                    ;;
            esac
            systemctl enable ${service}.service
            print_status "Created and enabled ${service}.service" "OK"
        else
            print_status "${service}.service already exists" "OK"
        fi
    done
}

# Function to disable systemd memory checks
disable_systemd_memory_checks() {
    local services=("logind" "hibernate")
    for service in "${services[@]}"; do
        local override_dir="/etc/systemd/system/systemd-${service}.service.d"
        local override_file="${override_dir}/override.conf"
        if [ ! -f "$override_file" ]; then
            print_status "Disabling systemd memory check for ${service}..." "DEBUG"
            mkdir -p "$override_dir"
            echo -e "[Service]\nEnvironment=SYSTEMD_BYPASS_HIBERNATION_MEMORY_CHECK=1" > "$override_file"
            print_status "Disabled systemd memory check for ${service}" "OK"
        else
            print_status "Systemd memory check already disabled for ${service}" "OK"
        fi
    done
}

# Checker functions
check_swap() {
    if swapon -s | grep -q "/dev/mapper/fedora-swap00"; then
        local swap_size=$(swapon --show=size --noheadings | awk '/fedora-swap00/ {print $3}')
        print_status "Swap is active (${swap_size})" "OK"
        return 0
    else
        print_status "Swap is not active" "WARNING"
        return 1
    fi
}

check_grub_config() {
    if grep -q "resume=UUID" /etc/default/grub; then
        print_status "GRUB configuration for resume exists" "OK"
        return 0
    else
        print_status "GRUB configuration for resume is missing" "MISSING"
        return 1
    fi
}

check_systemd_units() {
    local status=0
    local services=("hibernate-preparation" "hibernate-resume")
    for service in "${services[@]}"; do
        if systemctl is-enabled --quiet ${service}.service; then
            print_status "${service}.service is enabled" "OK"
        else
            print_status "${service}.service is missing or not enabled" "MISSING"
            status=1
        fi
    done
    return $status
}

check_systemd_memory_checks() {
    local status=0
    local services=("logind" "hibernate")
    for service in "${services[@]}"; do
        if [ -f "/etc/systemd/system/systemd-${service}.service.d/override.conf" ]; then
            print_status "Systemd memory check disabled for ${service}" "OK"
        else
            print_status "Systemd memory check not disabled for ${service}" "MISSING"
            status=1
        fi
    done
    return $status
}

# Main function
main() {
    check_root
    echo "Fedora Workstation Hibernation Setup Script (LVM version)"
    echo "========================================================="
    echo

    # Run all checks
    local issues=()
    check_swap || issues+=("swap")
    check_grub_config || issues+=("grub_config")
    check_systemd_units || issues+=("systemd_units")
    check_systemd_memory_checks || issues+=("systemd_memory_checks")

    if [ ${#issues[@]} -eq 0 ]; then
        echo "No issues found. Your system is ready for hibernation."
        exit 0
    fi

    echo "The following issues were found:"
    for issue in "${issues[@]}"; do
        echo "- $issue"
    done

    read -p "Do you want to fix these issues? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi

    # Handle issues
    configure_swap
    update_grub
    configure_dracut
    create_systemd_units
    disable_systemd_memory_checks

    echo "Fixes applied. Checking final status..."
    check_swap
    check_grub_config
    check_systemd_units
    check_systemd_memory_checks

    echo "Current swap status:"
    swapon --show

    read -p "Do you want to reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# Run the main function
main
