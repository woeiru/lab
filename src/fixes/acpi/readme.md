# ACPI Wakeup Device Disabler

## Purpose

This project provides a solution for managing ACPI wakeup devices on Linux systems, particularly focusing on preventing unwanted system wakeups and handling USB device reinitialization after sleep. It's designed to work on systems with or without SELinux enabled, improving system stability and power management.

## Features

- Disables specified ACPI wakeup devices to prevent unwanted system wakeups
- Manages USB power settings to ensure proper device functionality after wake-up
- Includes a post-wake USB reset mechanism to reinitialize USB devices
- Supports systems with SELinux enabled
- Provides detailed logging for troubleshooting

## Prerequisites

- A Linux system with systemd
- Root access to the system
- SELinux tools (`checkmodule`, `semodule_package`) if SELinux is enabled

## Files

- `depl.sh`: Main deployment script
- `disable-devices-as-wakeup.service`: Systemd service file for disabling wakeup devices
- `disable-devices-as-wakeup.sh`: Script to disable specified wakeup devices
- `post-wake-usb-reset.service`: Systemd service file for post-wake USB reset
- `post-wake-usb-reset.sh`: Script to reset USB devices after system wake-up

## Installation

1. Clone this repository or download the files to your local system.

2. Modify the `disable-devices-as-wakeup.sh` script to include the ACPI devices you want to disable:

   ```bash
   nano disable-devices-as-wakeup.sh
   ```

   Update the `devices` array with your specific device names:

   ```bash
   declare -a devices=("GPP0" "XHC0")  # Modify this list as needed
   ```

3. Make the deployment script executable:

   ```bash
   chmod +x depl.sh
   ```

4. Run the deployment script with root privileges:

   ```bash
   sudo ./depl.sh
   ```

   This script will:
   - Copy necessary files to appropriate system directories
   - Configure SELinux if it's enabled
   - Set up and start the required systemd services
   - Log all actions to `/var/log/acpi-wakeup-disabler-deploy.log`

## Configuration

- The main configuration is done in the `disable-devices-as-wakeup.sh` script, where you specify which ACPI devices to disable.
- The `post-wake-usb-reset.sh` script handles USB device reinitialization after wake-up. Modify this script if you need to add specific USB device handling.

## Logging

- Deployment logs: `/var/log/acpi-wakeup-disabler-deploy.log`
- Runtime logs for disabling devices: `/var/log/disable-devices-as-wakeup.log`
- Post-wake USB reset logs: `/var/log/post-wake-usb-reset.log`

Check these logs for troubleshooting and to verify the system's behavior.

## Troubleshooting

If you encounter issues:

1. Check the log files mentioned above for error messages or unexpected behavior.
2. Ensure that the ACPI devices you've specified actually exist on your system. You can check available devices with:
   ```
   cat /proc/acpi/wakeup
   ```
3. If USB devices are not functioning correctly after wake-up, check the post-wake USB reset logs and consider modifying the `post-wake-usb-reset.sh` script.

## Uninstallation

To remove the changes made by this script:

1. Disable and stop the services:
   ```
   sudo systemctl disable --now disable-devices-as-wakeup.service post-wake-usb-reset.service
   ```
2. Remove the installed files:
   ```
   sudo rm /etc/systemd/system/disable-devices-as-wakeup.service
   sudo rm /etc/systemd/system/post-wake-usb-reset.service
   sudo rm /usr/local/bin/disable-devices-as-wakeup.sh
   sudo rm /usr/local/bin/post-wake-usb-reset.sh
   ```
3. If SELinux is enabled, remove the custom policy:
   ```
   sudo semodule -r disable_wakeup
   ```

## Contributing

Contributions to improve this project are welcome. Please feel free to submit issues or pull requests on the project's repository.

## License

[Specify your license here, e.g., MIT, GPL, etc.]

## Disclaimer

This script modifies system behavior related to power management and device control. While efforts have been made to ensure its reliability, use it at your own risk. Always test thoroughly on non-critical systems before deploying in a production environment.
