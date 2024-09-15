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

# Displays an overview of specific NFS-related functions in the script, showing their usage, shortname, and description
# overview functions
# 
nfs-fun() {
    all-laf "$FILEPATH_nfs" "$@"
}
# Displays an overview of NFS-specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
# 
nfs-var() {
    all-acu -o "$CONFIG_nfs" "$DIR_LIB/.."
}

# Sets up an NFS share by prompting for necessary information (NFS header, shared folder, and options) and applying the configuration
# nfs setup
# <nfs_header> <shared_folder> <nfs_options>
nfs-set() {
    local function_name="${FUNCNAME[0]}"
    local nfs_header="$1"
    local shared_folder="$2"
    local nfs_options="$3"

    # Prompt for missing inputs
    all-mev "nfs_header" "Enter NFS header" "$nfs_header"
    all-mev "shared_folder" "Enter path to shared folder" "$shared_folder"
    all-mev "nfs_options" "Enter NFS options" "$nfs_options"

    # Apply the NFS configuration
    nfs-apl "$nfs_header" "$shared_folder" "$nfs_options"
    all-nos "$function_name" "NFS setup complete"
}

# Applies NFS configuration by creating the shared folder if needed, updating /etc/exports, and restarting the NFS server
# nfs apply config
# <nfs_header> <shared_folder> <nfs_options>
nfs-apl() {
    local function_name="${FUNCNAME[0]}"
    local nfs_header="$1"
    local shared_folder="$2"
    local nfs_options="$3"

    # Check if the shared folder exists, create it if not
    if [ ! -d "$shared_folder" ]; then
        mkdir -p "$shared_folder"
        chmod -R 777 "$shared_folder"
        echo "Shared folder created: $shared_folder"
    fi

    # Check if the NFS export already exists in /etc/exports
    if grep -qF "$shared_folder" /etc/exports; then
        echo "NFS export already exists in /etc/exports. Skipping addition."
    else
        # Append NFS export line to /etc/exports
        echo "$shared_folder $nfs_options" | tee -a /etc/exports > /dev/null
        echo "NFS export added to /etc/exports."
    fi

    # Restart NFS server
    exportfs -ra
    systemctl restart nfs-server

    # Print confirmation message
    echo "NFS server configured. Shared folder: $shared_folder"
    all-nos "$function_name" "NFS configuration applied"
}

