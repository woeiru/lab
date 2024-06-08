# Get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# Source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

#list all Functions in a given File
pbs() {
    printf "+--------------------+----------------------------------------------------------------+-----------------+-----------------+\n"
    printf "| %-18s | %-62s | %-15s | %-15s |\n" "Function Name" "Description" "Size - Lines" "Location - Line"
    printf "+--------------------+----------------------------------------------------------------+-----------------+-----------------+\n"
    local file_name="${1:-${BASH_SOURCE[0]}}"
    # Initialize variables
    local last_comment_line=0
    local line_number=0
    declare -a comments=()

    # Read all comments into an array
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            comments[$line_number]="${line:2}"  # Remove leading '# '
        fi
    done < "$file_name"

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
            # Truncate the description if it's longer than 60 characters
            truncated_desc=$(echo "${comments[$last_comment_line]:-N/A}" | awk '{ if (length($0) > 60) print substr($0, 1, 57) "..."; else print $0 }')
            # Print function name, function size, comment line number, and comment
            printf "%20s | %-62s | %-15s | %s\n" "$func_name" "$truncated_desc" "$func_size" "${last_comment_line:-N/A}"
        elif [[ $line =~ ^[[:space:]]*#[[:space:]]+ ]]; then
            last_comment_line=$line_number
        fi
    done < "$file_name"
    printf "+--------------------+----------------------------------------------------------------+-----------------+-----------------+\n"
}

# Function to disable repository by commenting out lines starting with "deb" in specified files
setup_gpg() {
    # Download the GPG key
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

    # Verify SHA512 checksum
    sha512_expected="7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87"
    sha512_actual=$(sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | awk '{print $1}')

    if [ "$sha512_actual" == "$sha512_expected" ]; then
        echo "SHA512 checksum verified successfully."
    else
        echo "SHA512 checksum verification failed."
    fi

    # Verify MD5 checksum
    md5_expected="41558dc019ef90bd0f6067644a51cf5b"
    md5_actual=$(md5sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg | awk '{print $1}')

    if [ "$md5_actual" == "$md5_expected" ]; then
        echo "MD5 checksum verified successfully."
    else
        echo "MD5 checksum verification failed."
    fi
}

# Function to add a line to sources.list if it doesn't already exist
add_repo() {
    local function_name="${FUNCNAME[0]}"
    line_to_add="deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription"
    file="/etc/apt/sources.list"

    if grep -Fxq "$line_to_add" "$file"; then
        notify_status "$function_name" "Line already exists in $file"
    else
        echo "$line_to_add" >> "$file"
        notify_status "$function_name" "Line added to $file"
    fi
}

# Function to update package lists and upgrade packages
update_upgrade() {
    local function_name="${FUNCNAME[0]}"
    apt update
    apt upgrade -y
    notify_status "$function_name" "Package lists updated and packages upgraded"
}

# Function to restore datastore
add_datastore () {
	local datastore_config="$1"
	local datastore_name="$2"
	local datastore_path="$3"

 # Define the file path to the configuration file
    local file="/etc/proxmox-backup/datastore.cfg"
    # Define the combined lines to be checked within the file
    local combined_lines="datastore: $datstore_name\n\tpath $datastore_path"

    # Check if the file exists
    if [[ -f "$file" ]]; then
        echo "$file exists."

        # Check if the combined lines are present in the file in sequence
        if grep -Pzo "(?s)$combined_lines" "$file"; then
            echo "The lines are present in sequence in $file."
        else
            echo "The lines are not present in sequence in $file. Adding the lines."
            # Append the combined lines to the file
            echo -e "$combined_lines" >> "$file"
            echo "Lines added to $file."
        fi
    else
        echo "$file does not exist. Creating the file and adding the lines."
        # Create the file and add the combined lines
        echo -e "$combined_lines" > "$file"
        echo "File created and lines added."
    fi

}
