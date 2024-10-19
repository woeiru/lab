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

# Renames all files containing a specified string in their names, within a given folder and its subfolders
# renames files in folder
# <path> <old_name> <new_name>
usr-rnf() {
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
