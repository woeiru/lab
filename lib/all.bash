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
    echo "Warning: Configuration file $CONFIG_LIB not found!"
    # Don't exit, just continue
fi

# Logging function
all-log() {
    local log_level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$log_level] $message"
}

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
    local col_width_1=7
    local col_width_2=16
    local col_width_3=18
    local col_width_4=36
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
    print_row "Func" "Arguments" "Shortname" "Description" "Size" "Loc" "file" "libr" "sets"
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

# Manages git operations, ensuring the local repository syncs with the remote.
# Performs status check, pull, commit, and push operations as needed.
#
all-gio() {
    local dir="${DIR_LIB:-.}/.."
    local branch="${GIT_BRANCH:-master}"
    local commit_message="${GIT_COMMITMESSAGE:-Auto-commit: $(date +%Y-%m-%d_%H-%M-%S)}"

    # Navigate to the git folder
    cd "$dir" || { echo "Failed to change directory to $dir"; return 1; }

    # Fetch updates from remote
    git fetch origin "$branch" || { echo "Failed to fetch from remote"; return 1; }

    # Get the current status
    local status_output
    status_output=$(git status --porcelain)

    if [[ -z "$status_output" ]]; then
        echo "Working tree clean. Checking for updates..."
        if git rev-list HEAD...origin/"$branch" --count | grep -q "^0$"; then
            echo "Local branch is up to date with origin/$branch."
        else
            echo "Updates available. Pulling changes..."
            git pull origin "$branch" || { echo "Failed to pull changes"; return 1; }
        fi
    else
        echo "Changes detected. Committing and pushing..."
        git add . || { echo "Failed to stage changes"; return 1; }
        git commit -m "$commit_message" || { echo "Failed to commit changes"; return 1; }
        git push origin "$branch" || { echo "Failed to push changes"; return 1; }
    fi

    # Return to the previous directory
    cd - > /dev/null || { echo "Failed to return to previous directory"; return 1; }
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
    $pman $update_cmd > /tmp/update_output.log 2>&1
    update_exit_code=$?

    if [ $update_exit_code -eq 0 ]; then
        echo "No updates available."
    elif [ $update_exit_code -eq 100 ]; then
        echo "Updates are available."
    else
        echo "Debug: $pman $update_cmd exited with code $update_exit_code"
        echo "Full command output:"
        cat /tmp/update_output.log
        all-nos "$function_name" "Failed to check for updates. Exit code: $update_exit_code"
        return 1
    fi

    echo "Debug: Update check completed successfully"

    # Execute upgrade command
    echo "Debug: Executing: $pman $upgrade_cmd"
    if ! $pman $upgrade_cmd > /tmp/upgrade_output.log 2>&1; then
        local exit_code=$?
        echo "Debug: $pman $upgrade_cmd exited with code $exit_code"
        echo "Full command output:"
        cat /tmp/upgrade_output.log
        all-nos "$function_name" "Failed to upgrade packages. Exit code: $exit_code"
        return 1
    fi

    echo "Debug: Upgrade command completed successfully"

    # Install all provided packages
    echo "Debug: Executing: $pman $install_cmd $*"
    if ! $pman $install_cmd $* > /tmp/install_output.log 2>&1; then
        local exit_code=$?
        echo "Debug: $pman $install_cmd $* exited with code $exit_code"
        echo "Full command output:"
        cat /tmp/install_output.log
        all-nos "$function_name" "Failed to install packages ( $* ). Exit code: $exit_code"
        return 1
    fi

    echo "Debug: Install command completed successfully"

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
# ssh upload keyfile
# <device_path> <mount_point> <subfolder_path> <upload_path> <file_name>
all-suk() {
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

# Generates an SSH key pair and handles the transfer process
# ssh key swap
# For client-side generation: all-sks -c <server_address> <key_name> [encryption_type] /// For server-side generation: all-sks -s <client_address> [encryption_type] <key_name>
all-sks() {
    local mode="$1"
    local remote_address="$2"
    local key_name="$3"
    local encryption_type="${4:-ed25519}"  # Default to ed25519 if not specified
    local ssh_dir="/root/.ssh"

    if [ $# -lt 3 ] || [ $# -gt 4 ]; then
        echo "Usage: all-sks -s <client_address> <key_name> [encryption_type] # for server-side generation"
        echo "       all-sks -c <server_address> <key_name> [encryption_type] # for client-side generation"
        echo "If encryption_type is not specified, ed25519 will be used by default."
        return 1
    fi

    # Function to generate SSH key
    generate_key() {
        local key_path="$1"
        case "$encryption_type" in
            rsa)
                ssh-keygen -t rsa -b 4096 -f "$key_path" -N ""
                ;;
            dsa)
                ssh-keygen -t dsa -f "$key_path" -N ""
                ;;
            ecdsa)
                ssh-keygen -t ecdsa -b 521 -f "$key_path" -N ""
                ;;
            ed25519|*)
                ssh-keygen -t ed25519 -f "$key_path" -N ""
                ;;
        esac
    }

    case "$mode" in
        -s) # Server-side generation
            mkdir -p "$ssh_dir"
            chmod 700 "$ssh_dir"
            generate_key "$ssh_dir/$key_name"
            if [ $? -ne 0 ]; then
                echo "Failed to generate SSH key pair."
                return 1
            fi
            echo "SSH key pair generated on server using $encryption_type encryption."
            echo "Transferring private key to client..."
            scp "$ssh_dir/$key_name" "${remote_address}:~/.ssh/"
            if [ $? -ne 0 ]; then
                echo "Failed to transfer private key to client."
                return 1
            fi
            rm "$ssh_dir/$key_name"
            echo "Private key transferred to client and removed from server."
            echo "Public key file: $ssh_dir/${key_name}.pub"
            echo "Please use all-sak to append the public key to authorized_keys if needed."
            ;;
        -c) # Client-side generation
            generate_key "$HOME/.ssh/$key_name"
            if [ $? -ne 0 ]; then
                echo "Failed to generate SSH key pair."
                return 1
            fi
            echo "SSH key pair generated on client using $encryption_type encryption."
            echo "Transferring public key to server..."
            scp "$HOME/.ssh/${key_name}.pub" "${remote_address}:/tmp/"
            if [ $? -ne 0 ]; then
                echo "Failed to transfer public key to server."
                return 1
            fi
            ssh "$remote_address" "mkdir -p $ssh_dir && mv /tmp/${key_name}.pub $ssh_dir/"
            if [ $? -ne 0 ]; then
                echo "Failed to move public key on server."
                return 1
            fi
            echo "Public key transferred to server and saved in $ssh_dir/${key_name}.pub"
            echo "Private key file on client: $HOME/.ssh/$key_name"
            echo "Please use all-sak on the server to append the public key to authorized_keys if needed."

            # Remove the public key from the client's .ssh folder
            rm "$HOME/.ssh/${key_name}.pub"
            echo "Public key removed from client's .ssh folder."
            ;;
        *)
            echo "Invalid mode. Use -s for server-side or -c for client-side generation."
            return 1
            ;;
    esac
    echo "SSH key generation and transfer completed successfully."
}

# Appends the content of a specified public SSH key file to the authorized_keys file.
# Provides informational output and restarts the SSH service.
# Usage: all-sak <upload_path> <file_name>
all-sak() {
    local upload_path="$1"
    local file_name="$2"
    local authorized_keys_path="$upload_path/authorized_keys"
    local upload_full_path="$upload_path/$file_name"

    # Check for correct number of arguments
    if [ $# -ne 2 ]; then
        echo "Usage: all-sak <upload_path> <file_name>"
        return 1
    fi

    # Check if the upload path exists
    if [ ! -d "$upload_path" ]; then
        echo "Error: Upload path '$upload_path' does not exist."
        return 1
    fi

    # Check if the file exists
    if [ ! -f "$upload_full_path" ]; then
        echo "Error: File '$upload_full_path' does not exist."
        return 1
    fi

    # Validate the file as a public key
    if ! ssh-keygen -l -f "$upload_full_path" &>/dev/null; then
        echo "Error: '$file_name' does not appear to be a valid public key."
        return 1
    fi

    # Create authorized_keys if it doesn't exist
    touch "$authorized_keys_path"
    chmod 600 "$authorized_keys_path"

    # Check if the key is already in authorized_keys
    if grep -qf "$upload_full_path" "$authorized_keys_path"; then
        echo "Info: This key already exists in authorized_keys. Appending anyway."
    fi

    # Append the content to authorized_keys
    if cat "$upload_full_path" >> "$authorized_keys_path"; then
        echo "Info: Content successfully appended to authorized_keys"
    else
        echo "Error: Failed to append content to authorized_keys"
        return 1
    fi

    echo "Info: Restarting SSH service..."
    if systemctl restart sshd; then
        echo "Info: SSH service restarted successfully."
    else
        echo "Error: Failed to restart SSH service. Please check the service manually."
        return 1
    fi

    echo "Info: SSH key append operation completed successfully."
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
    echo "Debug: All arguments: $*"
    
    if [ $# -lt 2 ]; then
        all-use
        return 1
    fi

    local user_shortcut=$1
    local server_shortcuts=$2
    shift 2
    local command="$*"

    echo "Debug: User shortcut: $user_shortcut"

    # Resolve user name from shortcut
    local user_name="${SSH_USERS[$user_shortcut]}"
    echo "Debug: Resolved user name: $user_name"

    if [[ -z $user_name ]]; then
        echo "Error: Unknown user shortcut '$user_shortcut'"
	echo "Debug: SSH_USERS array contents: ${SSH_USERS[@]}"
  	echo "Debug: SSH_USERS keys: ${!SSH_USERS[@]}"
        return 1
    fi

    echo "Debug: Server shortcuts (raw): $server_shortcuts"
    echo "Debug: ALL_IP_ARRAYS: ${ALL_IP_ARRAYS[*]}"

    # Function to handle an array of servers
    handle_server_array() {
        local array_name=$1
        declare -n server_array=$array_name
        echo "Debug: Processing array: $array_name"
        echo "Debug: Array contents: ${!server_array[*]}"
        for server_shortcut in "${!server_array[@]}"; do
            local server_ip=${server_array[$server_shortcut]}
            echo "Debug: Resolved server IP for $server_shortcut: $server_ip"
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

    # Function to normalize server shortcuts
    normalize_shortcut() {
        local input=$1
        local normalized=$input

        # Check if input matches any array name or alias (case-insensitive)
        for array in "${!ARRAY_ALIASES[@]}"; do
            local aliases=(${ARRAY_ALIASES[$array]})
            for alias in "${aliases[@]}"; do
                if [[ ${input,,} == ${alias,,} ]]; then
                    normalized=$array
                    echo "Debug: Match found, normalized '$input' to '$normalized'" >&2
                    break 2
                fi
            done
        done

        echo "Debug: Normalized '$input' to '$normalized'" >&2
        echo "$normalized"
    }

    # Function to find server IP
    find_server_ip() {
        local shortcut=$1
        local ip=""
        local array_name=""
        for array in "${ALL_IP_ARRAYS[@]}"; do
            echo "Debug: Searching for '$shortcut' in '$array'" >&2
            declare -n current_array=$array
            echo "Debug: $array contents: ${!current_array[*]}" >&2
            if [[ -n ${current_array[$shortcut]} ]]; then
                ip=${current_array[$shortcut]}
                array_name=$array
                echo "Debug: Found '$shortcut' in '$array'" >&2
                break
            fi
        done
        echo "Debug: Found IP for $shortcut: $ip (from $array_name)" >&2
        echo "$ip"
    }

    # Function to check if input is an array name
    is_array_name() {
        local input=$1
        echo "Debug: Checking if '$input' is an array name" >&2
        if [[ $input == "all" ]]; then
            echo "Debug: '$input' is 'all'" >&2
            return 0
        fi
        for array in "${ALL_IP_ARRAYS[@]}"; do
            if [[ $input == $array ]]; then
                echo "Debug: '$input' matches array '$array'" >&2
                return 0
            fi
        done
        echo "Debug: '$input' is not an array name" >&2
        return 1
    }

    # Normalize the server shortcuts
    local normalized_shortcuts=$(normalize_shortcut "$server_shortcuts")
    echo "Debug: Normalized server shortcuts: $normalized_shortcuts"

    # Handle server_shortcuts
    if is_array_name "$normalized_shortcuts"; then
        echo "Debug: Processing as array name"
        if [[ $normalized_shortcuts == "all" ]]; then
            echo "Debug: Processing all servers"
            for array in "${ALL_IP_ARRAYS[@]}"; do
                handle_server_array $array
            done
        else
            echo "Debug: Processing specific IP array: $normalized_shortcuts"
            handle_server_array $normalized_shortcuts
        fi
    else
        echo "Debug: Processing as individual server(s)"
        IFS=',' read -ra servers <<< "$normalized_shortcuts"
        if [[ ${#servers[@]} -gt 1 && -z $command ]]; then
            echo "Error: No command provided for multiple servers"
            return 1
        fi
        for server_shortcut in "${servers[@]}"; do
            local server_ip=$(find_server_ip "$server_shortcut")
            if [[ -z $server_ip ]]; then
                echo "Error: Unknown server shortcut '$server_shortcut'"
                return 1
            fi
            local ssh_command="ssh ${user_name}@${server_ip}"
            if [[ -n $command ]]; then
                ssh_command+=" \"$command\""
            fi
            echo "Executing: $ssh_command"
            eval $ssh_command
        done
    fi
    echo "Debug: Raw command: $command"
}

# Mounts an NFS share interactively or with provided arguments
# network file share
# [server_ip] [shared_folder] [mount_point] [options]
all-nfs() {
    local function_name="${FUNCNAME[0]}"
    local server_ip=""
    local shared_folder=""
    local mount_point=""
    local options=""

    # If arguments are provided, use them
    if [ $# -eq 4 ]; then
        server_ip="$1"
        shared_folder="$2"
        mount_point="$3"
        options="$4"
    else
        # Use all-mev to prompt for each parameter
        all-mev "server_ip" "Enter NFS server IP" "$NFS_SERVER_IP"
        all-mev "shared_folder" "Enter NFS shared folder" "$NFS_SHARED_FOLDER"
        all-mev "mount_point" "Enter local mount point" "$NFS_MOUNT_POINT"
        all-mev "options" "Enter mount options" "$NFS_MOUNT_OPTIONS"
    fi

    # Create the mount point if it doesn't exist
    if [ ! -d "$mount_point" ]; then
        echo "Creating mount point $mount_point"
        sudo mkdir -p "$mount_point"
    fi

    # Perform the mount
    echo "Mounting NFS share..."
    if sudo mount -t nfs -o "$options" "${server_ip}:${shared_folder}" "$mount_point"; then
        echo "NFS share mounted successfully at $mount_point"
    else
        echo "Failed to mount NFS share"
        return 1
    fi

    # Verify the mount
    if mount | grep -q "$mount_point"; then
        echo "Mount verified successfully"
    else
        echo "Mount verification failed"
        return 1
    fi

    all-nos "$function_name" "NFS mount completed"
}

all-ans() {
    # Check if two arguments are provided
    if [ $# -ne 2 ]; then
        echo "Error: Incorrect number of arguments. Usage: all-ans <ansible_pro_path> <ansible_site_path>"
        return 1
    fi

    # Store the Ansible path and site path from the arguments
    local ansible_pro_path="$1"
    local ansible_site_path="$2"

    # Store the current directory
    local current_dir=$(pwd)

    # Navigate to the specified Ansible directory
    cd "$ansible_pro_path" || return

    # Execute the Ansible playbook with the provided site path
    ansible-playbook "$ansible_site_path"

    # Return to the previous directory
    cd "$current_dir" || return
}
