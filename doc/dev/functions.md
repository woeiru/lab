<!-- 
    This documentation focuses exclusively on generic pure functions from the lib/ folder.
    Pure functions are stateless, parameterized, and environment-independent.
    They provide predictable behavior and are fully testable with explicit inputs.
    
    The lib/ folder contains three categories of pure functions:
    - lib/core/  : Core system utilities (error handling, logging, timing)
    - lib/ops/   : Operations functions (infrastructure management)
    - lib/gen/   : General utilities (environment, security, infrastructure)
-->

# Pure Functions Reference

Generic pure functions available in the Lab Environment Management System.

## 📚 Library Structure

The `lib/` folder contains three categories of pure functions:

### Core Utilities (`lib/core/`)
- **err**: Error handling and stack traces
- **lo1**: Module-specific debug logging
- **tme**: Performance timing and monitoring
- **ver**: Module version verification

### Operations Functions (`lib/ops/`)
- **aux**: Auxiliary operations and utilities
- **gpu**: GPU passthrough management
- **net**: Network configuration and management
- **pbs**: Proxmox Backup Server operations
- **pve**: Proxmox VE cluster management
- **srv**: System service operations
- **sto**: Storage and filesystem management
- **sys**: System-level operations
- **usr**: User account management

### General Utilities (`lib/gen/`)
- **env**: Environment configuration utilities
- **inf**: Infrastructure deployment utilities
- **sec**: Security and credential management
- **ssh**: SSH key and connection management

## 🔍 Function Metadata Table

<!-- AUTO-GENERATED SECTION: DO NOT EDIT MANUALLY -->
<!-- Command: aux-ffl aux-laf "" "$LIB_CORE_DIR" & aux-ffl aux-laf "" "$LIB_OPS_DIR" & aux-ffl aux-laf "" "$LIB_GEN_DIR" -->

| Library | Module | Function | Description |
|---------|--------|----------|-------------|
| core | err | err_process_error |  |
| core | err | err_lo1_handle_error |  |
| core | err | clean_exit |  |
| core | err | has_errors |  |
| core | err | error_handler |  |
| core | err | enable_error_trap |  |
| core | err | disable_error_trap |  |
| core | err | dangerous_operation |  |
| core | err | safe_operation |  |
| core | err | print_error_report |  |
| core | err | setup_error_handling |  |
| core | err | register_cleanup |  |
| core | err | main_cleanup |  |
| core | err | main_error_handler |  |
| core | err | init_traps |  |
| core | lo1 | lo1_debug_log |  |
| core | lo1 | get_cached_log_state |  |
| core | lo1 | dump_stack_trace |  |
| core | lo1 | cleanup_cache |  |
| core | lo1 | ensure_state_directories |  |
| core | lo1 | init_state_files |  |
| core | lo1 | is_root_function |  |
| core | lo1 | get_base_depth |  |
| core | lo1 | calculate_final_depth |  |
| core | lo1 | get_indent |  |
| core | lo1 | get_color |  |
| core | lo1 | log |  |
| core | lo1 | setlog |  |
| core | lo1 | init_logger |  |
| core | lo1 | cleanup_logger |  |
| core | lo1 | lo1_log_message |  |
| core | lo1 | lo1_tme_log_with_timer |  |
| core | tme | tme_init_timer |  |
| core | tme | tme_start_timer |  |
| core | tme | tme_stop_timer |  |
| core | tme | tme_end_timer |  |
| core | tme | calculate_component_depth |  |
| core | tme | print_timing_entry |  |
| core | tme | sort_components_by_duration |  |
| core | tme | print_tree_recursive |  |
| core | tme | tme_settme |  |
| core | tme | tme_print_timing_report |  |
| core | tme | tme_start_nested_timing |  |
| core | tme | tme_end_nested_timing |  |
| core | tme | tme_cleanup_timer |  |
| core | tme | tme_set_output |  |
| core | tme | tme_show_output_settings |  |
| core | ver | ver_log | ----------------------------------------------------------------------------- |
| core | ver | verify_path | Path and Variable Verification |
| core | ver | verify_var |  |
| core | ver | essential_check | Module Verification |
| core | ver | verify_module |  |
| core | ver | validate_module |  |
| core | ver | verify_function_dependencies | Function and Dependency Verification |
| core | ver | verify_function |  |
| core | ver | init_verification |  |
JSON files preserved in: /home/es/lab/.tmp/doc
| ops | aux | aux-fun | Shows a summary of selected functions in the script, displaying their usage, shortname, and description |
| ops | aux | aux-var | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files |
| ops | aux | aux-log |  |
| ops | aux | aux-ffl | Recursively processes files in a directory and its subdirectories using a specified function, allowing for additional arguments to be passed |
| ops | aux | aux-laf | Lists all functions in a file, displaying their usage, shortname, and description. Supports truncation and line break options for better readability |
| ops | aux | aux-acu | Analyzes the usage of variables from a config file across target folders, displaying variable names, values, and occurrence counts in various files |
| ops | aux | aux-mev | Prompts the user to input or confirm a variable's value, allowing for easy customization of script parameters |
| ops | aux | aux-nos | Logs a function's execution status with a timestamp, providing a simple way to track script progress and debugging information |
| ops | aux | aux-flc | Displays the source code of a specified function from the library folder, including its description, shortname, and usage |
| ops | aux | aux-use | Displays the usage information, shortname, and description of the calling function, helping users understand how to use it |
| ops | gpu | _gpu_init_colors | ============================================================================ |
| ops | gpu | _gpu_validate_pci_id |  |
| ops | gpu | _gpu_extract_vendor_device_id |  |
| ops | gpu | _gpu_get_current_driver |  |
| ops | gpu | _gpu_is_gpu_device |  |
| ops | gpu | _gpu_load_config |  |
| ops | gpu | _gpu_get_config_pci_ids |  |
| ops | gpu | _gpu_find_all_gpus |  |
| ops | gpu | _gpu_get_target_gpus |  |
| ops | gpu | _gpu_ensure_vfio_modules |  |
| ops | gpu | _gpu_unbind_device |  |
| ops | gpu | _gpu_bind_device |  |
| ops | gpu | _gpu_get_host_driver |  |
| ops | gpu | _gpu_get_host_driver_parameterized |  |
| ops | gpu | _gpu_get_config_pci_ids_parameterized |  |
| ops | gpu | _gpu_get_target_gpus_parameterized |  |
| ops | gpu | _gpu_get_iommu_groups |  |
| ops | gpu | _gpu_get_detailed_device_info |  |
| ops | gpu | gpu-fun | ============================================================================ |
| ops | gpu | gpu-var |  |
| ops | gpu | gpu-nds |  |
| ops | gpu | gpu-pt1 |  |
| ops | gpu | gpu-pt2 |  |
| ops | gpu | gpu-pt3 |  |
| ops | gpu | gpu-ptd |  |
| ops | gpu | gpu-pta |  |
| ops | gpu | gpu-pts |  |
| ops | net | net-fun | Displays an overview of specific functions in the script, showing their usage, shortname, and description |
| ops | net | net-var |  |
| ops | net | net-uni | Guides the user through renaming a network interface by updating udev rules and network configuration, with an option to reboot the system |
| ops | net | net-fsr | Adds a specified service to the firewalld configuration and reloads the firewall. Checks for the presence of firewall-cmd before proceeding |
| ops | net | net-fas | Allows a specified service through the firewall using firewall-cmd, making the change permanent and reloading the firewall configuration |
| ops | pbs | pbs-fun | show an overview of specific functions |
| ops | pbs | pbs-var | show an overview of specific variables |
| ops | pbs | pbs-dav | Download Proxmox GPG key and verify checksums. |
| ops | pbs | pbs-adr | Add Proxmox repository to sources.list if not already present. |
| ops | pbs | pbs-rda | Restore datastore configuration file with given parameters. |
| ops | pbs | pbs-mon | Monitors and displays various aspects of the Proxmox Backup Server |
| ops | pve | pve-fun | Displays an overview of specific Proxmox Virtual Environment (PVE) related functions in the script, showing their usage, shortname, and description |
| ops | pve | pve-var | Displays an overview of PVE-specific variables defined in the configuration file, showing their names, values, and usage across different files |
| ops | pve | pve-dsr | Disables specified Proxmox repository files by commenting out 'deb' lines, typically used to manage repository sources  |
| ops | pve | pve-rsn | Removes the Proxmox subscription notice by modifying the web interface JavaScript file, with an option to restart the pveproxy service  |
| ops | pve | pve-clu | Updates the Proxmox VE Appliance Manager (pveam) container template list |
| ops | pve | pve-cdo | Downloads a specified container template to a given storage location, with error handling and options to list available templates |
| ops | pve | pve-cbm | Configures a bind mount for a specified Proxmox container, linking a host directory to a container directory |
| ops | pve | pve-ctc | Sets up different containers specified in cfg/env/site. |
| ops | pve | pve-cto | Manages multiple Proxmox containers by starting, stopping, enabling, or disabling them, supporting individual IDs, ranges, or all containers |
| ops | pve | pve-vmd | Deploys or modifies the VM shutdown hook for GPU reattachment |
| ops | pve | pve-vmc | Sets up different virtual machines specified in cfg/env/site. |
| ops | pve | pve-vms | Starts a VM on the current node or migrates it from another node, with an option to shut down the source node after migration |
| ops | pve | pve-vmg | Migrates a VM from a remote node to the current node, handling PCIe passthrough disable/enable during the process |
| ops | pve | pve-vpt | Toggles PCIe passthrough configuration for a specified VM, modifying its configuration file to enable or disable passthrough devices |
| ops | pve | pve-vck | Checks and reports which node in the Proxmox cluster is currently hosting a specified VM |
| ops | srv | srv-fun | Displays an overview of specific NFS-related functions in the script, showing their usage, shortname, and description |
| ops | srv | srv-var | Displays an overview of NFS-specific variables defined in the configuration file, showing their names, values, and usage across different files |
| ops | srv | nfs-set | Sets up an NFS share by prompting for necessary information (NFS header, shared folder, and options) and applying the configuration |
| ops | srv | nfs-apl | Applies NFS configuration by creating the shared folder if needed, updating /etc/exports, and restarting the NFS server |
| ops | srv | nfs-mon | Monitors and displays various aspects of the NFS server |
| ops | srv | smb-set | Sets up a Samba share by prompting for missing configuration details and applying the configuration. Handles various share parameters including permissions, guest access, and file masks |
| ops | srv | smb-apl | Applies Samba configuration by creating the shared folder if needed, updating cfg/env/site. with share details, restarting the Samba service, and setting up user passwords. Supports both user-specific and 'nobody' shares |
| ops | srv | smb-mon | Monitors and displays various aspects of the SMB server |
| ops | sto | sto-fun | Displays an overview of specific functions in the script, showing their usage, shortname, and description |
| ops | sto | sto-var | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files |
| ops | sto | sto-fea | Adds auto-mount entries for devices to /etc/fstab using blkid. Allows user to select a device UUID and automatically creates the appropriate fstab entry |
| ops | sto | sto-fec | Adds custom entries to /etc/fstab using device UUIDs. Allows user to specify mount point, filesystem, mount options, and other parameters |
| ops | sto | sto-nfs | Mounts an NFS share interactively or with provided arguments |
| ops | sto | sto-bfs-tra | Transforms a folder into a Btrfs subvolume, optionally setting attributes (e.g., disabling COW). Handles multiple folders, preserving content and ownership. |
| ops | sto | sto-bfs-ra1 | Creates a Btrfs RAID 1 filesystem on two specified devices, mounts it, and optionally adds an entry to /etc/fstab |
| ops | sto | sto-bfs-csf | Checks and lists subvolume status of folders in a specified path. Supports filtering by folder type (regular, hidden, or both) and subvolume status. |
| ops | sto | sto-bfs-shc | Creates a new Snapper snapshot for the specified configuration or automatically selects a 'home_*' configuration if multiple exist |
| ops | sto | sto-bfs-shd | Deletes a specified Snapper snapshot from a given configuration or automatically selects a 'home_*' configuration if multiple exist |
| ops | sto | sto-bfs-shl | Lists Snapper snapshots for the specified configuration or automatically selects a 'home_*' configuration if multiple exist |
| ops | sto | sto-bfs-sfr | Resyncs a Btrfs snapshot subvolume to a flat folder using rsync, excluding specific directories (.snapshots and .ssh) and preserving attributes |
| ops | sto | sto-bfs-hub | Creates a backup subvolume for a user's home directory on a backup drive, then sends and receives Btrfs snapshots incrementally, managing full and incremental backups |
| ops | sto | sto-bfs-snd | Recursively deletes a Btrfs parent subvolume and all its nested child subvolumes, with options for interactive mode and forced deletion |
| ops | sto | sto-zfs-cpo | Creates a ZFS pool on a specified drive in a Proxmox VE environment |
| ops | sto | sto-zfs-dim | Creates a new ZFS dataset or uses an existing one, sets its mountpoint, and ensures it's mounted at the specified path |
| ops | sto | sto-zfs-dbs | Creates and sends ZFS snapshots from a source pool to a destination pool. Supports initial full sends and incremental sends for efficiency |
| ops | sys | sys-fun | Shows a summary of specific functions in the script, displaying their usage, shortname, and description |
| ops | sys | sys-var | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files |
| ops | sys | sys-gio | Manages git operations, ensuring the local repository syncs with the remote. |
| ops | sys | sys-dpa | Detects the system's package manager |
| ops | sys | sys-upa | Updates and upgrades system packages using the detected package manager |
| ops | sys | sys-ipa | Installs specified packages using the system's package manager |
| ops | sys | sys-gst | Configures git globally with a specified username and email, essential for proper commit attribution |
| ops | sys | sys-sst | Installs, enables, and starts the sysstat service for system performance monitoring. Modifies the configuration to ensure it's enabled |
| ops | sys | sys-ust | Creates a new user with a specified username and password, prompting for input if not provided. Verifies successful user creation |
| ops | sys | sys-sdc | Enables and starts a specified systemd service. Checks if the service is active and prompts for continuation if it's not |
| ops | sys | sys-suk | Uploads an SSH key from a plugged-in device to a specified folder (default: /root/.ssh). Handles mounting, file copying, and unmounting of the device |
| ops | sys | sys-spi | Appends a private SSH key identifier to the SSH config file for a specified user. Creates the .ssh directory and config file if they don't exist |
| ops | sys | sys-sks | Generates an SSH key pair and handles the transfer process |
| ops | sys | sys-sak | Appends the content of a specified public SSH key file to the authorized_keys file. |
| ops | sys | sys-loi | Loops a specified SSH operation (bypass StrictHostKeyChecking or refresh known_hosts) through a range of IPs defined in the configuration |
| ops | sys | sys-sca | Resolves custom SSH aliases using the configuration file. Supports connecting to single or multiple servers, executing commands remotely |
| ops | sys | sys-gre | An interactive Bash function that guides users through Git history navigation, offering options for reset type and subsequent actions, with built-in safeguards and explanations. |
| ops | sys | sys-hos | Adds or updates a host entry in /etc/hosts. If IP or hostname is empty, logs an error and exits. |
| ops | usr | usr-fun | Shows a summary of selected functions in the script, displaying their usage, shortname, and description |
| ops | usr | usr-var | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files |
| ops | usr | usr-ckp | Changes the Konsole profile for the current user by updating the konsolerc file |
| ops | usr | usr-vsf | Prompts the user to select a file from the current directory by displaying a numbered list of files and returning the chosen filename |
| ops | usr | usr-cff | Counts files in directories based on specified visibility (regular, hidden, or both). Displays results sorted by directory name |
| ops | usr | usr-duc | Compares data usage between two paths up to a specified depth. Displays results in a tabular format with color-coded differences |
| ops | usr | usr-cif | Concatenates and displays the contents of all files within a specified folder, separating each file's content with a line of dashes |
| ops | usr | usr-rsf | Replaces strings in files within a specified folder and its subfolders. If in a git repository, it stages changes and shows the diff |
| ops | usr | usr-rsd | Performs an rsync operation from a source to a destination path. Displays files to be transferred and prompts for confirmation before proceeding |
| ops | usr | usr-swt | Schedules a system wake-up using rtcwake. Supports absolute or relative time input and different sleep states (mem/disk) |
| ops | usr | usr-adr | Adds a specific line to a target if not already present |
| ops | usr | usr-cap | Appends a line to a file if it does not already exist, preventing duplicate entries and providing feedback on the operation |
| ops | usr | usr-rif | Replaces all occurrences of a string in files within a given folder |
| ops | usr | usr-ans | Navigates to the Ansible project directory, runs the playbook, then returns to the original directory |
JSON files preserved in: /home/es/lab/.tmp/doc
| gen | env | update_ecc |  |
| gen | env | env_switch |  |
| gen | env | site_switch |  |
| gen | env | node_switch |  |
| gen | env | env_status |  |
| gen | env | env_list |  |
| gen | env | env_validate |  |
| gen | env | env_usage |  |
| gen | env | main |  |
| gen | inf | set_container_defaults |  |
| gen | inf | generate_ip_sequence |  |
| gen | inf | define_container |  |
| gen | inf | define_containers |  |
| gen | inf | set_vm_defaults |  |
| gen | inf | define_vm |  |
| gen | inf | define_vms |  |
| gen | inf | validate_config |  |
| gen | inf | show_config_summary |  |
| gen | sec | generate_secure_password | Generate a secure password with specified length |
| gen | sec | store_secure_password |  |
| gen | sec | generate_service_passwords |  |
| gen | sec | create_password_file |  |
| gen | sec | load_stored_passwords |  |
| gen | sec | get_password_directory |  |
| gen | sec | init_password_management |  |
| gen | sec | init_password_management_auto |  |
| gen | sec | get_password_file |  |
| gen | sec | get_secure_password |  |
| gen | ssh | set_ssh |  |
| gen | ssh | setup_ssh |  |
| gen | ssh | add_ssh_keys |  |
| gen | ssh | list_ssh_keys |  |
| gen | ssh | remove_ssh_keys |  |
JSON files preserved in: /home/es/lab/.tmp/doc

<!-- END AUTO-GENERATED SECTION -->

## 🎯 Pure Function Characteristics

### Design Principles
- **Stateless**: No global state dependencies
- **Parameterized**: All inputs via explicit parameters
- **Predictable**: Same inputs always produce same outputs
- **Testable**: Can be tested in isolation

### Usage Pattern
```bash
# Pure function call
function_name "param1" "param2" "param3"

# No environment variables required
# No side effects on global state
# Fully deterministic behavior
```

## 🔧 Integration

To use pure functions in your scripts:

```bash
# Source the required library modules
source "$LIB_CORE_DIR/err"
source "$LIB_OPS_DIR/pve"
source "$LIB_GEN_DIR/inf"

# Call functions with explicit parameters
pve-vmc "101" "node1,node2,node3"
handle_error "component" "message" "ERROR"
```

## 📖 Related Documentation

- **[System Architecture](architecture.md)** - Complete system design
- **[Logging System](logging.md)** - Debug and logging frameworks
- **[Verbosity Controls](verbosity.md)** - Output control mechanisms
