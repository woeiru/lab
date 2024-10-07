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

(Content remains the same)

### 2. Shortcuts Configuration File (`shortcuts.yml`)

The `shortcuts.yml` file contains all the tasks for configuring shortcuts and related settings. Here's a breakdown of each task:

#### 2.1 Ensure .config Directory Exists

(Content remains the same)

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
    - { section: "org.kde.konsole.desktop", option: "_launch", value: "Meta+Return,none,Konsole" }
```

This task updates the `kglobalshortcutsrc` file with global shortcut configurations. It uses the `ini_file` module to ensure idempotency and loops through multiple shortcut configurations. The new addition is the Konsole shortcut, which opens a new Konsole window when pressing Meta+Return.

(The rest of the document remains the same)

## Customization

To customize the shortcut settings:

1. Modify the shortcut configurations in the "Configure global shortcuts" and "Configure custom shortcuts" tasks.
2. Adjust the content of the custom shortcut files in the "Create custom shortcut files" task.
3. Update the `plasmashellstaterc` configuration if needed.
4. To add new global shortcuts, add a new item to the loop in the "Configure global shortcuts" task, specifying the appropriate section, option, and value.

(The rest of the document remains the same)
