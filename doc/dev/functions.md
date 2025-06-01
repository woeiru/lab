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
<!-- CORE FUNCTIONS -->
| core | /home/es/lab/lib/core/[32merr[0m - Contains [31m377[0m Lines and [33m15[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | err_process_error | Process error messages and log them appropriately |  |  | 33 | 53 | 2 |  |  | |  |  |
| core | | err_lo1_handle_error | Function to handle errors more comprehensively |  |  | 16 | 88 | 1 |  |  | |  |  |
| core | | clean_exit | Function to ensure clean exit from the script |  |  | 6 | 106 | 2 |  | 12 | |  |  |
| core | | has_errors | Function to check if a component has any errors |  |  | 13 | 114 | 1 |  |  | |  |  |
| core | | error_handler | Enhanced error handler function that only catches real errors |  |  | 31 | 129 | 3 |  |  | |  |  |
| core | | enable_error_trap | Function to enable error trapping |  |  | 4 | 162 | 2 |  |  | |  |  |
| core | | disable_error_trap | Function to disable error trapping |  |  | 4 | 168 | 2 |  |  | |  |  |
| core | | dangerous_operation | Wrap dangerous operations with error trapping | Example usage in your scripts |  |  | 6 | 175 |  |  |  | |  |
| core | | safe_operation | For package management and other safe operations, don't use error trapping |  |  | 6 | 183 |  |  |  | |  |  |
| core | | print_error_report | Enhanced error reporting function with better organization |  |  | 93 | 191 | 1 |  |  | |  |  |
| core | | setup_error_handling | Setup function to initialize error handling |  |  | 12 | 286 | 2 |  |  | |  |  |
| core | | register_cleanup | Central trap registration system |  |  | 11 | 300 | 1 |  |  | |  |  |
| core | | main_cleanup | Main cleanup orchestrator |  |  | 20 | 313 | 2 |  |  | |  |  |
| core | | main_error_handler | Central error handler |  |  | 9 | 335 | 1 |  |  | |  |  |
| core | | init_traps | Initialize trap system |  |  | 13 | 346 | 1 |  |  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | /home/es/lab/lib/core/[32mlo1[0m - Contains [31m412[0m Lines and [33m17[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | lo1_debug_log | Enhanced debug logging - moved to top |  |  | 8 | 46 | 20 |  |  | |  |  |
| core | | get_cached_log_state | Log state caching helper functions |  |  | 8 | 87 | 1 |  |  | |  |  |
| core | | dump_stack_trace | Update dump_stack_trace to use lo1_debug_log |  |  | 10 | 97 | 3 |  |  | |  |  |
| core | | cleanup_cache | Performance optimization |  |  | 9 | 109 | 1 |  |  | |  |  |
| core | | ensure_state_directories | Maintenance functions |  |  | 15 | 120 | 2 |  |  | |  |  |
| core | | init_state_files |  |  |  | 4 | 136 | 1 |  |  | |  |  |
| core | | is_root_function | Core functions |  |  | 7 | 142 | 2 |  |  | |  |  |
| core | | get_base_depth | Update get_base_depth to use lo1_debug_log |  |  | 44 | 151 | 3 |  |  | |  |  |
| core | | calculate_final_depth |  |  |  | 3 | 196 | 1 |  |  | |  |  |
| core | | get_indent |  |  |  | 17 | 200 | 1 |  |  | |  |  |
| core | | get_color |  |  |  | 8 | 218 | 1 |  |  | |  |  |
| core | | log | Main logging function |  |  | 36 | 228 | 9 | 29 |  | |  |  |
| core | | setlog | Logger control |  |  | 24 | 266 | 7 |  |  | |  |  |
| core | | init_logger | Update init_logger to use lo1_debug_log | Initialization and cleanup |  | 44 | 293 | 3 |  |  | |  |  |
| core | | cleanup_logger | Update cleanup_logger to use lo1_debug_log |  |  | 8 | 339 | 3 |  |  | |  |  |
| core | | lo1_log_message | Standard logging function for modules to use |  |  | 31 | 354 | 3 |  |  | |  |  |
| core | | lo1_tme_log_with_timer | Logging function with timing information |  |  | 15 | 387 | 1 |  |  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | /home/es/lab/lib/core/[32mtme[0m - Contains [31m586[0m Lines and [33m15[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | tme_init_timer | Initialize timer system with optional log file |  |  | 83 | 61 | 2 |  |  | |  |  |
| core | | tme_start_timer | Start timing a component with optional parent component |  |  | 32 | 146 | 2 |  |  | |  |  |
| core | | tme_stop_timer | Stop timing for a component (alias for end_timer for compatibility) |  |  | 5 | 180 | 1 |  |  | |  |  |
| core | | tme_end_timer | End timing for a component |  |  | 30 | 187 | 4 |  |  | |  |  |
| core | | calculate_component_depth | Calculate the depth of a component in the timing tree |  |  | 12 | 219 | 1 |  |  | |  |  |
| core | | print_timing_entry | Print formatted timing entry |  |  | 48 | 233 | 2 |  |  | |  |  |
| core | | sort_components_by_duration | Helper function to sort an array of component names by their TME_DURATIONS |  |  | 22 | 283 | 3 |  |  | |  |  |
| core | | print_tree_recursive | Recursive function to print the component tree |  |  | 47 | 307 | 3 |  |  | |  |  |
| core | | tme_settme | The settme function to control timer output |  |  | 65 | 356 | 5 |  |  | |  |  |
| core | | tme_print_timing_report | Enhanced timing report |  |  | 41 | 423 | 1 |  |  | |  |  |
| core | | tme_start_nested_timing | Example of how to use nested timing |  |  | 4 | 466 | 1 |  |  | |  |  |
| core | | tme_end_nested_timing |  |  |  | 4 | 471 | 1 |  |  | |  |  |
| core | | tme_cleanup_timer |  |  |  | 19 | 476 | 1 |  |  | |  |  |
| core | | tme_set_output | Control nested TME terminal output switches |  |  | 44 | 497 | 2 |  |  | |  |  |
| core | | tme_show_output_settings | Display current TME terminal output settings |  |  | 11 | 543 | 1 |  |  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | /home/es/lab/lib/core/[32mver[0m - Contains [31m399[0m Lines and [33m9[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | ver_log | Debug logging helper - uses existing LOG_DEBUG_FILE from ruc |  | ----------------------------------------------------------------------------- | 20 | 34 | 26 |  |  | |  |  |
| core | | verify_path |  | ########################################## | Path and Variable Verification | 64 | 59 | 4 |  |  | |  |  |
| core | | verify_var |  |  |  | 25 | 124 | 4 |  |  | |  |  |
| core | | essential_check |  | ########################################## | Module Verification | 26 | 154 | 1 |  |  | |  |  |
| core | | verify_module |  |  |  | 97 | 181 | 3 |  |  | |  |  |
| core | | validate_module |  |  |  | 29 | 279 | 1 |  |  | |  |  |
| core | | verify_function_dependencies |  | ########################################## | Function and Dependency Verification | 23 | 313 | 1 |  |  | |  |  |
| core | | verify_function |  |  |  | 34 | 337 | 2 |  |  | |  |  |
| core | | init_verification | Initialize verification system |  |  | 16 | 373 | 1 |  |  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
<!-- OPS FUNCTIONS -->
| ops | /home/es/lab/lib/ops/[32maux[0m - Contains [31m731[0m Lines and [33m10[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | aux-fun |  | overview functions | Shows a summary of selected functions in the script, displaying their usage, shortname, and description | 4 | 35 | 1 |  |  | |  |  |
| ops | | aux-var |  | overview variables | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files | 3 | 43 | 1 |  |  | |  |  |
| ops | | aux-log | Logging function |  |  | 5 | 48 | 1 |  |  | |  |  |
| ops | | aux-ffl | <function> <flag> <path> [max_depth] [current_depth] [extra_args ..] | function folder loop | Recursively processes files in a directory and its subdirectories using a specified function, allowing for additional arguments to be passed | 80 | 57 | 2 |  |  | |  |  |
| ops | | aux-laf | <file name> [-t] [-b] | list all functions | Lists all functions in a file, displaying their usage, shortname, and description. Supports truncation and line break options for better readability | 229 | 141 | 3 | 10 |  | |  |  |
| ops | | aux-acu | <sort mode |  -o|-a|""|> <config file or directory> <target folder1> [target folder2 ...] | analyze config usage | Analyzes the usage of variables from a config file across target folders, displaying variable names, values, and occurrence counts in various files | 250 | 374 | 3 | 8 |  | |  |
| ops | | aux-mev | <var_name> <prompt_message> <current_value> | main eval variable | Prompts the user to input or confirm a variable's value, allowing for easy customization of script parameters | 17 | 628 | 1 | 17 |  | |  |  |
| ops | | aux-nos | <function_name> <status> | main display notification | Logs a function's execution status with a timestamp, providing a simple way to track script progress and debugging information | 7 | 649 | 1 | 44 |  | |  |  |
| ops | | aux-flc | <function_name> | function library cat | Displays the source code of a specified function from the library folder, including its description, shortname, and usage | 38 | 660 | 1 |  |  | |  |  |
| ops | | aux-use |  | function usage information | Displays the usage information, shortname, and description of the calling function, helping users understand how to use it | 30 | 702 | 5 | 38 |  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32mgpu[0m - Contains [31m1170[0m Lines and [33m27[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | _gpu_init_colors | Initialize color constants |  | ============================================================================ | 12 | 27 | 5 |  |  | |  |  |
| ops | | _gpu_validate_pci_id | Validate PCI ID format |  |  | 4 | 41 | 6 |  |  | |  |  |
| ops | | _gpu_extract_vendor_device_id | Extract vendor and device IDs from lspci output |  |  | 18 | 47 |  |  |  | |  |  |
| ops | | _gpu_get_current_driver | Get current driver for a PCI device |  |  | 11 | 67 |  |  |  | |  |  |
| ops | | _gpu_is_gpu_device | Check if device is GPU-related (VGA/3D/Audio) |  |  | 4 | 80 | 2 |  |  | |  |  |
| ops | | _gpu_load_config | Load configuration file if available |  |  | 11 | 86 |  |  |  | |  |  |
| ops | | _gpu_get_config_pci_ids | Get PCI IDs from hostname-based configuration |  |  | 25 | 99 |  |  |  | |  |  |
| ops | | _gpu_find_all_gpus | Find all GPU devices via lspci scan |  |  | 25 | 126 |  |  |  | |  |  |
| ops | | _gpu_get_target_gpus | Get target GPUs for processing (handles all the logic for determining which GPUs to process) |  |  | 62 | 153 |  |  |  | |  |  |
| ops | | _gpu_ensure_vfio_modules | Ensure VFIO modules are loaded |  |  | 21 | 217 |  |  |  | |  |  |
| ops | | _gpu_unbind_device | Unbind device from current driver |  |  | 22 | 240 | 2 |  |  | |  |  |
| ops | | _gpu_bind_device | Bind device to specific driver |  |  | 33 | 264 | 2 |  |  | |  |  |
| ops | | _gpu_get_host_driver | Determine appropriate host driver for GPU |  |  | 34 | 299 |  |  |  | |  |  |
| ops | | _gpu_get_host_driver_parameterized | Determine appropriate host driver for GPU (parameterized version) |  |  | 28 | 335 |  |  |  | |  |  |
| ops | | _gpu_get_config_pci_ids_parameterized | Get PCI IDs from explicit parameters (parameterized version) |  |  | 21 | 365 |  |  |  | |  |  |
| ops | | _gpu_get_target_gpus_parameterized | Get target GPUs for processing (parameterized version) |  |  | 64 | 388 |  |  |  | |  |  |
| ops | | _gpu_get_iommu_groups | Helper function to get IOMMU groups for GPU devices |  |  | 54 | 454 | 1 |  |  | |  |  |
| ops | | _gpu_get_detailed_device_info | Helper function to get detailed GPU device information |  |  | 92 | 510 |  |  |  | |  |  |
| ops | | gpu-fun | Shows a summary of selected functions in the script |  | ============================================================================ | 5 | 608 |  |  |  | |  |  |
| ops | | gpu-var | Displays an overview of specific variables |  |  | 5 | 615 |  |  |  | |  |  |
| ops | | gpu-nds | Downloads and installs NVIDIA drivers, blacklisting Nouveau |  |  | 35 | 622 |  |  |  | |  |  |
| ops | | gpu-pt1 | Configures initial GRUB and EFI settings for GPU passthrough |  |  | 17 | 659 |  |  |  | |  |  |
| ops | | gpu-pt2 | Adds necessary kernel modules for GPU passthrough |  |  | 17 | 678 |  |  |  | |  |  |
| ops | | gpu-pt3 | Finalizes or reverts GPU passthrough setup |  |  | 119 | 697 |  |  |  | |  |  |
| ops | | gpu-ptd | Detaches the GPU from the host system for VM passthrough |  |  | 89 | 818 |  |  |  | |  |  |
| ops | | gpu-pta | Attaches the GPU back to the host system |  |  | 70 | 909 |  |  |  | |  |  |
| ops | | gpu-pts | Checks the current status of the GPU (complete detailed version) |  |  | 190 | 981 |  |  |  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32mnet[0m - Contains [31m117[0m Lines and [33m5[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | net-fun |  | overview functions | Displays an overview of specific functions in the script, showing their usage, shortname, and description | 3 | 30 | 1 |  |  | |  |  |
| ops | | net-var |  | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files |  | 3 | 35 | 1 |  |  | |  |  |
| ops | | net-uni | [interactive] | udev network interface | Guides the user through renaming a network interface by updating udev rules and network configuration, with an option to reboot the system | 37 | 42 | 1 |  |  | |  |  |
| ops | | net-fsr | <service> | firewall (add) service (and) reload | Adds a specified service to the firewalld configuration and reloads the firewall. Checks for the presence of firewall-cmd before proceeding | 16 | 83 | 1 |  |  | |  |  |
| ops | | net-fas | <service> | firewall allow service | Allows a specified service through the firewall using firewall-cmd, making the change permanent and reloading the firewall configuration | 15 | 103 | 1 |  |  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32mpbs[0m - Contains [31m209[0m Lines and [33m6[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | pbs-fun |  | overview functions | show an overview of specific functions | 3 | 31 | 1 |  |  | |  |  |
| ops | | pbs-var |  | overview variables | show an overview of specific variables | 3 | 37 | 1 |  |  | |  |  |
| ops | | pbs-dav |  | download and verify | Download Proxmox GPG key and verify checksums. | 24 | 44 | 1 |  | 1 | |  |  |
| ops | | pbs-adr |  | setup sources.list | Add Proxmox repository to sources.list if not already present. | 12 | 72 | 1 |  | 1 | |  |  |
| ops | | pbs-rda | <datastore_config> <datastore_name> <datastore_path> | restore datastore | Restore datastore configuration file with given parameters. | 39 | 88 | 1 |  | 1 | |  |  |
| ops | | pbs-mon | [option] | pbs monitor | Monitors and displays various aspects of the Proxmox Backup Server | 79 | 131 | 2 |  |  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32mpve[0m - Contains [31m1022[0m Lines and [33m15[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | pve-fun | <script_path> | overview functions | Displays an overview of specific Proxmox Virtual Environment (PVE) related functions in the script, showing their usage, shortname, and description | 22 | 40 | 1 |  |  | |  |  |
| ops | | pve-var | <config_file> <analysis_dir> | overview variables | Displays an overview of PVE-specific variables defined in the configuration file, showing their names, values, and usage across different files | 28 | 66 | 1 |  |  | |  |  |
| ops | | pve-dsr |  | disable repository | Disables specified Proxmox repository files by commenting out 'deb' lines, typically used to manage repository sources  | 29 | 98 | 1 |  | 1 | |  |  |
| ops | | pve-rsn |  | remove sub notice | Removes the Proxmox subscription notice by modifying the web interface JavaScript file, with an option to restart the pveproxy service  | 26 | 131 | 1 |  | 1 | |  |  |
| ops | | pve-clu |  | container list update | Updates the Proxmox VE Appliance Manager (pveam) container template list | 18 | 161 | 1 |  | 1 | |  |  |
| ops | | pve-cdo |  | container downloads | Downloads a specified container template to a given storage location, with error handling and options to list available templates | 46 | 183 | 2 |  | 1 | |  |  |
| ops | | pve-cbm | <vmid> <mphost> <mpcontainer> | container bindmount | Configures a bind mount for a specified Proxmox container, linking a host directory to a container directory | 42 | 233 | 1 |  | 1 | |  |  |
| ops | | pve-ctc | <id> <template> <hostname> <storage> <rootfs_size> <memory> <swap> <nameserver> <searchdomain> <password> <cpus> <privileged> <ip_address> <cidr> <gateway> <ssh_key_file> <net_bridge> <net_nic> | container create | Sets up different containers specified in cfg/env/site. | 78 | 279 | 2 |  | 1 | |  |  |
| ops | | pve-cto | <start|stop|enable|disable> <containers|all> | container toggle | Manages multiple Proxmox containers by starting, stopping, enabling, or disabling them, supporting individual IDs, ranges, or all containers | 82 | 361 | 2 |  |  | |  |  |
| ops | | pve-vmd | Usage |  pve-vmd <operation> <vm_id> <hook_script> <lib_ops_dir> [<vm_id2> ...] | vm shutdown hook | Deploys or modifies the VM shutdown hook for GPU reattachment | 75 | 447 | 2 |  |  | |  |
| ops | | pve-vmc | <id> <name> <ostype> <machine> <iso> <boot> <bios> <efidisk> <scsihw> <agent> <disk> <sockets> <cores> <cpu> <memory> <balloon> <net> | virtual machine create | Sets up different virtual machines specified in cfg/env/site. | 72 | 583 | 2 |  | 1 | |  |  |
| ops | | pve-vms | <vm_id> <cluster_nodes_str> <pci0_id> <pci1_id> <core_count_on> <core_count_off> <usb_devices_str> <pve_conf_path> [s |  optional, shutdown other node] | vm start get shutdown | Starts a VM on the current node or migrates it from another node, with an option to shut down the source node after migration | 82 | 659 | 2 |  |  | |  |
| ops | | pve-vmg | <vm_id> <cluster_nodes_str> <pci0_id> <pci1_id> <core_count_on> <core_count_off> <usb_devices_str> <pve_conf_path> | vm get start | Migrates a VM from a remote node to the current node, handling PCIe passthrough disable/enable during the process | 72 | 745 | 3 |  |  | |  |  |
| ops | | pve-vpt | <vm_id> <on|off> <pci0_id> <pci1_id> <core_count_on> <core_count_off> <usb_devices_str> <pve_conf_path> | vm passthrough toggle | Toggles PCIe passthrough configuration for a specified VM, modifying its configuration file to enable or disable passthrough devices | 99 | 821 | 3 |  |  | |  |  |
| ops | | pve-vck | <vm_id> <cluster_nodes_array> | vm check node | Checks and reports which node in the Proxmox cluster is currently hosting a specified VM | 99 | 924 | 4 |  |  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32msrv[0m - Contains [31m335[0m Lines and [33m8[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | srv-fun |  | overview functions | Displays an overview of specific NFS-related functions in the script, showing their usage, shortname, and description | 3 | 33 | 1 |  |  | |  |  |
| ops | | srv-var |  | overview variables | Displays an overview of NFS-specific variables defined in the configuration file, showing their names, values, and usage across different files | 3 | 39 | 1 |  |  | |  |  |
| ops | | nfs-set | <nfs_header> <shared_folder> <nfs_options> | nfs setup | Sets up an NFS share by prompting for necessary information (NFS header, shared folder, and options) and applying the configuration | 15 | 46 | 1 |  | 1 | |  |  |
| ops | | nfs-apl | <nfs_header> <shared_folder> <nfs_options> | nfs apply config | Applies NFS configuration by creating the shared folder if needed, updating /etc/exports, and restarting the NFS server | 30 | 65 | 2 |  |  | |  |  |
| ops | | nfs-mon | [option] | nfs monitor | Monitors and displays various aspects of the NFS server | 68 | 99 | 2 |  |  | |  |  |
| ops | | smb-set | <smb_header> <shared_folder> <username> <smb_password> <writable_yesno> <guestok_yesno> <browseable_yesno> <create_mask> <dir_mask> <force_user> <force_group> | samba setup 1 | Sets up a Samba share by prompting for missing configuration details and applying the configuration. Handles various share parameters including permissions, guest access, and file masks | 30 | 171 | 1 |  | 2 | |  |  |
| ops | | smb-apl | <smb_header> <shared_folder> <username> <smb_password> <writable_yesno> <guestok_yesno> <browseable_yesno> <create_mask> <dir_mask> <force_user> <force_group> | samba apply config | Applies Samba configuration by creating the shared folder if needed, updating cfg/env/site. with share details, restarting the Samba service, and setting up user passwords. Supports both user-specific and 'nobody' shares | 58 | 205 | 2 |  |  | |  |  |
| ops | | smb-mon | [option] | smb monitor | Monitors and displays various aspects of the SMB server | 68 | 267 | 2 |  |  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32msto[0m - Contains [31m875[0m Lines and [33m17[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | sto-fun |  | overview functions | Displays an overview of specific functions in the script, showing their usage, shortname, and description | 3 | 42 | 1 |  |  | |  |  |
| ops | | sto-var |  | overview variables | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files | 3 | 48 | 1 |  |  | |  |  |
| ops | | sto-fea |  | fstab entry auto | Adds auto-mount entries for devices to /etc/fstab using blkid. Allows user to select a device UUID and automatically creates the appropriate fstab entry | 34 | 55 | 1 |  |  | |  |  |
| ops | | sto-fec | <line_number> <mount_point> <filesystem> <mount_options> <fsck_pass_number> <mount_at_boot_priority>" | fstab entry custom | Adds custom entries to /etc/fstab using device UUIDs. Allows user to specify mount point, filesystem, mount options, and other parameters | 35 | 93 | 1 |  |  | |  |  |
| ops | | sto-nfs | [server_ip] [shared_folder] [mount_point] [options] | network file share | Mounts an NFS share interactively or with provided arguments | 39 | 132 | 1 |  | 1 | |  |  |
| ops | | sto-bfs-tra | <folder_name> <user_name> <C> | transforming folder subvolume | Transforms a folder into a Btrfs subvolume, optionally setting attributes (e.g., disabling COW). Handles multiple folders, preserving content and ownership. | 48 | 175 | 2 |  |  | |  |  |
| ops | | sto-bfs-ra1 | <device1> <device2> <mount_point> | btrfs raid 1 | Creates a Btrfs RAID 1 filesystem on two specified devices, mounts it, and optionally adds an entry to /etc/fstab | 38 | 227 | 1 |  | 1 | |  |  |
| ops | | sto-bfs-csf | <path> <folder_type |  1=regular, 2=hidden, 3=both> <yes=show subvolumes, no=show non-subvolumes, all=show all> | check subvolume folder | Checks and lists subvolume status of folders in a specified path. Supports filtering by folder type (regular, hidden, or both) and subvolume status. | 52 | 269 | 1 |  |  | |  |
| ops | | sto-bfs-shc | <configname> | snapper home create | Creates a new Snapper snapshot for the specified configuration or automatically selects a 'home_*' configuration if multiple exist | 38 | 325 | 1 |  |  | |  |  |
| ops | | sto-bfs-shd | <configname> <snapshot> | snapper home delete | Deletes a specified Snapper snapshot from a given configuration or automatically selects a 'home_*' configuration if multiple exist | 44 | 366 | 2 |  |  | |  |  |
| ops | | sto-bfs-shl | <configname> | snapper home list | Lists Snapper snapshots for the specified configuration or automatically selects a 'home_*' configuration if multiple exist | 38 | 414 | 1 |  |  | |  |  |
| ops | | sto-bfs-sfr | <snapshot subvolume> <target folder> | snapshot flat resync | Resyncs a Btrfs snapshot subvolume to a flat folder using rsync, excluding specific directories (.snapshots and .ssh) and preserving attributes | 22 | 456 | 1 |  |  | |  |  |
| ops | | sto-bfs-hub | <user> <snapshots |  "all"> | home user backups | Creates a backup subvolume for a user's home directory on a backup drive, then sends and receives Btrfs snapshots incrementally, managing full and incremental backups | 139 | 481 | 1 |  |  | |  |
| ops | | sto-bfs-snd | <parent subvolume> | subvolume nested delete | Recursively deletes a Btrfs parent subvolume and all its nested child subvolumes, with options for interactive mode and forced deletion | 94 | 624 | 2 |  |  | |  |  |
| ops | | sto-zfs-cpo | <pool_name> <drive_name_or_path> | zfs create pool | Creates a ZFS pool on a specified drive in a Proxmox VE environment | 42 | 723 | 1 |  |  | |  |  |
| ops | | sto-zfs-dim | <pool_name> <dataset_name> <mountpoint_path> | zfs directory mount | Creates a new ZFS dataset or uses an existing one, sets its mountpoint, and ensures it's mounted at the specified path | 43 | 770 | 1 |  | 1 | |  |  |
| ops | | sto-zfs-dbs | <sourcepoolname> <destinationpoolname> <datasetname> | zfs dataset backup | Creates and sends ZFS snapshots from a source pool to a destination pool. Supports initial full sends and incremental sends for efficiency | 59 | 817 | 1 |  |  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32msys[0m - Contains [31m921[0m Lines and [33m18[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | sys-fun |  | overview functions | Shows a summary of specific functions in the script, displaying their usage, shortname, and description | 4 | 40 | 1 |  |  | |  |  |
| ops | | sys-var |  | overview variables | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files | 3 | 48 | 1 |  |  | |  |  |
| ops | | sys-gio | sys-gio [commit message] | Performs status check, pull, commit, and push operations as needed. | Manages git operations, ensuring the local repository syncs with the remote. | 41 | 55 | 2 |  |  | |  |  |
| ops | | sys-dpa |  | detect package all | Detects the system's package manager | 16 | 100 | 3 |  |  | |  |  |
| ops | | sys-upa |  | update packages all | Updates and upgrades system packages using the detected package manager | 37 | 120 | 1 |  | 1 | |  |  |
| ops | | sys-ipa | <pak1> <pak2> ... | install packages all | Installs specified packages using the system's package manager | 49 | 161 | 1 |  | 5 | |  |  |
| ops | | sys-gst | <username> <usermail> | git set config | Configures git globally with a specified username and email, essential for proper commit attribution | 15 | 214 | 1 |  | 1 | |  |  |
| ops | | sys-sst |  | setup sysstat | Installs, enables, and starts the sysstat service for system performance monitoring. Modifies the configuration to ensure it's enabled | 13 | 233 | 1 |  |  | |  |  |
| ops | | sys-ust | <username> <password> | user setup | Creates a new user with a specified username and password, prompting for input if not provided. Verifies successful user creation | 28 | 250 | 1 |  | 2 | |  |  |
| ops | | sys-sdc | <service> | systemd setup service | Enables and starts a specified systemd service. Checks if the service is active and prompts for continuation if it's not | 30 | 282 | 1 |  | 2 | |  |  |
| ops | | sys-suk | <device_path> <mount_point> <subfolder_path> <upload_path> <file_name> | ssh upload keyfile | Uploads an SSH key from a plugged-in device to a specified folder (default |  /root/.ssh). Handles mounting, file copying, and unmounting of the device | 62 | 316 | 1 |  | 2 | |  |
| ops | | sys-spi | <user> <keyname> | ssh private identifier | Appends a private SSH key identifier to the SSH config file for a specified user. Creates the .ssh directory and config file if they don't exist | 43 | 382 | 1 |  |  | |  |  |
| ops | | sys-sks | client-side generation |  sys-sks -c [-d] <server_address> <key_name> [encryption_type] / server-side generation |  sys-sks -s [-d] <client_address> <key_name> [encryption_type] | ssh key swap | Generates an SSH key pair and handles the transfer process | 110 | 429 | 5 |  | 1 | |
| ops | | sys-sak | Usage |  sys-sak -c <server_address> <key_name> *for client-side operation /// sys-sak -s <client_address> <key_name> *for server-side operation | Provides informational output and restarts the SSH service. | Appends the content of a specified public SSH key file to the authorized_keys file. | 59 | 543 | 5 |  | 2 | |  |
| ops | | sys-loi | <ip array |  hy,ct> <operation |  bypass = Perform initial SSH login to bypass StrictHostKeyChecking / refresh = Remove the SSH key for the given IP from known_hosts> | loop operation ip | Loops a specified SSH operation (bypass StrictHostKeyChecking or refresh known_hosts) through a range of IPs defined in the configuration | 45 | 606 |  |  |  | |
| ops | | sys-sca | <usershortcut> <servershortcut> <ssh_users_array_name> <all_ip_arrays_array_name> <array_aliases_array_name> [command] | ssh custom aliases | Resolves custom SSH aliases using the configuration file. Supports connecting to single or multiple servers, executing commands remotely | 156 | 655 |  |  | 4 | |  |  |
| ops | | sys-gre | Usage |  sys-gre  # Then follow prompts, e.g., enter '2' for commits, '3' for hard reset, '2' to create new branch 'feat | GRE |  Git Reset Explorer | An interactive Bash function that guides users through Git history navigation, offering options for reset type and subsequent actions, with built-in safeguards and explanations. | 69 | 815 | 1 |  |  | |
| ops | | sys-hos | <ip_address> <hostname> | add host | Adds or updates a host entry in /etc/hosts. If IP or hostname is empty, logs an error and exits. | 34 | 888 | 1 |  | 5 | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | /home/es/lab/lib/ops/[32musr[0m - Contains [31m674[0m Lines and [33m14[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | usr-fun |  | overview functions | Shows a summary of selected functions in the script, displaying their usage, shortname, and description | 4 | 38 | 1 |  |  | |  |  |
| ops | | usr-var |  | overview variables | Displays an overview of specific variables defined in the configuration file, showing their names, values, and usage across different files | 3 | 45 | 1 |  |  | |  |  |
| ops | | usr-ckp | <profile_number> | change konsole profile | Changes the Konsole profile for the current user by updating the konsolerc file | 56 | 52 | 1 |  |  | |  |  |
| ops | | usr-vsf |  | variable select filename | Prompts the user to select a file from the current directory by displaying a numbered list of files and returning the chosen filename | 10 | 112 | 1 |  |  | |  |  |
| ops | | usr-cff | <path> <folder_type |  1=regular, 2=hidden, 3=both> | count files folder | Counts files in directories based on specified visibility (regular, hidden, or both). Displays results sorted by directory name | 44 | 126 | 1 |  |  | |  |
| ops | | usr-duc | <path1> <path2> <depth> | data usage comparison | Compares data usage between two paths up to a specified depth. Displays results in a tabular format with color-coded differences | 63 | 174 | 1 |  |  | |  |  |
| ops | | usr-cif | <path> | cat in folder | Concatenates and displays the contents of all files within a specified folder, separating each file's content with a line of dashes | 22 | 241 | 1 |  |  | |  |  |
| ops | | usr-rsf | <foldername> <old_string> <new_string> | replace strings folder | Replaces strings in files within a specified folder and its subfolders. If in a git repository, it stages changes and shows the diff | 46 | 267 | 1 |  |  | |  |  |
| ops | | usr-rsd | <source_path> <destination_path> | rsync source (to) destination | Performs an rsync operation from a source to a destination path. Displays files to be transferred and prompts for confirmation before proceeding | 39 | 317 | 1 |  |  | |  |  |
| ops | | usr-swt | <-r for relative or -a for absolute> <time> <state> | sheduled wakeup timer | Schedules a system wake-up using rtcwake. Supports absolute or relative time input and different sleep states (mem/disk) | 101 | 360 | 2 |  |  | |  |  |
| ops | | usr-adr |  | adding line (to) target | Adds a specific line to a target if not already present | 38 | 465 | 1 |  | 1 | |  |  |
| ops | | usr-cap | <file> <line> | check append create | Appends a line to a file if it does not already exist, preventing duplicate entries and providing feedback on the operation | 19 | 507 | 1 |  |  | |  |  |
| ops | | usr-rif | Options |  -d (dry run), -r (recursive), -i (interactive) | Usage |  usr-rif [-d] [-r] [-i] <path> <old_string> <new_string> | Replaces all occurrences of a string in files within a given folder | 118 | 530 | 4 |  |  | |
| ops | | usr-ans | Usage |  usr-ans <ansible_pro_path> <ansible_site_path> | ansible deployment desk | Navigates to the Ansible project directory, runs the playbook, then returns to the original directory | 23 | 652 | 2 |  |  | |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
<!-- GEN FUNCTIONS -->
| gen | /home/es/lab/lib/gen/[32menv[0m - Contains [31m355[0m Lines and [33m9[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | update_ecc | Helper function to update environment controller |  |  | 23 | 90 | 3 |  |  | |  |  |
| gen | | env_switch | Switch environment (dev/test/staging/prod) |  |  | 13 | 115 | 3 |  |  | |  |  |
| gen | | site_switch | Switch site |  |  | 20 | 130 | 3 |  |  | |  |  |
| gen | | node_switch | Switch node |  |  | 13 | 152 | 3 |  |  | |  |  |
| gen | | env_status | Show current environment status |  |  | 39 | 167 | 5 |  |  | |  |  |
| gen | | env_list | List available environments and overrides |  |  | 13 | 208 | 2 |  |  | |  |  |
| gen | | env_validate | Validate configuration files |  |  | 66 | 223 | 1 |  |  | |  |  |
| gen | | env_usage | Show usage |  |  | 28 | 291 | 2 |  |  | |  |  |
| gen | | main | Main function for command-line usage |  |  | 30 | 321 | 2 | 2 |  | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | /home/es/lab/lib/gen/[32minf[0m - Contains [31m441[0m Lines and [33m9[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | set_container_defaults | Set container defaults (can be called to override global defaults) |  |  | 33 | 114 | 2 |  |  | |  |  |
| gen | | generate_ip_sequence | Generate sequential IP addresses |  |  | 15 | 149 | 1 |  |  | |  |  |
| gen | | define_container | Define a container with minimal parameters |  |  | 48 | 166 | 3 |  |  | |  |  |
| gen | | define_containers | Define multiple containers from a configuration string |  |  | 17 | 216 | 2 |  |  | |  |  |
| gen | | set_vm_defaults | Set VM defaults |  |  | 25 | 235 | 1 |  |  | |  |  |
| gen | | define_vm | Define a VM with minimal parameters |  |  | 47 | 262 | 2 |  |  | |  |  |
| gen | | define_vms | Format |  "id1 | name1 |
| gen | | validate_config | Validate configuration |  |  | 50 | 338 | 1 |  |  | |  |  |
| gen | | show_config_summary | Show configuration summary |  |  | 30 | 390 | 1 |  |  | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | /home/es/lab/lib/gen/[32msec[0m - Contains [31m294[0m Lines and [33m10[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | generate_secure_password | Default length |  16, Default special chars |  included | Usage |
| gen | | store_secure_password | Usage |  store_secure_password variable_name [length] [exclude_special] | Generate a secure password and store it in a variable |  | 14 | 120 | 9 |  |  | |  |
| gen | | generate_service_passwords | Usage |  generate_service_passwords | Generate multiple passwords for different services |  | 16 | 137 | 2 |  |  | |  |
| gen | | create_password_file | Usage |  create_password_file filename password | Create a password file with proper permissions |  | 13 | 156 | 7 |  |  | |  |
| gen | | load_stored_passwords | Usage |  load_stored_passwords [password_dir] | Load passwords from secure storage |  | 14 | 172 | 2 |  |  | |  |
| gen | | get_password_directory | Usage |  get_password_directory | Get the appropriate password directory based on system capabilities |  | 18 | 189 | 1 |  |  | |  |
| gen | | init_password_management | Usage |  init_password_management [password_dir] | Initialize secure password management |  | 38 | 210 | 3 |  |  | |  |
| gen | | init_password_management_auto | Usage |  init_password_management_auto | Initialize password management with smart directory selection |  | 6 | 251 | 1 |  |  | |  |
| gen | | get_password_file | Usage |  get_password_file filename | Get password file path with fallback mechanism |  | 14 | 260 | 1 |  |  | |  |
| gen | | get_secure_password | Usage |  get_secure_password filename [length] | Get password with smart lookup |  | 12 | 277 | 1 |  |  | |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | /home/es/lab/lib/gen/[32mssh[0m - Contains [31m49[0m Lines and [33m5[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func | Arguments | Shortname | Description | Size | Loc | file | lib | src | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | set_ssh |  | !/bin/bash |  | 8 | 3 |  |  |  | |  |  |
| gen | | setup_ssh |  |  |  | 8 | 12 | 1 |  |  | |  |  |
| gen | | add_ssh_keys |  |  |  | 19 | 21 | 1 |  |  | |  |  |
| gen | | list_ssh_keys |  |  |  | 4 | 41 | 1 |  |  | |  |  |
| gen | | remove_ssh_keys |  |  |  | 4 | 46 |  |  |  | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |

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
