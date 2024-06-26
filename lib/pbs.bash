# get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

#  
# overview
#  
pbs-fun() {
local file_name="$BASH_SOURCE"
all-laf "$file_name"
}
 
# Download Proxmox GPG key and verify checksums.
# disable repository
#   
pbs-sgp() {
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

# Add Proxmox repository to sources.list if not already present.
# setup sources.list
#   
pbs-adr() {
    local function_name="${FUNCNAME[0]}"
    line_to_add="deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription"
    file="/etc/apt/sources.list"

    if grep -Fxq "$line_to_add" "$file"; then
        all-nos "$function_name" "Line already exists in $file"
    else
        echo "$line_to_add" >> "$file"
        all-nos "$function_name" "Line added to $file"
    fi
}

# Update package lists and upgrade packages.
# packages update upgrade
#   
pbs-puu() {
    local function_name="${FUNCNAME[0]}"
    apt update
    apt upgrade -y
    all-nos "$function_name" "Package lists updated and packages upgraded"
}

# Restore datastore configuration file with given parameters.
# restore datastore
# <datastore_config> <datastore_name> <datastore_path>
pbs-rda() {
        local function_name="${FUNCNAME[0]}"
	local datastore_config="$1"
	local datastore_name="$2"
	local datastore_path="$3"

     if [ $# -ne 3 ]; then
       all-use
       return 1
     fi

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
        echo "$combined_lines"
    fi

    all-nos "$function_name" "executed ( $1 $2 $3 )"
}
