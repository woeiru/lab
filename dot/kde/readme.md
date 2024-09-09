# KDE Configuration Tracker

## Overview

The KDE Configuration Tracker is a bash script designed to backup and manage KDE Plasma desktop environment configurations. It creates versioned backups of specified configuration directories and provides a mechanism to apply these configurations to the system, including automatically restarting the Plasma shell to ensure changes take effect.

## Features

- Creates versioned backups of KDE configuration files
- Tracks changes between versions
- Generates a script to apply configurations from any saved version
- Supports applying the latest configuration or a specific version
- Automatically restarts the Plasma shell after applying changes

## Files

- `kde-config-tracker.sh`: Main script for creating backups
- `apply_changes.sh`: Generated script for applying saved configurations

## Usage

### Creating Backups

Run the main script periodically to create backups:

```bash
./kde-config-tracker.sh
```

This will create a new version of your configuration backup in `~/kde-config-backup/version_X`, where X is an incrementing number.

### Applying Configurations

To apply configurations, use the generated `apply_changes.sh` script:

- Apply the latest version:
  ```bash
  ~/kde-config-backup/apply_changes.sh latest
  ```

- Apply a specific version:
  ```bash
  ~/kde-config-backup/apply_changes.sh <version_number>
  ```

- List available versions:
  ```bash
  ~/kde-config-backup/apply_changes.sh
  ```

After applying the configurations, the script will automatically restart the Plasma shell to ensure the changes take effect.

## Configuration

The script monitors the following directories by default:
- `$HOME/.config`
- `$HOME/.local/share/plasma`
- `$HOME/.kde`

To modify the monitored directories, edit the `MONITOR_DIRS` array in `kde-config-tracker.sh`.

## How It Works

### Backup Process (`kde-config-tracker.sh`)

1. On first run, creates an initial snapshot of all files in monitored directories.
2. On subsequent runs:
   - Creates a new version directory.
   - Compares current files with the previous version.
   - Copies changed or new files to the new version directory.
   - Copies unchanged files from the previous version.
3. Logs changes to `changes.log`.
4. Generates/updates `apply_changes.sh`.

### Apply Process (`apply_changes.sh`)

1. Takes a version number or 'latest' as an argument.
2. Locates the corresponding version directory.
3. Copies all files from the version directory to the home directory, maintaining relative paths.
4. Restarts the Plasma shell using the command:
   ```
   kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell &
   ```

## Important Notes

- Applying a configuration will overwrite existing files in your home directory. Use with caution.
- The script does not delete files. If a file exists in your current setup but not in the applied version, it will remain unchanged.
- Consider running the backup script before making significant changes to your KDE configuration.
- The Plasma shell restart may cause a brief interruption in your desktop environment.

## Limitations

- Does not track file deletions.
- Applies entire configuration states, not individual changes.
- May overwrite manual changes made between backups.

## Troubleshooting

If you encounter permission issues:
1. Ensure the scripts are executable: `chmod +x kde-config-tracker.sh`
2. Check if you have write permissions in the backup directory.

If changes don't appear to take effect after applying:
1. Log out and log back in to your KDE session.
2. If issues persist, reboot your system.

For other issues, check the `changes.log` file for any error messages or unexpected behavior.

## Contributing

Contributions to improve the script are welcome. Please submit issues or pull requests on the project's repository.

## License
