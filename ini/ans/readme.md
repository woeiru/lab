# Ansible Deployment Guide for Beginners

This guide will walk you through the process of setting up Ansible and deploying roles to your localhost, from installation to execution.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installing Ansible](#installing-ansible)
3. [Project Structure](#project-structure)
4. [Configuring Ansible](#configuring-ansible)
5. [Running Playbooks](#running-playbooks)
6. [Customizing Roles](#customizing-roles)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

- A Unix-like operating system (Linux or macOS)
- Python 3.x installed
- Basic knowledge of YAML syntax
- Familiarity with command-line operations

## Installing Ansible

The installation method depends on your operating system:

### For Fedora (or other RPM-based systems):

1. Open your terminal.
2. Install Ansible using DNF:
   ```
   sudo dnf install ansible
   ```

### For other systems:

1. Open your terminal.
2. Install Ansible using pip (Python package manager):
   ```
   pip install ansible
   ```

After installation, verify it by running:
```
ansible --version
```

## Project Structure

Your Ansible project is organized with roles and a `start` directory for playbooks. The structure will evolve over time as you add more roles and tasks.

## Configuring Ansible

1. Create an `ansible.cfg` file in your project root:
   ```
   [defaults]
   inventory = inventory
   roles_path = ./roles
   ```

2. Create an inventory file named `inventory` in your project root with the following content:
   ```
   localhost ansible_connection=local
   ```
   This single line defines localhost as a target for Ansible, using a local connection.

## Running Playbooks

1. Create a main playbook (e.g., `site.yml`) in the `start` directory:
   ```yaml
   ---
   - hosts: localhost
     roles:
       - development_env
       - editor_config
       - gui_apps
       - security_config
       - shell_config
       - system_preferences
   ```

2. Run the playbook:
   ```
   ansible-playbook start/site.yml
   ```

3. To perform a dry run (check mode):
   ```
   ansible-playbook start/site.yml --check
   ```
   This simulates the execution without making any changes to your system.

4. For a dry run with detailed diff output:
   ```
   ansible-playbook start/site.yml --check --diff
   ```
   This shows you what changes would be made without actually applying them.

## Customizing Roles

Each role has a `tasks/main.yml` file that defines its tasks. To customize a role:

1. Navigate to the role's directory (e.g., `roles/editor_config/`).
2. Edit the `tasks/main.yml` file to add or modify tasks.
3. If you need to add new configuration files, place them in the `files/` directory of the role.

Example (`roles/editor_config/tasks/main.yml`):
```yaml
---
- name: Include Konsole configuration tasks
  include_tasks: konsole.yml

- name: Your new task here
  # Task definition
```

## Troubleshooting

- If you encounter permission issues, try running the playbook with `sudo`:
  ```
  sudo ansible-playbook start/site.yml
  ```

- For more verbose output, add the `-v` flag:
  ```
  ansible-playbook -v start/site.yml
  ```

- Check Ansible documentation for specific error messages: [Ansible Docs](https://docs.ansible.com/)

Remember to review and understand each role before deploying, especially when adding new roles or tasks. Always test changes in a safe environment before applying them to your main system.
