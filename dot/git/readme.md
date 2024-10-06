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
   /*
   !.gitignore
   !.config/
   !.config/**
   !.local/
   !.local/**
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

## Handling Untracked Files and Directories

When dealing with new, untracked files or directories:

1. Use `git status` to see which directories contain untracked files.

2. For more detailed view of untracked files:
   ```
   git status -u
   ```
   or for even more detail:
   ```
   git status -uall
   ```

3. To see the contents of a specific untracked file:
   ```
   git diff --no-index -- /dev/null 'path/to/specific/file'
   ```

4. If you don't know the names of new files in a directory:
   ```
   ls path/to/directory/
   git diff --no-index -- /dev/null path/to/directory/filename
   ```

5. To stage new files or directories:
   ```
   git add path/to/new/file_or_directory
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

There are two main approaches to exporting changes: exporting all changes since the initial commit, and exporting only recent changes. Choose the approach that best fits your needs.

### Approach 1: Exporting All Changes

Use this approach when you want to export all changes since the initial commit, including untracked files:

1. Stage all changes, including untracked files:
   ```
   git add -A
   ```

2. Create a temporary commit (we'll undo this later):
   ```
   git commit -m "Temporary commit for exporting changes"
   ```

3. Export all changes, including newly added files, to a diff file:
   ```
   git diff $(git rev-list --max-parents=0 HEAD) HEAD > all_config_changes.diff
   ```

4. Undo the temporary commit, keeping the changes staged:
   ```
   git reset --soft HEAD^
   ```

5. Unstage the changes:
   ```
   git reset
   ```

### Approach 2: Exporting Only Recent Changes

Use this approach when you want to export only the most recent changes:

1. If you have uncommitted changes you want to include, first commit them:
   ```
   git add -A
   git commit -m "Recent changes for export"
   ```

2. Export only the most recent commit:
   ```
   git diff HEAD^ HEAD > recent_changes.diff
   ```

   Or, to include staged but uncommitted changes:
   ```
   git diff HEAD > recent_changes.diff
   ```

3. To see these changes before exporting:
   ```
   git diff HEAD^ HEAD
   ```
   Or for staged changes:
   ```
   git diff --staged
   ```

### Working with Exported Diffs

Regardless of the approach you choose:

1. Review the diff file to understand all changes:
   ```
   less all_config_changes.diff
   ```
   or
   ```
   less recent_changes.diff
   ```

2. Group related changes into potential Ansible tasks.

3. Identify configuration files and their locations.

4. Research how to apply these changes via command line or config files, which will help in creating Ansible tasks.

5. For new files that were previously untracked, you may need to use Ansible's `copy` or `template` modules to create these files on the target system.

Remember, you'll need to carefully review and translate these changes into appropriate Ansible tasks.

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
