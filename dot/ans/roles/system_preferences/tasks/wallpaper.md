# Technical Documentation: Wallpaper Configuration Task

## Overview

This document provides technical details for the Ansible task that configures wallpapers on KDE Plasma desktop environments. The task is part of the `system_preferences` role and manages wallpaper settings across multiple containments.

## File Structure

The wallpaper configuration task is organized as follows within the `system_preferences` role:

```
roles/
└── system_preferences/
    └── tasks/
        ├── main.yml
        └── wallpaper.yml
```

## Task Breakdown

### 1. Main Task File (`main.yml`)

The `main.yml` file serves as the entry point for the `system_preferences` role and includes the wallpaper configuration task.

```yaml
---
- name: Configure system preferences
  block:
    - name: Include wallpaper configuration tasks
      include_tasks: wallpaper.yml

  # Additional system preference tasks can be added here
```

### 2. Wallpaper Configuration File (`wallpaper.yml`)

The `wallpaper.yml` file contains the specific tasks for configuring the wallpaper settings.

#### 2.1 Ensure Config Directory Exists

```yaml
- name: Ensure .config directory exists
  file:
    path: "{{ ansible_env.HOME }}/.config"
    state: directory
    mode: '0755'
```

This task ensures that the `.config` directory exists in the user's home directory.

#### 2.2 Configure Plasma Wallpaper Settings

```yaml
- name: Configure Plasma wallpaper settings in plasmarc
  ini_file:
    path: "{{ ansible_env.HOME }}/.config/plasmarc"
    section: Wallpapers
    option: usersWallpapers
    value: ""
    create: yes
```

This task creates or modifies the `plasmarc` file, setting the `usersWallpapers` option to an empty string in the `[Wallpapers]` section.

#### 2.3 Configure Plasma Desktop Applets

```yaml
- name: Configure Plasma desktop applets
  blockinfile:
    path: "{{ ansible_env.HOME }}/.config/plasma-org.kde.plasma.desktop-appletsrc"
    block: |
      [Containments][1][ConfigDialog]
      DialogHeight=2532
      DialogWidth=1440

      [Containments][1][Wallpaper][org.kde.image][General]
      Image=/usr/share/wallpapers/Kay/
      PreviewImage=/usr/share/wallpapers/Kay/
      SlidePaths=/usr/share/wallpapers/

      # ... (similar blocks for Containments 2 and 3)
    create: yes
    marker: "# {mark} ANSIBLE MANAGED BLOCK - WALLPAPER SETTINGS"
```

This task updates the `plasma-org.kde.plasma.desktop-appletsrc` file with wallpaper settings for multiple containments. It sets the wallpaper image, preview image, and slide paths for each containment.

## Usage

To use this wallpaper configuration task:

1. Ensure the `system_preferences` role is included in your main playbook.
2. Run your Ansible playbook targeting the desired hosts.

Example:
```
ansible-playbook main.yml -l desktop_hosts
```

## Customization

To customize the wallpaper settings:

1. Modify the `Image`, `PreviewImage`, and `SlidePaths` values in the `wallpaper.yml` file.
2. Adjust the `DialogHeight` and `DialogWidth` values if needed for different screen resolutions.
3. Add or remove `[Containments]` blocks as necessary for your specific setup.

## Considerations

- This task assumes a KDE Plasma desktop environment.
- The task will create the necessary configuration files if they don't exist.
- The `blockinfile` module uses marker comments to identify and update the managed block in future runs.
- Ensure that the specified wallpaper paths (`/usr/share/wallpapers/Kay/`) exist on the target systems.

## Troubleshooting

If you encounter issues:

1. Check that the target system is running KDE Plasma.
2. Verify that the user running the playbook has permissions to modify files in their home directory.
3. Ensure the specified wallpaper directories and files exist on the target system.
4. Run the playbook with increased verbosity (`-v` or `-vv`) for more detailed output.

For any persistent issues, consult the KDE Plasma documentation or community forums for specific configuration details.
