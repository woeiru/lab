# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# list all Functions in a given File
a() {
    local file_name="${1:-${BASH_SOURCE[0]}}"
    printf "%-20s | %-10s | %-10s | %-20s\n" "Function Name" "Size" "Header" "Comment"
    printf "%-20s | %-10s | %-10s | %-20s\n" "--------------------" "----------" "----------" "-------"

    # Initialize variables
    local last_comment_line=0
    local line_number=0
    declare -a comments=()

    # Read all comments into an array
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            comments[$line_number]="$line"
        fi
    done < "$file_name"

    # Loop through all lines in the file again
    line_number=0
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_-]*\(\) ]]; then
            # Extract function name
            func_name=$(echo "$line" | awk '{print $1}')
            # Calculate function size
            func_start_line=$line_number
            func_size=0
            while IFS= read -r func_line; do
                ((func_size++))
                if [[ $func_line == *} ]]; then
                    break
                fi
            done < <(tail -n +$func_start_line "$file_name")
            # Print function name, function size, comment line number, and comment
            printf "%-20s | %-10s | %-10s | %s\n" "$func_name" "$func_size" "${last_comment_line:-N/A}" "${comments[$last_comment_line]:-N/A}"
        elif [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            last_comment_line=$line_number
        fi
    done < "$file_name"
}


# count files in parent folder
a-count() {
    if [ $# -ne 2 ]; then
        echo "Usage: a-count <path> <1|2|3>"
        return 1
    fi

    local path="$1"
    local folder_type="$2"
    
    # Function to count files in a directory
    count_files() {
        local dir="$1"
        find "$dir" -type f | wc -l
    }
    
    # Function to print directory information
    print_directory_info() {
        local dir="$1"
        local file_count=$(count_files "$dir")
        printf "%-20s %5s\n" "$dir" "$file_count"
    }
    
    # Main function logic
    case "$folder_type" in
        1)
            find "$path" -mindepth 1 -maxdepth 1 -type d -name '[^.]*' | while read -r dir; do
                print_directory_info "$dir"
            done
            ;;
        2)
            find "$path" -mindepth 1 -maxdepth 1 -type d -name '.*' | while read -r dir; do
                print_directory_info "$dir"
            done
            ;;
        3)
            find "$path" -mindepth 1 -maxdepth 1 -type d \( -name '[^.]*' -o -name '.*' \) | while read -r dir; do
                print_directory_info "$dir"
            done
            ;;
        *)
            echo "Invalid folder type. Please provide either 1, 2, or 3."
            ;;
    esac | sort
}

# Add an entry to fstab

# Add a entry to fstab
a-fstab() {
  if [ $# -eq 0 ]; then
    # List blkid output with line numbers
    echo "Available devices:"
    blkid | nl -v 1
    echo "Usage: a-fstab <line_number> <mount_point> <filesystem> <mount_options> <fsck_pass_number> <mount_at_boot_priority>"
    return 0
  elif [ $# -ne 6 ]; then
    echo "Usage: a-fstab <line_number> <mount_point> <filesystem> <mount_options> <fsck_pass_number> <mount_at_boot_priority>"
    return 1
  fi

  line_number=$1
  mount_point=$2
  filesystem=$3
  mount_options=$4
  fsck_pass_number=$5
  mount_at_boot_priority=$6

  # Extract the UUID based on the specified line number
  uuid=$(blkid | sed -n "${line_number}s/.*UUID=\"\([^\"]*\)\".*/\1/p")
  if [ -z "$uuid" ]; then
    echo "Error: No UUID found at line $line_number"
    return 1
  fi

  # Create the fstab entry
  fstab_entry="UUID=${uuid} ${mount_point} ${filesystem} ${mount_options} ${fsck_pass_number} ${mount_at_boot_priority}"

  # Append the entry to /etc/fstab
  echo "$fstab_entry" >> /etc/fstab

  echo "Entry added to /etc/fstab:"
  echo "$fstab_entry"
}



# selects a file in current folder and saves it as var 'sel'
a-select() {
    files=($(ls))
    echo "Select a file by entering its index:"
    for i in "${!files[@]}"; do
        echo "$i: ${files[$i]}"
    done
    read -p "Enter the index of the file you want: " index
    sel="${files[$index]}"
    echo "$selected_file"
}

# git all in one
gg() {
    # Navigate to the git folder
    cd "$DIR/.." || return

    # Display the current status of the repository
    status_output=$(git status)

    # Check if the working tree is clean
    if echo "$status_output" | grep -q "nothing to commit, working tree clean"; then
        echo "Nothing to commit, working tree clean..."
	git pull
        cd - || return
        return
    fi

    # Check if the branch is behind
    if echo "$status_output" | grep -q "Your branch is behind"; then
        # If the branch is behind, pull the changes and return
        echo "Branch is behind, pulling changes..."
        git pull origin master
        cd - || return
        return
    fi

    # Define commit message
    local commit_message="$GIT_COMMITMESSAGE"

    # Stage all changes
    git add .

    # Commit the changes with the provided commit message
    git commit -m "$commit_message"

    # Push changes to remote
    git push origin master

    # Check if the branch is ahead of the remote
    if git status | grep -q "Your branch is ahead"; then
        # If there are changes ahead of the master branch, push them
        git push origin master
    fi

    # Return to the previous directory
    cd - || return
}

zfs_dset_backup() {
    local sourcepoolname="$1"
    local destinationpoolname="$2"
    local datasetname="$3"
    
    # Generate a unique snapshot name based on the current date and hour
    local snapshot_name="$(date +%Y%m%d_%H)"
    local full_snapshot_name="${sourcepoolname}/${datasetname}@${snapshot_name}"
    
    # Check if the snapshot already exists
    if zfs list -t snapshot -o name | grep -q "^${full_snapshot_name}$"; then
        echo "Snapshot ${full_snapshot_name} already exists."
        read -p "Do you want to delete the existing snapshot? [y/N]: " delete_snapshot
        
        if [[ "$delete_snapshot" =~ ^[Yy]$ ]]; then
            # Delete the existing snapshot
            local delete_snapshot_cmd="zfs destroy ${full_snapshot_name}"
            echo "Deleting snapshot: ${delete_snapshot_cmd}"
            eval "${delete_snapshot_cmd}"
        else
            echo "Aborting backup to avoid overwriting existing snapshot."
            return 1
        fi
    fi
    
    # Create the snapshot
    local create_snapshot_cmd="zfs snapshot ${full_snapshot_name}"
    echo "Creating snapshot: ${create_snapshot_cmd}"
    eval "${create_snapshot_cmd}"
    
    # Determine the correct send and receive commands
    if zfs list -H -t snapshot -o name | grep -q "^${destinationpoolname}/${datasetname}@"; then
        # Get the name of the most recent snapshot in the destination pool
        local last_snapshot=$(zfs list -H -t snapshot -o name | grep "^${destinationpoolname}/${datasetname}@" | tail -1)
        
        # Prepare the incremental send and receive commands
        local send_cmd="zfs send -i ${last_snapshot} ${full_snapshot_name}"
        local receive_cmd="zfs receive ${destinationpoolname}/${datasetname}"
        
        echo "Incremental send command: ${send_cmd} | ${receive_cmd}"
    else
        # Prepare the initial full send and receive commands
        local send_cmd="zfs send ${full_snapshot_name}"
        local receive_cmd="zfs receive ${destinationpoolname}/${datasetname}"
        
        echo "Initial send command: ${send_cmd} | ${receive_cmd}"
    fi
    
    # Wait for user confirmation before executing the commands
    read -p "Press enter to execute the above command..."
    
    # Execute the send and receive commands
    eval "${send_cmd} | ${receive_cmd}"

# data usage comparison
du-c() {
    local path1=$1
    local path2=$2
    local depth=$3

    # Check if required arguments are provided
    if [ -z "$path1" ] || [ -z "$path2" ] || [ -z "$depth" ]; then
        echo "Usage: compare_du <path1> <path2> <depth>"
        return 1
    fi

    # Function to remove base path and sort by subpath
    process_du() {
        local path=$1
        local depth=$2
        du -bh -d "$depth" "$path" | sed "s|^$path/||" | sort -k2
    }

    # Process and sort du output for both paths
    output1=$(process_du "$path1" "$depth")
    output2=$(process_du "$path2" "$depth")

    # Join the results on the common subpath
    join -j 1 <(echo "$output1") <(echo "$output2") | awk '
    BEGIN { OFS="\t"; print "Path", "Size1", "Size2", "Difference" }
    {
        size1 = $2
        path = $1
        size2 = $3
        diff = (substr(size1, 1, length(size1)-1) - substr(size2, 1, length(size2)-1))
        print path, size1, size2, diff
    }'
}

}
