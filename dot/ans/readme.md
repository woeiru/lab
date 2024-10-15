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
9. [Advanced Execution Scenarios](#advanced-execution-scenarios)

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
│   └── desk_1/
│       └── tasks/
│           └── main.yml
└── site.yml
```

This structure may evolve as you add more roles and tasks.

## Configuring Ansible

1. The `ansible.cfg` file in your project root contains:
   ```ini
   [defaults]
   inventory = inventory
   roles_path = ./roles
   ```

2. The inventory file named `inventory` in your project root contains:
   ```
   localhost ansible_connection=local
   ```
   This defines localhost as a target for Ansible, using a local connection.

## Running Playbooks

1. Your main playbook (`site.yml`) looks like this:
   ```yaml
   - hosts: localhost
     vars:
       config_desk_1: true
     roles:
       - { role: desk_1, when: config_desk_1 | bool, tags: ['desk'] }
   ```

2. Run the playbook:
   ```
   ansible-playbook site.yml
   ```

3. For a dry run (check mode):
   ```
   ansible-playbook site.yml --check
   ```

4. For a dry run with detailed diff output:
   ```
   ansible-playbook site.yml --check --diff
   ```

5. To run specific parts of the playbook:
   - Use tags: `ansible-playbook site.yml --tags desk`
   - Use variables: `ansible-playbook site.yml --extra-vars "config_desk_1=false"`

## Customizing Roles

The `desk_1` role has a `tasks/main.yml` file that defines its tasks. To customize this role:

1. Navigate to the role's directory (`roles/desk_1/`).
2. Edit the `tasks/main.yml` file to add or modify tasks.

The current `main.yml` file includes tasks for:
- Configuring Konsole profiles
- Disabling KWallet
- Configuring keyboard layout

## Maintenance Tips

1. **Modifying Existing Roles**:
   - Edit the `tasks/main.yml` file in the `desk_1` role directory.
   - Add new task files and include them in `main.yml` if needed.

2. **Best Practices**:
   - Use relative paths in your playbooks and role definitions.
   - Utilize variables for paths that might change across environments.
   - Use `{{ ansible_env.HOME }}` for user home directory paths.

3. **Version Control**:
   - Keep your Ansible project in a version control system like Git.
   - Use meaningful commit messages to track changes.

4. **Testing**:
   - Test changes on a non-production system before applying to your main environment.
   - Use the `--check` flag for dry runs.

5. **Documentation**:
   - Keep this README updated as you modify your project.
   - Document role-specific details in comments within the YAML files.

6. **Security**:
   - Use Ansible Vault for sensitive data if needed.
   - Regularly update Ansible to the latest stable version.

## Troubleshooting

- If you encounter permission issues, try running the playbook with `sudo`:
  ```
  sudo ansible-playbook site.yml
  ```

- For more verbose output, add the `-v`, `-vv`, or `-vvv` flag:
  ```
  ansible-playbook -v site.yml
  ```

- Check [Ansible documentation](https://docs.ansible.com/) for specific error messages.

Remember to run your playbook from the project root directory (/root/lab/dot/ans/) to ensure proper path resolution. Always test changes in a safe environment before applying them to your main system.

For any questions or issues, refer to the Ansible documentation or seek community support.

## Advanced Execution Scenarios

### Running as a Non-Root User

While this playbook is typically run as root, you can also run it as a normal user with some modifications:

1. Ensure your user has sudo privileges.

2. Modify the `site.yml` file to use `become` for privilege escalation:

   ```yaml
   - hosts: localhost
     vars:
       config_desk_1: true
     roles:
       - { role: desk_1, when: config_desk_1 | bool, tags: ['desk'] }
     become: true
     become_method: sudo
     become_user: root
   ```

3. In your roles' task files, use `become: true` only for tasks that require root privileges.

4. Run the playbook with the `--ask-become-pass` or `-K` flag:

   ```
   ansible-playbook site.yml --ask-become-pass
   ```

   This will prompt you for your sudo password.

Remember to test thoroughly when switching between root and non-root execution to ensure all tasks work as expected.

### Running a Root-Owned Ansible Playbook as a Normal User

When your Ansible playbook is located in a root-owned directory (e.g., /root/lab/dot/ans), you can still run it as a normal user by using sudo. Here's how:

1. Ensure your user has sudo privileges.

2. Use sudo to run the ansible-playbook command:

   ```
   sudo ansible-playbook /root/lab/dot/ans/site.yml
   ```

3. If your playbook uses `become` for privilege escalation, you might need to use the `-b` flag:

   ```
   sudo ansible-playbook -b /root/lab/dot/ans/site.yml
   ```

4. If you need to specify the inventory file, use the `-i` flag:

   ```
   sudo ansible-playbook -b -i /root/lab/dot/ans/inventory /root/lab/dot/ans/site.yml
   ```

5. To avoid potential issues with environment variables or user-specific configurations, you may want to use the `-H` flag with sudo, which sets the HOME environment variable to the target user's home directory:

   ```
   sudo -H ansible-playbook -b -i /root/lab/dot/ans/inventory /root/lab/dot/ans/site.yml
   ```

Remember:
- Using sudo will run the playbook with root privileges, so be cautious and ensure you trust the playbook content.
- If your playbook references files using relative paths, you may need to adjust these or use absolute paths.
- Always test in a safe environment before running on your main system.

NOTE: While this method works, it's generally better practice to store Ansible playbooks in a location accessible to the users who need to run them, rather than in /root. Consider discussing with your system administrator about moving the playbook to a more appropriate location.
