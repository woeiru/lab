#!/bin/bash

# tracker.sh v1

# Set up directories
SCRIPT_DIR="/root/lab/dot/git"
TMP_DIR="$HOME/.tmp"
DATA_DIR="$TMP_DIR/labdotgit"
LOG_DIR="$DATA_DIR/logs"
EXPORT_DIR="$DATA_DIR/exports"

# Store the original working directory
ORIGINAL_DIR=$(pwd)

# Function to ensure directories exist
ensure_directories() {
    mkdir -p "$TMP_DIR" "$LOG_DIR" "$EXPORT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create necessary directories. Please check permissions."
        exit 1
    fi
    echo "Necessary directories have been created or already exist."
}

# Ensure directories exist before proceeding
ensure_directories

# Set up logging
LOG_FILE="$LOG_DIR/dotfiles_manager_$(date '+%Y%m%d').log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    log "ERROR: $1"
    cd "$ORIGINAL_DIR"
    exit 1
}

# Function to check if a command was successful
check_success() {
    if [ $? -ne 0 ]; then
        error "$1"
    fi
}

# Change to home directory
cd "$HOME" || error "Failed to change to home directory"
log "Changed working directory to $HOME"

# Function to initialize the repository
initialize_repo() {
    log "Initializing repository..."
    git init
    check_success "Failed to initialize Git repository"

    log "Creating .gitignore file..."
    cat << 'EOF' > .gitignore
/*
!.gitignore
!.config/
!.config/**
!.local/
!.local/**
EOF
    check_success "Failed to create .gitignore file"

    log "Setting default branch name..."
    git config --global init.defaultBranch main
    check_success "Failed to set default branch name"

    log "Renaming current branch to 'main'..."
    git branch -m main
    check_success "Failed to rename branch"

    log "Adding .config and .local directories..."
    git add .config .local
    check_success "Failed to add directories"

    log "Committing initial state..."
    git commit -m "Initial commit of .config and .local"
    check_success "Failed to commit initial state"

    log "Repository initialized successfully"
}

# Function to track changes
track_changes() {
    log "Checking for changes..."
    git status

    read -p "Do you want to review changes? (y/n): " review_changes
    if [[ $review_changes =~ ^[Yy]$ ]]; then
        git diff
    fi

    read -p "Do you want to commit these changes? (y/n): " commit_changes
    if [[ $commit_changes =~ ^[Yy]$ ]]; then
        read -p "Enter commit message: " commit_message
        git add -A
        git commit -m "$commit_message"
        check_success "Failed to commit changes"
        log "Changes committed successfully"
    else
        log "Changes not committed"
    fi
}

# Function to handle untracked files
handle_untracked() {
    log "Checking for untracked files..."
    echo "Current status of the repository:"
    git status -u

    read -p "Do you want to see the contents of any untracked files? (y/n): " view_untracked
    if [[ $view_untracked =~ ^[Yy]$ ]]; then
        echo "List of untracked files:"
        git ls-files --others --exclude-standard
        read -p "Enter the path to the untracked file: " untracked_file
        git diff --no-index -- /dev/null "$untracked_file"
    fi

    read -p "Do you want to stage any untracked files? (y/n): " stage_untracked
    if [[ $stage_untracked =~ ^[Yy]$ ]]; then
        echo "List of untracked files:"
        git ls-files --others --exclude-standard
        read -p "Enter the path to the file or directory to stage: " stage_path
        git add "$stage_path"
        check_success "Failed to stage $stage_path"
        log "$stage_path staged successfully"
    fi
}

# Function to review changes
review_changes() {
    echo "Recent commits:"
    git log --oneline -n 10  # Show the last 10 commits
    echo ""

    read -p "Enter commit hash to review (leave blank for all changes): " commit_hash
    if [ -z "$commit_hash" ]; then
        echo "Showing all changes since the initial commit:"
        git diff $(git rev-list --max-parents=0 HEAD) HEAD
    else
        echo "Showing changes for commit $commit_hash:"
        git show "$commit_hash"
    fi
}

# Function to export changes
export_changes() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    read -p "Export all changes (a) or recent changes (r)? " export_type
    if [[ $export_type =~ ^[Aa]$ ]]; then
        log "Exporting all changes..."
        git add -A
        git commit -m "Temporary commit for exporting changes"
        git diff $(git rev-list --max-parents=0 HEAD) HEAD > "$EXPORT_DIR/all_config_changes_$timestamp.diff"
        git reset --soft HEAD^
        git reset
        log "All changes exported to $EXPORT_DIR/all_config_changes_$timestamp.diff"
    elif [[ $export_type =~ ^[Rr]$ ]]; then
        log "Exporting recent changes..."
        git diff HEAD > "$EXPORT_DIR/recent_changes_$timestamp.diff"
        log "Recent changes exported to $EXPORT_DIR/recent_changes_$timestamp.diff"
    else
        error "Invalid export type selected"
    fi

    log "Handling untracked files..."
    git status -u | grep "^??" | cut -d' ' -f2- | while read -r file; do
        git diff --no-index -- /dev/null "$file" > "$EXPORT_DIR/${file##*/}_$timestamp.diff"
        log "Untracked file $file exported to $EXPORT_DIR/${file##*/}_$timestamp.diff"
    done
}

# Main menu
while true; do
    echo "
Dotfiles Manager Menu:
1. Initialize repository
2. Track changes
3. Handle untracked files
4. Review changes
5. Export changes
6. Exit
"
    read -p "Enter your choice: " choice

    case $choice in
        1) initialize_repo ;;
        2) track_changes ;;
        3) handle_untracked ;;
        4) review_changes ;;
        5) export_changes ;;
        6) log "Exiting Dotfiles Manager"; break ;;
        *) log "Invalid option. Please try again." ;;
    esac
done

# Return to the original directory
cd "$ORIGINAL_DIR"
log "Returned to original directory: $ORIGINAL_DIR"

exit 0
