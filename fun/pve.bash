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

# Displays an overview of specific Proxmox Virtual Environment (PVE) related functions in the script, showing their usage, shortname, and description
# overview functions
#  
pve-fun() {
    all-laf "$FILEPATH_pve" "$@"
}
# Displays an overview of PVE-specific variables defined in the configuration file, showing their names, values, and usage across different files
# overview variables
# 
pve-var() {
    all-acu -o "$CONFIG_pve" "$DIR_LIB/.."
}

# Disables specified Proxmox repository files by commenting out 'deb' lines, typically used to manage repository sources 
# disable repository
#  
pve-dsr() {
    local function_name="${FUNCNAME[0]}"
    files=(
        "/etc/apt/sources.list.d/pve-enterprise.list"
        "/etc/apt/sources.list.d/ceph.list"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            sed -i '/^deb/ s/^/#/' "$file"
            all-nos "$function_name" "Changes applied to $file"
        else
            all-nos "$function_name" "File $file not found."
        fi
    done
}


# Removes the Proxmox subscription notice by modifying the web interface JavaScript file, with an option to restart the pveproxy service 
# remove sub notice
#   
pve-rsn() {
    local function_name="${FUNCNAME[0]}"
    sed -Ezi.bak "s/(Ext\.Msg\.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

    # Prompt user whether to restart the service
    read -p "Do you want to restart the pveproxy.service now? (y/n): " choice
    case "$choice" in
        y|Y ) systemctl restart pveproxy.service && all-nos "$function_name" "Service restarted successfully.";;
        n|N ) all-nos "$function_name" "Service not restarted.";;
        * ) all-nos "$function_name" "Invalid choice. Service not restarted.";;
    esac
}

# Updates the Proxmox VE Appliance Manager (pveam) container template list
# container list update
#  
pve-clu() {
    local function_name="${FUNCNAME[0]}"

    	pveam update

    all-nos "$function_name" "executed"
}

# Downloads a specified container template to a given storage location, with error handling and options to list available templates
# container downloads
#   
pve-cdo() {
    local function_name="${FUNCNAME[0]}"
    local ct_dl_sto="$1"
    local ct_dl="$2"

    # Attempt to download the template
    if ! pveam download "$ct_dl_sto" "$ct_dl" 2>/dev/null; then
        echo "Error: Unable to download template '$ct_dl'."
        
        # Ask user if they want to see available templates
        read -p "Would you like to see a list of available templates? (y/n): " answer
        
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo "Available templates:"
            pveam available
            
            # Ask user if they want to try downloading a different template
            read -p "Would you like to try downloading a different template? (y/n): " retry_answer
            
            if [[ "$retry_answer" =~ ^[Yy]$ ]]; then
                read -p "Enter the name of the template you'd like to download: " new_ct_dl
                pve-cdo "$ct_dl_sto" "$new_ct_dl"
                return
            fi
        fi
        
        echo "$function_name: Failed to download template ( $ct_dl )"
    else
        echo "$function_name: Successfully downloaded template ( $ct_dl )"
    fi
}


# Configures a bind mount for a specified Proxmox container, linking a host directory to a container directory
# container bindmount
# <vmid> <mphost> <mpcontainer>
pve-cbm() {
    local function_name="${FUNCNAME[0]}"
    local vmid="$1"
    local mphost="$2"
    local mpcontainer="$3"
    if [ $# -ne 3 ]; then
	all-use
        return 1
    fi

    # Debugging output to check the parameters
    echo "Function: $function_name"
    echo "VMID: $vmid"
    echo "MPHOST: $mphost"
    echo "MPCONTAINER: $mpcontainer"

    # Ensure all arguments are provided
    if [[ -z "$vmid" || -z "$mphost" || -z "$mpcontainer" ]]; then
        echo "Error: Missing arguments."
        return 1
    fi

    # Properly quote the entire argument for -mp0
    pct set "$vmid" -mp0 "$mphost,mp=$mpcontainer"

    all-nos "$function_name" "executed ( $vmid / $mphost / $mpcontainer )"
}

# Setting up different containers specified in pve.conf
# container create
# <passed global variables>
pve-ctc() {
    local id="$1"
    local template="$2"
    local hostname="$3"
    local storage="$4"
    local rootfs_size="$5"
    local memory="$6"
    local swap="$7"
    local nameserver="$8"
    local searchdomain="$9"
    local password="${10}"
    local cpus="${11}"
    local privileged="${12}"
    local ip_address="${13}"
    local cidr="${14}"
    local gateway="${15}"
    local ssh_key_file="${16}"
    local net_bridge="${17}"
    local net_nic="${18}"

    if [ ! -f "$ssh_key_file" ]; then
        echo "SSH key file $ssh_key_file does not exist. Aborting."
        return 1
    fi

    # Correcting the parameters passed to pct create
    pct create "$id" "$template" \
        --hostname "$hostname" \
        --storage "$storage" \
        --rootfs "$storage:$rootfs_size" \
        --memory "$memory" \
        --swap "$swap" \
        --net0 "name=$net_nic,bridge=$net_bridge,ip=$ip_address/$cidr,gw=$gateway" \
        --nameserver "$nameserver" \
        --searchdomain "$searchdomain" \
        --password "$password" \
        --cores "$cpus" \
        --features "keyctl=1,nesting=1" \
        $(if [ "$privileged" == "no" ]; then echo "--unprivileged"; fi) \
        --ssh-public-keys "$ssh_key_file"
}

# Manages multiple Proxmox containers by starting, stopping, enabling, or disabling them, supporting individual IDs, ranges, or all containers
# container toggle
# <start|stop|enable|disable> <containers|all>
pve-cto() {
    local action=$1
    shift
    
    if [[ $action != "start" && $action != "stop" && $action != "enable" && $action != "disable" ]]; then
        echo "Invalid action: $action"
        echo "Usage: pve-cto <start|stop|enable|disable> <containers|all>"
        return 1
    fi
    
    handle_action() {
        local vmid=$1
        local config_file="/etc/pve/lxc/${vmid}.conf"
        
        if [[ ! -f "$config_file" ]]; then
            echo "ERROR: Config file for container $vmid does not exist"
            return 1
        fi
        
        case $action in
            start)
                echo "Starting container $vmid"
                pct start "$vmid"
                ;;
            stop)
                echo "Stopping container $vmid"
                pct stop "$vmid"
                ;;
            enable|disable)
                local onboot_value=$([[ $action == "enable" ]] && echo 1 || echo 0)
                echo "Setting onboot to $onboot_value for container $vmid"
                
                sed -i '/^onboot:/d' "$config_file"
                echo "onboot: $onboot_value" >> "$config_file"
                
                echo "Container $vmid configuration updated:"
                grep '^onboot:' "$config_file" || echo "ERROR: onboot entry not found after modification"
                ;;
        esac
    }
    
    if [[ $1 == "all" ]]; then
        echo "Processing all containers"
        container_ids=$(pct list | awk 'NR>1 {print $1}')
        for vmid in $container_ids; do
            handle_action "$vmid"
        done
    else
        for arg in "$@"; do
            if [[ $arg == *-* ]]; then
                IFS='-' read -r start end <<< "$arg"
                for (( vmid=start; vmid<=end; vmid++ )); do
                    handle_action "$vmid"
                done
            else
                handle_action "$arg"
            fi
        done
    fi
    
    if [[ $action == "start" || $action == "stop" ]]; then
        echo "Current container status:"
        pct list
    fi
}


# Deploys or modifies the VM shutdown hook for GPU reattachment
# Usage: pve-vmd <operation> <vm_id> [<vm_id2> ...]
# Operations: add, remove, debug
pve-vmd() {
    local function_name="${FUNCNAME[0]}"
    local hook_script="/var/lib/vz/snippets/gpu-reattach-hook.pl"
    local operation="$1"
    local vm_id="$2"

    echo "Debug: Operation: $operation, VM ID: $vm_id"

    # Validate operation
    if [[ ! "$operation" =~ ^(add|remove|debug)$ ]]; then
        echo "Error: Invalid operation. Use 'add', 'remove', or 'debug'."
        return 1
    fi

    # Check if /var/lib/vz/snippets exists, create if not
    if [ ! -d "/var/lib/vz/snippets" ]; then
        echo "Creating /var/lib/vz/snippets directory..."
        if ! mkdir -p "/var/lib/vz/snippets"; then
            echo "Error: Failed to create /var/lib/vz/snippets directory. Aborting."
            return 1
        fi
    fi

    # Function to create or update hook script
    create_or_update_hook_script() {
        if ! cat > "$hook_script" << EOL
#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);

my \$vmid = shift;
my \$phase = shift;

my \$log_file = '/var/log/gpu-reattach-hook.log';

open(my \$log, '>>', \$log_file) or die "Could not open log file: \$!";
print \$log strftime("%Y-%m-%d %H:%M:%S", localtime) . " - VM \$vmid, Phase: \$phase\n";

if (\$phase eq 'post-stop') {
    print \$log "Attempting to reattach GPU for VM \$vmid\n";
    my \$result = system("bash -c 'source /root/lab/lib/pve.bash && gpu-pta'");
    print \$log "gpu-pta execution result: \$result\n";
}

close(\$log);
EOL
        then
            echo "Error: Failed to create or update hook script. Aborting."
            return 1
        fi

        if ! chmod 755 "$hook_script"; then
            echo "Error: Failed to set permissions on hook script. Aborting."
            return 1
        fi
        echo "Hook script created/updated and made executable."
    }

    # Create or update hook script
    if ! create_or_update_hook_script; then
        return 1
    fi

    if [ "$operation" = "debug" ]; then
        echo "Debugging hook setup:"
        echo "1. Checking hook script existence and permissions:"
        ls -l "$hook_script"
        echo "2. Checking hook script content:"
        cat "$hook_script"
        echo "3. Checking Proxmox VM configurations for hook references:"
        grep -r "hookscript" /etc/pve/qemu-server/
        echo "4. Manually triggering hook script:"
        perl "$hook_script" "$vm_id" "post-stop"
        echo "5. Checking log file:"
        cat /var/log/gpu-reattach-hook.log
        return 0
    fi

    # Perform operation
    case "$operation" in
        add)
            if qm set "$vm_id" -hookscript "local:snippets/$(basename "$hook_script")"; then
                echo "Hook applied to VM $vm_id"
            else
                echo "Failed to apply hook to VM $vm_id"
                return 1
            fi
            ;;
        remove)
            if qm set "$vm_id" -delete hookscript; then
                echo "Hook removed from VM $vm_id"
            else
                echo "Failed to remove hook from VM $vm_id"
                return 1
            fi
            ;;
    esac

    all-nos "$function_name" "Hook $operation completed for VM $vm_id"
}

# Setting up different virtual machines specified in pve.conf
# virtual machine create
# <passed global variables>
pve-vmc() {
    local id="$1"
    local name="$2"
    local ostype="$3"
    local machine="$4"
    local iso="$5"
    local boot="$6"
    local bios="$7"
    local efidisk="$8"
    local scsihw="$9"
    local agent="${10}"
    local disk="${11}"
    local sockets="${12}"
    local cores="${13}"
    local cpu="${14}"
    local memory="${15}"
    local balloon="${16}"
    local net="${17}"

    qm create "$id" \
        --name "$name" \
        --ostype "$ostype" \
        --machine "$machine" \
        --ide2 "$iso,media=cdrom" \
        --boot "$boot" \
        --bios "$bios" \
        --efidisk0 "$efidisk" \
        --scsihw "$scsihw" \
        --agent "$agent" \
        --scsi0 "$disk" \
        --sockets "$sockets" \
        --cores "$cores" \
        --cpu "$cpu" \
        --memory "$memory" \
        --balloon "$balloon" \
        --net0 "$net"
}

# Starts a VM on the current node or migrates it from another node, with an option to shut down the source node after migration
# vm start get shutdown
# <vm_id> [s: optional, shutdown other node]
pve-vms() {
    # Retrieve and store hostname
    local hostname=$(hostname)

    # Check if vm_id argument is provided
    if [ -z "$1" ]; then
        all-use
        return 1
    fi

    # Assign vm_id to a variable
    local vm_id=$1

    # Call pve-vck function to get node_id
    local node_id=$(pve-vck "$vm_id")

    # Check if node_id is empty
    if [ -z "$node_id" ]; then
        echo "Node ID is empty. Cannot proceed."
        return 1
    fi

    # Main logic
    if [ "$hostname" = "$node_id" ]; then
        qm start "$vm_id"
        if [ "$2" = "s" ]; then
            # Shutdown the other node
            echo "Shutting down node $node_id"
            ssh "root@$node_id" "shutdown now"
        fi 
    else
        pve-vmg "$vm_id"
        qm start "$vm_id"
        if [ "$2" = "s" ]; then
            # Shutdown the other node
            echo "Shutting down node $node_id"
            ssh "root@$node_id" "shutdown now"
        fi
    fi
}

# Migrates a VM from a remote node to the current node, handling PCIe passthrough disable/enable during the process
# vm get start
# <vm_id>
pve-vmg() {
    local vm_id="$1"
    if [ $# -ne 1 ]; then
        all-use
        return 1
    fi

    # Call pve-vck to check if VM exists and get the node
    local node=$(pve-vck "$vm_id")
    if [ -n "$node" ]; then
        echo "VM found on node: $node"

        # Disable PCIe passthrough for the VM on the remote node
        if ! ssh "$node" "pve-vpt $vm_id off"; then
            echo "Failed to disable PCIe passthrough for VM on $node." >&2
            return 1
        fi

        # Migrate the VM to the current node
        if ! ssh "$node" "qm migrate $vm_id $(hostname)"; then
            echo "Failed to migrate VM from $node to $(hostname)." >&2
            return 1
        fi

        # Enable PCIe passthrough for the VM on the current node
        if ! pve-vpt "$vm_id" on; then
            echo "Failed to enable PCIe passthrough for VM on $(hostname)." >&2
            return 1
        fi

        echo "VM migrated and PCIe passthrough enabled."
        return 0  # Return success once VM is found and migrated
    fi

    echo "VM not found on any other node."
    return 1  # Return failure if VM is not found
}

# Toggles PCIe passthrough configuration for a specified VM, modifying its configuration file to enable or disable passthrough devices
# vm passthrough toggle
# <vm_id> <on|off>
pve-vpt() {
    local vm_id="$1"
    local action="$2"
    local vm_conf="$CONF_PATH_QEMU/$vm_id.conf"
    if [ $# -ne 2 ]; then
        all-use
        return 1
    fi

    # Get hostname for variable names
    local hostname=$(hostname)
    local node_pci0="${hostname}_node_pci0"
    local node_pci1="${hostname}_node_pci1"
    local core_count_on="${hostname}_core_count_on"
    local core_count_off="${hostname}_core_count_off"
    local usb_devices_var="${hostname}_usb_devices[@]"

    # Find the starting line of the VM configuration section
    local section_start=$(awk '/^\[/{print NR-1; exit}' "$vm_conf")

    # Action based on the parameter
    case "$action" in
        on)
            # Set core count based on configuration when toggled on
            sed -i "s/cores:.*/cores: ${!core_count_on}/" "$vm_conf"

            # Add passthrough lines
            if [ -z "$section_start" ]; then
                # If no section found, append passthrough lines at the end of the file
                for usb_device in "${!usb_devices_var}"; do
                    echo "$usb_device" >> "$vm_conf"
                done
                echo "hostpci0: ${!node_pci0},pcie=1,x-vga=1" >> "$vm_conf"
                echo "hostpci1: ${!node_pci1},pcie=1" >> "$vm_conf"
            else
                # If a section is found, insert passthrough lines at the appropriate position
                for usb_device in "${!usb_devices_var}"; do
                    sed -i "${section_start}a\\${usb_device}" "$vm_conf"
                    ((section_start++))
                done
                sed -i "${section_start}a\\hostpci0: ${!node_pci0},pcie=1,x-vga=1" "$vm_conf"
                ((section_start++))
                sed -i "${section_start}a\\hostpci1: ${!node_pci1},pcie=1" "$vm_conf"
            fi

            echo "Passthrough lines added to $vm_conf."
            ;;
        off)
            # Set default core count when toggled off
            sed -i "s/cores:.*/cores: ${!core_count_off}/" "$vm_conf"

            # Remove passthrough lines
            sed -i '/^usb[0-9]*:/d; /^hostpci[0-9]*:/d' "$vm_conf"

            echo "Passthrough lines removed from $vm_conf."
            ;;
        *)
            echo "Invalid parameter. Usage: pve-vpt <VM_ID> <on|off>"
            exit 1
            ;;
    esac
}

# Checks and reports which node in the Proxmox cluster is currently hosting a specified VM
# vm check node
# <vm_id>
pve-vck() {
    local vm_id="$1"
    local found_node=""
    if [ $# -ne 1 ]; then
        all-use
        return 1
    fi

    # Check if cluster_nodes array is populated
    if [ ${#cluster_nodes[@]} -eq 0 ]; then
        echo "Error: cluster_nodes array is empty"
        return 1
    fi

    for node in "${cluster_nodes[@]}"; do
        # Skip SSH for the local node
        if [ "$node" != "$(hostname)" ]; then
            ssh_output=$(ssh "$node" "qm list" 2>&1)
            ssh_exit_status=$?
            if [ $ssh_exit_status -eq 0 ] && echo "$ssh_output" | grep -q "\<$vm_id\>"; then
                found_node="$node"
                break
            fi
        else
            local_output=$(qm list 2>&1)
            local_exit_status=$?
            if [ $local_exit_status -eq 0 ] && echo "$local_output" | grep -q "\<$vm_id\>"; then
                found_node="$node"
                break
            fi
        fi
    done

    if [ -n "$found_node" ]; then
        echo "$found_node"
        return 0
    else
        return 1
    fi
}
