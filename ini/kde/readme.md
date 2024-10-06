# Managing Your .config Folder with Git

This guide explains how to use Git to manage your .config folder locally, allowing you to track changes to your configuration files over time, with a focus on KDE Plasma settings.

## Initial Setup

1. Navigate to your .config folder:
   ```
   cd ~/.config
   ```
2. Initialize a new Git repository:
   ```
   git init
   ```
3. Rename the default branch to 'main':
   ```
   git branch -m main
   ```
4. Add all files to the staging area:
   ```
   git add .
   ```
5. Create the initial commit:
   ```
   git commit -m "Initial commit of .config folder"
   ```

## Regular Usage

After the initial setup, use these commands to manage your repository:

- Check the status of your changes:
  ```
  git status
  ```
- Review differences:
  ```
  git diff
  ```
- Stage changes:
  ```
  git add <changed-files>
  ```
- Commit changes:
  ```
  git commit -m "Description of changes"
  ```
- View commit history:
  ```
  git log
  ```

## Tracking KDE Plasma Configuration Changes

To systematically capture KDE Plasma configuration changes for later conversion to Ansible:

1. Focus on one area of configuration at a time (e.g., shortcuts, power settings, themes).
2. Make the desired changes in the KDE Plasma interface.
3. Use `git status` to see which files were modified.
4. Stage the changes:
   ```
   git add -u
   ```
5. Create a commit with a descriptive message:
   ```
   git commit -m "Changed keyboard shortcuts for application launching"
   ```
6. Repeat this process for each logical group of changes.

### Reviewing Changes

- To see the changes in a specific commit:
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

### Exporting Changes for Ansible

When ready to convert to Ansible:

1. Export all changes to a file:
   ```
   git diff <initial-commit-hash> HEAD > all_kde_changes.diff
   ```
2. Group related changes into potential Ansible tasks.
3. Identify configuration files and their locations.
4. Research how to apply these changes via command line or config files, which will help in creating Ansible tasks.

## Ignoring Sensitive Files

To prevent Git from tracking sensitive files:

1. Create a .gitignore file:
   ```
   echo "sensitive_file.conf" >> .gitignore
   ```
2. Add and commit the .gitignore file:
   ```
   git add .gitignore
   git commit -m "Add .gitignore file"
   ```
Replace "sensitive_file.conf" with the names of files or patterns you want Git to ignore.

## Note

This setup is for local use only. No remote repository is configured, so all changes are tracked only on your local machine.
