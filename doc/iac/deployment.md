# Deployment

This document provides comprehensive instructions for using the deployment scripts located in the `src/set/` directory. These scripts automate infrastructure setup and configuration tasks for various services and system components using a consistent, environment-aware framework.

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
*   **Hierarchical Configuration Loading**: Supports base -> environment -> node configuration overrides
*   **Usage Information**: Dynamic help generation based on script functions and configuration

### Architecture

Each deployment script defines a `MENU_OPTIONS` associative array mapping letter keys (e.g., `a`, `b`) to task functions (named `a_xall`, `b_xall`, etc.). The framework provides:

- **Configuration hierarchy**: `cfg/env/site1` -> `cfg/env/site1-dev` -> `cfg/env/site1-w2` 
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

This design allows for host-specific customization and simplified deployment execution.

## Prerequisites

Before using the deployment scripts, ensure:

1. **System Requirements**:
   - Bash 4.0+
   - Standard Linux utilities
   - Appropriate privileges for target operations

2. **Environment Setup**:
   - Execute from the project root directory
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

# Initialize the environment
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

All scripts from `src/set/` follow consistent invocation patterns. Ensure you are in the project root directory.

### 1. Displaying Usage and Help

To see available tasks and options for any script:
```bash
./src/set/script_name
```

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

## Available Deployment Scripts

### 1. `src/set/t1` - Development Environment Setup
**Purpose**: Configures development workstations and tools

**Available Tasks**:
*   **`a_xall`**: Installs common system packages and configures global Git user credentials
*   **`b_xall`**: Configures global Git user credentials only

### 2. `src/set/c1` - Network File System Setup
**Purpose**: Deploys and configures NFS server infrastructure

**Available Tasks**:
*   **`a_xall`**: Installs NFS server packages, enables the NFS service, and creates NFS management user account
*   **`b_xall`**: Configures NFS exports by setting up shared folders with specified access permissions

### 3. `src/set/c3` - Proxmox Backup Server Setup  
**Purpose**: Installs and configures Proxmox Backup Server

**Available Tasks**:
*   **`a_xall`**: Downloads and verifies Proxmox Backup Server GPG key, adds repository, and installs PBS packages
*   **`b_xall`**: Configures PBS datastore with specified name and path for backup storage

### 4. `src/set/h1` - Proxmox Virtual Environment Setup
**Purpose**: Comprehensive Proxmox VE cluster setup and management

**Available Tasks**:
*   **`a_xall`**: Disables enterprise repository, adds community repository
*   **`b_xall`**: Installs required system packages including corosync-qdevice for cluster management  
*   **`c_xall`**: Sets up /etc/hosts entries for Proxmox nodes (x1, x2) and QDevice
*   **`d_xall`**: Generates and distributes SSH keys for secure communication between nodes
*   **`i_xall`**: Creates a RAID 1 Btrfs filesystem across two devices
*   **`j_xall`**: Creates and configures multiple ZFS datasets
*   **`p_xall`**: Updates container template list, downloads specified template
*   **`q_xall`**: Creates multiple Proxmox containers using configuration parameters
*   **`r_xall`**: Configures bind mounts for all defined containers
*   **`s_xall`**: Creates multiple virtual machines using specifications defined in site configuration

### 5. `src/set/c2` - Samba (SMB/CIFS) Server Setup
**Purpose**: Deploys Windows-compatible file sharing services

**Available Tasks**:
*   **`a_xall`**: Installs Samba packages, enables the SMB service, creates initial user account
*   **`b_xall`**: Sets up multiple Samba shares with different access permissions

### 6. `src/set/t2` - Temporary/Utility Operations
**Purpose**: Provides utility functions for system operations and testing

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

## Troubleshooting

### Common Issues

1. **Configuration Variables Not Found**
   - Ensure you're in the project root directory
   - Verify configuration files exist in `cfg/env/`
   - Check environment variable settings

2. **Permission Errors**
   - Many operations require root privileges
   - Use `sudo ./src/set/script_name` when necessary

3. **Function Not Found Errors**
   - Ensure `src/aux/set` is properly sourced
   - Check that required utility functions exist in `lib/ops/`
   - Verify runtime constants are loaded from `cfg/core/ric`

## Advanced Usage

### Batch Operations

Execute multiple tasks in sequence:
```bash
# Proxmox cluster setup sequence
for task in a_xall b_xall c_xall d_xall; do
    ./src/set/h1 -x $task
done
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

- **Configuration Management**: `doc/man/configuration.md`
- **Initialization Process**: `doc/man/initiation.md`
- **Logging System**: `doc/man/logging.md`

## Function Architecture Integration

### Pure Functions vs Management Wrappers

The deployment scripts integrate with a sophisticated function separation pattern implemented in the operations modules:

#### Implementation in Deployment Context

**Deployment Scripts** (`src/set/`) call **DIC Operations** (`src/dic/ops`) which handle dependency injection and call **Pure Functions** (`lib/ops/`) with explicit parameters.

##### Example: PVE Deployment Integration
```bash
# In deployment script (src/set/h1)
source src/dic/ops  # Load DIC operations

# Call DIC operation (handles global variable extraction)
ops pve vpt -j 100 on  # Enable passthrough for VM 100

# The DIC operations handle dependency injection and call pure functions
```
