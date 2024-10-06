# Managing Your Dotfiles with Git

This guide explains how to use Git to manage your configuration files (dotfiles) across multiple directories, with a focus on KDE Plasma settings.

## Initial Setup

1. Create a new directory in your home folder to store your dotfiles:
   ```
   mkdir ~/dotfiles
   cd ~/dotfiles
   ```

2. Set the default branch name for new repositories (you can choose 'main' or any other name you prefer):
   ```
   git config --global init.defaultBranch main
   ```

3. Initialize a new Git repository:
   ```
   git init
   ```

4. Verify that the branch is named 'main' (or the name you chose):
   ```
   git branch
   ```

5. Create symbolic links for .config and .local:
   ```
   ln -s ~/.config config
   ln -s ~/.local local
   ```

6. Create a .gitignore file to exclude unnecessary files:
   ```
   echo "
   *
   !config/
   !local/
   !config/kde*
   !config/plasma*
   !local/share/plasma*
   !.gitignore
   " > .gitignore
   ```

   This .gitignore setup ignores everything by default, then explicitly includes the directories and files we want to track.

7. Add and commit the initial state:
   ```
   git add .
   git commit -m "Initial commit of dotfiles"
   ```

## Tracking Changes

Follow these steps to track changes to your KDE Plasma configuration:

1. Make changes in the KDE Plasma interface as needed.

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
   git add -u
   git commit -m "Description of KDE Plasma changes"
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
  git diff <initial-commit-hash> HEAD
  ```

## Exporting Changes for Ansible

When ready to convert to Ansible:

1. Export all changes to a file:
   ```
   git diff <initial-commit-hash> HEAD > all_kde_changes.diff
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

Remember to restart your KDE Plasma session or log out and log back in for some changes to take effect.
