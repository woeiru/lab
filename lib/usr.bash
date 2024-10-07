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

# Configures Git and SSH to disable password prompting by updating Git global configuration and SSH config file
# configure git ssh passphrase
#
usr-cgp() {
    local ssh_config="$HOME/.ssh/config"
    local askpass_line="    SetEnv SSH_ASKPASS=''"

    # Set Git configuration
    if git config --global core.askPass ""; then
        echo "Git global configuration updated to disable password prompting."
    else
        echo "Error: Failed to update Git configuration."
        return 1
    fi

    # Update SSH config
   if [ ! -f "$ssh_config" ]; then
        mkdir -p "$HOME/.ssh"
        touch "$ssh_config"
        chmod 600 "$ssh_config"
    fi

    if ! grep -q "^Host \*$" "$ssh_config"; then
        echo -e "\n# Disable SSH_ASKPASS\nHost *" >> "$ssh_config"
    fi

    if ! grep -q "^$askpass_line" "$ssh_config"; then
        sed -i '/^Host \*/a\'"$askpass_line" "$ssh_config"
        echo "SSH configuration updated to disable ASKPASS."
    else
        echo "SSH configuration already contains ASKPASS setting."
    fi

    echo "configure_git_ssh_passphrase: Git and SSH configurations have been updated."
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
