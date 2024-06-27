# get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

# Recursively processes bash files in a directory.
# extended overview
# <path-optional>
all-fun() {
    local target="$1"
    if [[ -z "$target" ]]; then
        target="$BASH_SOURCE" # Default to the current file if no argument is provided
    fi

    if [[ -d "$target" ]]; then
        for file in "$target"/*.bash; do # Adjust the extension according to the file type you want to process
            if [[ -f "$file" ]]; then
                echo "Processing file: $file"
                all-laf "$file"
            fi
        done
    elif [[ -f "$target" ]]; then
        all-laf "$target"
    else
        echo "Invalid target: $target"
    fi
}

# Lists all functions with details in a table format.
all-laf() {
    # Column width parameters
    local col_width_1=9
    local col_width_2=35
    local col_width_3=30
    local col_width_4=50
    local col_width_5=5
    local col_width_6=5
    local col_width_7=5
    local col_width_8=5
    local col_width_9=5

    # Function to print a separator line
    print_separator() {
        printf "+-%s+-%s+-%s+-%s+-%s+-%s+-%s+-%s+-%s+\n" \
            "$(printf '%*s' $col_width_1 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_2 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_3 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_4 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_5 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_6 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_7 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_8 '' | tr ' ' '-')" \
            "$(printf '%*s' $col_width_9 '' | tr ' ' '-')"
    }

    # Print table header
    print_separator
    printf "| %-$(($col_width_1 - 1))s | %-$(($col_width_2 - 1))s | %-$(($col_width_3 - 1))s | %-$(($col_width_4 - 1))s | %-$(($col_width_5 - 1))s | %-$(($col_width_6 - 1))s | %-$(($col_width_7 - 1))s | %-$(($col_width_8 - 1))s | %-$(($col_width_9 - 1))s |\n" \
        "Function" "Arguments" "Shortname" "Description" "Size" "Loc" "Cfil" "Clib" "Cset"
    print_separator

    local file_name="$1"
    local third_last_comment_line=0
    local second_last_comment_line=0
    local last_comment_line=0
    local line_number=0
    declare -a comments=()

    # Read all comments into an array
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            comments[$line_number]="${line:2}"  # Remove leading '# '
            third_last_comment_line=$second_last_comment_line
            second_last_comment_line=$last_comment_line
            last_comment_line=$line_number
        fi
    done < "$file_name"

    # Counts all function calls
    count_calls() {
        local func_name="$1"
        local count=$(awk -v func_name="$func_name" '{ for (i=1; i<=NF; i++) if ($i == func_name) count++ } END { print count }' "$file_name")
        echo "${count}"
    }

    # Counts all function calls in a folder, excluding a specific file
    count_calls_folder() {
        local func_name="$1"
        local folder_name="$2"
        local exclude_file="$3"
        local count=$(find "$folder_name" -type f ! -name "$(basename "$exclude_file")" -exec awk -v func_name="$func_name" '{ for (i=1; i<=NF; i++) if ($i == func_name) count++ } END { print count }' {} + | awk '{sum += $1} END {if (sum == 0) print ""; else print sum}')
        echo "${count}"
    }

    # Loop through all lines in the file again
    line_number=0
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_-]*\(\) ]]; then
            # Extract function name without parentheses
            func_name=$(echo "$line" | awk -F '[(|)]' '{print $1}')
            # Calculate function size
            func_start_line=$line_number
            func_size=0
            while IFS= read -r func_line; do
                ((func_size++))
                if [[ $func_line == *} ]]; then
                    break
                fi
            done < <(tail -n +$func_start_line "$file_name")
            # Count the number of calls to the function
            func_calls=$(count_calls "$func_name")
            callslib=$(count_calls_folder "$func_name" "/root/lab/lib" "$file_name")
            callsset=$(count_calls_folder "$func_name" "/root/lab/set" "$file_name")
            # Truncate the description if it's longer than col_width_4 characters
            truncated_desc=$(echo "${comments[$third_last_comment_line]:-N/A}" | awk '{ if (length($0) > '"$col_width_4"' - 2 ) print substr($0, 1, '"$col_width_4 - 3"') ".."; else print $0 }')
            # Truncate the shortname if it's longer than col_width_3 characters
            truncated_shortname=$(echo "${comments[$second_last_comment_line]:-N/A}" | awk '{ if (length($0) > '"$col_width_3"' - 2 ) print substr($0, 1, '"$col_width_3 - 3"') ".."; else print $0 }')
            # Truncate the usage example if it's longer than col_width_2 characters
            truncated_usage=$(echo "${comments[$last_comment_line]:-N/A}" | awk '{ if (length($0) > '"$col_width_2"') print substr($0, 1, '"$col_width_2 - 3"') ".."; else print $0 }')
            # Print function name, function size, comment line number, and comment
            printf "| %-$(($col_width_1 - 1))s | %-$(($col_width_2 - 1))s | %-$(($col_width_3 - 1))s | %-$(($col_width_4 - 1))s | %-$(($col_width_5 - 1))s | %-$(($col_width_6 - 1))s | %-$(($col_width_7 - 1))s | %-$(($col_width_8 - 1))s | %-$(($col_width_9 - 1))s |\n" \
                "$func_name" "$truncated_usage" "$truncated_shortname" "$truncated_desc" "$func_size" "${last_comment_line:-N/A}" "$func_calls" "$callslib" "$callsset"
        elif [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            third_last_comment_line=$second_last_comment_line
            second_last_comment_line=$last_comment_line
            last_comment_line=$line_number
        fi
    done < "$file_name"

    print_separator
    echo ""
}

# Manages git operations, ensuring local repository syncs with remote.
# git all in
#  
all-gio() {
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

# Adds auto-mount entries for devices to /etc/fstab using blkid.
# fstab entry auto
#   
all-fea() {
    # Perform blkid and filter entries with sd*
    blkid_output=$(blkid | grep '/dev/sd*')

    # Display filtered results
    echo "Filtered entries with sd*:"
    echo "$blkid_output"

    # Prompt for the line number
    read -p "Enter the line number to retrieve the UUID: " line_number

    # Retrieve UUID based on the chosen line number
    chosen_line=$(echo "$blkid_output" | sed -n "${line_number}p")

    # Extract UUID from the chosen line
    TARGET_UUID=$(echo "$chosen_line" | grep -oP ' UUID="\K[^"]*')

    echo "The selected UUID is: $TARGET_UUID"

    # Check if the device's UUID is already present in /etc/fstab
    if grep -q "UUID=$TARGET_UUID" /etc/fstab; then
        echo "This UUID is already present in /etc/fstab."
    else
        # Check if the script is run as root
        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script as root to modify /etc/fstab."
            exit 1
        fi

        # Append entry to /etc/fstab for auto-mounting
        echo "UUID=$TARGET_UUID /mnt/auto auto defaults 0 0" >> /etc/fstab
        echo "Entry added to /etc/fstab for auto-mounting."
    fi
}

# Adds custom entries to /etc/fstab using device UUIDs.
# fstab entry custom
# <line_number> <mount_point> <filesystem> <mount_options> <fsck_pass_number> <mount_at_boot_priority>"
all-fec() {
  if [ $# -eq 0 ]; then
    # List blkid output with line numbers
    echo "Available devices:"
    blkid | nl -v 1
    all-use
    return 0
  elif [ $# -ne 6 ]; then
    all-use
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

# Prompts the user to select a file from the current directory.
# variable select filename
#   
all-vsf() {
    files=($(ls))
    echo "Select a file by entering its index:"
    for i in "${!files[@]}"; do
        echo "$i: ${files[$i]}"
    done
    read -p "Enter the index of the file you want: " index
    sel="${files[$index]}"
    echo "$selected_file"
}

# Counts files in directories based on specified visibility.
# count files folder
# <path> <folder_type: 1=regular, 2=hidden, 3=both>
all-cff() {
    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi

    local path="$1"
    local folder_type="$2"
    
    # count files in a directory
    count_files() {
        local dir="$1"
        find "$dir" -type f | wc -l
    }
    
    # print directory information
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

# Sends ZFS snapshots from a source pool to a destination pool.
# zfs dataset backup
# <sourcepoolname> <destinationpoolname> <datasetname>
all-zdb() {
    local sourcepoolname="$1"
    local destinationpoolname="$2"
    local datasetname="$3"

     if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

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
}

# Compares data usage between two paths up to a specified depth.
# data usage comparison
# <path1> <path2> <depth>
all-duc() {
    local path1=$1
    local path2=$2
    local depth=$3

    if [ $# -ne 3 ]; then
        all-use
        return 1
    fi

    # Convert relative paths to absolute paths
    path1=$(realpath "$path1")
    path2=$(realpath "$path2")

    # remove base path and sort by subpath
    process_du() {
        local path=$1
        local depth=$2
        du -b -d "$depth" "$path" | sed "s|$path/||" | sort -k2
    }

    # Process and sort du output for both paths
    output1=$(process_du "$path1" "$depth")
    output2=$(process_du "$path2" "$depth")

    # Define ANSI color codes
    RED='\033[0;31m'
    NC='\033[0m'  # No Color

    # Join the results on the common subpath
    join -j 2 <(echo "$output1") <(echo "$output2") | awk -v p1="$path1" -v p2="$path2" -v red="$RED" -v nc="$NC" '
        BEGIN {
            OFS = "\t";
            print "Path", p1, p2, "Difference"
        }
        function abs(value) {
            return (value < 0) ? -value : value
        }
        function hr(bytes) {
            if (bytes >= 1073741824) {
                return sprintf("%.2fG", bytes / 1073741824)
            } else if (bytes >= 1048576) {
                return sprintf("%.2fM", bytes / 1048576)
            } else if (bytes >= 1024) {
                return sprintf("%.2fK", bytes / 1024)
            } else {
                return bytes "B"
            }
        }
        {
            subpath = $1
            size1 = $2 + 0
            size2 = $3 + 0
            diff = abs(size1 - size2)
            if (size1 < size2) {
                print subpath, red hr(size1) nc, hr(size2), hr(diff)
            } else if (size2 < size1) {
                print subpath, hr(size1), red hr(size2) nc, hr(diff)
            } else {
                print subpath, hr(size1), hr(size2), hr(diff)
            }
        }' | column -t
}


# Prompts the user to input or confirm a variable's value.
# main eval variable
# <var_name> <prompt_message> <current_value>
all-mev() {
    local var_name=$1
    local prompt_message=$2
    local current_value=$3
    
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

    read -p "$prompt_message [$current_value]: " input
    if [ -n "$input" ]; then
        eval "$var_name=\"$input\""
    else
        eval "$var_name=\"$current_value\""
    fi
}

# Logs a function's execution status with a timestamp.
# main display notification
# <function_name> <status>
all-nos() {
    local function_name="$1"
    local status="$2"
	
   
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Appends a line to a file if it does not already exist.
# check append create
# <file> <line>
all-cap() {
    local file="$1"
    local line="$2"
    
    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi


    # Check if the line is already present in the file
    if ! grep -Fxq "$line" "$file"; then
        # If not, append the line to the file
        echo "$line" >> "$file"
        echo "Line appended to $file"
    else
        echo "Line already present in $file"
    fi
}

# Installs specified packages using a package manager.
# install packages
# <pman> <pak1> <pak2>
all-ipa() {
    local function_name="${FUNCNAME[0]}"
    local pman="$1"
    local pak1="$2"
    local pak2="$3"
   
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

    "$pman" update
    "$pman" upgrade -y
    "$pman" install -y "$pak1" "$pak2"

    # Check if installation was successful
    if [ $? -eq 0 ]; then
	    all-nos "$function_name" "executed ( $1 $2 $3 )"
    else
        all-nos "$function_name" "Failed to install  ( $1 $2 $3 )"
        return 1
    fi
} 

# Configures git with a specified username and email.
# git set config
# <username> <usermail>
all-gst() {
    local function_name="${FUNCNAME[0]}"
    local username="$1"
    local usermail="$2"
    
    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi

    git config --global user.name "$username"
    git config --global user.email "$usermail"

    all-nos "$function_name" "executed ( $1 $2 )"
}

# Installs, enables, and starts the sysstat service.
# setup sysstat
#   
all-sst() {
  # Step 1: Install sysstat
  install_pakages sysstat

  # Step 2: Enable sysstat
  sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat

  # Step 3: Start the sysstat service
  systemctl enable sysstat
  systemctl start sysstat

  echo "sysstat has been installed, enabled, and started."
}

# Allows a specified service through the firewall.
# firewall allow service
# <service>
all-fas() {
    local function_name="${FUNCNAME[0]}" 
    local fwd_as_1="$1"
   
    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi

    firewall-cmd --state
    firewall-cmd --add-service="$fwd_as_1" --permanent
    firewall-cmd --reload

    all-nos "$function_name" "executed"
}

# Creates a user with a specified username and password.
# user setup
# <username> <password>
all-ust() {
    local function_name="${FUNCNAME[0]}"
    local username="$1"
    local password="$2"
   
    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi

    # Prompt for user details
    all-mev "username" "Enter new username" "$username"
    while [ -z "$password" ]; do
        all-mev "password" "Enter password for $username" "$password"
    done

    # Create the user
    useradd -m "$username"
    echo "$username:$password" | chpasswd

    # Check if user creation was successful
    if id -u "$username" > /dev/null 2>&1; then
        all-nos "$function_name" "User $username created successfully"
    else
        all-nos "$function_name" "Failed to create user $username"
        return 1
    fi
}

# Enables and starts a specified systemd service.
# systemd setup service
# <service>
all-sdc() {
    local function_name="${FUNCNAME[0]}"
    local service="$1"
    
    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi

    # Enable and start smbd service
    systemctl enable "$service"
    systemctl start "$service"
    
    # Check if service is active
    systemctl is-active --quiet "$service"
    if [ $? -eq 0 ]; then
        all-nos "$function_name" "$service is active"
    else
        read -p "$service is not active. Do you want to continue anyway? [Y/n] " choice
        case "$choice" in 
            [yY]|[yY][eE][sS])
                all-nos "$function_name" "$service is not active"
                ;;
            *)
                all-nos "$function_name" "$service is not active. Exiting."
                return 1
                ;;
        esac
    fi
}

# Replaces strings in files within a specified folder, optionally staged by git.
# replace strings 2
# <foldername> <old_string> <new_string>
all-rsf() {
  local foldername="$1"
  local old_string="$2"
  local new_string="$3"
    
  if [ $# -ne 3 ]; then
    all-use
    return 1
  fi

  # Navigate to the specified folder
  cd "$foldername" || { echo "Folder not found: $foldername"; return 1; }

  # Check if we are inside a git repository
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    # Stage all current changes
    git add . || { echo "Failed to stage changes"; return 1; }
  fi
    
  # Run the substitution command with a check for modified files
  find . -type f -exec sh -c '
    for file; do
      if grep -q "$0" "$file"; then
        sed -i -e "s/$0/$1/g" "$file"
        echo "Modified $file"
      fi
    done
  ' "$old_string" "$new_string" {} +

  # Check if we are inside a git repository
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    # Check the status to see which files have been modified
    git status || { echo "Failed to get git status"; return 1; }

    # Use git diff to see the exact lines that were changed
    git diff || { echo "Failed to get git diff"; return 1; }

    # Optionally commit the changes (uncomment if you want to commit automatically)
    # Uncomment the following lines if you want to commit automatically
    # read -p "Do you want to commit the changes? (y/n) " -n 1 -r
    # echo    # move to a new line
    # if [[ $REPLY =~ ^[Yy]$ ]]; then
    #     git commit -am "Replaced $old_string with $new_string" || { echo "Failed to commit changes"; return 1; }
    # fi
  fi
}

# renames all files in folder and in nested folders too
# renames files in folder
# <path> <old_name> <new_name>
all-rnf() {
    local path="$1"
    local oldname="$2"
    local newname="$3"

    if [[ ! -d "$path" ]]; then
        echo "The specified path is not a directory."
        return 1
    fi

    find "$path" -type f -name "*$oldname*" | while read -r file; do
        local dirname=$(dirname "$file")
        local basename=$(basename "$file")
        local newfile="${basename//$oldname/$newname}"
        mv "$file" "$dirname/$newfile"
    done
}


#  
# get function arguments
#   
all-use() {
    local caller_line=$(caller 0)
    local caller_function=$(echo $caller_line | awk '{print $2}')
    local script_file="${BASH_SOURCE[1]}"

    # Use grep to locate the function's declaration line number
    local function_start_line=$(grep -n -m 1 "^[[:space:]]*${caller_function}()" "$script_file" | cut -d: -f1)
    
    if [ -z "$function_start_line" ]; then
        echo "Function not found."
        return
    fi

    # Calculate the line number of the comment
    local description_line=$((function_start_line - 3))
    local shortname_line=$((function_start_line - 2))
    local usage_line=$((function_start_line - 1))

    # Use sed to get the comment line and strip off leading "# "
    local description=$(sed -n "${description_line}s/^# //p" "$script_file")
    local shortname=$(sed -n "${shortname_line}s/^# //p" "$script_file")
    local usage=$(sed -n "${usage_line}s/^# //p" "$script_file")
    local funcname=${caller_function}

    # Display the comment
    echo "Description:    $description"
    echo "Shortname:      $shortname"
    echo "Usage:          $funcname" "$usage"

}

#  
# rysnc source destination
# <storage_name>
all-rav() {
    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi
    local source_path="$1"
    local destination_path="$2"

    # Check if destination path exists
    if [ ! -d "$destination_path" ]; then
        echo "Destination path $destination_path will be created."
	mkdir -p $destination_path
    fi
    # Check again
    if [ ! -d "$destination_path" ]; then
        echo "Destination path $destination_path could not been created."
	return 1
    fi

    # Display files to be transferred
    echo "Files to be transferred from $source to $destination_path:"
    rsync -avhn "$source_path/" "$destination_path/"

    # Ask for confirmation
    read -p "Do you want to proceed with the transfer? (y/n): " confirm
    case $confirm in
        [Yy])   # Proceed with the transfer
                # Perform the transfer
                rsync -avh --human-readable "$source_path/" "$destination_path/"
                echo "Transfer completed successfully."
                ;;
        [Nn])   # Abort the transfer
                echo "Transfer aborted."
                ;;
        *)      # Invalid input
                echo "Invalid input. Please enter 'y' or 'n'."
                ;;
    esac
}

# cats all files inside a particular folder
# cat in folder
# <path>
all-cif() {
    # Check if exactly one argument (directory path) is provided
    if [ $# -ne 1 ]; then
        all-use
        return 1
    fi

    # Check if the argument is a directory
    if [ ! -d "$1" ]; then
        echo "$1 is not a directory."
        return 1
    fi

    # Concatenate all files within the directory
    for file in "$1"/*; do
        if [ -f "$file" ]; then
            echo "Contents of $file:"
            cat "$file"
            echo "-----------------------------------"
        fi
    done
}

# cats the source code of a function inside the lib folder
# function library cat
# <function_name>
all-flc() {
    # Check if a function name is provided
    if [ -z "$1" ]; then
        all-use
        return 1
    fi

    # Extract the library prefix from the function name
    func_name="$1"
    lib_prefix="${func_name%%-*}"
    lib_file="/root/lab/lib/${lib_prefix}.bash"

    # Check if the library file exists
    if [ ! -f "$lib_file" ]; then
        echo "Library file $lib_file not found!"
        return 1
    fi

    # Search for the function definition in the library file
    start_line=$(grep -n "^[[:space:]]*${func_name}[[:space:]]*()" "$lib_file" | cut -d: -f1)
    start_line=$((start_line - 3))
    
    if [ -z "$start_line" ]; then
        echo "Function $func_name not found in $lib_file"
        return 1
    fi

    # Extract the function source code
    awk "NR >= $start_line { print; if (/^\}$/) exit }" "$lib_file"
}

# firewalld add service and reload
# fire wall service
# <function_name>
all-fws() {
    local function_name="${FUNCNAME[0]}"
    local fw_service="$1"
    if [ $# -ne 1 ]; then
	all-use
        return 1
    fi
   # Open firewall ports
    if command -v firewall-cmd > /dev/null; then
        firewall-cmd --permanent --add-service=$fw_service
        firewall-cmd --reload
	all-nos "$function_name" "executed ( $1 )"
    else
        echo "firewall-cmd not found, skipping firewall configuration."
    fi
}


# This function uploads an SSH key from a device plugged in, into the /root/.ssh folder.
# upload ssh key
# <device_path> <mount_point> <file_path> <file_name> <upload_path>
all-usk() {
    local device_path
    local mount_point
    local file_path
    local file_name
    local full_path
    local upload_path

    lsblk -h

    # Evaluate and confirm variables
    all-mev device_path "Enter the device path" ""
    all-mev mount_point "Enter the mount point" ""
    all-mev file_path "Enter the file path on the device" ""
    all-mev file_name "Enter the file name" ""
    all-mev upload_path "Enter the upload path" "/root/.ssh"

    full_path="$mount_point/$file_path/$file_name"

    # Mount the device
    mount $device_path $mount_point

    # Check if mount was successful
    if [ $? -ne 0 ]; then
        echo "Failed to mount $device_path at $mount_point"
        return 1
    fi

    # Copy the SSH key to the upload path
    cp $full_path $upload_path

    # Check if copy was successful
    if [ $? -ne 0 ]; then
        echo "Failed to copy $full_path to $upload_path"
        umount $mount_point
        return 1
    fi

    # Unmount the device
    umount $mount_point

    echo "SSH key successfully uploaded to $upload_path"
}
