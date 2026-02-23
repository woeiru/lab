# Infrastructure Configuration Guide

## Overview

This document describes the infrastructure configuration system for the lab environment, including IP allocation schemes, naming conventions, container definitions, and security practices.

## IP Allocation Scheme

### Network Ranges

The lab environment uses the `192.168.178.0/24` network with the following allocation scheme:

#### Hypervisor Nodes
- **h1**: `192.168.178.110` - Primary hypervisor node
- **w2**: `192.168.178.120` - Secondary hypervisor node  
- **x1**: `192.168.178.221` - Cluster node 1
- **x2**: `192.168.178.222` - Cluster node 2

#### Container Services
- **PBS (Proxmox Backup Server)**:
  - Node h1: `192.168.178.111` (ID: 111)
  - Node w2: `192.168.178.121` (ID: 121)
- **NFS (Network File System)**:
  - Node h1: `192.168.178.112` (ID: 112)
  - Node w2: `192.168.178.122` (ID: 122)
- **SMB (Samba File Server)**:
  - Node h1: `192.168.178.113` (ID: 113)
  - Node w2: `192.168.178.123` (ID: 123)

#### Network Infrastructure
- **Gateway**: `192.168.178.1`
- **QDevice**: `192.168.178.223` - Corosync QDevice
- **Client Systems**: `192.168.178.55` (t1)

## Naming Conventions

### Container Naming
- **Format**: `{service}{instance}`
- **Examples**: `pbs1`, `nfs1`, `smb1`, `pbs2`, `nfs2`, `smb2`
- **Service Types**:
  - `pbs` - Proxmox Backup Server
  - `nfs` - NFS Server
  - `smb` - Samba Server

### Node Naming
- **Format**: `{prefix}{number}`
- **Examples**: `h1`, `w2`, `x1`, `x2`
- **Prefixes**:
  - `w` - Workstation nodes
  - `x` - Extended/cluster nodes
  - `t` - Test/client nodes

### Container ID Assignment
- **Pattern**: Last two digits match IP address
- **Examples**:
  - Container with IP `192.168.178.111` gets ID `111`
  - Container with IP `192.168.178.122` gets ID `122`

## Infrastructure Utilities

### Location
Infrastructure configuration utilities are located in `lib/gen/inf`

### Key Functions

#### Container Definition
```bash
# Define a single container
define_container id hostname ip_address [additional_params...]

# Define multiple containers from array
define_containers "id1:hostname1:ip1:id2:hostname2:ip2:..."
```

#### Default Configuration
```bash
# Set container defaults
set_container_defaults \
    template="..." \
    storage="..." \
    memory=8192 \
    ...

# Set VM defaults  
set_vm_defaults \
    ostype="..." \
    machine="..." \
    ...
```

#### Utility Functions
```bash
# Generate sequential IPs
generate_ip_sequence base_ip count

# Validate configuration
validate_config

# Show configuration summary
show_config_summary
```

### Default Container Configuration

The infrastructure utilities provide the following defaults:

- **Template**: `local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst`
- **Storage**: `local-zfs`
- **Root FS**: 32GB
- **Memory**: 8192MB
- **Swap**: 8192MB
- **CPUs**: 8
- **Network**: `vmbr0` bridge with DHCP
- **Nameserver**: `8.8.8.8`
- **Search Domain**: `fritz.box`
- **Gateway**: `192.168.178.1`
- **CIDR**: /24
- **Privileged**: Yes
- **SSH Key**: `/root/.ssh/h1.pub`

## Security Configuration

### Password Management

Security utilities are located in `lib/gen/sec` and provide:

#### Secure Password Generation
```bash
# Generate secure password (default 16 chars)
generate_secure_password [length] [exclude_special]

# Store password in variable
store_secure_password variable_name [length] [exclude_special]

# Generate all service passwords
generate_service_passwords
```

#### Password Storage
- **Location**: Default is `/etc/lab/passwords/` or `/tmp/lab_passwords` depending on system capabilities
- **Permissions**: 700 (directory), 600 (files)
- **Files**:
  - `ct_pbs.pwd` - PBS container root password
  - `ct_nfs.pwd` - NFS container root password  
  - `ct_smb.pwd` - SMB container root password
  - `nfs_user.pwd` - NFS service user password
  - `smb_user.pwd` - SMB service user password

#### Password Initialization
```bash
# Initialize password management
init_password_management [password_dir]

# Load existing passwords
load_stored_passwords [password_dir]
```

## Environment-Aware Configuration

### Environment Variables
The system supports environment-specific configurations through:

- **Base Site**: `cfg/env/site1`
- **Environment Override**: `cfg/env/site1-dev`
- **Node Override**: `cfg/env/site1-w2`

### Loading Hierarchy
1. Load base site configuration
2. Apply environment-specific overrides
3. Apply node-specific overrides
4. Load runtime constants

## Storage Configuration

### ZFS Datasets
- **Pool**: `rpool`
- **Datasets**:
  - `rpool/pbs` -> `/sto/pbs`
  - `rpool/nfs` -> `/sto/nfs`
  - `rpool/smb` -> `/sto/smb`

### Btrfs Configuration
- **Devices**: `/dev/nvme0n1`, `/dev/nvme2n1`
- **Mount Point**: `/sto`
- **Subvolumes**:
  - `/sto/pbs`
  - `/sto/nfs`
  - `/sto/smb`

### Container Bind Mounts
- **PBS**: Host `/sto/pbs` -> Container `/home`
- **NFS**: Host `/sto/nfs` -> Container `/home`
- **SMB**: Host `/sto/smb` -> Container `/home`

## Usage Examples

### Creating a New Container
```bash
# Load utilities
source lib/gen/inf
source lib/gen/sec

# Initialize security
init_password_management

# Define container with custom settings
define_container 114 "web" "192.168.178.114" \
    memory=4096 \
    cpus=4 \
    rootfs_size=16

# Or use bulk creation
define_containers "114:web:192.168.178.114:115:db:192.168.178.115"
```

### Environment Switching
```bash
# Switch to development environment
export ENVIRONMENT="dev"
source src/set/.menu

# Switch to specific node
export NODE="w2"
source src/set/.menu
```

## Troubleshooting

### Common Issues

1. **Missing Passwords**: Run `init_password_management` to generate
2. **Configuration Conflicts**: Check environment variable hierarchy
3. **Network Issues**: Verify IP allocation doesn't conflict
4. **Storage Problems**: Ensure ZFS/Btrfs datasets are available

### Validation Commands
```bash
# Check configuration
validate_config

# Show loaded environment
echo "Site: $SITE, Environment: $ENVIRONMENT, Node: $NODE"

# Test password generation
generate_secure_password 20
```

## Migration Guide

### From Legacy Configuration
1. Replace hardcoded variables
2. Use `define_containers` for bulk creation
3. Implement secure password management
4. Update deployment scripts to source utilities

### Configuration Updates
1. Add `source lib/gen/inf` to configuration files
2. Add `source lib/gen/sec` for security features
3. Replace password variables with secure generation

## Function Architecture Patterns

### Pure Function Design in Library Modules

The infrastructure utilities follow a pure function design pattern where library functions in `lib/ops/` and `lib/gen/` directories accept explicit parameters rather than accessing global variables directly.

#### Benefits
- **Enhanced Testability**: Functions can be tested in isolation with known inputs
- **Explicit Dependencies**: All required data is passed as parameters, making dependencies clear
- **Reduced Coupling**: Functions don't depend on specific global variable configurations

#### Implementation Example
```bash
# Pure function (lib/ops/pve) - parameterized approach
pve_vpt() {
    local vm_id="$1"
    local action="$2"  
    local pci0_id="$3"
    local pci1_id="$4"
    local core_count_on="$5"
    local core_count_off="$6"
    local usb_devices_str="$7"
    local pve_conf_path="$8"
    
    # Logic uses only explicit parameters
    if [[ "$action" == "on" ]]; then
        # Enable passthrough with provided parameters
    fi
}

# DIC operations (src/dic/ops) - handles dependency injection
# Usage: ops pve vpt -j
```
