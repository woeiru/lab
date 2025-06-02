# Deployment

This document provides comprehensive instructions for using the deployment scripts located in the `src/set/` directory. These scripts automate infrastructure setup and configuration tasks for various services and system components using a consistent, environment-aware framework.

## Table of Contents

1. [Overview](#overview)
2. [Core Framework](#core-framework-srcauxset)
   - [Hostname-Based Script Organization](#hostname-based-script-organization)
3. [Prerequisites](#prerequisites)
4. [Quick Start Guide](#quick-start-guide)
5. [Usage Patterns](#usage-patterns)
6. [Available Deployment Scripts](#available-deployment-scripts)
7. [Configuration Management](#configuration-management)
8. [Workflow Examples](#workflow-examples)
9. [Security Considerations](#security-considerations)
10. [Troubleshooting](#troubleshooting)
11. [Advanced Usage](#advanced-usage)
12. [Related Documentation](#related-documentation)
13. [Support and Maintenance](#support-and-maintenance)
14. [Function Architecture Integration](#function-architecture-integration)

### NFS File Server Setup

```bash
# Complete NFS server deployment
./src/set/c1 -x a_xall
./src/set/c1 -x b_xall

# Or interactive mode for guided setup
./src/set/c1 -i
```

## Security Considerations

### Access Control

- **Privilege Requirements**: Many deployment operations require root privileges
- **SSH Key Management**: Scripts handle SSH key generation and distribution securely
- **File Permissions**: Configuration files should have appropriate restrictive permissions

### Best Practices

1. **Environment Isolation**: Use different environments (`dev`, `test`, `prod`) to isolate deployments
2. **Configuration Security**: Store sensitive data in environment-specific configuration files
3. **Network Security**: Verify firewall settings before deploying network services
4. **Backup Strategy**: Always backup existing configurations before running deployment scripts

### Security-Related Variables

```bash
# SSH configuration
SSH_USERS=("admin" "operator")
KEY_NAME="lab-cluster"

# Network isolation
QDEVICE_IP="192.168.1.12"  # Dedicated QDevice network
```

### Audit Trail

The framework provides comprehensive logging for security auditing:
- Execution timestamps and user context
- Configuration changes and their sources
- Error tracking and resolution steps
1. [Overview](#overview)
2. [Core Framework](#core-framework-libaux src)
3. [Prerequisites](#prerequisites)
4. [Quick Start Guide](#quick-start-guide)
5. [Usage Patterns](#usage-patterns)
6. [Available Deployment Scripts](#available-deployment-scripts)
7. [Configuration Management](#configuration-management)
8. [Workflow Examples](#workflow-examples)
9. [Security Considerations](#security-considerations)
10. [Troubleshooting](#troubleshooting)
11. [Advanced Usage](#advanced-usage)
12. [Related Documentation](#related-documentation)
13. [Support and Maintenance](#support-and-maintenance)

## Overview

The IaC deployment system provides automated infrastructure provisioning through:

- **Environment-aware configuration loading** with hierarchical overrides
- **Interactive and direct execution modes** for flexible deployment approaches  
- **Standardized utility integration** for consistent infrastructure management
- **Comprehensive logging and error handling** for reliable operations

## Core Framework: `src/aux/set`

All scripts within `src/set/` leverage the Environment-Aware Deployment Framework located at `src/aux/set`. This framework provides:

### Key Features

*   **Interactive Mode**: Menu-driven interface for selecting and executing specific deployment tasks
*   **Direct Execution Mode**: Command-line execution of specific tasks for automation and scripting
*   **Environment Context Management**: Automatic loading of base, environment, and node-specific configurations
*   **Hierarchical Configuration Loading**: Supports base → environment → node configuration overrides
*   **Usage Information**: Dynamic help generation based on script functions and configuration

### Architecture

Each deployment script defines a `MENU_OPTIONS` associative array mapping letter keys (e.g., `a`, `b`) to task functions (named `a_xall`, `b_xall`, etc.). The framework provides:

- **Configuration hierarchy**: `cfg/env/site1` → `cfg/env/site1-dev` → `cfg/env/site1-w2` 
- **Runtime constants integration** with automatic LAB_ROOT detection
- **Infrastructure and security utility loading** from `lib/ops/` and `lib/gen/`
- **Environment variable context** (`SITE`, `ENVIRONMENT`, `NODE`)

### Hostname-Based Script Organization

The `src/set/` directory uses a **hostname-based naming convention** where each script corresponds to a specific infrastructure node:

| Script | Hostname | Purpose | Infrastructure Role |
|--------|----------|---------|-------------------|
| **`h1`** | Hypervisor 1 | Proxmox VE cluster setup | Primary virtualization host |
| **`c1`** | Container 1 | NFS server deployment | Network file storage |
| **`c2`** | Container 2 | Samba/SMB services | Windows-compatible file sharing |
| **`c3`** | Container 3 | Proxmox Backup Server | Backup infrastructure |
| **`t1`** | Test Node 1 | Development environment | Developer workstation setup |
| **`t2`** | Test Node 2 | Utility operations | Testing and temporary operations |

This design allows for:
- **Host-specific customization**: Each script contains deployment logic tailored to its target system
- **Clear infrastructure mapping**: Script names directly correspond to actual hostnames in the lab
- **Simplified remote deployment**: Scripts can be executed directly on target systems or via remote SSH
- **Environment-aware execution**: All scripts automatically adapt to development, testing, or production contexts

## Prerequisites

Before using the deployment scripts, ensure:

1. **System Requirements**:
   - Bash 4.0+ (for associative arrays and advanced features)
   - Standard Linux utilities (`grep`, `sed`, `awk`, etc.)
   - Appropriate privileges for target operations

2. **Environment Setup**:
   - Execute from the project root directory (`/home/es/lab/`)
   - Source the initialization framework: `source bin/ini` (recommended)
   - Configure environment variables if using non-default settings

3. **Configuration Files**:
   - Base site configuration: `cfg/env/site1`
   - Environment-specific overrides (optional): `cfg/env/site1-dev`
   - Node-specific overrides (optional): `cfg/env/site1-w2`

## Quick Start Guide

### 1. First-Time Setup

```bash
# Navigate to lab directory
cd /home/es/lab

# Initialize the environment (recommended)
source bin/ini

# Verify available scripts
ls src/set/
```

### 2. Interactive Exploration

```bash
# Explore development setup options
./src/set/t1

# Use interactive mode for guided setup
./src/set/t1 -i
```

### 3. Direct Deployment

```bash
# Quick development environment setup
./src/set/t1 -x a_xall

# NFS server deployment
./src/set/c1 -x a_xall && ./src/set/c1 -x b_xall
```

### 4. Environment-Specific Deployment

```bash
# Development environment
ENVIRONMENT=dev ./src/set/h1 -x a_xall

# Production node
ENVIRONMENT=prod NODE=w2 ./src/set/h1 -x a_xall
```

## Usage Patterns

All scripts from `src/set/` follow consistent invocation patterns. Ensure you are in the project root directory (`/home/es/lab/`) for proper operation.

### 1. Displaying Usage and Help

To see available tasks and options for any script:
```bash
./src/set/script_name
```

**Example**:
```bash
./src/set/t1
```

This displays the framework's help information, including:
- Available task sections and their descriptions
- Execution mode options (`-i` interactive, `-x` direct)
- Display format options (1-6 for different output styles)
- Environment context information

### 2. Interactive Mode

For menu-driven task selection:
```bash
./src/set/script_name -i [display_option] [-s section]
```

**Examples**:
```bash
./src/set/t1 -i              # Interactive mode with default display
./src/set/h1 -i 3            # Interactive mode with function descriptions
./src/set/c1 -i -s a         # Focus on section 'a' only
```

**Display Options**:
- `1`: Default display (default)
- `2`: Expand variables in output
- `3`: Show function descriptions
- `4`: Expand variables and show descriptions
- `5`: Show only function names and descriptions
- `6`: Show only function descriptions

### 3. Direct Task Execution

For automation and scripting:
```bash
./src/set/script_name -x task_function_name
```

**Examples**:
```bash
./src/set/t1 -x a_xall       # Install packages and configure Git
./src/set/h1 -x b_xall       # Install Proxmox packages only
./src/set/c1 -x b_xall       # Configure NFS exports only
```

### 4. Environment Context

Scripts automatically load configuration based on environment variables:

```bash
# Default (site1)
./src/set/h1 -x a_xall

# Development environment 
ENVIRONMENT=dev ./src/set/h1 -x a_xall

# Node-specific configuration
NODE=w2 ./src/set/h1 -x a_xall

# Combined environment and node
ENVIRONMENT=dev NODE=w2 ./src/set/h1 -x a_xall
```

## Available Deployment Scripts

The following scripts are available in `src/set/` for infrastructure deployment:

### 1. `src/set/t1` - Development Environment Setup
**Purpose**: Configures development workstations and tools

**Available Tasks**:
*   **`a_xall`**: Installs common system packages and configures global Git user credentials
*   **`b_xall`**: Configures global Git user credentials only

**Use Cases**: Initial workstation setup, developer onboarding, Git configuration standardization

**Example Usage**:
```bash
./src/set/t1 -x a_xall    # Full development setup
./src/set/t1 -x b_xall    # Git configuration only
```

### 2. `src/set/c1` - Network File System Setup
**Purpose**: Deploys and configures NFS server infrastructure

**Available Tasks**:
*   **`a_xall`**: Installs NFS server packages, enables the NFS service, and creates NFS management user account
*   **`b_xall`**: Configures NFS exports by setting up shared folders with specified access permissions

**Use Cases**: Centralized file storage, shared development environments, backup destinations

**Configuration Requirements**: NFS-related variables in site configuration (`NFS_PACKAGES_ALL`, `NFS_USERNAME_1`, etc.)

**Example Usage**:
```bash
./src/set/c1 -x a_xall    # Install and enable NFS server
./src/set/c1 -x b_xall    # Configure shares only
```

### 3. `src/set/c3` - Proxmox Backup Server Setup  
**Purpose**: Installs and configures Proxmox Backup Server

**Available Tasks**:
*   **`a_xall`**: Downloads and verifies Proxmox Backup Server GPG key, adds repository, and installs PBS packages
*   **`b_xall`**: Configures PBS datastore with specified name and path for backup storage

**Use Cases**: Enterprise backup infrastructure, Proxmox ecosystem integration, automated backup management

**Configuration Requirements**: PBS-related variables (`PBS_PACKAGES_ALL`, datastore configuration)

### 4. `src/set/h1` - Proxmox Virtual Environment Setup
**Purpose**: Comprehensive Proxmox VE cluster setup and management

**Available Tasks**:
*   **`a_xall`**: Disables enterprise repository, adds community repository, and removes subscription notice
*   **`b_xall`**: Installs required system packages including corosync-qdevice for cluster management  
*   **`c_xall`**: Sets up /etc/hosts entries for Proxmox nodes (x1, x2) and QDevice
*   **`d_xall`**: Generates and distributes SSH keys for secure communication between nodes
*   **`i_xall`**: Creates a RAID 1 Btrfs filesystem across two devices with specified mount point
*   **`j_xall`**: Creates and configures multiple ZFS datasets with their respective mount points
*   **`p_xall`**: Updates container template list, downloads specified template, and updates configuration
*   **`q_xall`**: Creates multiple Proxmox containers using configuration parameters from site config
*   **`r_xall`**: Configures bind mounts for all defined containers to link host and container directories
*   **`s_xall`**: Creates multiple virtual machines using specifications defined in site configuration

**Use Cases**: Virtualization infrastructure, container platforms, high-availability clusters

**Configuration Requirements**: Extensive PVE variables (node IPs, storage configuration, VM/CT definitions)

### 5. `src/set/c2` - Samba (SMB/CIFS) Server Setup
**Purpose**: Deploys Windows-compatible file sharing services

**Available Tasks**:
*   **`a_xall`**: Installs Samba packages, enables the SMB service, and creates initial user account for Samba access
*   **`b_xall`**: Sets up multiple Samba shares with different access permissions for regular and guest users

**Use Cases**: Windows integration, mixed-environment file sharing, legacy system support

**Configuration Requirements**: SMB-related variables (packages, user accounts, share definitions)

### 6. `src/set/t2` - Temporary/Utility Operations
**Purpose**: Provides utility functions for system operations and testing

**Available Tasks**:
*   **`a_xall`**: Uploads private SSH key from USB device to system for secure authentication
*   **`b_xall`**: Uploads public SSH key from USB device and adds it to authorized keys
*   **`c_xall`**: Mounts a predefined NFS share using global configuration variables
*   **`d_xall`**: Executes remote commands via SSH using configured aliases

**Use Cases**: Key management, temporary mounts, remote command execution, system testing

## Configuration Management

### Configuration Hierarchy

The framework uses a three-tier configuration hierarchy:

1. **Base Configuration**: `cfg/env/site1` (default site)
2. **Environment Override**: `cfg/env/site1-dev` (when `ENVIRONMENT=dev`)  
3. **Node Override**: `cfg/env/site1-w2` (when `NODE=w2`)

### Environment Variables

Control deployment behavior with these variables:

- **`SITE`**: Base site identifier (default: `site1`)
- **`ENVIRONMENT`**: Environment override (`dev`, `test`, `staging`, `prod`)
- **`NODE`**: Node-specific override (`h1`, `w2`, `x1`, `x2`, etc.)
- **`LAB_ROOT`**: Lab directory root (auto-detected)

### Configuration Files

Each script requires specific configuration variables. Common patterns:

```bash
# Package lists
PACKAGES_DEV=("git" "vim" "curl" "wget")
NFS_PACKAGES_ALL=("nfs-kernel-server" "nfs-common")

# Service configuration  
NFS_USERNAME_1="nfsuser"
NFS_SHARED_FOLDER_1="/export/shared"

# Network configuration
NODE1_IP="192.168.1.10"
NODE2_IP="192.168.1.11"
QDEVICE_IP="192.168.1.12"
```

Refer to `cfg/env/site1` for complete configuration examples.

## Workflow Examples

### Development Environment Setup

```bash
# Complete development workstation setup
./src/set/t1 -i

# Or direct execution
./src/set/t1 -x a_xall
```

### Proxmox Cluster Deployment

```bash
# Step 1: Repository and package setup
./src/set/h1 -x a_xall

# Step 2: Install cluster packages  
./src/set/h1 -x b_xall

# Step 3: Configure networking
./src/set/h1 -x c_xall

# Step 4: Set up SSH keys
./src/set/h1 -x d_xall

# Step 5: Create storage (interactive selection)
./src/set/h1 -i -s i    # Btrfs RAID 1
./src/set/h1 -i -s j    # ZFS datasets
```

### NFS File Server Setup

```bash
# Complete NFS server deployment
./src/set/c1 -x a_xall
./src/set/c1 -x b_xall

# Or interactive mode for guided setup
./src/set/c1 -i
```

## Troubleshooting

### Common Issues

1. **Configuration Variables Not Found**
   - Ensure you're in the project root directory
   - Verify configuration files exist in `cfg/env/`
   - Check environment variable settings

2. **Permission Errors**
   - Many operations require root privileges
   - Use `sudo ./src/set/script_name` when necessary
   - Verify file permissions on configuration directories

3. **Function Not Found Errors**
   - Ensure `src/aux/set` is properly sourced
   - Check that required utility functions exist in `lib/ops/`
   - Verify runtime constants are loaded from `cfg/core/ric`

4. **Network Configuration Issues**
   - Verify IP addresses in configuration files
   - Ensure DNS resolution works for hostnames
   - Check firewall settings for required ports

### Debug Mode

Enable detailed logging:
```bash
set -x
./src/set/script_name -x function_name
set +x
```

### Validation

Check configuration before deployment:
```bash
# View loaded configuration
./src/set/script_name -i 2    # Expand variables

# Test specific sections
./src/set/script_name -i -s section_id
```

## Advanced Usage

### Batch Operations

Execute multiple tasks in sequence:
```bash
# Proxmox cluster setup sequence
for task in a_xall b_xall c_xall d_xall; do
    ./src/set/h1 -x $task
done
```

### Environment-Specific Deployments

```bash
# Development environment
ENVIRONMENT=dev ./src/set/h1 -x a_xall

# Production node w2
ENVIRONMENT=prod NODE=w2 ./src/set/h1 -x a_xall
```

### Integration with Automation

The scripts are designed for integration with automation tools:

```bash
#!/bin/bash
# Deployment automation script

export ENVIRONMENT="dev"
export NODE="h1"

# Deploy NFS server
./src/set/c1 -x a_xall
./src/set/c1 -x b_xall

# Deploy Proxmox
./src/set/h1 -x a_xall
./src/set/h1 -x b_xall
```

## Related Documentation

- **System Architecture**: `doc/man/architecture.md` - Overall lab system design and component relationships
- **Configuration Management**: `doc/man/configuration.md` - Detailed configuration file formats and options
- **Initialization Process**: `doc/man/initiation.md` - Lab environment initialization and runtime control
- **Logging System**: `doc/man/logging.md` - Comprehensive logging and monitoring capabilities
- **Framework Flow**: `doc/flo/aux_src_menu_architecture.md` - Technical flow diagrams and decision trees

### Component Documentation

- **Core Libraries**: `lib/core/` - Error handling, logging, and timing modules
- **Operations Libraries**: `lib/ops/` - System, storage, and service management functions
- **Utility Libraries**: `lib/gen/` - Infrastructure, security, and environment utilities
- **Configuration Files**: `cfg/` - Environment configurations and runtime constants

## Support and Maintenance

### Getting Help

1. **Built-in Documentation**: Use `./src/set/script_name` to view detailed help for any script
2. **Function Reference**: Examine source files in `lib/ops/` for available operations and their parameters
3. **Configuration Examples**: Review `cfg/env/site1` for complete parameter formats and examples
4. **Framework Source**: See `src/aux/set` source code for advanced features and customization options

### Maintenance Tasks

**Regular Updates**:
- Review and update configuration files in `cfg/env/` as infrastructure changes
- Test deployment scripts in development environment before production use
- Monitor logs for errors or performance issues
- Update package lists and service configurations as needed

**Version Control**:
- All configuration changes are tracked through the lab's version control system
- Use environment-specific branches for testing configuration changes
- Document infrastructure changes in the appropriate `doc/` files

**Performance Monitoring**:
- The framework includes built-in timing and performance monitoring
- Use `tme_print_timing_report` after deployments to analyze performance
- Monitor system resources during large-scale deployments

### Contributing

The deployment framework is actively maintained and welcomes contributions:

1. **Bug Reports**: Document issues with specific error messages and reproduction steps
2. **Feature Requests**: Propose new deployment scripts or framework enhancements
3. **Configuration Updates**: Submit updates for new services or infrastructure components
4. **Documentation**: Help improve and expand documentation for better usability

The framework supports the lab's evolving infrastructure automation requirements and is designed for extensibility and maintainability.

## Function Architecture Integration

### Pure Functions vs Management Wrappers

The deployment scripts integrate with a sophisticated **function separation pattern** implemented in the operations modules:

#### Architecture Overview
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Deployment      │ -> │  Wrapper (-w)    │ -> │  Pure Function  │
│ Script (src/set)│    │  src/mgt/*       │    │  lib/ops/*      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                v
                       ┌──────────────────┐
                       │  Global Config   │
                       │  Environment     │
                       └──────────────────┘
```

#### Implementation in Deployment Context

**Deployment Scripts** (`src/set/`) call **Management Wrappers** (`src/mgt/`) which extract global variables from the environment and call **Pure Functions** (`lib/ops/`) with explicit parameters.

##### Example: PVE Deployment Integration
```bash
# In deployment script (src/set/h1)
source "${SRC_MGT_DIR}/pve"  # Load wrapper functions

# Call wrapper function (handles global variable extraction)
pve-vpt-w 100 on  # Enable passthrough for VM 100

# The wrapper (src/mgt/pve) extracts globals and calls pure function
# pve-vpt-w() {
#     local hostname=$(hostname)
#     local pci0_id="${!hostname}_NODE_PCI0"
#     local pci1_id="${!hostname}_NODE_PCI1"
#     # ...extract other globals
#     pve-vpt "$vm_id" "$action" "$pci0_id" "$pci1_id" ...
# }
```

#### Benefits for Infrastructure Deployment

1. **Environment Independence**: Pure functions work regardless of deployment context
2. **Testing Capability**: Pure functions can be unit tested independently
3. **Configuration Flexibility**: Wrappers adapt to different environment configurations
4. **Maintainable Automation**: Clear separation between deployment logic and infrastructure operations

#### Available Function Categories

**Pure Functions** (9 parameterized from PVE module):
- `pve-fun` - Function listing and documentation
- `pve-var` - Variable analysis and configuration review
- `pve-vmd` - VM shutdown hook management
- `pve_vck` - VM cluster node location checking
- `pve-vpt` - PCI passthrough toggle operations
- `pve-ctc` - Container creation with full configuration
- `pve-vmc` - Virtual machine creation and setup
- `pve-vms` - VM start/shutdown with passthrough management
- `pve-vmg` - VM migration and orchestration

**Management Wrappers** (corresponding `-w` functions):
- Handle global variable extraction from environment
- Provide deployment-friendly interfaces
- Integrate with configuration hierarchy
- Support environment-aware operations
