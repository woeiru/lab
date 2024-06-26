# get dirname and filename and basename
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE=$(basename "$BASH_SOURCE")
BASE="${FILE%.*}"

# source config.sh using the absolute path
source "$DIR/../var/${BASE}.conf"

#  
# overview
#   
nfs-fun() {
local file_name="$BASH_SOURCE"
all-laf "$file_name"
}

# Unified function to set up NFS
# nfs setup
# <nfs_header> <shared_folder> <nfs_options>
nfs-setup() {
    local function_name="${FUNCNAME[0]}"
    local nfs_header="$1"
    local shared_folder="$2"
    local nfs_options="$3"

    # Prompt for missing inputs
    all-mev "nfs_header" "Enter NFS header" "$nfs_header"
    all-mev "shared_folder" "Enter path to shared folder" "$shared_folder"
    all-mev "nfs_options" "Enter NFS options" "$nfs_options"

    # Apply the NFS configuration
    nfs-apply "$nfs_header" "$shared_folder" "$nfs_options"
    all-nos "$function_name" "NFS setup complete"
}

# Helper script for NFS setup.
# nfs apply config
# <nfs_header> <shared_folder> <nfs_options>
nfs-apply() {
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

