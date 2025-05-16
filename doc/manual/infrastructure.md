# Infrastructure as Code (IaC) for `src/set/` Deployment

This document provides instructions on how to use the deployment scripts located in the `src/set/` directory. These scripts are designed to automate various setup and configuration tasks for different services and system components.

## Core Framework: `lib/aux/src`

All scripts within `src/set/` leverage a common shell script framework located at `lib/aux/src`. This framework provides a consistent way to execute scripts, offering features such as:

*   **Interactive Mode**: A menu-driven interface to select and execute specific tasks within a script.
*   **Direct Execution Mode**: Allows running a specific task directly by providing its name as an argument.
*   **Usage Information**: Displays help text detailing the available tasks and how to run them.

Each deployment script defines a `MENU_OPTIONS` associative array, which maps short letter keys (e.g., `a`, `b`) to task functions (typically named `a_xall`, `b_xall`, etc.). These tasks represent the individual operations the script can perform.

## Common Invocation Methods

To use any script from the `src/set/` directory (e.g., `dsk`, `nfs`), ensure you are in the project root directory (`./`) and use the following patterns:

1.  **Displaying Usage/Help**:
    To see the available tasks and options for a script, run it without any arguments:
    ```bash
    ./src/set/script_name
    ```
    For example, for the `dsk` script:
    ```bash
    ./src/set/dsk
    ```
    This will invoke the `print_usage` function from the `lib/aux/src` framework, which typically lists available tasks based on the script's `MENU_OPTIONS` and function comments.

2.  **Interactive Mode**:
    To use the menu-driven interactive mode, run the script with the `-i` flag:
    ```bash
    ./src/set/script_name -i
    ```
    For example:
    ```bash
    ./src/set/dsk -i
    ```
    This will present a list of available tasks (e.g., `a`, `b`, `c`) that you can select to execute.

3.  **Direct Task Execution**:
    To execute a specific task directly, use the `-x` flag followed by the task's function name (e.g., `a_xall`, `b_xall`):
    ```bash
    ./src/set/script_name -x task_function_name
    ```
    For example, to directly run the `a_xall` task from the `dsk` script:
    ```bash
    ./src/set/dsk -x a_xall
    ```

## Available Deployment Scripts and Tasks

Below is a list of the scripts available in `src/set/` and the tasks they can perform.

### 1. `src/set/dsk`
   Script for desktop environment setup tasks.
   *   **`a_xall`**: Installs common system packages and configures global Git user credentials.
   *   **`b_xall`**: Configures global Git user credentials.
   *   **`c_xall`**: Uploads private SSH key from USB device to system for secure authentication.

### 2. `src/set/nfs`
   Script for Network File System (NFS) server setup.
   *   **`a_xall`**: Installs NFS server packages, enables the NFS service, and creates a user account for NFS management.
   *   **`b_xall`**: Configures NFS exports by setting up a shared folder with specified access permissions.

### 3. `src/set/pbs`
   Script for Proxmox Backup Server (PBS) setup.
   *   **`a_xall`**: Downloads and verifies Proxmox Backup Server GPG key, adds repository, and installs PBS packages.
   *   **`b_xall`**: Configures PBS datastore with specified name and path for backup storage.

### 4. `src/set/pve`
   Script for Proxmox Virtual Environment (PVE) setup and management.
   *   **`a_xall`**: Disables enterprise repository, adds community repository, and removes subscription notice from Proxmox web interface.
   *   **`b_xall`**: Installs required system packages including corosync-qdevice for cluster management.
   *   **`c_xall`**: Uploads public SSH key from USB device and adds it to the authorized keys for secure remote access.
   *   **`d_xall`**: Generates and distributes SSH keys for secure communication between client and server nodes.
   *   **`i_xall`**: Creates a RAID 1 Btrfs filesystem across two devices with the specified mount point.
   *   **`j_xall`**: Creates and configures multiple ZFS datasets with their respective mount points based on configuration.
   *   **`p_xall`**: Updates container template list, downloads specified template, and updates container configuration.
   *   **`q_xall`**: Creates multiple Proxmox containers using configuration parameters from `site.conf`.
   *   **`r_xall`**: Configures bind mounts for all defined containers to link host and container directories.
   *   **`s_xall`**: Creates multiple virtual machines using the specifications defined in `site.conf`.
   *(Note: The `pve` script contains additional tasks not listed here for brevity. Refer to the script's usage information for a complete list.)*

### 5. `src/set/smb`
   Script for Samba (SMB/CIFS) server setup.
   *   **`a_xall`**: Installs Samba packages, enables the SMB service, and creates initial user account for Samba access.
   *   **`b_xall`**: Sets up multiple Samba shares with different access permissions for regular and guest users.

To understand the full capabilities and specific parameters used by each task, it is recommended to also review the source code of the respective scripts in `src/set/` and their associated configuration files if applicable.
