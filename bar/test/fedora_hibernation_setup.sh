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

# Function to create btrfs subvolume
create_btrfs_subvolume() {
    if [ ! -d "/swap" ]; then
        btrfs subvolume create /swap
        print_status "Created btrfs subvolume /swap" "OK"
    else
        print_status "Btrfs subvolume /swap already exists" "OK"
    fi
}

# Function to calculate and create swap file
setup_swap_file() {
    local zram_size=$(swapon --show=size --noheadings | awk '{print $1}' | sed 's/[^0-9]*//g')
    local ram_size=$(free -g | awk '/Mem:/ {print $2}')
    local zram_uncompressed=$((zram_size * 2))
    local total_size=$((zram_uncompressed + ram_size))

    echo "ZRAM size: ${zram_size}G"
    echo "RAM size: ${ram_size}G"
    echo "Recommended swap file size: ${total_size}G"
    read -p "Enter desired swap file size in GB: " user_swap_size

    if [ -f "/swap/swapfile" ]; then
        read -p "Swap file already exists. Recreate? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deactivating existing swap file" "DEBUG"
            swapoff /swap/swapfile 2>&1 | tee -a setup.log || true
            print_status "Removing existing swap file" "DEBUG"
            rm /swap/swapfile 2>&1 | tee -a setup.log
        else
            print_status "Attempting to use existing swap file" "DEBUG"
            if ! swapon /swap/swapfile; then
                print_status "Failed to activate existing swap file" "ERROR"
                cat setup.log
                return 1
            fi
            print_status "Successfully activated existing swap file" "OK"
            return 0
        fi
    fi

    print_status "Creating swap file..." "DEBUG"
    touch /swap/swapfile
    chattr +C /swap/swapfile
    fallocate --length ${user_swap_size}G /swap/swapfile 2>&1 | tee -a setup.log
    chmod 600 /swap/swapfile

    print_status "Setting up swap..." "DEBUG"
    if ! mkswap /swap/swapfile 2>&1 | tee -a setup.log; then
        print_status "Failed to set up swap file" "ERROR"
        cat setup.log
        return 1
    fi

    print_status "Activating swap..." "DEBUG"
    if ! swapon /swap/swapfile 2>&1 | tee -a setup.log; then
        print_status "Failed to activate swap file" "ERROR"
        cat setup.log
        return 1
    fi

    print_status "Created and activated ${user_swap_size}G swap file" "OK"
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
    dracut -f 2>&1 | tee -a setup.log
    print_status "Rebuilt initramfs" "OK"
}

# Function to get UUID and physical offset
get_uuid_and_offset() {
    print_status "Getting UUID and offset..." "DEBUG"
    uuid=$(findmnt -no UUID -T /swap/swapfile)
    physical_offset=$(btrfs inspect-internal map-swapfile -r /swap/swapfile)
    page_size=$(getconf PAGESIZE)
    resume_offset=$((physical_offset / page_size))
    print_status "Got UUID ($uuid) and resume offset ($resume_offset)" "OK"
}

# Function to update GRUB configuration
update_grub() {
    print_status "Updating GRUB configuration..." "DEBUG"
    grubby --args="resume=UUID=$uuid resume_offset=$resume_offset" --update-kernel=ALL 2>&1 | tee -a setup.log
    print_status "Updated GRUB configuration" "OK"
}

# Function to create systemd units
create_systemd_units() {
    for service in hibernate-preparation hibernate-resume; do
        if [ ! -f "/etc/systemd/system/${service}.service" ]; then
            print_status "Creating ${service}.service..." "DEBUG"
            case $service in
                hibernate-preparation)
                    cat <<EOF > /etc/systemd/system/${service}.service
[Unit]
Description=Enable swap file and disable zram before hibernate
Before=systemd-hibernate.service

[Service]
User=root
Type=oneshot
ExecStart=/bin/bash -c "/usr/sbin/swapon /swap/swapfile && /usr/sbin/swapoff /dev/zram0"

[Install]
WantedBy=systemd-hibernate.service
EOF
                    ;;
                hibernate-resume)
                    cat <<EOF > /etc/systemd/system/${service}.service
[Unit]
Description=Disable swap after resuming from hibernation
After=hibernate.target

[Service]
User=root
Type=oneshot
ExecStart=/usr/sbin/swapoff /swap/swapfile

[Install]
WantedBy=hibernate.target
EOF
                    ;;
            esac
            systemctl enable ${service}.service 2>&1 | tee -a setup.log
            print_status "Created and enabled ${service}.service" "OK"
        else
            print_status "${service}.service already exists" "OK"
        fi
    done
}

# Function to disable systemd memory checks
disable_systemd_memory_checks() {
    for service in logind hibernate; do
        override_dir="/etc/systemd/system/systemd-${service}.service.d"
        override_file="${override_dir}/override.conf"
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

# Function to check system status
check_system_status() {
    echo "Checking system status..."

    # Check swap file
    if [ -f "/swap/swapfile" ]; then
        swap_size=$(du -h /swap/swapfile | cut -f1)
        print_status "Swap file exists (${swap_size})" "OK"
    else
        print_status "Swap file is missing" "MISSING"
    fi

    # Check if swap is active
    if swapon -s | grep -q "/swap/swapfile"; then
        print_status "Swap file is active" "OK"
    else
        print_status "Swap file is not active" "WARNING"
    fi

    # Check GRUB configuration
    if grep -q "resume=UUID" /etc/default/grub; then
        print_status "GRUB configuration for resume exists" "OK"
    else
        print_status "GRUB configuration for resume is missing" "MISSING"
    fi

    # Check systemd units
    for service in hibernate-preparation hibernate-resume; do
        if systemctl is-enabled --quiet ${service}.service; then
            print_status "${service}.service is enabled" "OK"
        else
            print_status "${service}.service is missing or not enabled" "MISSING"
        fi
    done

    # Check systemd memory checks
    for service in logind hibernate; do
        if [ -f "/etc/systemd/system/systemd-${service}.service.d/override.conf" ]; then
            print_status "Systemd memory check disabled for ${service}" "OK"
        else
            print_status "Systemd memory check not disabled for ${service}" "MISSING"
        fi
    done
}

# Function to check if btrfs-progs is installed
check_btrfs_progs() {
    if ! command -v btrfs &> /dev/null; then
        print_status "btrfs-progs is not installed" "MISSING"
        echo "Please install btrfs-progs using your package manager:"
        echo "sudo dnf install btrfs-progs"
        return 1
    else
        print_status "btrfs-progs is installed" "OK"
    fi
}

# Main function
main() {
    check_root
    echo "Fedora Workstation Hibernation Setup Script"
    echo "==========================================="
    echo

    # Clear previous log
    > setup.log

    check_system_status
    check_btrfs_progs

    read -p "Do you want to proceed with the setup? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi

    create_btrfs_subvolume
    setup_swap_file || {
        echo "Swap file setup failed. Please review the messages above and the setup.log file for more details."
        exit 1
    }
    configure_dracut
    get_uuid_and_offset
    update_grub
    create_systemd_units
    disable_systemd_memory_checks

    echo "Setup complete. Checking final status..."
    check_system_status

    echo "Current swap status:"
    swapon --show

    echo "Setup log:"
    cat setup.log

    read -p "Do you want to reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# Run the main function
main
