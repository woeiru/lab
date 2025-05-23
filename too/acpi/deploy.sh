#!/bin/bash

# Deployment script for ACPI Wakeup Device Disabler

# Constants
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="/var/log/acpi-wakeup-disabler-deploy.log"
REQUIRED_FILES=(
    "disable-devices-as-wakeup.service"
    "disable-devices-as-wakeup.sh"
    "post-wake-usb-reset.service"
    "post-wake-usb-reset.sh"
)

# Function to log messages
log_message() {
    echo "$(date): $1" | tee -a "$LOGFILE"
}

# Function to print usage
print_usage() {
    echo "Usage: $0 [-d directory] [-h]"
    echo "  -d  Specify the directory containing the required files (default: current directory)"
    echo "  -h  Show this help message"
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_message "This script must be run as root"
        exit 1
    fi
}

# Function to validate directory and required files
validate_directory() {
    local dir="$1"

    # Check if directory exists
    if [ ! -d "$dir" ]; then
        log_message "Error: Directory '$dir' does not exist"
        exit 1
    fi

    # Check for required files
    local missing_files=()
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$dir/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -ne 0 ]; then
        log_message "Error: Missing required files in '$dir':"
        for file in "${missing_files[@]}"; do
            log_message "  - $file"
        done
        exit 1
    fi

    log_message "Directory validation successful: '$dir'"
}

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

# Function to deploy files
deploy_files() {
    local source_dir="$1"
    log_message "Deploying files from '$source_dir'..."

    # Copy service files
    cp "$source_dir/disable-devices-as-wakeup.service" /etc/systemd/system/ || { log_message "Failed to copy service file"; exit 1; }
    cp "$source_dir/post-wake-usb-reset.service" /etc/systemd/system/ || { log_message "Failed to copy post-wake service file"; exit 1; }

    # Copy and set permissions for script files
    cp "$source_dir/disable-devices-as-wakeup.sh" /usr/local/bin/ || { log_message "Failed to copy script file"; exit 1; }
    cp "$source_dir/post-wake-usb-reset.sh" /usr/local/bin/ || { log_message "Failed to copy post-wake script file"; exit 1; }
    chmod +x /usr/local/bin/disable-devices-as-wakeup.sh || { log_message "Failed to make script executable"; exit 1; }
    chmod +x /usr/local/bin/post-wake-usb-reset.sh || { log_message "Failed to make post-wake script executable"; exit 1; }

    log_message "Files deployed successfully"
}

# Function to handle SELinux configuration
configure_selinux() {
    log_message "Configuring SELinux..."

    # Set contexts for executables
    chcon -t bin_t /usr/local/bin/disable-devices-as-wakeup.sh || { log_message "Failed to set SELinux context for script"; exit 1; }
    chcon -t bin_t /usr/local/bin/post-wake-usb-reset.sh || { log_message "Failed to set SELinux context for post-wake script"; exit 1; }

    # Create temporary directory for SELinux policy files
    local temp_dir=$(mktemp -d)
    cd "$temp_dir" || { log_message "Failed to create temporary directory"; exit 1; }

    log_message "Creating and compiling SELinux policy file in $temp_dir"
    cat << EOF > disable_wakeup.te
module disable_wakeup 1.0;

require {
    type bin_t;
    type proc_t;
    type init_t;
    class file { read write open };
    class process execmem;
}

#============= init_t ==============
allow init_t bin_t:file { read open };
allow init_t proc_t:file { read write open };
allow init_t self:process execmem;
EOF

    checkmodule -M -m -o disable_wakeup.mod disable_wakeup.te || { log_message "Failed to create SELinux module"; exit 1; }
    semodule_package -o disable_wakeup.pp -m disable_wakeup.mod || { log_message "Failed to package SELinux module"; exit 1; }
    semodule -i disable_wakeup.pp || { log_message "Failed to install SELinux module"; exit 1; }

    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    log_message "SELinux policy created, compiled, and loaded"
}

# Function to configure systemd
configure_systemd() {
    log_message "Configuring systemd..."

    systemctl daemon-reload || { log_message "Failed to reload systemd configuration"; exit 1; }

    # Enable and start services
    systemctl enable disable-devices-as-wakeup.service || { log_message "Failed to enable service"; exit 1; }
    systemctl start disable-devices-as-wakeup.service || { log_message "Failed to start service"; exit 1; }
    systemctl enable post-wake-usb-reset.service || { log_message "Failed to enable post-wake service"; exit 1; }

    log_message "Systemd configured successfully"
}

# Main execution
main() {
    local source_dir="$SCRIPT_DIR"

    # Parse command line arguments
    while getopts ":d:h" opt; do
        case $opt in
            d)
                source_dir="$OPTARG"
                ;;
            h)
                print_usage
                exit 0
                ;;
            \?)
                log_message "Invalid option: -$OPTARG"
                print_usage
                exit 1
                ;;
            :)
                log_message "Option -$OPTARG requires an argument"
                print_usage
                exit 1
                ;;
        esac
    done

    log_message "Starting deployment of ACPI Wakeup Device Disabler"
    log_message "Using source directory: $source_dir"

    # Validate environment
    check_root
    validate_directory "$source_dir"

    # Deploy
    deploy_files "$source_dir"

    if is_selinux_enabled; then
        log_message "SELinux is enabled. Applying SELinux-specific configurations."
        configure_selinux
    else
        log_message "SELinux is not enabled. Skipping SELinux-specific configurations."
    fi

    configure_systemd

    # Verify service status
    if systemctl is-active --quiet disable-devices-as-wakeup.service; then
        log_message "disable-devices-as-wakeup service is active and running"
    else
        log_message "disable-devices-as-wakeup service failed to start. Check the system logs for more information."
    fi

    log_message "Deployment completed. Please check $LOGFILE for full deployment log."
}

# Run the main function
main "$@"
