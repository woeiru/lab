#!/bin/bash

# Deployment script for ACPI Wakeup Device Disabler

# Log file
LOGFILE="/var/log/acpi-wakeup-disabler-deploy.log"

# Function to log messages
log_message() {
    echo "$(date): $1" | tee -a "$LOGFILE"
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_message "This script must be run as root"
        exit 1
    fi
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
    log_message "Deploying files..."

    cp "disable-devices-as-wakeup.service" /etc/systemd/system/ || { log_message "Failed to copy service file"; exit 1; }
    cp "disable-devices-as-wakeup.sh" /usr/local/bin/ || { log_message "Failed to copy script file"; exit 1; }
    chmod +x /usr/local/bin/disable-devices-as-wakeup.sh || { log_message "Failed to make script executable"; exit 1; }

    # Add new files
    cp "post-wake-usb-reset.service" /etc/systemd/system/ || { log_message "Failed to copy post-wake service file"; exit 1; }
    cp "post-wake-usb-reset.sh" /usr/local/bin/ || { log_message "Failed to copy post-wake script file"; exit 1; }
    chmod +x /usr/local/bin/post-wake-usb-reset.sh || { log_message "Failed to make post-wake script executable"; exit 1; }

    log_message "Files deployed successfully"
}

# Function to handle SELinux configuration
configure_selinux() {
    log_message "Configuring SELinux..."

    chcon -t bin_t /usr/local/bin/disable-devices-as-wakeup.sh || { log_message "Failed to set SELinux context for script"; exit 1; }
    chcon -t bin_t /usr/local/bin/post-wake-usb-reset.sh || { log_message "Failed to set SELinux context for post-wake script"; exit 1; }

    log_message "Creating and compiling SELinux policy file."
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
allow init_t bin_t:file { read open execute };
allow init_t proc_t:file { read write open };
allow init_t self:process execmem;
EOF

    checkmodule -M -m -o disable_wakeup.mod disable_wakeup.te || { log_message "Failed to create SELinux module"; exit 1; }
    semodule_package -o disable_wakeup.pp -m disable_wakeup.mod || { log_message "Failed to package SELinux module"; exit 1; }
    semodule -i disable_wakeup.pp || { log_message "Failed to install SELinux module"; exit 1; }
    log_message "SELinux policy created, compiled, and loaded"

    # Clean up temporary files
    rm -f disable_wakeup.te disable_wakeup.mod disable_wakeup.pp
    log_message "Temporary SELinux files cleaned up"
}

# Function to configure systemd
configure_systemd() {
    log_message "Configuring systemd..."

    systemctl daemon-reload || { log_message "Failed to reload systemd configuration"; exit 1; }
    systemctl enable disable-devices-as-wakeup.service || { log_message "Failed to enable service"; exit 1; }
    systemctl start disable-devices-as-wakeup.service || { log_message "Failed to start service"; exit 1; }

    # Add new service
    systemctl enable post-wake-usb-reset.service || { log_message "Failed to enable post-wake service"; exit 1; }

    log_message "Systemd configured successfully"
}

# Main execution
main() {
    log_message "Starting deployment of ACPI Wakeup Device Disabler"

    check_root
    deploy_files

    if is_selinux_enabled; then
        log_message "SELinux is enabled. Applying SELinux-specific configurations."
        configure_selinux
    else
        log_message "SELinux is not enabled. Skipping SELinux-specific configurations."
    fi

    configure_systemd

    if systemctl is-active --quiet disable-devices-as-wakeup.service; then
        log_message "disable-devices-as-wakeup service is active and running"
    else
        log_message "disable-devices-as-wakeup service failed to start. Check the system logs for more information."
    fi

    log_message "Deployment completed. Please check $LOGFILE for full deployment log."
}

# Run the main function
main
