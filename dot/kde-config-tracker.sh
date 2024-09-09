#!/bin/bash

# Set up directories
BACKUP_DIR="$HOME/kde-config-backup"
CHANGE_LOG="$BACKUP_DIR/changes.log"
SCRIPT_OUTPUT="$BACKUP_DIR/apply_changes.sh"

# Directories to monitor
MONITOR_DIRS=(
    "$HOME/.config"
    "$HOME/.local/share/plasma"
    "$HOME/.kde"
)

# Function to get the next version number
get_next_version() {
    local max_version=0
    for dir in "$BACKUP_DIR"/version_*; do
        if [ -d "$dir" ]; then
            version=${dir##*_}
            if (( version > max_version )); then
                max_version=$version
            fi
        fi
    done
    echo $((max_version + 1))
}

# Initialize backup and log
init_backup() {
    mkdir -p "$BACKUP_DIR"
    touch "$CHANGE_LOG"
    echo "#!/bin/bash" > "$SCRIPT_OUTPUT"
    echo "" >> "$SCRIPT_OUTPUT"
    chmod +x "$SCRIPT_OUTPUT"
}

# Function to create initial snapshot
create_snapshot() {
    local version=$(get_next_version)
    local version_dir="$BACKUP_DIR/version_$version"
    mkdir -p "$version_dir"

    for dir in "${MONITOR_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f | while read file; do
                rel_path="${file#$HOME/}"
                mkdir -p "$version_dir/$(dirname "$rel_path")"
                cp "$file" "$version_dir/$rel_path"
            done
        fi
    done
    echo "Initial snapshot created as version $version at $(date)" >> "$CHANGE_LOG"
}

# Function to check for changes and update snapshot
check_and_update() {
    local prev_version=$(( $(get_next_version) - 1 ))
    local current_version=$(get_next_version)
    local prev_dir="$BACKUP_DIR/version_$prev_version"
    local current_dir="$BACKUP_DIR/version_$current_version"
    
    mkdir -p "$current_dir"

    for dir in "${MONITOR_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f | while read file; do
                rel_path="${file#$HOME/}"
                current_file="$current_dir/$rel_path"
                prev_file="$prev_dir/$rel_path"
                
                if [ ! -f "$prev_file" ]; then
                    # New file
                    mkdir -p "$(dirname "$current_file")"
                    cp "$file" "$current_file"
                    echo "New file in version $current_version: $rel_path" >> "$CHANGE_LOG"
                    echo "# New file: $rel_path" >> "$SCRIPT_OUTPUT"
                    echo "mkdir -p \"\$(dirname \"$rel_path\")\"" >> "$SCRIPT_OUTPUT"
                    echo "cat << 'EOF' > \"$rel_path\"" >> "$SCRIPT_OUTPUT"
                    cat "$file" >> "$SCRIPT_OUTPUT"
                    echo "EOF" >> "$SCRIPT_OUTPUT"
                    echo "" >> "$SCRIPT_OUTPUT"
                elif ! cmp -s "$file" "$prev_file"; then
                    # File changed
                    mkdir -p "$(dirname "$current_file")"
                    cp "$file" "$current_file"
                    echo "Changed in version $current_version: $rel_path" >> "$CHANGE_LOG"
                    echo "# Changed: $rel_path" >> "$SCRIPT_OUTPUT"
                    echo "cat << 'EOF' > \"$rel_path\"" >> "$SCRIPT_OUTPUT"
                    cat "$file" >> "$SCRIPT_OUTPUT"
                    echo "EOF" >> "$SCRIPT_OUTPUT"
                    echo "" >> "$SCRIPT_OUTPUT"
                else
                    # File unchanged, copy from previous version
                    mkdir -p "$(dirname "$current_file")"
                    cp "$prev_file" "$current_file"
                fi
            done
        fi
    done
}

# Main execution
init_backup

if [ ! -d "$BACKUP_DIR/version_1" ]; then
    create_snapshot
else
    check_and_update
fi

echo "KDE configuration check completed at $(date)" >> "$CHANGE_LOG"
echo "Changes have been logged and a script to apply changes has been updated."
