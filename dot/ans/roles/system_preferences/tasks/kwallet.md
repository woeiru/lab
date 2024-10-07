# KWallet Configuration Task Documentation

## Overview

This document provides technical details for the Ansible task that configures KWallet on various systems. The task is designed to be flexible and handle different system configurations, including cases where KWallet may not be installed or may have different service names.

## Task Structure

The task is composed of several steps:

1. Directory creation
2. KWallet configuration
3. KWallet manager configuration
4. KWallet manager state configuration
5. KWallet service management

## Detailed Task Breakdown

### 1. Directory Creation

Three directory creation tasks ensure the necessary paths exist:

```yaml
- name: Ensure KWallet config directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.config"
    state: directory
    mode: '0755'

- name: Ensure KWallet manager config directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.config"
    state: directory
    mode: '0755'

- name: Ensure KWallet manager state directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.local/state"
    state: directory
    mode: '0755'
```

These tasks create the `.config` and `.local/state` directories in the user's home directory if they don't already exist.

### 2. KWallet Configuration

```yaml
- name: Configure KWallet
  ansible.builtin.blockinfile:
    path: "{{ ansible_env.HOME }}/.config/kwalletrc"
    create: yes
    block: |
      [Wallet]
      Enabled=false
      Close When Idle=false
      Close on Screensaver=false
      Idle Timeout=10
      Launch Manager=false
      Leave Manager Open=false
      Leave Open=true
      Prompt on Open=false
      Use One Wallet=true

      [org.freedesktop.secrets]
      apiEnabled=true
  register: kwallet_config
```

This task creates or updates the KWallet configuration file (`kwalletrc`). It uses `blockinfile` to ensure idempotency and to create the file if it doesn't exist.

### 3. KWallet Manager Configuration

```yaml
- name: Configure KWallet manager
  ansible.builtin.copy:
    content: |
      [MainWindow]
      ToolBarsMovable=Disabled
    dest: "{{ ansible_env.HOME }}/.config/kwalletmanagerrc"
    force: no
```

This task creates the KWallet manager configuration file if it doesn't exist. The `force: no` option prevents overwriting an existing file.

### 4. KWallet Manager State Configuration

```yaml
- name: Configure KWallet manager state
  ansible.builtin.copy:
    content: |
      [MainWindow]
      2194x1234 screen: Height=354
      2194x1234 screen: Width=288
      RestorePositionForNextInstance=false
      State=AAAA/wAAAAD9AAAAAAAAASAAAAFEAAAABAAAAAQAAAAIAAAACPwAAAAA
    dest: "{{ ansible_env.HOME }}/.local/state/kwalletmanagerstaterc"
    force: no
```

This task creates the KWallet manager state file if it doesn't exist. Like the previous task, `force: no` prevents overwriting an existing file.

### 5. KWallet Service Management

```yaml
- name: Check if KWallet service exists
  ansible.builtin.command: systemctl list-unit-files --type=service | grep -E 'kwalletd|kwallet'
  register: kwallet_service_check
  changed_when: false
  failed_when: false

- name: Restart KWallet service if it exists
  ansible.builtin.systemd:
    name: "{{ item }}"
    state: restarted
    scope: user
  when: 
    - kwallet_config.changed
    - item in kwallet_service_check.stdout
  loop:
    - kwalletd5.service
    - kwalletd.service
  ignore_errors: yes

- name: Notify user if KWallet service was not found
  ansible.builtin.debug:
    msg: "KWallet service not found. You may need to restart it manually or it may not be installed on this system."
  when: kwallet_service_check.rc != 0
```

These tasks handle the KWallet service:
1. Check if a KWallet service exists on the system.
2. If it exists and the configuration has changed, attempt to restart the service.
3. If no service is found, notify the user via a debug message.

## Usage

Include this task in your main playbook (e.g., `site.yml`) to apply KWallet configurations across your systems.

## Considerations

1. **Idempotency**: The tasks are designed to be idempotent, meaning they can be run multiple times without changing the result beyond the initial application.

2. **Flexibility**: The service restart task checks for different possible service names (`kwalletd5.service` and `kwalletd.service`) to accommodate different system configurations.

3. **Error Handling**: The service restart task uses `ignore_errors: yes` to prevent playbook failure if the restart fails for any reason.

4. **User Notification**: If no KWallet service is found, a debug message notifies the user, allowing the playbook to continue without failing.

## Customization

To customize this task for your environment:

1. Modify the KWallet configuration settings in the `Configure KWallet` task to match your desired setup.
2. Adjust the KWallet manager and state configurations if needed.
3. If you have systems that don't use KWallet, consider adding a variable to conditionally skip these tasks.
4. For non-systemd systems, you may need to add alternative methods for managing services.

## Troubleshooting

If you encounter issues:

1. Check the Ansible output for any error messages or debug notifications.
2. Verify that the paths used in the tasks match your system's directory structure.
3. Ensure that the user running the playbook has the necessary permissions to modify the configuration files and restart services.
4. If the KWallet service is not found, manually check if it's installed and running on your system.

Remember to test any modifications in a safe environment before applying them to production systems.
