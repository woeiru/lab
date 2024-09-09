# Configuration Tracker

## Overview

The Configuration Tracker is a bash script designed to backup and manage user configurations for both regular users and the root user. It creates versioned backups of specified directories (including the entire `.config` folder) and provides a mechanism to apply these configurations to the system.

## Features

- Creates versioned backups of configuration files for a specified user or the root user
- Tracks changes between versions
- Generates a script to apply configurations from any saved version
- Supports applying the latest configuration or a specific version

## Files

- `/root/lab/ini/tracker.sh`: Main script for creating backups
- `~/.config-backup/apply_changes.sh` or `/root/.config-backup/apply_changes.sh`: Generated script for applying saved configurations

## Usage

### Creating Backups

Run the main script, optionally specifying the target user:

```bash
# For a regular user (run as root or with sudo)
sudo /root/lab/ini/tracker.sh <username>

# For the root user (run while logged in as root)
/root/lab/ini/tracker.sh
```

This will create a new version of the user's configuration backup in `/home/<username>/.config-backup/version_X` or `/root/.config-backup/version_X`, where X is an incrementing number.

### Applying Configurations

To apply configurations, use the generated `apply_changes.sh` script in the user's home directory or root's home directory:

- Apply the latest version:
  ```bash
  ~/.config-backup/apply_changes.sh latest
  # or for root
  /root/.config-backup/apply_changes.sh latest
  ```

- Apply a specific version:
  ```bash
  ~/.config-backup/apply_changes.sh <version_number>
  # or for root
  /root/.config-backup/apply_changes.sh <version_number>
  ```

- List available versions:
  ```bash
  ~/.config-backup/apply_changes.sh
  # or for root
  /root/.config-backup/apply_changes.sh
  ```

## Configuration

The script monitors the following directories by default:
- `$USER_HOME/.config`
- `$USER_HOME/.local/share`

To modify the monitored directories, edit the `MONITOR_DIRS` array in the `tracker.sh` script.

## How It Works

### Backup Process (`tracker.sh`)

1. Takes an optional username as an argument. If no username is provided, it assumes the current user (which could be root).
2. Sets up the backup directory in the user's home folder or root's home folder.
3. On first run, creates an initial snapshot of all files in monitored directories.
4. On subsequent runs:
   - Creates a new version directory.
   - Compares current files with the previous version.
   - Copies changed or new files to the new version directory.
   - Copies unchanged files from the previous version.
5. Logs changes to `changes.log`.
6. Generates/updates `apply_changes.sh`.

### Apply Process (`apply_changes.sh`)

1. Takes a version number or 'latest' as an argument.
2. Locates the corresponding version directory.
3. Copies all files from the version directory to the user's home directory or root's home directory, maintaining relative paths.

## Important Notes

- The main script (`tracker.sh`) must be run as root for regular users, but can be run directly when logged in as root.
- Applying a configuration will overwrite existing files in the user's home directory or root's home directory. Use with caution.
- The script does not delete files. If a file exists in the current setup but not in the applied version, it will remain unchanged.
- Consider running the backup script before making significant changes to your configurations.

## Limitations

- Does not track file deletions.
- Applies entire configuration states, not individual changes.
- May overwrite manual changes made between backups.

## Troubleshooting

If you encounter permission issues:
1. Ensure the scripts are executable: `chmod +x /root/lab/ini/tracker.sh`
2. Check if the script is being run with appropriate permissions (as root for regular users, or directly as root).

If changes don't appear to take effect after applying:
1. Log out and log back in to your session.
2. If issues persist, reboot the system.

For other issues, check the `changes.log` file in the user's or root's `.config-backup` directory for any error messages or unexpected behavior.

## Contributing

Contributions to improve the script are welcome. Please submit issues or pull requests on the project's repository.

## License

[Specify the license here, e.g., MIT, GPL, etc.]
