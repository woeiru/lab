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

# Shows a summary of selected functions in the script, displaying their usage, shortname, and description
# overview functions
#
all-fun() {
    # Pass all arguments directly to all-laf
    all-laf "$FILEPATH_all" "$@"
}

# Lists all functions in a file, displaying their usage, shortname, and description. Supports truncation and line break options for better readability
# list all functions
# <file name> [-t] [-b]
all-laf() {
    local truncate_mode=false
    local break_mode=false
    local file_name

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t)
                truncate_mode=true
                shift
                ;;
            -b)
                break_mode=true
                shift
                ;;
            *)
                file_name="$1"
                shift
                ;;
        esac
    done

    if [ -z "$file_name" ]; then
        all-use
        return 1
    fi

    # Column width parameters
    local col_width_1=9
    local col_width_2=30
    local col_width_3=26
    local col_width_4=50
    local col_width_5=4
    local col_width_6=4
    local col_width_7=4
    local col_width_8=4
    local col_width_9=4

    # Function to truncate and pad strings
    truncate_and_pad() {
        local str="$1"
        local width="$2"
        if [ ${#str} -gt $width ]; then
            echo "${str:0:$((width-2))}.."
        else
            printf "%-${width}s" "$str"
        fi
    }

    # Function to wrap text
    wrap_text() {
        local text="$1"
        local width="$2"
        echo "$text" | fold -s -w "$width"
    }

    # Function to print a row (including header and data rows)
    print_row() {
        if $break_mode; then
            local col1=$(wrap_text "$1" $col_width_1)
            local col2=$(wrap_text "$2" $col_width_2)
            local col3=$(wrap_text "$3" $col_width_3)
            local col4=$(wrap_text "$4" $col_width_4)
            local col5=$(wrap_text "$5" $col_width_5)
            local col6=$(wrap_text "$6" $col_width_6)
            local col7=$(wrap_text "$7" $col_width_7)
            local col8=$(wrap_text "$8" $col_width_8)
            local col9=$(wrap_text "$9" $col_width_9)
            
            local IFS=$'\n'
            local lines1=($col1)
            local lines2=($col2)
            local lines3=($col3)
            local lines4=($col4)
            local lines5=($col5)
            local lines6=($col6)
            local lines7=($col7)
            local lines8=($col8)
            local lines9=($col9)
            
            local max_lines=$(( ${#lines1[@]} > ${#lines2[@]} ? ${#lines1[@]} : ${#lines2[@]} ))
            max_lines=$(( max_lines > ${#lines3[@]} ? max_lines : ${#lines3[@]} ))
            max_lines=$(( max_lines > ${#lines4[@]} ? max_lines : ${#lines4[@]} ))
            max_lines=$(( max_lines > ${#lines5[@]} ? max_lines : ${#lines5[@]} ))
            max_lines=$(( max_lines > ${#lines6[@]} ? max_lines : ${#lines6[@]} ))
            max_lines=$(( max_lines > ${#lines7[@]} ? max_lines : ${#lines7[@]} ))
            max_lines=$(( max_lines > ${#lines8[@]} ? max_lines : ${#lines8[@]} ))
            max_lines=$(( max_lines > ${#lines9[@]} ? max_lines : ${#lines9[@]} ))
            
            for i in $(seq 0 $((max_lines-1))); do
                printf "| %-${col_width_1}s | %-${col_width_2}s | %-${col_width_3}s | %-${col_width_4}s | %-${col_width_5}s | %-${col_width_6}s | %-${col_width_7}s | %-${col_width_8}s | %-${col_width_9}s |\n" \
                    "${lines1[$i]:-}" \
                    "${lines2[$i]:-}" \
                    "${lines3[$i]:-}" \
                    "${lines4[$i]:-}" \
                    "${lines5[$i]:-}" \
                    "${lines6[$i]:-}" \
                    "${lines7[$i]:-}" \
                    "${lines8[$i]:-}" \
                    "${lines9[$i]:-}"
            done
        elif $truncate_mode; then
            printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
                "$(truncate_and_pad "$1" $col_width_1)" \
                "$(truncate_and_pad "$2" $col_width_2)" \
                "$(truncate_and_pad "$3" $col_width_3)" \
                "$(truncate_and_pad "$4" $col_width_4)" \
                "$(truncate_and_pad "$5" $col_width_5)" \
                "$(truncate_and_pad "$6" $col_width_6)" \
                "$(truncate_and_pad "$7" $col_width_7)" \
                "$(truncate_and_pad "$8" $col_width_8)" \
                "$(truncate_and_pad "$9" $col_width_9)"
        else
            printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
                "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
        fi
    }

    # Function to print a separator line
    print_separator() {
        local total_width=$((col_width_1 + col_width_2 + col_width_3 + col_width_4 + col_width_5 + col_width_6 + col_width_7 + col_width_8 + col_width_9 + 26))
        printf "+%s+\n" "$(printf '%*s' $total_width '' | tr ' ' '-')"
    }

    print_separator_2() {
        local total_width=$((col_width_1 + col_width_2 + col_width_3 + col_width_4 + col_width_5 + col_width_6 + col_width_7 + col_width_8 + col_width_9 + 26))
        printf "+%s+\n" "$(printf '%*s' $total_width '' | tr ' ' ' ')"
    }

    local line_number=0
    declare -a comments=()

    # Read all comments into an array
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[[:space:]]*# ]]; then
            comments[$line_number]="${line#"${line%%[![:space:]]*}"}"  # Remove leading whitespace
            comments[$line_number]="${comments[$line_number]#\# }"    # Remove leading '# '
            comments[$line_number]="${comments[$line_number]#\#}"     # Remove leading '#' if there's no space after it
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

    # Function to get comment or empty string
    get_comment() {
        local line_num=$1
        local comment="${comments[$line_num]:-}"
        # Return empty string if comment is just whitespace
        if [[ -z "${comment// }" ]]; then
            echo ""
        else
            echo "$comment"
        fi
    }

    # Print table header
    print_separator
    print_row "Function" "Arguments" "Shortname" "Description" "Size" "Loc" "Cfil" "Clib" "Cset"
    print_separator

    # Loop through all lines in the file again
    line_number=0
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[a-zA-Z_][a-zA-Z0-9_-]*\(\) ]]; then
            # Extract function name without parentheses
            func_name=$(echo "$line" | awk -F '[(|)]' '{print $1}')
            # Calculate function size
            func_start_line=$line_number
            func_end_line=$(tail -n +$((func_start_line+1)) "$file_name" | grep -n '^}' | head -1 | cut -d: -f1)
            func_size=$((func_end_line + 1))  # +1 to include the closing brace
            
            # Count the number of calls to the function
            func_calls=$(count_calls "$func_name")
            callslib=$(count_calls_folder "$func_name" "/root/lab/lib" "$file_name")
            callsset=$(count_calls_folder "$func_name" "/root/lab/set" "$file_name")
            
            # Get comments for arguments, shortname, and description
            description=$(get_comment $((line_number-3)))
            shortname=$(get_comment $((line_number-2)))
            arguments=$(get_comment $((line_number-1)))

            # Print function information
            print_row "$func_name" "$arguments" "$shortname" "$description" "$func_size" "$line_number" "$func_calls" "$callslib" "$callsset"
            if $break_mode; then
                print_separator_2
            fi
        fi
    done < "$file_name"

    if ! $break_mode; then
        print_separator
    fi
    echo ""
}

# Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
#
all-var() {
    all-acu -o "$CONFIG_all" "$DIR_LIB/.." 
}

# Analyzes the usage of variables from a config file across a target folder, displaying variable names, values, and occurrence counts in various files
# analyze config usage
# <sort mode: o|a > <target folder> <config file>
all-acu() {
    local sort_mode=$1
    local conf_file=$2
    local target_folder=$3

    # Customizable column widths
    local tab_width_var_names=20
    local tab_width_var_values=18
    local tab_width_var_occurences=5

    if [ $# -ne 3 ]; then
        echo "Usage: all-acu <sort mode: -o|-a> <target folder> <config file>"
        return 1
    fi

    if [[ ! -f $conf_file ]]; then
        echo "Config file $conf_file does not exist."
        return 1
    fi

    if [[ ! -d $target_folder ]]; then
        echo "Target folder $target_folder does not exist."
        return 1
    fi

    declare -A config_vars
    declare -a var_order

    # Function to read config file and store variables and their values
    read_config_file() {
        local conf_file=$1
        while IFS='=' read -r var value; do
            config_vars[$var]=$value
            var_order+=("$var")
        done < <(grep -E -v '^(#|declare|[[:space:]]*\))' "$conf_file" | grep '=' | sed 's/[[:space:]]//g')
    }

    # Function to sort variables based on the sort mode
    sort_variables() {
        local sort_mode=$1
        if [[ $sort_mode == "-a" ]]; then
            IFS=$'\n' sorted_vars=($(sort <<<"${var_order[*]}"))
            unset IFS
        else
            sorted_vars=("${var_order[@]}")
        fi
    }


    list_target_files() {
        local target_folder=$1
        target_files=($(find "$target_folder" \( -name .git -o -name arc -o -name con -o -name ini -o -name var \) -prune -o -type f -name '*.*' -print | sort))
    }


    # Function to truncate strings that exceed the column width
    truncate_string() {
        local str=$1
        local max_length=$2
        if [ ${#str} -gt $max_length ]; then
            echo "${str:0:max_length-2}.."
        else
            echo "$str"
        fi
    }

    # Function to print header with borders
    print_header() {
       echo ""
       printf "| %-*s | %-*s |" "$tab_width_var_names" "Variable" "$tab_width_var_values" "Value"

       for sh_file in "${target_files[@]}"; do
           local truncated_filename=$(basename "$sh_file" | cut -c 1-$tab_width_var_occurences)
           printf " %-*s |" "$tab_width_var_occurences" "$truncated_filename"
        done
        echo

        # Print separator
        printf "| %s | %s | " "$(printf -- '-%.0s' $(seq $tab_width_var_names))" "$(printf -- '-%.0s' $(seq $tab_width_var_values))"
        for _ in "${target_files[@]}"; do
        printf "%s | " "$(printf -- '-%.0s' $(seq $tab_width_var_occurences))"
        done
        echo
}

    # Function to print variable usage across target files
    print_variables_usage() {
        for var in "${sorted_vars[@]}"; do
            local truncated_var=$(truncate_string "$var" "$tab_width_var_names")
            local truncated_value=$(truncate_string "${config_vars[$var]}" "$tab_width_var_values")
            printf "| %-*s | %-*s |" "$tab_width_var_names" "$truncated_var" "$tab_width_var_values" "$truncated_value"
            
            if [[ $var == *"["* ]]; then
                # Skip counting for array elements
                for sh_file in "${target_files[@]}"; do
                    printf " %-*s |" "$tab_width_var_occurences" ""
                done
            else
                for sh_file in "${target_files[@]}"; do
                    local count=$(grep -o "\b$var\b" "$sh_file" | wc -l)
                    if [[ $count -ne 0 ]]; then
                        printf " %-*s |" "$tab_width_var_occurences" "$count"
                    else
                        printf " %-*s |" "$tab_width_var_occurences" ""
                    fi
                done
            fi
            echo
        done

        echo ""
    }

    read_config_file "$conf_file"
    sort_variables "$sort_mode"
    list_target_files "$target_folder"
    print_header
    print_variables_usage
}

# Recursively processes files in a directory and its subdirectories using a specified function, allowing for additional arguments to be passed
# function folder loop
# <function> <flag> <path> [extra_args ..]
all-ffl() {
    local fnc
    local flag
    local folder
    local extra_args=()

    fnc="$1"
    flag="$2"
    folder="$3"
    shift 3

    # Collect remaining arguments as extra_args
    while [[ $# -gt 0 ]]; do
        extra_args+=("$1")
        shift
    done

    if [[ -d "$folder" ]]; then
        for file in "$folder"/{*,.[!.]*,..?*}; do
            if [[ -f "$file" ]]; then
                echo "Processing file: $file"
                "$fnc" "$flag" "$file" "${extra_args[@]}"
            elif [[ -d "$file" && "$file" != "$folder"/. && "$file" != "$folder"/.. ]]; then
                all-ffl "$fnc" "$flag" "$file" "${extra_args[@]}"
            fi
        done
    else
        echo "Invalid folder: $folder"
        return 1
    fi
}

# Displays the source code of a specified function from the library folder, including its description, shortname, and usage
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

# Manages git operations, ensuring the local repository syncs with the remote. Performs status check, pull, commit, and push operations as needed
# git all in
#
all-gio() {
    # Navigate to the git folder
    cd "$DIR_LIB/.." || return

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

# Adds auto-mount entries for devices to /etc/fstab using blkid. Allows user to select a device UUID and automatically creates the appropriate fstab entry
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

# Adds custom entries to /etc/fstab using device UUIDs. Allows user to specify mount point, filesystem, mount options, and other parameters
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

# Prompts the user to select a file from the current directory by displaying a numbered list of files and returning the chosen filename
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

# Counts files in directories based on specified visibility (regular, hidden, or both). Displays results sorted by directory name
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

# Creates and sends ZFS snapshots from a source pool to a destination pool. Supports initial full sends and incremental sends for efficiency
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

# Compares data usage between two paths up to a specified depth. Displays results in a tabular format with color-coded differences
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


# Prompts the user to input or confirm a variable's value, allowing for easy customization of script parameters
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

# Logs a function's execution status with a timestamp, providing a simple way to track script progress and debugging information
# main display notification
# <function_name> <status>
all-nos() {
    local function_name="$1"
    local status="$2"
	
   
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $function_name: $status"
}

# Appends a line to a file if it does not already exist, preventing duplicate entries and providing feedback on the operation
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

# Installs specified packages using the system's package manager (apt, dnf, yum, or zypper). Performs update, upgrade, and installation operations
# install packages
# <pak1> <pak2> ...
all-ipa() {
    local function_name="${FUNCNAME[0]}"

    echo "Debug: all-ipa function called with arguments: $@"

    if [ $# -lt 1 ]; then
        all-use
        return 1
    fi

    # Function to detect the package manager
    detect_package_manager() {
        if command -v apt &> /dev/null; then
            echo "apt"
        elif command -v dnf &> /dev/null; then
            echo "dnf"
        elif command -v yum &> /dev/null; then
            echo "yum"
        elif command -v zypper &> /dev/null; then
            echo "zypper"
        else
            echo "unknown"
        fi
    }

    # Detect the package manager
    local pman=$(detect_package_manager)
    echo "Debug: Detected package manager: $pman"

    if [ "$pman" = "unknown" ]; then
        all-nos "$function_name" "Could not detect a supported package manager"
        return 1
    fi

    # Define commands based on package manager
    case "$pman" in
        apt)
            local update_cmd="update"
            local upgrade_cmd="upgrade -y"
            local install_cmd="install -y"
            ;;
        dnf|yum)
            local update_cmd="check-update"
            local upgrade_cmd="upgrade -y"
            local install_cmd="install -y"
            ;;
        zypper)
            local update_cmd="refresh"
            local upgrade_cmd="update -y"
            local install_cmd="install -y"
            ;;
        *)
            all-nos "$function_name" "Unsupported package manager: $pman"
            return 1
            ;;
    esac

    echo "Debug: Update command: $pman $update_cmd"
    echo "Debug: Upgrade command: $pman $upgrade_cmd"
    echo "Debug: Install command: $pman $install_cmd"

    # Execute update command
    echo "Debug: Executing: $pman $update_cmd"
    if ! $pman $update_cmd; then
        all-nos "$function_name" "Failed to update package list"
        return 1
    fi

    # Execute upgrade command
    echo "Debug: Executing: $pman $upgrade_cmd"
    if ! $pman $upgrade_cmd; then
        all-nos "$function_name" "Failed to upgrade packages"
        return 1
    fi

    # Install all provided packages
    echo "Debug: Executing: $pman $install_cmd $*"
    if ! $pman $install_cmd $*; then
        all-nos "$function_name" "Failed to install packages ( $* )"
        return 1
    fi

    all-nos "$function_name" "Successfully executed ( $pman $install_cmd $* )"
}

# Configures git globally with a specified username and email, essential for proper commit attribution
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

# Installs, enables, and starts the sysstat service for system performance monitoring. Modifies the configuration to ensure it's enabled
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

# Allows a specified service through the firewall using firewall-cmd, making the change permanent and reloading the firewall configuration
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

# Creates a new user with a specified username and password, prompting for input if not provided. Verifies successful user creation
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

# Enables and starts a specified systemd service. Checks if the service is active and prompts for continuation if it's not
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

# Replaces strings in files within a specified folder and its subfolders. If in a git repository, it stages changes and shows the diff
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
    #   git commit -am "Replaced $old_string with $new_string" || { echo "Failed to commit changes"; return 1; }
    # fi
  fi
}

# Renames all files containing a specified string in their names, within a given folder and its subfolders
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


# Displays the usage information, shortname, and description of the calling function, helping users understand how to use it
# function usage information 
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

# Performs an rsync operation from a source to a destination path. Displays files to be transferred and prompts for confirmation before proceeding
# rsync source (to) destination
# <storage_name> <destination_path>
all-rsd() {
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

# Concatenates and displays the contents of all files within a specified folder, separating each file's content with a line of dashes
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

# Adds a specified service to the firewalld configuration and reloads the firewall. Checks for the presence of firewall-cmd before proceeding 
# firewall (add) service (and) reload
# <service>
all-fsr() {
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


# Uploads an SSH key from a plugged-in device to a specified folder (default: /root/.ssh). Handles mounting, file copying, and unmounting of the device
# upload ssh keyfile
# <device_path> <mount_point> <subfolder_path> <upload_path> <file_name>
all-usk() {
    local device_path="$1"
    local mount_point="$2"
    local subfolder_path="$3"
    local upload_path="$4"
    local file_name="$5"

    if [ $# -ne 5 ]; then
	all-use
        return 1
    fi

    local full_path
    local upload_full_path

    echo "" 
    lsblk
    echo "" 
    echo "ls /mnt output :" 
    ls /mnt
    echo "" 

    # Evaluate and confirm variables
    all-mev "device_path" "Enter the device path" $device_path
    all-mev "mount_point" "Enter the mount point" $mount_point
    all-mev "subfolder_path" "Enter the subfolder(s) on the device" $subfolder_path
    all-mev "file_name" "Enter the file name" $file_name
    all-mev "upload_path" "Enter the upload path" $upload_path

    full_path="$mount_point/$subfolder_path/$file_name"
    upload_full_path="$upload_path/$file_name"

    # Check if mount point exists
    if [ ! -d "$mount_point" ]; then
        echo "Mount Point $mount_point will be created."
	mkdir -p $mount_point
    fi

    # Mount the device
    mount $device_path $mount_point

    # Check if mount was successful
    if [ $? -ne 0 ]; then
        echo "Failed to mount $device_path at $mount_point"
        return 1
    fi

    # Copy the SSH key to the upload path
    cp $full_path $upload_full_path

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

# Appends a private SSH key identifier to the SSH config file for a specified user. Creates the .ssh directory and config file if they don't exist
# ssh private identifier
# <user> <keyname>
# Append a private SSH key identifier to a config inside .ssh
# ssh private identifier
# <user> <keyname>
all-spi() {
    local keyname=$2
    local user=$2
    local ssh_dir
    local config_file
    local user_home

    if [ $# -ne 2 ]; then
	all-use
        return 1
    fi


    if [ "$user" == "root" ]; then
        ssh_dir="/root/.ssh"
        user_home="/root"
    else
        ssh_dir="/home/$user/.ssh"
        user_home="/home/$user"
    fi

    config_file="$ssh_dir/config"

    # Create the .ssh directory if it doesn't exist
    mkdir -p $ssh_dir

    # Define the configuration line to add
    identity_file_line="    IdentityFile $user_home/.ssh/$keyname"

    # Check if the IdentityFile line already exists
    if ! grep -qx "$identity_file_line" "$config_file" 2>/dev/null; then
        # Append the configuration to the config file
        echo -e "\nHost *\n$identity_file_line" >> $config_file

        # Set the correct permissions
        chown $user:$user $config_file
        chmod 600 $config_file

        echo "SSH config file updated at $config_file"
    else
        echo "Configuration already exists in $config_file"
    fi
}

# Appends the content of a specified public SSH key file to the authorized_keys file. Prompts for confirmation and restarts the SSH service
# append authorized keys
# <upload_path> <file_name>
all-aak() {
    local upload_path="$1"
    local file_name="$2"
    local authorized_keys_path="$upload_path/authorized_keys"
    local upload_full_path="$upload_path/$file_name"

    if [ $# -ne 2 ]; then
        echo "Usage: append_to_authorized_keys <upload_path> <file_name>"
        return 1
    fi

    # Evaluate and confirm variables
    all-mev "upload_path" "Enter the SSH folder path" $upload_path
    all-mev "file_name" "Enter the SSH key file name" $file_name

    # Prompt user to append to authorized_keys
    read -p "Do you want to append the content of $file_name to authorized_keys? (yes/no): " append_choice
    case "$append_choice" in
        [yY]|[yY][eE][sS])
            # Append the content to authorized_keys
            cat "$upload_full_path" >> "$authorized_keys_path"
            if [ $? -eq 0 ]; then
                echo "Content appended to authorized_keys"
            else
                echo "Failed to append content to authorized_keys"
            fi
            ;;
        *)
            echo "Content was not appended to authorized_keys"
            ;;
    esac
    echo "performing a systemctl restart sshd"
    systemctl restart sshd
}

# Supported operations: 
# - bypass: Perform initial SSH login to bypass StrictHostKeyChecking
# - refresh: Remove the SSH key for the given IP from known_hosts
#
# Loops a specified SSH operation (bypass StrictHostKeyChecking or refresh known_hosts) through a range of IPs defined in the configuration
# loop operation ip
# <ip array: hy,ct> <operation>
all-loi() {
    local ip_type=$1
    local operation=$2
    local ip_array_name="${ip_type^^}_IPS"

    # Ensure both parameters are provided
    if [ -z "$ip_type" ] || [ -z "$operation" ]; then
	  all-use
	  return 1
    fi

    # Ensure the array exists
    if ! declare -p "$ip_array_name" >/dev/null 2>&1; then
        echo "Invalid IP type: $ip_type"
        return 1
    fi

    # Get the associative array
    declare -n IP_ARRAY="$ip_array_name"

    for KEY in "${!IP_ARRAY[@]}"; do
        IP=${IP_ARRAY[$KEY]}

        if [ -n "$IP" ]; then
            if [ "$operation" == "bypass" ]; then
                echo "Performing SSH login to bypass StrictHostKeyChecking for $IP"
                ssh -o StrictHostKeyChecking=no root@"$IP" "exit"
                if [ $? -ne 0 ]; then
                    echo "Failed to SSH into $IP"
                fi
            elif [ "$operation" == "refresh" ]; then
                echo "Removing SSH key for $IP from known_hosts"
                ssh-keygen -R "$IP"
                if [ $? -ne 0 ]; then
                    echo "Failed to remove SSH key for $IP"
                fi
            else
                echo "Invalid operation: $operation"
                return 1
            fi
        else
            echo "IP is empty for key $KEY"
        fi
    done
}

# Resolves custom SSH aliases using the configuration file. Supports connecting to single or multiple servers, executing commands remotely
# ssh custom aliases
# <usershortcut> <servershortcut: single or csv or all or array> [command]
all-sca() {
    echo "Debug: Number of arguments: $#"
    echo "Debug: Arguments: $*"

    if [ $# -lt 1 ]; then
        all-use
        return 1
    fi

    local user_shortcut=$1
    local server_shortcuts=$2
    shift 2
    local command="$*"

    echo "Debug: user_shortcut: $user_shortcut"
    echo "Debug: server_shortcuts: $server_shortcuts"
    echo "Debug: raw command: $command"

    # Resolve user name from shortcut
    local user_name=${SSH_USERS[$user_shortcut]}
    echo "Debug: user_name: $user_name"
    if [[ -z $user_name ]]; then
        echo "Error: Unknown user shortcut '$user_shortcut'"
        return 1
    fi

    # Function to resolve server IPs from shortcuts
    resolve_server_ip() {
        local server_shortcut=$1
        local server_ip=${HY_IPS[$server_shortcut]}
        if [[ -z $server_ip ]]; then
            server_ip=${CT_IPS[$server_shortcut]}
        fi
        echo $server_ip
    }

    # Function to handle an array of servers
    handle_server_array() {
        local array_name=$1
        declare -n server_array=$array_name
        for server_shortcut in "${!server_array[@]}"; do
            local server_ip=${server_array[$server_shortcut]}
            # Construct the SSH command
            local ssh_command="ssh ${user_name}@${server_ip}"
            if [[ -n $command ]]; then
                ssh_command+=" \"$command\""
            fi

            # Execute the SSH command
            echo "Executing: $ssh_command"
            eval $ssh_command
        done
    }

    # Handle server_shortcuts
    case $server_shortcuts in
        all)
            # Loop through all servers in HY_IPS and CT_IPS
            for server_shortcut in "${!HY_IPS[@]}" "${!CT_IPS[@]}"; do
                local server_ip=$(resolve_server_ip $server_shortcut)
                # Construct the SSH command
                local ssh_command="ssh ${user_name}@${server_ip}"
                if [[ -n $command ]]; then
                    ssh_command+=" \"$command\""
                fi

                # Execute the SSH command
                echo "Executing: $ssh_command"
                eval $ssh_command
            done
            ;;
        hy_ips|ct_ips)
            # Handle specific IP array
            handle_server_array ${server_shortcuts^^}
            ;;
        *)
            # Split server_shortcuts by comma
            IFS=',' read -ra servers <<< "$server_shortcuts"

            # Check if multiple servers are provided and no command is given
            if [[ ${#servers[@]} -gt 1 && -z $command ]]; then
                echo "Error: No command provided for multiple servers"
                return 1
            fi

            # Loop through each server shortcut
            for server_shortcut in "${servers[@]}"; do
                # Resolve server IP from name shortcut
                local server_ip=$(resolve_server_ip $server_shortcut)
                if [[ -z $server_ip ]]; then
                    echo "Error: Unknown server shortcut '$server_shortcut'"
                    return 1
                fi

                # Construct the SSH command
                local ssh_command="ssh ${user_name}@${server_ip}"
                if [[ -n $command ]]; then
                    ssh_command+=" \"$command\""
                fi

                # Execute the SSH command
                echo "Executing: $ssh_command"
                eval $ssh_command
            done
            ;;
    esac
}

# Schedules a system wake-up using rtcwake. Supports absolute or relative time input, different sleep states (mem/disk), and logs operations
# sheduled wakeup timer
# <-r for relative or -a for absolute> <time> <state>
all-swt() {
    local log_file="/var/log/wake_up.log"

    # Function to log messages
    log_message() {
        local message="$1"
        echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | sudo tee -a "$log_file" > /dev/null
    }

    # Check if correct number of arguments is provided
    if [ $# -lt 3 ]; then
        echo "Usage: all-swt [-a|-r] <time> <state>"
        echo "  -a: absolute time (e.g., 7, 7:00, 2024-07-20 07:00)"
        echo "  -r: relative time (e.g., 6, 6:30 for 6 hours 30 minutes)"
        echo "  state: mem or disk"
        return 1
    fi

    local mode="$1"
    local input_time="$2"
    local state="$3"
    local wake_seconds
    local now=$(date +%s)

    # Validate sleep state
    if [[ "$state" != "mem" && "$state" != "disk" ]]; then
        echo "Invalid sleep state. Use 'mem' or 'disk'."
        return 1
    fi

    case "$mode" in
        -a)
            # Function to parse absolute time and get next occurrence
            get_next_occurrence() {
                local input="$1"
                local parsed_time
                
                # Try parsing as full date-time
                if date -d "$input" &>/dev/null; then
                    parsed_time=$(date -d "$input" +%s)
                # Try parsing as HH:MM
                elif [[ $input =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
                    parsed_time=$(date -d "today $input" +%s)
                # Try parsing as HH
                elif [[ $input =~ ^[0-9]{1,2}$ ]]; then
                    parsed_time=$(date -d "today $input:00" +%s)
                else
                    echo "Invalid time format."
                    return 1
                fi
                
                # If the parsed time is in the past, add a day
                if [ $parsed_time -le $now ]; then
                    parsed_time=$(date -d "tomorrow $input" +%s)
                fi
                
                echo $parsed_time
            }

            wake_seconds=$(get_next_occurrence "$input_time")
            if [ $? -ne 0 ]; then
                return 1
            fi
            ;;
        -r)
            # Parse relative time
            local hours=0
            local minutes=0
            if [[ $input_time =~ ^[0-9]+:[0-9]+$ ]]; then
                IFS=':' read hours minutes <<< "$input_time"
            elif [[ $input_time =~ ^[0-9]+$ ]]; then
                hours=$input_time
            else
                echo "Invalid relative time format."
                return 1
            fi
            wake_seconds=$((now + hours*3600 + minutes*60))
            ;;
        *)
            echo "Invalid mode. Use -a for absolute time or -r for relative time."
            return 1
            ;;
    esac

    local duration=$((wake_seconds - now))
    local duration_readable=$(date -u -d @"$duration" +'%-Hh %-Mm %-Ss')
    local wake_time_readable=$(date -d @"$wake_seconds" +'%Y-%m-%d %H:%M:%S')

    echo "System will wake up at: $wake_time_readable"
    echo "Time until wake-up: $duration_readable"
    echo "Sleep state: $state"
    read -p "Do you want to proceed with putting the system to sleep? (y/n): " answer

    if [[ $answer =~ ^[Yy]$ ]]; then
        echo "Putting system to sleep using state '$state'. It will wake up at $wake_time_readable"
        log_message "System set to sleep using state '$state'. Wake-up time: $wake_time_readable"
        
        sudo rtcwake -m $state -l -t "$wake_seconds" -v
        sleep_result=$?
        if [ $sleep_result -eq 0 ]; then
            log_message "System woke up at $(date +'%Y-%m-%d %H:%M:%S') using state: $state"
            echo "System woke up successfully."
            return 0
        else
            log_message "Failed to sleep using state: $state (Exit code: $sleep_result)"
            echo "Failed to sleep using state: $state (Exit code: $sleep_result)"
            return 1
        fi
    else
        echo "Operation cancelled."
        log_message "Operation cancelled by user"
    fi
}
