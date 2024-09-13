# ACPI Wakeup Device Disabler

## Purpose

This solution provides a method to disable specific ACPI wakeup devices on Linux systems using a systemd service. It's designed to work on systems with or without SELinux enabled, improving system stability and power management by preventing unwanted system wakeups.

## Prerequisites

- Root access to your system
- `systemd` (standard on most modern Linux distributions)
- SELinux tools (`checkmodule`, `semodule_package`) if SELinux is enabled

## Files

Ensure you have the following files in your working directory:

- `depl.sh`: Main deployment script
- `disable-devices-as-wakeup.service`: Systemd service file
- `disable-devices-as-wakeup.sh`: Script to disable wakeup devices

## Installation

1. Clone this repository or download the files to your local system.

2. Modify the `disable-devices-as-wakeup.sh` script to include the ACPI devices you want to disable:

   ```bash
   nano disable-devices-as-wakeup.sh
   ```

   Update the `devices` array with your specific device names:

   ```bash
   declare -a devices=("GPP0" "GPP8" "XHC0")  # Modify this list as needed
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
   - Configure SELinux if it's enabled (creating, compiling, and loading a policy)
   - Set up and start the systemd service
   - Log all actions to `/var/log/acpi-wakeup-disabler-deploy.log`

## SELinux Configuration

If SELinux is enabled on your system, the deployment script will automatically create, compile, and load an appropriate SELinux policy. This policy allows the service to function correctly within SELinux constraints. The entire process is handled during deployment and does not require any manual intervention.

If you need to customize the SELinux policy, you can modify the policy generation section in the `depl.sh` script before running it.

[The rest of the README remains the same as in previous versions]
