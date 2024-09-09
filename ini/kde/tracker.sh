#!/bin/bash

# Check if a username is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME=$1
USER_HOME="/home/$USERNAME"
BACKUP_DIR="$USER_HOME/.kde-config-backup"
CHANGE_LOG="$BACKUP_DIR/changes.log"
SCRIPT_OUTPUT="$BACKUP_DIR/apply_changes.sh"

# Directories to monitor
MONITOR_DIRS=(
    "$USER_HOME/.config"
    "$USER_HOME/.local/share/plasma"
    "$USER_HOME/.kde"
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
    chown -R $USERNAME:$USERNAME "$BACKUP_DIR"
}

# Function to create initial snapshot
create_snapshot() {
    local version=$(get_next_version)
    local version_dir="$BACKUP_DIR/version_$version"
    mkdir -p "$version_dir"

    for dir in "${MONITOR_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f | while read file; do
                rel_path="${file#$USER_HOME/}"
                mkdir -p "$version_dir/$(dirname "$rel_path")"
                cp "$file" "$version_dir/$rel_path"
            done
        fi
    done
    echo "Initial snapshot created as version $version at $(date)" >> "$CHANGE_LOG"
    chown -R $USERNAME:$USERNAME "$version_dir"
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
                rel_path="${file#$USER_HOME/}"
                current_file="$current_dir/$rel_path"
                prev_file="$prev_dir/$rel_path"
                
                if [ ! -f "$prev_file" ] || ! cmp -s "$file" "$prev_file"; then
                    # New or changed file
                    mkdir -p "$(dirname "$current_file")"
                    cp "$file" "$current_file"
                    echo "Updated in version $current_version: $rel_path" >> "$CHANGE_LOG"
                else
                    # File unchanged, copy from previous version
                    mkdir -p "$(dirname "$current_file")"
                    cp "$prev_file" "$current_file"
                fi
            done
        fi
    done
    chown -R $USERNAME:$USERNAME "$current_dir"
}

# Function to create the apply_changes script
create_apply_script() {
    cat << EOF > "$SCRIPT_OUTPUT"
#!/bin/bash

BACKUP_DIR="$BACKUP_DIR"
USER_HOME="$USER_HOME"

apply_version() {
    local version=\$1
    local version_dir="\$BACKUP_DIR/version_\$version"
    
    if [ ! -d "\$version_dir" ]; then
        echo "Version \$version does not exist."
        exit 1
    fi

    echo "Applying configuration version \$version..."
    
    find "\$version_dir" -type f | while read file; do
        rel_path="\${file#\$version_dir/}"
        target_file="\$USER_HOME/\$rel_path"
        mkdir -p "\$(dirname "\$target_file")"
        cp "\$file" "\$target_file"
        echo "Updated: \$rel_path"
    done

    echo "Configuration version \$version has been applied."
    
    echo "Restarting Plasma shell to apply changes..."
    kquitapp5 plasmashell || killall plasmashell && kstart5 plasmashell &
    echo "Plasma shell restart initiated. Changes should now be visible."
}

if [ "\$1" == "latest" ]; then
    latest_version=\$(ls -d \$BACKUP_DIR/version_* | sort -V | tail -n 1 | sed 's/.*version_//')
    apply_version \$latest_version
elif [ -n "\$1" ]; then
    apply_version \$1
else
    echo "Usage: \$0 <version_number> or \$0 latest"
    echo "Available versions:"
    ls -d \$BACKUP_DIR/version_* | sed 's/.*version_//'
fi
EOF

    chmod +x "$SCRIPT_OUTPUT"
    chown $USERNAME:$USERNAME "$SCRIPT_OUTPUT"
}

# Main execution
init_backup

if [ ! -d "$BACKUP_DIR/version_1" ]; then
    create_snapshot
else
    check_and_update
fi

create_apply_script

echo "KDE configuration check completed at $(date)" >> "$CHANGE_LOG"
echo "Changes have been logged and apply_changes.sh has been updated."
echo "To apply changes, run: $SCRIPT_OUTPUT <version_number> or $SCRIPT_OUTPUT latest"
