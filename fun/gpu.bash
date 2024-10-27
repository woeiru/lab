#!/bin/bash

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

# Shows a summary of selected functions in the script, displaying their usage, shortname, and description
# overview functions
#
gpu-fun() {
    # Pass all arguments directly to all-laf
    all-laf "$FILEPATH_gpu" "$@"
}
# Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
#
gpu-var() {
    all-acu -o "$CONFIG_gpu" "$DIR_LIB/.."
}

# Configures initial GRUB and EFI settings for GPU passthrough, installs necessary packages, and reboots the system
# gpu passthrough step 1
#
gpu-pt1() {
    local function_name="${FUNCNAME[0]}"
    echo "Executing section 1:"

    # Display EFI boot information
    efibootmgr -v

    # Edit GRUB configuration
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet iommu=pt"/' /etc/default/grub
    update-grub
    update-grug2

    # Install grub-efi-amd64
    apt install grub-efi-amd64 -y

    # Notify status
    all-nos "$function_name" "Completed section 1, system will reboot now."

    # Perform system reboot without prompting
    reboot
}

# Adds necessary kernel modules for GPU passthrough to /etc/modules, updates initramfs, and reboots the system
# gpu passthrough step 2
#
gpu-pt2() {
    local function_name="${FUNCNAME[0]}"
    echo "Executing section 2:"

    # Add modules to /etc/modules
    echo "vfio" >> /etc/modules
    echo "vfio_iommu_type1" >> /etc/modules
    echo "vfio_pci" >> /etc/modules

    # Update initramfs
    update-initramfs -u -k all

    # Notify status
    all-nos "$function_name" "Completed section 2, system will reboot now."

    # Perform system reboot without prompting
    reboot
}

# Finalizes or reverts GPU passthrough setup by configuring or removing VFIO-PCI IDs and blacklisting specific GPU drivers
# gpu passthrough step 3
# <enable|disable>
gpu-pt3() {
    local function_name="${FUNCNAME[0]}"
    local action="$1"

    if [ "$action" != "enable" ] && [ "$action" != "disable" ]; then
        echo "Usage: $function_name <enable|disable>"
        return 1
    fi

    echo "Executing section 3 ($action mode):"

    vfio_conf="/etc/modprobe.d/vfio.conf"
    blacklist_conf="/etc/modprobe.d/blacklist.conf"

    if [ "$action" == "enable" ]; then
        # Enable GPU passthrough

        # Check for vfio-related logs in kernel messages
        dmesg | grep -i vfio
        dmesg | grep 'remapping'

        # List NVIDIA and AMD devices
        lspci -nn | grep 'NVIDIA'
        lspci -nn | grep 'AMD'

        # Configure VFIO
        if [ ! -f "$vfio_conf" ]; then
            # Prompt for the IDs input in the format ****:****,****:****
            read -p "Please enter the IDs in the format ****:****,****:****: " ids_input

            # Split the IDs based on comma
            IFS=',' read -ra id_list <<< "$ids_input"

            # Construct the line with the IDs
            options_line="options vfio-pci ids="

            # Build the line for each ID
            for id in "${id_list[@]}"
            do
                options_line+="$(echo "$id" | tr '\n' ',')"
            done

            # Remove the trailing comma
            options_line="${options_line%,}"

            # Append the line into the file
            echo "$options_line" >> "$vfio_conf"
        fi

        # Blacklist GPU drivers
        echo "blacklist radeon" >> "$blacklist_conf"
        echo "blacklist amdgpu" >> "$blacklist_conf"

        all-nos "$function_name" "Completed section 3 (enable mode), system will reboot now."
    else
        # Disable GPU passthrough

        # Remove VFIO configuration
        if [ -f "$vfio_conf" ]; then
            rm "$vfio_conf"
            echo "Removed VFIO configuration file."
        else
            echo "VFIO configuration file not found. Skipping removal."
        fi

        # Remove GPU driver blacklisting
        if [ -f "$blacklist_conf" ]; then
            sed -i '/blacklist radeon/d' "$blacklist_conf"
            sed -i '/blacklist amdgpu/d' "$blacklist_conf"
            echo "Removed GPU driver blacklisting from $blacklist_conf."
        else
            echo "Blacklist configuration file not found. Skipping modification."
        fi

        all-nos "$function_name" "Completed section 3 (disable mode), system will reboot now."
    fi

    # Perform system reboot without prompting
    reboot
}

# Detaches the GPU from the host system, making it available for VM passthrough
# gpu passthrough detach
#
gpu-ptd() {
    local function_name="${FUNCNAME[0]}"

    echo "Current GPU driver and IOMMU group:"
    lspci -nnk | grep -A3 "VGA compatible controller"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done

    # Unload NVIDIA or AMD drivers if loaded
    for driver in nouveau nvidia amdgpu radeon; do
        if lsmod | grep -q $driver; then
            echo "Unloading $driver driver"
            if ! modprobe -r $driver; then
                all-nos "$function_name" "Warning: Failed to unload $driver driver. Continuing anyway."
            fi
        else
            echo "$driver driver not loaded."
        fi
    done

    # Load VFIO driver
    if ! modprobe vfio-pci; then
        all-nos "$function_name" "Error: Failed to load VFIO-PCI driver. GPU detachment may fail."
        return 1
    fi

    # Get GPU PCI IDs (including both NVIDIA and AMD)
    local gpu_ids=$(lspci -nn | grep -iE "VGA compatible controller|3D controller" | awk '{print $1}')

    if [ -z "$gpu_ids" ]; then
        all-nos "$function_name" "Error: No GPU found."
        return 1
    fi

    for id in $gpu_ids; do
        if [ -e "/sys/bus/pci/devices/0000:$id/driver" ]; then
            echo "0000:$id" > /sys/bus/pci/devices/0000:$id/driver/unbind
        fi
        echo "vfio-pci" > /sys/bus/pci/devices/0000:$id/driver_override
        if ! echo "0000:$id" > /sys/bus/pci/drivers/vfio-pci/bind; then
            all-nos "$function_name" "Warning: Failed to bind GPU $id to VFIO-PCI."
        fi
    done

    echo "GPU driver and IOMMU group after detachment:"
    lspci -nnk | grep -A3 "VGA compatible controller"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done

    all-nos "$function_name" "GPU detachment process completed. Check above output for details."
}

# Attaches the GPU back to the host system
# gpu passthrough attach
#
gpu-pta() {
    local function_name="${FUNCNAME[0]}"

    all-log "INFO" "Starting GPU reattachment process"

    all-log "INFO" "Current GPU driver and IOMMU group:"
    lspci -nnk | grep -A3 "VGA compatible controller" | while read -r line; do
        all-log "INFO" "$line"
    done

    # Get GPU PCI IDs
    local gpu_ids=$(lspci -nn | grep -i "VGA compatible controller" | awk '{print $1}')

    if [ -z "$gpu_ids" ]; then
        all-log "ERROR" "No GPU found."
        all-nos "$function_name" "Error: No GPU found."
        return 1
    fi

    all-log "INFO" "Found GPU(s) with PCI ID(s): $gpu_ids"

    for id in $gpu_ids; do
        all-log "INFO" "Processing GPU with PCI ID: $id"
        if [ -e "/sys/bus/pci/devices/0000:$id/driver" ]; then
            all-log "INFO" "Unbinding GPU $id from current driver"
            echo "0000:$id" > /sys/bus/pci/devices/0000:$id/driver/unbind
            if [ $? -eq 0 ]; then
                all-log "INFO" "Successfully unbound GPU $id"
            else
                all-log "WARNING" "Failed to unbind GPU $id"
            fi
        else
            all-log "INFO" "GPU $id is not bound to any driver"
        fi

        all-log "INFO" "Resetting driver_override for GPU $id"
        echo > /sys/bus/pci/devices/0000:$id/driver_override

        # Determine the correct driver based on the GPU vendor
        local vendor_id=$(lspci -n -s "$id" | awk '{print $3}' | cut -d':' -f1)
        local driver
        case "$vendor_id" in
            1002)
                driver="amdgpu"
                ;;
            10de)
                driver="nouveau"
                ;;
            *)
                all-log "ERROR" "Unknown GPU vendor: $vendor_id. Cannot proceed with reattachment."
                all-nos "$function_name" "Error: Unknown GPU vendor: $vendor_id. Cannot proceed with reattachment."
                return 1
                ;;
        esac

        all-log "INFO" "Attempting to load $driver driver"
        if ! modprobe "$driver"; then
            all-log "ERROR" "Failed to load $driver driver. You may need to install it."
            all-nos "$function_name" "Error: Failed to load $driver driver. You may need to install it."
            return 1
        else
            all-log "INFO" "$driver driver loaded successfully."
        fi

        all-log "INFO" "Probing for new driver for GPU $id"
        echo "0000:$id" > /sys/bus/pci/drivers_probe
        if [ $? -eq 0 ]; then
            all-log "INFO" "Successfully probed for new driver for GPU $id"
        else
            all-log "WARNING" "Failed to probe for new driver for GPU $id"
        fi

        # Explicitly bind the driver if it's not automatically bound
        if [ ! -e "/sys/bus/pci/devices/0000:$id/driver" ]; then
            all-log "INFO" "Attempting to explicitly bind $driver to GPU $id"
            echo "0000:$id" > /sys/bus/pci/drivers/$driver/bind
            if [ $? -eq 0 ]; then
                all-log "INFO" "Successfully bound $driver to GPU $id"
            else
                all-log "ERROR" "Failed to bind $driver to GPU $id"
                all-nos "$function_name" "Error: Failed to bind $driver to GPU $id"
                return 1
            fi
        fi
    done

    all-log "INFO" "GPU driver and IOMMU group after reattachment:"
    lspci -nnk | grep -A3 "VGA compatible controller" | while read -r line; do
        all-log "INFO" "$line"
    done

    all-log "INFO" "GPU reattachment process completed."
    all-nos "$function_name" "GPU reattachment process completed. Check logs for details."
}

# Checks the current status of the GPU
# gpu passthrough status
#
gpu-pts() {
    local function_name="${FUNCNAME[0]}"

    echo "GPU Status:"
    echo "==========="

    # Check IOMMU groups
    echo -e "\nIOMMU Groups:"
    for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d); do
        echo "IOMMU Group ${iommu_group##*/}:"
        for device in $(ls -1 "$iommu_group"/devices/); do
            echo -e "\t$(lspci -nns "$device")"
        done
    done

    # Check loaded GPU-related modules
    echo "Loaded GPU modules:"
    lsmod | grep -E "nvidia|vfio" || echo "No NVIDIA or VFIO modules loaded."

    # Check GPU PCI devices
    echo -e "\nGPU PCI devices:"
    lspci -nnk | grep -A3 "VGA compatible controller"

    all-nos "$function_name" "GPU status check completed."
}
