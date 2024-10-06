# Dotfiles Configuration Management with Ansible

## Project Overview

This project manages and version controls dotfiles and system configurations using Ansible. By converting configuration changes (captured in diff files) into Ansible playbooks, we automate the process of applying these changes across multiple systems or restoring configurations to a known state.

## Project Structure

```
.
├── ans
│   ├── playbooks          # Ansible playbooks generated from diffs
│   └── readme.md          # This file
└── git
    ├── diffs              # Git-related configuration diffs
    └── readme.md          # Git-specific documentation
```

## How It Works

1. **Capture Changes**: When you make changes to your configuration files, capture these changes in a diff file.
2. **Add Diff File**: Add the diff file to the appropriate `diffs` directory (e.g., `git/diffs` for Git-related changes).
3. **Generate Playbook**: Use the diff file to create or update an Ansible playbook in the `ans/playbooks` directory.
4. **Apply Changes**: Run the Ansible playbook to apply the configuration changes to your environment.

## Adding New Configuration Changes

To add a new configuration change:

1. Make the desired changes in your environment.
2. Generate a diff file of the changes:
   ```
   diff -u {old-config-file} {new-config-file} > git/diffs/change-xxx.diff
   ```
   For example, for a Git config change:
   ```
   diff -u ~/.gitconfig.old ~/.gitconfig > git/diffs/gitconfig-update.diff
   ```
3. Create or update an Ansible playbook in the `ans/playbooks/` directory to apply these changes.
   - Use declarative Ansible modules where possible (e.g., `ini_file`, `lineinfile`, `blockinfile`).
   - Ensure idempotency by using appropriate Ansible modules and conditionals.

## Running Playbooks

To apply configuration changes:

```bash
ansible-playbook ans/playbooks/config-001.yml
```

## Best Practices

- Keep diff files organized within the `git/diffs` directory.
- Use meaningful names for diff files and playbooks to easily identify their purpose.
- Comment your Ansible tasks to explain the purpose of each configuration change.
- Test playbooks in a non-production environment before applying to your main system.
- Use version control to track changes to both diff files and playbooks.

## Future Improvements

- Develop a script to automatically generate Ansible tasks from diff files.
- Implement continuous integration to test playbooks against various environments.
- Create a rollback mechanism to revert changes if needed.
- Add support for different types of configurations beyond Git.

By following this structure and process, you can effectively manage your Git configurations using Ansible, allowing for easy replication and version control of your environment setup across multiple systems.

## Additional Notes

- Refer to the `readme.md` file in the `git` directory for specific instructions or notes related to Git configuration management.
- This structure can be extended to manage other types of configurations in the future by adding new directories similar to the `git` directory.
