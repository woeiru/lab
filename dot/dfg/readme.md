# DOT FILES with GIT

This guide explains how to use Git to manage all your configuration files in .config and .local directories.

## Initial Setup

1. Create a new directory in your home folder to store your dotfiles:
   ```
   mkdir ~/dotfiles
   cd ~/dotfiles
   ```

2. Set the default branch name for new repositories:
   ```
   git config --global init.defaultBranch main
   ```

3. Initialize a new Git repository:
   ```
   git init
   ```

4. Verify that the branch is named 'main':
   ```
   git branch
   ```

5. Create symbolic links for .config and .local:
   ```
   ln -s ~/.config config
   ln -s ~/.local local
   ```

6. Add all files to the repository:
   ```
   git add .
   ```

7. Commit the initial state:
   ```
   git commit -m "Initial commit of all dotfiles"
   ```

## Tracking Changes

Follow these steps to track changes to your configuration:

1. Make changes in your system as needed.

2. Check which files have been modified:
   ```
   cd ~/dotfiles
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

## Restoring Configuration

To restore your configuration on a new system:

1. Clone your dotfiles repository:
   ```
   git clone /path/to/your/dotfiles/repo ~/dotfiles
   ```

2. Create symbolic links:
   ```
   ln -s ~/dotfiles/config ~/.config
   ln -s ~/dotfiles/local ~/.local
   ```

Remember to restart your session or log out and log back in for some changes to take effect.
