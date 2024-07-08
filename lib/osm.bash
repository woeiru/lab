# Define directory and file variables
DIR_LIB="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_LIB=$(basename "$BASH_SOURCE")
BASE_LIB="${FILE_LIB%.*}"
FILEPATH_LIB="${DIR_LIB}/${FILE_LIB}"
CONFIG_LIB="$DIR_LIB/../var/${BASE_LIB}.conf"

# Dynamically create variables based on the base name
eval "FILEPATH_${BASE_LIB}=\$FILEPATH_LIB"
eval "FILE_${BASE_LIB}=\$FILE_LIB"
eval "BASE_${BASE_LIB}=\$BASE_LIB"
eval "CONFIG_${BASE_LIB}=\$CONFIG_LIB"

# Source the configuration file
if [ -f "$CONFIG_LIB" ]; then
    source "$CONFIG_LIB"
else
    echo "Configuration file $CONFIG_LIB not found!"
    exit 1
fi

#
# overview functions
#
osm-fun() {
    all-laf "$FILEPATH_osm"
}
#
# overview variables
#
osm-var() {
    all-acu o "$DIR_LIB/.." "$CONFIG_osm"
}

# Transform a folder subvolume.
# transforming folder subvolume
# <folder_name> <user_name> <C>
osm-tra() {
    if [ $# -ne 3 ]; then
        echo "Usage: osm-trans <folder_name> <user_name> <C>"
        return 1
    fi

    local folder_name="$1"
    local user_name="$2"
    local attr_cow="$3"
    local old_swap="${folder_name}-old"

    # Move current folder to .folder_name-old
    cmd1="mv $folder_name $old_swap"
    read -p "$cmd1"
    eval "$cmd1"

    # Create new subvolume
    cmd2="sudo btrfs subvolume create $folder_name"
    read -p "$cmd2"
    eval "$cmd2"

    # Change ownership to specified user
    cmd3="sudo chown $user_name: $folder_name"
    read -p "$cmd3"
    eval "$cmd3"

    # Disable copy-on-write on new target
    if [ "$attr_cow" = "C" ]; then
        cmd4="sudo chattr +C $folder_name"
        read -p "$cmd4"
        eval "$cmd4"
    else
        echo "COW Stays Enabled"
    fi

    # Move contents from old folder to new one
    cmd5="mv $old_swap/* $folder_name"
    read -p "$cmd5"
    eval "$cmd5"

    # Remove old folder
    cmd6="rm -r $old_swap"
    read -p "$cmd6"
    eval "$cmd6"
}

# Check subvolume folder and filter results.
# check subvolume folder
# <path> <folder_type: 1=regular, 2=hidden, 3=both> <yes=show subvolumes, no=show non-subvolumes, all=show all>
osm-csf() {
    local path="$1"
    local folder_type="$2"
    local filter="$3"

    # Check if arguments are provided
    if [ -z "$path" ] || [ -z "$folder_type" ] || [ -z "$filter" ]; then
        all-use
        return 1
    fi

    # Check if the path exists and is a directory
    if [ ! -d "$path" ]; then
        echo "Error: $path is not a valid directory."
        return 1
    fi

    # Get the output of 'btrfs sub list' in the specified directory
    local subvol_output
    subvol_output=$(btrfs sub list -o "$path")

    # Get the list of folders based on folder type and sort alphabetically
    local all_folders
    if [ "$folder_type" -eq 1 ]; then
        all_folders=$(find "$path" -mindepth 1 -maxdepth 1 ! -name ".*" -type d -exec basename {} \; | sort)
    elif [ "$folder_type" -eq 2 ]; then
        all_folders=$(find "$path" -mindepth 1 -maxdepth 1 -name ".*" -type d -exec basename {} \; | sort)
    elif [ "$folder_type" -eq 3 ]; then
        all_folders=$(find "$path" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
    else
        echo "Error: Invalid folder type argument. Please specify 1, 2, or 3."
        return 1
    fi

    # Iterate over each folder and filter based on the third argument
    local folder_name
    for folder_name in $all_folders; do
        local is_subvol="no"
        if echo "$subvol_output" | grep -q "$path/$folder_name"; then
            is_subvol="yes"
        fi

        # Print the folder path and whether it is a subvolume based on the filter
        if [ "$filter" == "yes" ] && [ "$is_subvol" == "yes" ]; then
            printf "%-40s %-3s\n" "$path/$folder_name" "$is_subvol"
        elif [ "$filter" == "no" ] && [ "$is_subvol" == "no" ]; then
            printf "%-40s %-3s\n" "$path/$folder_name" "$is_subvol"
        elif [ "$filter" == "all" ]; then
            printf "%-40s %-3s\n" "$path/$folder_name" "$is_subvol"
        fi
    done
}

# snapper -c home_* create
# snapper home create
# <configname>
osm-shc() {
    local configname=$1

    if [ -z "$configname" ]; then
        all-use
        return 1
    fi

    if [ "$configname" == "home" ]; then
        # Get the list of configs
        configs=$(snapper list-configs | awk '$1 ~ /^home_/ {print $1}')

        # Count the number of home_ configs
        config_count=$(echo "$configs" | wc -l)

        if [ "$config_count" -eq 0 ]; then
            echo "No configurations found starting with 'home_'."
            return 1
        elif [ "$config_count" -eq 1 ]; then
            configname=$(echo "$configs" | head -n 1)
            echo "Using configuration: $configname"
        else
            echo "Multiple configurations found starting with 'home_':"
            echo "$configs"
            echo "Please enter the configuration name to use:"
            read selected_config
            if echo "$configs" | grep -q "^$selected_config$"; then
                configname=$selected_config
            else
                echo "Invalid configuration selected."
                return 1
            fi
        fi
    fi

    echo "snapper -c "$configname" create"
    snapper -c "$configname" create
}
# snapper -c home_* delete <snapshot>
# snapper home delete <snapshot>
# <configname> <snapshot>
osm-shd() {
    local configname
    local snapshot

    if [ $# -eq 0 ]; then
        echo "Usage: osm-shd <snapshot> [<configname>]"
        return 1
    elif [ $# -eq 1 ]; then
        snapshot=$1
    else
        snapshot=$1
        configname=$2
    fi

    if [ -z "$configname" ]; then
        # Get the list of configs
        configs=$(snapper list-configs | awk '$1 ~ /^home_/ {print $1}')

        # Count the number of home_ configs
        config_count=$(echo "$configs" | wc -l)

        if [ "$config_count" -eq 0 ]; then
            echo "No configurations found starting with 'home_'."
            return 1
        elif [ "$config_count" -eq 1 ]; then
            configname=$(echo "$configs" | head -n 1)
            echo "Using configuration: $configname"
        else
            echo "Multiple configurations found starting with 'home_':"
            echo "$configs"
            echo "Please enter the configuration name to use:"
            read selected_config
            if echo "$configs" | grep -q "^$selected_config$"; then
                configname=$selected_config
            else
                echo "Invalid configuration selected."
                return 1
            fi
        fi
    fi

    echo "snapper -c "$configname" delete "$snapshot""
    snapper -c "$configname" delete "$snapshot"
}

# snapper -c home_* list
# snapper home list
# <configname>
osm-shl() {
    local configname=$1

    if [ -z "$configname" ]; then
        all-use
        return 1
    fi

    if [ "$configname" == "home" ]; then
        # Get the list of configs
        configs=$(snapper list-configs | awk '$1 ~ /^home_/ {print $1}')

        # Count the number of home_ configs
        config_count=$(echo "$configs" | wc -l)

        if [ "$config_count" -eq 0 ]; then
            echo "No configurations found starting with 'home_'."
            return 1
        elif [ "$config_count" -eq 1 ]; then
            configname=$(echo "$configs" | head -n 1)
            echo "Using configuration: $configname"
        else
            echo "Multiple configurations found starting with 'home_':"
            echo "$configs"
            echo "Please enter the configuration name to use:"
            read selected_config
            if echo "$configs" | grep -q "^$selected_config$"; then
                configname=$selected_config
            else
                echo "Invalid configuration selected."
                return 1
            fi
        fi
    fi

    echo "snapper -c "$configname" list"
    snapper -c "$configname" list
}

# Resyncing a Btrfs snapshot to a flat folder
# snapshot flat resync
# <snapshot subvolume> <target folder>
osm-sfr() {
    local snapshot_sub="$1"
    local target_folder="$2"

    # Check if arguments are provided
    if [ -z "$snapshot_sub" ] || [ -z "$target_folder" ]; then
	all-use
        return 1
    fi

    # Perform rsync with exclusions
    rsync -aAXv --delete \
        --exclude='.snapshots' \
        --exclude='.ssh' \
        "$snapshot_sub/" "$target_folder"

    # Check rsync exit status
    local rsync_status=$?
    if [ $rsync_status -ne 0 ]; then
        echo "rsync encountered an error. Exit status: $rsync_status"
    fi
}
# creating a subvol on bak then sending snapshots there
# home user backups
# <user> <snapshots: "all">
osm-hub() {
    local username="$1"
    local snapshot_option="$2"
    local source_sub="/home/$username"
    local source_dir="$source_sub/.snapshots"
    local backup_home="/bak"
    local backup_sub="$backup_home/$username"
    local backup_dir="$backup_sub/.snapshots"
    local log_file="$backup_home/.$username.log"

    if [ $# -ne 2 ]; then
        all-use
        return 1
    fi

    log() {
       local message="$1"
       local short_timestamp=$(date '+%H:%M')
       local full_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
       echo "$short_timestamp - $message"
       echo "$full_timestamp - $message" >> "$log_file"
    }

    log_variables() {
        log "Username: $username"
        log "Snapshot option: $snapshot_option"
        log "Source user sub: $source_sub"
        log "Source snapshot dir: $source_dir"
        log "Backup drive: $backup_drive"
        log "Backup home: $backup_home"
        log "Backup user sub: $backup_sub"
        log "Backup snapshot dir: $backup_dir"
    }

    check_directories() {
        
	if [ ! -d "$source_sub" ]; then
            log "User home directory $source_sub does not exist."
            exit 1
        fi

        if [ ! -d "$backup_sub" ]; then
            log "Creating backup subvolume $backup_sub."
            btrfs subvolume create "$backup_sub"
        fi

        if [ ! -d "$backup_dir" ]; then
            log "Creating backup directory $backup_dir."
            mkdir -p "$backup_dir"
        fi
    }

    get_snapshots() {
        local dir="$1"
        echo $(ls "$dir" 2>/dev/null | sort -n)
    }

    log_snapshots() {
        log "Source snapshots : ${src_snapshots[*]}"
        log "Backup snapshots : ${tgt_snapshots[*]}"
    }

    copy_info_file() {
        local snapshot="$1"
        local info_source="$source_dir/$snapshot/info.xml"
        local info_target="$backup_dir/$snapshot/info.xml"

        if [ -f "$info_source" ]; then
            log "$(date '+%H:%M') - Copying $info_source to $info_target"
            mkdir -p "$(dirname "$info_target")"
            cp "$info_source" "$info_target"

            local timestamp=$(xmllint --xpath 'string(/snapshot/date)' "$info_source")
            log "$(date '+%H:%M') - Info.xml copied - containing snapshot timestamp: $timestamp"
        else
            log "$(date '+%H:%M') - Info.xml not found at $info_source for snapshot: $snapshot"
        fi
    }

    full_backup() {
        local snapshot="$1"
        log "Starting full backup of smallest snapshot: $snapshot"
        mkdir -p "$backup_dir/$snapshot"
        btrfs send "$source_dir/$snapshot/snapshot" | btrfs receive "$backup_dir/$snapshot"
        copy_info_file "$snapshot"
        log "Full backup of smallest snapshot $snapshot completed."
    }

    incremental_backup() {
        local parent_snapshot="$1"
        local snapshot="$2"
        log "Starting incremental backup of snapshot: $snapshot with parent snapshot: $parent_snapshot"
        mkdir -p "$backup_dir/$snapshot"
        if [ -n "$parent_snapshot" ]; then
            btrfs send -p "$source_dir/$parent_snapshot/snapshot" "$source_dir/$snapshot/snapshot" | btrfs receive "$backup_dir/$snapshot"
        else
            btrfs send "$source_dir/$snapshot/snapshot" | btrfs receive "$backup_dir/$snapshot"
        fi
        copy_info_file "$snapshot"
        log "Incremental backup of snapshot $snapshot completed."
    }


    perform_backups() {
        if [ ${#src_snapshots[@]} -gt 0 ] && [ ${#tgt_snapshots[@]} -eq 0 ]; then
            log "Target is empty and source has snapshots. Performing full and incremental backups."
            full_backup "${src_snapshots[0]}"
            prev_snapshot="${src_snapshots[0]}"
            for snapshot in "${src_snapshots[@]:1}"; do
                incremental_backup "$prev_snapshot" "$snapshot"
                prev_snapshot="$snapshot"
            done
        elif [ ${#src_snapshots[@]} -gt ${#tgt_snapshots[@]} ]; then
            log "There are fewer snapshots in the target. Performing incremental backups for missing snapshots."
            prev_snapshot=""
            for snapshot in "${src_snapshots[@]}"; do
                if ! [[ " ${tgt_snapshots[*]} " =~ " $snapshot " ]]; then
                    incremental_backup "$prev_snapshot" "$snapshot"
                fi
                prev_snapshot="$snapshot"
            done
        else
            log "No actions needed. Exiting."
        fi
    }

    check_directories
    log_variables
    src_snapshots=($(get_snapshots "$source_dir"))
    tgt_snapshots=($(get_snapshots "$backup_dir"))
    log_snapshots

    if [ ${#src_snapshots[@]} -eq 0 ] && [ ${#tgt_snapshots[@]} -eq 0 ]; then
        log "Both source and target snapshots are empty. Exiting."
        return 0
    fi

    perform_backups
}

# delete a parent subvolume with all it nested childs
# subvolume nested delete
# <parent subvolume>
# delete a parent subvolume with all it nested childs
# subvolume nested delete
# <parent subvolume>
osm-snd() {
    local target_path=""
    local interactive=false
    local force=false
    local depth=0

    echo "Debug: Function called with arguments: $@"
    echo "Debug: OPTIND at start: $OPTIND"

    # Parse command line options
    while getopts "if" opt; do
        case $opt in
            i) interactive=true; echo "Debug: Interactive flag set to true" ;;
            f) force=true; echo "Debug: Force flag set to true" ;;
            \?) echo "Invalid option: -$OPTARG" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND-1))

    echo "Debug: After getopts, interactive=$interactive, force=$force, OPTIND=$OPTIND"

    echo "Debug: Interactive mode is set to $interactive"

    # Check if target path is provided
    if [ $# -eq 0 ]; then
        echo "Error: Target path not provided" >&2
        echo "Usage: osm-snd [-i|-f] <target_path>" >&2
        return 1
    fi

    target_path="$1"
    local full_path

    # Function to print tree view
    print_tree() {
        local message="$1"
        local current_depth="$2"
        printf "%*s%s\n" $((current_depth * 2)) "" "$message"
    }

    # Function to print error messages
    error() {
        echo "[ERROR] $1" >&2
    }

    # Function to list subvolumes and filter out '@' symbol
    list_subvolumes() {
        local path="$1"
        btrfs subvolume list -o "$path" | awk '{print $NF}' | sed 's|@/||g'
    }

    # Convert relative path to absolute path if necessary
    if [[ "$target_path" = /* ]]; then
        full_path="$target_path"
    else
        full_path="$(pwd)/$target_path"
    fi
    
    print_tree "Target path: $full_path" 0

    # Function to delete subvolumes recursively
    delete_subvolumes() {
        local current_path="$1"
        local subvolumes
        local current_depth="$2"
        local can_delete=true

        print_tree "Checking subvolumes in: ${current_path##*/}" $current_depth
        echo "Debug: Entering delete_subvolumes for ${current_path##*/}, interactive=$interactive"

        # List subvolumes and store them in an array
        mapfile -t subvolumes < <(list_subvolumes "$current_path")

        # If no subvolumes found, attempt to delete the current subvolume
        if [ ${#subvolumes[@]} -eq 0 ]; then
            print_tree "No nested subvolumes found in: ${current_path##*/}" $((current_depth + 1))
            echo "Debug: No nested subvolumes found, interactive=$interactive"
            if $interactive; then
                echo "Debug: Prompting for deletion of leaf subvolume ${current_path##*/}"
                read -p "Delete subvolume ${current_path##*/}? (y/n): " answer
                echo "Debug: User response for ${current_path##*/}: $answer"
                if [[ $answer != [Yy]* ]]; then
                    print_tree "Skipping deletion of ${current_path##*/}" $((current_depth + 1))
                    echo "Debug: User chose to skip ${current_path##*/}"
                    return 1
                fi
            else
                echo "Debug: Non-interactive mode, proceeding with deletion of ${current_path##*/}"
            fi
            if ! btrfs subvolume delete "$current_path"; then
                error "Failed to delete subvolume: $current_path"
                return 1
            fi
            print_tree "Deleted: ${current_path##*/}" $((current_depth + 1))
            return 0
        fi

        # Iterate through subvolumes
        for subvol in "${subvolumes[@]}"; do
            local subvol_path="${current_path}/${subvol##*/}"
            print_tree "Processing subvolume: ${subvol_path##*/}" $((current_depth + 1))
            echo "Debug: Processing nested subvolume ${subvol_path##*/}"

            # Recursively delete nested subvolumes
            if ! delete_subvolumes "$subvol_path" $((current_depth + 2)); then
                can_delete=false
                echo "Debug: Failed to delete nested subvolume ${subvol_path##*/}, can_delete set to false"
            fi
        done

        # After processing all nested subvolumes, attempt to delete the current subvolume
        if $can_delete; then
            echo "Debug: All nested subvolumes processed, can_delete=$can_delete, interactive=$interactive"
            if $interactive; then
                echo "Debug: Prompting for deletion of parent subvolume ${current_path##*/}"
                read -p "Delete subvolume ${current_path##*/}? (y/n): " answer
                echo "Debug: User response for ${current_path##*/}: $answer"
                if [[ $answer != [Yy]* ]]; then
                    print_tree "Skipping deletion of ${current_path##*/}" $((current_depth + 1))
                    echo "Debug: User chose to skip ${current_path##*/}"
                    return 1
                fi
            else
                echo "Debug: Non-interactive mode, proceeding with deletion of ${current_path##*/}"
            fi
            if ! btrfs subvolume delete "$current_path"; then
                error "Failed to delete subvolume: $current_path"
                return 1
            fi
            print_tree "Deleted: ${current_path##*/}" $((current_depth + 1))
            return 0
        else
            print_tree "Cannot delete ${current_path##*/} due to remaining child subvolumes" $((current_depth + 1))
            echo "Debug: Cannot delete ${current_path##*/}, can_delete=$can_delete"
            return 1
        fi
    }

    # Start the recursive deletion process
    echo "Debug: Starting recursive deletion process, interactive=$interactive"
    if ! delete_subvolumes "$full_path" 0; then
        error "Failed to complete the subvolume deletion process"
        return 1
    fi

    print_tree "Subvolume deletion process completed successfully" 0
    return 0
}
