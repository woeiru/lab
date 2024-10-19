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

# Shows a summary of selected functions in the script, displaying their usage, shortname, and description
# overview functions
#
usr-fun() {
    # Pass all arguments directly to all-laf
    all-laf "$FILEPATH_usr" "$@"
}
# Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
#
usr-var() {
    all-acu -o "$CONFIG_usr" "$DIR_LIB/.."
}

# Changes the Konsole profile for the current user by updating the konsolerc file
# change konsole profile
# <profile_number>
usr-ckp() {
    local profile_number="$1"
    local username
    local konsole_profile_path
    local profile_name
    username=$(whoami)
    echo "Changing Konsole profile for user: $username"
    if [ "$username" = "root" ]; then
        konsole_profile_path="/root/.local/share/konsole"
    else
        konsole_profile_path="$HOME/.local/share/konsole"
    fi
    if [ ! -d "$konsole_profile_path" ]; then
        echo "Error: Konsole profile directory not found at $konsole_profile_path"
        return 1
    fi
    if ! [[ "$profile_number" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid profile number. Please provide a positive integer."
        return 1
    fi
    profile_name="Profile $profile_number.profile"
    if [ ! -f "$konsole_profile_path/$profile_name" ]; then
        echo "Error: Profile $profile_number does not exist in $konsole_profile_path"
        return 1
    fi
    local konsolerc_path
    if [ "$username" = "root" ]; then
        konsolerc_path="/root/.config/konsolerc"
    else
        konsolerc_path="$HOME/.config/konsolerc"
    fi
    if [ ! -f "$konsolerc_path" ]; then
        echo "Error: Konsole configuration file not found at $konsolerc_path"
        return 1
    fi
    
    # Check if [Desktop Entry] section exists
    if ! grep -q '^\[Desktop Entry\]' "$konsolerc_path"; then
        # If it doesn't exist, add it and the DefaultProfile line
        echo -e "\n[Desktop Entry]\nDefaultProfile=Profile $profile_number.profile" >> "$konsolerc_path"
        echo "Added [Desktop Entry] section with DefaultProfile to $konsolerc_path"
    else
        # If [Desktop Entry] exists, check if DefaultProfile line exists
        if ! sed -n '/^\[Desktop Entry\]/,/^\[/p' "$konsolerc_path" | grep -q '^DefaultProfile='; then
            # If it doesn't exist, add it to the [Desktop Entry] section
            sed -i '/^\[Desktop Entry\]/a DefaultProfile=Profile '"$profile_number"'.profile' "$konsolerc_path"
            echo "Added DefaultProfile line to $konsolerc_path"
        else
            # If it exists, update it
            sed -i '/^\[Desktop Entry\]/,/^\[/ s/^DefaultProfile=.*/DefaultProfile=Profile '"$profile_number"'.profile/' "$konsolerc_path"
            echo "Updated existing DefaultProfile line in $konsolerc_path"
        fi
    fi
    
    echo "Konsole default profile updated to Profile $profile_number for user $username."
}

# Prompts the user to select a file from the current directory by displaying a numbered list of files and returning the chosen filename
# variable select filename
#
usr-vsf() {
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
usr-cff() {
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

# Compares data usage between two paths up to a specified depth. Displays results in a tabular format with color-coded differences
# data usage comparison
# <path1> <path2> <depth>
usr-duc() {
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

# Concatenates and displays the contents of all files within a specified folder, separating each file's content with a line of dashes
# cat in folder
# <path>
usr-cif() {
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

# Replaces strings in files within a specified folder and its subfolders. If in a git repository, it stages changes and shows the diff
# replace strings folder
# <foldername> <old_string> <new_string>
usr-rsf() {
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

# Performs an rsync operation from a source to a destination path. Displays files to be transferred and prompts for confirmation before proceeding
# rsync source (to) destination
# <source_path> <destination_path>
usr-rsd() {
    if [ $# -ne 2 ]; then
        all-use
        return 1
    fi
    local source_path="$1"
    local destination_path="$2"

    # Check if destination path exists
    if [ ! -d "$destination_path" ]; then
        echo "Destination path $destination_path will be created."
        mkdir -p "$destination_path"
    fi
    # Check again
    if [ ! -d "$destination_path" ]; then
        echo "Destination path $destination_path could not been created."
        return 1
    fi

    # Display files to be transferred
    echo "Files to be transferred from $source_path to $destination_path:"
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

# Schedules a system wake-up using rtcwake. Supports absolute or relative time input and different sleep states (mem/disk)
# sheduled wakeup timer
# <-r for relative or -a for absolute> <time> <state>
usr-swt() {
    # Check if correct number of arguments is provided
    if [ $# -lt 3 ]; then
        echo "Usage: usr-swt [-a|-r] <time> <state>"
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

        sudo rtcwake -m $state -l -t "$wake_seconds" -v
        sleep_result=$?
        if [ $sleep_result -eq 0 ]; then
            echo "System woke up successfully."
            return 0
        else
            echo "Failed to sleep using state: $state (Exit code: $sleep_result)"
            return 1
        fi
    else
        echo "Operation cancelled."
    fi
}

# Adds a specific line to a target if not already present
# adding line (to) target
#
pve-adr() {
    local function_name="${FUNCNAME[0]}"
    local file="$1"
    local line_to_add="$2"
    local temp_file=$(mktemp)

    # Check if both arguments were provided
    if [ -z "$file" ] || [ -z "$line_to_add" ]; then
        all-nos "$function_name" "Error: Both file path and line to add must be provided"
        return 1
    fi

    # Check if the file exists and is writable
    if [ ! -w "$file" ]; then
        all-nos "$function_name" "Error: $file does not exist or is not writable"
        return 1
    fi

    # Check if the line already exists in the file
    if grep -Fxq "$line_to_add" "$file"; then
        all-nos "$function_name" "Line already exists in $file"
        return 0
    fi

    # Create a temporary file with the new content
    cat "$file" > "$temp_file"
    echo "$line_to_add" >> "$temp_file"

    # Use mv to atomically replace the original file
    if mv "$temp_file" "$file"; then
        all-nos "$function_name" "Line added to $file"
        return 0
    else
        all-nos "$function_name" "Error: Failed to update $file"
        rm -f "$temp_file"
        return 1
    fi
}

# Updates the container template reference in the Proxmox configuration file, prompting for user confirmation and new template name
# config update containertemplate
# [interactive]
pve-cuc() {
    # Check if CONFIG_pve is set
    if [ -z "$CONFIG_pve" ]; then
        echo "Error: CONFIG_pve is not set. Please ensure it's defined before calling this function."
        return 1
    fi

    local current_template
    local new_template

    # Prompt user if they want to update the config file
    read -p "Do you want to update the container config file ($CONFIG_pve)? (y/n): " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Config update cancelled."
        return 0
    fi

    # Find the current template
    current_template=$(grep -oP 'CT_DL_1="\K[^"]+' "$CONFIG_pve")
    if [ -z "$current_template" ]; then
        echo "Error: Couldn't find the current template in the config file."
        return 1
    fi

    # Prompt for the new template
    read -p "Enter the new template name (current: $current_template): " new_template
    if [ -z "$new_template" ]; then
        echo "No new template provided. Config update cancelled."
        return 0
    fi

    # Update the config file
    if sed -i "s|$current_template|$new_template|g" "$CONFIG_pve"; then
        echo "Config file updated successfully."
        echo "Changed template from '$current_template' to '$new_template' in:"
        grep -n "$new_template" "$CONFIG_pve"
    else
        echo "Error: Failed to update the config file."
        echo "The original file is unchanged. You can find a backup at ${CONFIG_pve}.bak"
        return 1
    fi
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

# Replaces all occurrences of a string in files within a given folder
# Usage: usr-rif [-d] [-r] [-i] <path> <old_string> <new_string>
# Options: -d (dry run), -r (recursive), -i (interactive)
usr-rif() {
    local recursive=false
    local interactive=false
    local dry_run=false
    local directory=""
    local search_string=""
    local replace_string=""
    local ignore_git=true
    local files_found=0
    local files_modified=0
    local files_skipped=0

    # ANSI color codes
    local GREEN='\033[0;32m'
    local RED='\033[0;31m'
    local YELLOW='\033[0;33m'
    local NC='\033[0m' # No Color

    # Parse options and arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--recursive) recursive=true; shift ;;
            -i|--interactive) interactive=true; shift ;;
            -d|--dry-run) dry_run=true; shift ;;
            --include-git) ignore_git=false; shift ;;
            *)
                if [[ -z "$directory" ]]; then
                    directory="$1"
                elif [[ -z "$search_string" ]]; then
                    search_string="$1"
                elif [[ -z "$replace_string" ]]; then
                    replace_string="$1"
                else
                    echo "Error: Too many arguments."
                    echo "Usage: usr-rif [-r] [-i] [-d] [--include-git] <directory> <search_string> <replace_string>"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Check if required arguments are provided
    if [[ -z "$directory" || -z "$search_string" || -z "$replace_string" ]]; then
        echo "Error: Missing required arguments."
        echo "Usage: usr-rif [-r] [-i] [-d] [--include-git] <directory> <search_string> <replace_string>"
        return 1
    fi

    # Validate and normalize directory path
    directory=$(realpath "$directory")
    if [[ ! -d "$directory" ]]; then
        echo "Error: '$directory' is not a valid directory."
        return 1
    fi

    # Construct find command
    local find_cmd="find \"$directory\" -type f"
    [[ "$recursive" != true ]] && find_cmd+=" -maxdepth 1"
    [[ "$ignore_git" == true ]] && find_cmd+=" -not -path '*/\.git/*'"

    echo "Searching for files containing '$search_string' in '$directory'..."
    while IFS= read -r file; do
        if grep -q "$search_string" "$file" 2>/dev/null; then
            ((files_found++))
            printf "Found match in file: ${GREEN}%s${NC}\n" "$file"
            if [[ "$dry_run" == true ]]; then
                echo "Would modify: $file"
                grep -n "$search_string" "$file" | head -n 1 | awk -v red="$RED" -v yellow="$YELLOW" -v nc="$NC" -v search="$search_string" '{
                    split($0, parts, ":")
                    line_num = parts[1]
                    content = substr($0, length(line_num) + 2)
                    match_start = index(content, search)
                    match_end = match_start + length(search) - 1
                    printf "Sample change: %s%s%s:%s%s%s%s\n",
                        red, line_num, nc,
                        substr(content, 1, match_start - 1),
                        yellow, substr(content, match_start, length(search)), nc,
                        substr(content, match_end + 1)
                }'
            elif [[ "$interactive" == true ]]; then
                echo "=== INTERACTIVE MODE ==="
                echo -e "Modify '${GREEN}$file${NC}'? (${YELLOW}y${NC}/${YELLOW}n${NC}): "
                read -r user_response
                if [[ $user_response =~ ^[Yy]$ ]]; then
                    if sed -i "s/$search_string/$replace_string/g" "$file"; then
                        echo -e "${GREEN}Modified:${NC} $file"
                        ((files_modified++))
                    else
                        echo -e "${RED}Failed to modify:${NC} $file"
                    fi
                else
                    echo -e "${YELLOW}Skipped:${NC} $file"
                    ((files_skipped++))
                fi
            else
                if sed -i "s/$search_string/$replace_string/g" "$file"; then
                    echo -e "${GREEN}Modified:${NC} $file"
                    ((files_modified++))
                else
                    echo -e "${RED}Failed to modify:${NC} $file"
                fi
            fi
        fi
    done < <(eval "$find_cmd")

    echo "Summary:"
    echo "  Files found with matches: $files_found"
    echo "  Files modified: $files_modified"
    [[ "$interactive" == true ]] && echo "  Files skipped: $files_skipped"

    if [[ "$dry_run" == true ]]; then
        echo "Dry run completed. $files_found file(s) would be modified."
    elif [[ $files_modified -eq 0 ]]; then
        echo "No files were modified in '$directory'."
    else
        echo "$files_modified file(s) were modified in '$directory'."
    fi
}

# Navigates to the Ansible project directory, runs the playbook, then returns to the original directory
# ansible deployment desk
# Usage: usr-ans <ansible_pro_path> <ansible_site_path>
usr-ans() {
    # Check if two arguments are provided
    if [ $# -ne 2 ]; then
        echo "Error: Incorrect number of arguments. Usage: usr-ans <ansible_pro_path> <ansible_site_path>"
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
