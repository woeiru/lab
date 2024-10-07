# Technical Documentation: Shortcuts Configuration Task

## Overview

This document provides technical details for the Ansible task that configures keyboard shortcuts and related settings on KDE Plasma desktop environments. The task is part of the `system_preferences` role and manages global shortcuts, custom shortcuts, and related configurations.

## File Structure

The shortcuts configuration task is organized as follows within the `system_preferences` role:

```
roles/
└── system_preferences/
    └── tasks/
        ├── main.yml
        └── shortcuts.yml
```

## Task Breakdown

### 1. Main Task File (`main.yml`)

The `main.yml` file serves as the entry point for the `system_preferences` role and includes the shortcuts configuration task.

```yaml
---
- name: Include wallpaper configuration tasks
  include_tasks: wallpaper.yml

- name: Include shortcut configuration tasks
  include_tasks: shortcuts.yml

# Additional system preference tasks can be added here
```

### 2. Shortcuts Configuration File (`shortcuts.yml`)

The `shortcuts.yml` file contains all the tasks for configuring shortcuts and related settings. Here's a breakdown of each task:

#### 2.1 Ensure .config Directory Exists

```yaml
- name: Ensure .config directory exists
  file:
    path: "{{ ansible_env.HOME }}/.config"
    state: directory
    mode: '0755'
```

This task ensures that the `.config` directory exists in the user's home directory.

#### 2.2 Configure Global Shortcuts

```yaml
- name: Configure global shortcuts
  ini_file:
    path: "{{ ansible_env.HOME }}/.config/kglobalshortcutsrc"
    section: "{{ item.section }}"
    option: "{{ item.option }}"
    value: "{{ item.value }}"
  loop:
    - { section: "kwin", option: "ExposeAll", value: "Ctrl+F10\\tLaunch (C)\\tMeta+Tab,Ctrl+F10\\tLaunch (C),Toggle Present Windows (All desktops)" }
    - { section: "kwin", option: "Window Close", value: "Alt+F4\\tMeta+Backspace,Alt+F4,Close Window" }
    - { section: "org.kde.kglobalaccel", option: "Sleep", value: "Meta+Del\\tSleep,Sleep,Suspend" }
    - { section: "plasmashell", option: "show-on-mouse-pos", value: "Meta+`\\tMeta+V,Meta+V,Show Clipboard Items at Mouse Position" }
```

This task updates the `kglobalshortcutsrc` file with global shortcut configurations. It uses the `ini_file` module to ensure idempotency and loops through multiple shortcut configurations.

#### 2.3 Configure Custom Shortcuts

```yaml
- name: Configure custom shortcuts
  ini_file:
    path: "{{ ansible_env.HOME }}/.config/kglobalshortcutsrc"
    section: "services"
    option: "{{ item.option }}"
    value: "{{ item.value }}"
  loop:
    - { option: "[net.local.bash-2.desktop]_launch", value: "Meta+End" }
    - { option: "[net.local.bash.desktop]_launch", value: "Meta+Home" }
```

This task adds custom shortcut configurations to the `kglobalshortcutsrc` file in the "services" section.

#### 2.4 Create Custom Shortcut Files

```yaml
- name: Create custom shortcut files
  copy:
    content: "{{ item.content }}"
    dest: "{{ ansible_env.HOME }}/.local/share/applications/{{ item.filename }}"
    mode: '0644'
  loop:
    - filename: "net.local.bash-2.desktop"
      content: |
        [Desktop Entry]
        Exec=bash -c -i "theme-preset-dark"
        Name=
        NoDisplay=true
        StartupNotify=false
        Type=Application
        X-KDE-GlobalAccel-CommandShortcut=true
    - filename: "net.local.bash.desktop"
      content: |
        [Desktop Entry]
        Exec=bash -c -i "theme-preset-bright"
        Name=
        NoDisplay=true
        StartupNotify=false
        Type=Application
        X-KDE-GlobalAccel-CommandShortcut=true
```

This task creates two custom shortcut files in the `.local/share/applications/` directory. These files define custom actions that can be triggered by the shortcuts configured in the previous task.

#### 2.5 Ensure .local/state Directory Exists

```yaml
- name: Ensure .local/state directory exists
  file:
    path: "{{ ansible_env.HOME }}/.local/state"
    state: directory
    mode: '0755'
```

This task ensures that the `.local/state` directory exists in the user's home directory.

#### 2.6 Update plasmashellstaterc

```yaml
- name: Update plasmashellstaterc
  ini_file:
    path: "{{ ansible_env.HOME }}/.local/state/plasmashellstaterc"
    section: "KickerRunnerManager][History"
    option: "a19edca3-f987-4565-9b0d-339920995a1f"
    value: "shortcuts,kde wallet,wallet,kde,kdewa,walle,kdewall"
```

This task updates the `plasmashellstaterc` file with a specific history entry for the KRunner.

## Usage

To use this shortcuts configuration task:

1. Ensure the `system_preferences` role is included in your main playbook.
2. Run your Ansible playbook targeting the desired hosts.

Example:
```
ansible-playbook main.yml -l desktop_hosts
```

## Customization

To customize the shortcut settings:

1. Modify the shortcut configurations in the "Configure global shortcuts" and "Configure custom shortcuts" tasks.
2. Adjust the content of the custom shortcut files in the "Create custom shortcut files" task.
3. Update the `plasmashellstaterc` configuration if needed.

## Considerations

- This task assumes a KDE Plasma desktop environment.
- The task will create necessary directories and files if they don't exist.
- Custom shortcuts are configured to run bash commands for changing themes.
- The `plasmashellstaterc` update includes a specific UUID which may need to be adjusted for different systems.

## Troubleshooting

If you encounter issues:

1. Check that the target system is running KDE Plasma.
2. Verify that the user running the playbook has permissions to modify files in their home directory.
3. Ensure the specified paths (e.g., `.config`, `.local/share/applications`) exist and are accessible.
4. Run the playbook with increased verbosity (`-v` or `-vv`) for more detailed output.
5. Check the KDE Plasma documentation for any changes in shortcut configuration files or methods.

For any persistent issues, consult the KDE Plasma documentation or community forums for specific configuration details.
