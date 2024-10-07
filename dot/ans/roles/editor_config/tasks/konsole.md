# Technical Documentation: konsole.yml

## Overview

This document provides technical details for the Ansible tasks defined in `konsole.yml`. These tasks are responsible for setting up Konsole profiles on a user's system. Konsole is the default terminal emulator for the KDE desktop environment.

## File Location

The `konsole.yml` file is typically located in the `tasks` directory of the `editor_config` role:

```
roles/
└── editor_config/
    └── tasks/
        └── konsole.yml
```

## Task Breakdown

The `konsole.yml` file contains three main tasks:

### 1. Ensure Konsole Directory Exists

```yaml
- name: Ensure .local/share/konsole directory exists
  file:
    path: "{{ ansible_env.HOME }}/.local/share/konsole"
    state: directory
    mode: '0755'
```

This task ensures that the directory for storing Konsole profiles exists.

- **Module**: `file`
- **Path**: Uses `{{ ansible_env.HOME }}` to reference the user's home directory
- **State**: `directory` ensures the directory is created if it doesn't exist
- **Mode**: `0755` sets read, write, and execute permissions for the owner, and read and execute for others

### 2. Copy Konsole Profile 1

```yaml
- name: Copy Konsole Profile 1
  copy:
    src: "Profile 1.profile"
    dest: "{{ ansible_env.HOME }}/.local/share/konsole/Profile 1.profile"
    mode: '0644'
```

This task copies the first Konsole profile to the user's Konsole directory.

- **Module**: `copy`
- **Source**: `"Profile 1.profile"` (assumed to be in the `files` directory of the role)
- **Destination**: User's Konsole profiles directory
- **Mode**: `0644` sets read and write permissions for the owner, and read-only for others

### 3. Copy Konsole Profile 2

```yaml
- name: Copy Konsole Profile 2
  copy:
    src: "Profile 2.profile"
    dest: "{{ ansible_env.HOME }}/.local/share/konsole/Profile 2.profile"
    mode: '0644'
```

This task copies the second Konsole profile to the user's Konsole directory.

- **Module**: `copy`
- **Source**: `"Profile 2.profile"` (assumed to be in the `files` directory of the role)
- **Destination**: User's Konsole profiles directory
- **Mode**: `0644` sets read and write permissions for the owner, and read-only for others

## Usage

To use these tasks:

1. Ensure the `konsole.yml` file is in the correct location within your Ansible role structure.
2. Include this file in your main tasks file (e.g., `main.yml`) using the `include_tasks` directive:

   ```yaml
   - name: Include Konsole configuration tasks
     include_tasks: konsole.yml
   ```

3. Make sure the profile files (`Profile 1.profile` and `Profile 2.profile`) are present in the `files` directory of your role.

## Considerations

- These tasks assume that Konsole is installed on the target system.
- The tasks will run for the user specified by `ansible_env.HOME`.
- Existing profile files with the same names will be overwritten.

## Customization

To customize these tasks:

1. Modify the profile filenames if you want to use different profile names.
2. Adjust the file permissions (mode) if needed for your security requirements.
3. Add more copy tasks if you have additional profiles to deploy.

## Troubleshooting

If you encounter issues:

1. Verify that the source profile files exist in the `files` directory of your role.
2. Check that the user running the playbook has permissions to create directories and files in their home directory.
3. Ensure Konsole is installed on the target system.
4. Run the playbook with increased verbosity (`-v` or `-vv`) for more detailed output.

For any persistent issues, consult the Konsole documentation or KDE community forums for specific configuration details.
