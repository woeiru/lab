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

# Displays an overview of specific functions in the script, showing their usage, shortname, and description
# overview functions
#
sto-fun() {
    all-laf "$FILEPATH_sto" "$@"
}
# Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
#
sto-var() {
    all-acu -o "$CONFIG_sto" "$DIR_LIB/.."
}

# Creates a new ZFS dataset or uses an existing one, sets its mountpoint, and ensures it's mounted at the specified path
# zfs directory mount
# <pool_name> <dataset_name> <mountpoint_path>
pve-zdm() {
    local function_name="${FUNCNAME[0]}"
    local pool_name="$1"
    local dataset_name="$2"
    local mountpoint_path="$3"
    local dataset_path="$pool_name/$dataset_name"
    local newly_created=false
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

    # Check if the dataset exists, create it if not
    if ! zfs list "$dataset_path" &>/dev/null; then
        echo "Creating ZFS dataset '$dataset_path'."
        zfs create "$dataset_path" || { echo "Failed to create ZFS dataset '$dataset_path'"; exit 1; }
        echo "ZFS dataset '$dataset_path' created."
        newly_created=true
    else
        echo "ZFS dataset '$dataset_path' already exists."
    fi

    # Check if the mountpoint directory exists, create it if not
    if [ ! -d "$mountpoint_path" ]; then
        mkdir -p "$mountpoint_path" || { echo "Failed to create mountpoint directory '$mountpoint_path'"; exit 1; }
        echo "Mountpoint directory '$mountpoint_path' created."
    fi

    # Get the current mountpoint and compare with the expected mountpoint
    current_mountpoint=$(zfs get -H -o value mountpoint "$dataset_path")
    expected_mountpoint="$mountpoint_path"

    if [ "$current_mountpoint" != "$expected_mountpoint" ]; then
        zfs set mountpoint="$expected_mountpoint" "$dataset_path" || { echo "Failed to set mountpoint for ZFS dataset '$dataset_path'"; exit 1; }
        echo "ZFS dataset '$dataset_path' mounted at '$expected_mountpoint'."
    elif [ "$newly_created" = true ]; then
        echo "ZFS dataset '$dataset_path' newly mounted at '$expected_mountpoint'."
    else
        echo "ZFS dataset '$dataset_path' is already mounted at '$expected_mountpoint'."
    fi

    all-nos "$function_name" "executed ( $pool_name / $dataset_name )"
}

# Creates and sends ZFS snapshots from a source pool to a destination pool. Supports initial full sends and incremental sends for efficiency
# zfs dataset backup
# <sourcepoolname> <destinationpoolname> <datasetname>
pve-zdb() {
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

# Creates a Btrfs RAID 1 filesystem on two specified devices, mounts it, and optionally adds an entry to /etc/fstab
# btrfs raid 1
# <device1> <device2> <mount_point>
pve-btr() {
    local function_name="${FUNCNAME[0]}"
    local device1="$1"
    local device2="$2"
    local mount_point="$3"
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

    # Create Btrfs RAID 1 filesystem
    mkfs.btrfs -m raid1 -d raid1 "$device1" "$device2"

    # Create mount point and mount the filesystem
    mkdir -p "$mount_point"
    mount "$device1" "$mount_point"

    # Verify the RAID 1 setup
    btrfs filesystem show "$mount_point"
    btrfs filesystem df "$mount_point"

    # Optionally add to fstab
    local uuid
    uuid=$(sudo blkid -s UUID -o value "$device1")
    local fstab_entry="UUID=$uuid $mount_point btrfs defaults,degraded 0 0"

    echo "The following line will be added to /etc/fstab:"
    echo "$fstab_entry"
    read -p "Do you want to add this line to /etc/fstab? [y/N]: " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$fstab_entry" | sudo tee -a /etc/fstab
        echo "Entry added to /etc/fstab."
    else
        echo "Entry not added to /etc/fstab."
    fi

    all-nos "$function_name" "executed ( $1 $2 $3 )"
}

