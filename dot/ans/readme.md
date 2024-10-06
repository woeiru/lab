# Ansible Deployment and Maintenance Guide

This guide walks you through the process of setting up Ansible, deploying roles to your localhost, and maintaining your Ansible project.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installing Ansible](#installing-ansible)
3. [Project Structure](#project-structure)
4. [Configuring Ansible](#configuring-ansible)
5. [Running Playbooks](#running-playbooks)
6. [Customizing Roles](#customizing-roles)
7. [Maintenance Tips](#maintenance-tips)
8. [Troubleshooting](#troubleshooting)

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

Your Ansible project is organized as follows:

```
/root/lab/dot/ans/
├── ansible.cfg
├── inventory
├── readme.md
├── roles/
│   ├── editor_config/
│   │   ├── files/
│   │   │   ├── Profile 1.profile
│   │   │   └── Profile 2.profile
│   │   └── tasks/
│   │       ├── konsole.yml
│   │       └── main.yml
│   └── system_preferences/
│       └── tasks/
│           ├── main.yml
│           └── wallpaper.yml
└── start/
    └── site.yml
```

This structure will evolve as you add more roles and tasks.

## Configuring Ansible

1. Create an `ansible.cfg` file in your project root:
   ```ini
   [defaults]
   inventory = inventory
   roles_path = ./roles
   ```

2. Create an inventory file named `inventory` in your project root:
   ```
   localhost ansible_connection=local
   ```
   This defines localhost as a target for Ansible, using a local connection.

## Running Playbooks

1. Your main playbook (`start/site.yml`) should look like this:
   ```yaml
   ---
   - hosts: localhost
     vars:
       config_editor: true
       config_system_prefs: true
     roles:
       - { role: editor_config, when: config_editor | bool, tags: ['editor'] }
       - { role: system_preferences, when: config_system_prefs | bool, tags: ['system'] }
     # Commented roles can be uncommented and added similarly when needed
     # - { role: development_env, when: config_dev_env | bool, tags: ['dev'] }
     # - { role: gui_apps, when: config_gui | bool, tags: ['gui'] }
     # - { role: security_config, when: config_security | bool, tags: ['security'] }
     # - { role: shell_config, when: config_shell | bool, tags: ['shell'] }
   ```

2. Run the playbook:
   ```
   ansible-playbook start/site.yml
   ```

3. For a dry run (check mode):
   ```
   ansible-playbook start/site.yml --check
   ```

4. For a dry run with detailed diff output:
   ```
   ansible-playbook start/site.yml --check --diff
   ```

5. To run specific parts of the playbook:
   - Use tags: `ansible-playbook start/site.yml --tags editor`
   - Use variables: `ansible-playbook start/site.yml --extra-vars "config_editor=false"`

## Customizing Roles

Each role has a `tasks/main.yml` file that defines its tasks. To customize a role:

1. Navigate to the role's directory (e.g., `roles/editor_config/`).
2. Edit the `tasks/main.yml` file to add or modify tasks.
3. Add new configuration files in the `files/` directory of the role if needed.

Example (`roles/editor_config/tasks/main.yml`):
```yaml
---
- name: Include Konsole configuration tasks
  include_tasks: konsole.yml

# Add more editor configuration tasks here
```

## Maintenance Tips

1. **Adding New Roles**: 
   - Create a new directory under `roles/`.
   - Add a `tasks/main.yml` file in the new role directory.
   - Include the new role in `start/site.yml`.

2. **Modifying Existing Roles**:
   - Edit the `tasks/main.yml` file in the respective role directory.
   - Add new task files and include them in `main.yml` if needed.

3. **Best Practices**:
   - Use relative paths in your playbooks and role definitions.
   - Utilize variables for paths that might change across environments.
   - Use `{{ playbook_dir }}` to reference files relative to your playbook location.
   - For files within a role, use `{{ role_path }}`.

4. **Version Control**:
   - Keep your Ansible project in a version control system like Git.
   - Use meaningful commit messages to track changes.

5. **Testing**:
   - Test changes on a non-production system before applying to your main environment.
   - Consider using Ansible Molecule for role testing.

6. **Documentation**:
   - Keep this README updated as you modify your project.
   - Document role-specific details in a README within each role directory.

7. **Security**:
   - Use Ansible Vault for sensitive data.
   - Regularly update Ansible to the latest stable version.

## Troubleshooting

- If you encounter permission issues, try running the playbook with `sudo`:
  ```
  sudo ansible-playbook start/site.yml
  ```

- For more verbose output, add the `-v`, `-vv`, or `-vvv` flag:
  ```
  ansible-playbook -v start/site.yml
  ```

- Check [Ansible documentation](https://docs.ansible.com/) for specific error messages.

Remember to run your playbook from the project root directory (/root/lab/dot/ans/) to ensure proper path resolution. Always test changes in a safe environment before applying them to your main system.

For any questions or issues, refer to the Ansible documentation or seek community support.
