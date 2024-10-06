# Managing Your Dotfiles with Git

This guide explains how to use Git to manage your configuration files in .config and .local directories directly from your home folder.

## Initial Setup

1. Navigate to your home directory:
   ```
   cd ~
   ```

2. Initialize a new Git repository:
   ```
   git init
   ```

3. Create a .gitignore file to exclude everything except .config and .local:
   ```
   cat << 'EOF' > .gitignore
   *
   !.gitignore
   !.config/
   !.local/
   EOF
   ```

4. Set the default branch name (if not already set):
   ```
   git config --global init.defaultBranch main
   ```

5. Rename the current branch to 'main' if necessary:
   ```
   git branch -m main
   ```

6. Add .config and .local directories to the repository:
   ```
   git add .config .local
   ```

7. Commit the initial state:
   ```
   git commit -m "Initial commit of .config and .local"
   ```

## Tracking Changes

Follow these steps to track changes to your configuration:

1. Make changes in your system as needed.

2. Check which files have been modified:
   ```
   git status
   ```

3. Review the changes:
   ```
   git diff
   ```

4. Stage and commit the changes:
   ```
   git add -A
   git commit -m "Description of changes"
   ```

## Reviewing Changes

- To see changes in a specific commit:
  ```
  git show <commit-hash>
  ```

- To compare changes between commits:
  ```
  git diff <commit-hash1> <commit-hash2>
  ```

- To review all changes since the initial commit:
  ```
  git diff $(git rev-list --max-parents=0 HEAD) HEAD
  ```

## Exporting Changes for Ansible

When ready to convert to Ansible:

1. Export all changes to a file:
   ```
   git diff $(git rev-list --max-parents=0 HEAD) HEAD > all_config_changes.diff
   ```

2. Group related changes into potential Ansible tasks.

3. Identify configuration files and their locations.

4. Research how to apply these changes via command line or config files, which will help in creating Ansible tasks.

## Note

This setup is for local use only. No remote repository is configured, so all changes are tracked only on your local machine. Be cautious about committing sensitive information.

## Applying Configuration to a New System

To apply your configuration on a new system:

1. Clone your dotfiles repository to the new home directory:
   ```
   git clone /path/to/your/dotfiles/repo ~
   ```

2. Your .config and .local directories should now be in place and up to date.

Remember to restart your session or log out and log back in for some changes to take effect.
