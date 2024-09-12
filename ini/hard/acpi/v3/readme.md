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
   - Configure SELinux if it's enabled (creating and loading a policy)
   - Set up and start the systemd service
   - Log all actions to `/var/log/acpi-wakeup-disabler-deploy.log`

## SELinux Configuration

If SELinux is enabled on your system, the deployment script will automatically create and load an appropriate SELinux policy. This policy allows the service to function correctly within SELinux constraints. The policy is created during deployment and does not require any manual intervention.

If you need to customize the SELinux policy, you can modify the policy generation section in the `depl.sh` script before running it.
