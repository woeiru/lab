# Operations Libraries (`lib/ops/`)

## 📋 Overview

The `lib/ops/` directory contains specialized operations libraries that provide infrastructure management capabilities for enterprise-grade systems. These modules handle complex infrastructure operations including GPU management, network configuration, storage orchestration, and virtualization management.

## 🗂️ Directory Contents

### 🎮 `gpu` - GPU Passthrough Management
Comprehensive GPU management system for virtualization environments with PCI passthrough capabilities.

**Key Features:**
- GPU device detection and enumeration
- PCI passthrough configuration
- Virtual machine GPU assignment
- Performance optimization controls

### 🌐 `net` - Network Configuration & Management
Advanced networking utilities for complex multi-node infrastructure deployments.

**Key Features:**
- Network interface management
- VLAN configuration
- Bridge and bond management
- Network troubleshooting utilities

### 📦 `pbs` - Proxmox Backup Server Operations
Specialized utilities for Proxmox Backup Server management and automation.

**Key Features:**
- Backup job automation
- Storage pool management
- Restore operations
- Backup verification and reporting

### 🖥️ `pve` - Proxmox VE Cluster Management
Comprehensive Proxmox Virtual Environment cluster management and orchestration.

**Key Features:**
- Cluster node management
- Virtual machine lifecycle operations
- Resource allocation and monitoring
- High availability configuration

### 🚀 `srv` - Service Deployment & Lifecycle Management
Service orchestration and deployment automation for containerized and traditional services.

**Key Features:**
- Service definition and deployment
- Health monitoring and auto-recovery
- Load balancing configuration
- Service discovery mechanisms

### 💾 `sto` - Storage Orchestration & Management
Advanced storage management covering multiple storage technologies and protocols.

**Key Features:**
- ZFS dataset management
- Btrfs snapshot operations
- NFS and SMB share configuration
- Storage performance optimization

### ⚙️ `sys` - System Administration Utilities
Core system administration functions for infrastructure maintenance and management.

**Key Features:**
- System resource monitoring
- Process management utilities
- Package management automation
- System configuration management

### 👥 `usr` - User & Permission Management
User account and permission management utilities for multi-user infrastructure environments.

**Key Features:**
- User account provisioning
- Group management
- Permission assignment
- Security policy enforcement

## 🚀 Usage Guidelines

### Loading Operations Libraries
Operations libraries are loaded on-demand based on environmental requirements:

```bash
# Load specific operations library
source lib/ops/gpu
source lib/ops/pve

# Use library functions
gpu-passthrough-setup "device-id" "vm-id"
pve-cluster-status
```

### Environment Integration
Operations libraries integrate with environment-specific configurations:

```bash
# Environment-aware operations
gpu-ptd "01:00.0" "x1" "cfg/env/site1" "0000:01:00.0" "0000:01:00.1" "nvidia"
pve-node-setup "site1-dev"
```

## 🔧 Architecture Patterns

### Function Organization
- **Core Operations**: Primary functionality functions (e.g., `gpu-ptd`, `pve-cluster-join`)
- **Wrapper Functions**: Environment-aware wrappers with `-w` suffix for management scripts
- **Utility Functions**: Supporting operations and helper functions
- **Validation Functions**: Input validation and system state verification

### Error Handling
- **Comprehensive Validation**: Input parameter validation with detailed error messages
- **State Verification**: System state checks before operations
- **Rollback Mechanisms**: Automatic rollback on operation failures
- **Logging Integration**: Full integration with `lib/core/lo1` logging system

## 🔗 Integration Points

### Management Layer
- **Source Management**: Operations wrapped by `src/mgt/` management scripts
- **Configuration Integration**: Environment-specific settings from `cfg/env/`
- **Core Services**: Error handling and logging via `lib/core/`

### System Dependencies
- **Hardware Access**: Direct hardware manipulation capabilities
- **Virtualization Platforms**: Proxmox VE, KVM, and container technologies
- **Network Infrastructure**: Advanced networking stack requirements
- **Storage Systems**: ZFS, Btrfs, and network storage protocols

## 📊 Performance Characteristics

### Operations Complexity
- **GPU Operations**: High-precision PCI device management
- **Network Operations**: Real-time network configuration changes
- **Storage Operations**: Large-scale data movement and organization
- **Virtualization**: Resource-intensive VM and container management

### Optimization Features
- **Parallel Execution**: Multi-threaded operations where applicable
- **Caching Mechanisms**: Intelligent caching of system state information
- **Bulk Operations**: Batch processing for multiple similar operations
- **Resource Management**: Intelligent resource allocation and cleanup

## 🔐 Security Considerations

### Privilege Requirements
- **Root Access**: Many operations require elevated privileges
- **Hardware Access**: Direct hardware device manipulation
- **Network Configuration**: System-level network changes
- **Storage Access**: Raw storage device access

### Security Patterns
- **Privilege Validation**: Verification of required permissions before operations
- **Input Sanitization**: Comprehensive input validation and sanitization
- **Audit Logging**: Detailed logging of all privileged operations
- **Safe Defaults**: Conservative default settings for security-sensitive operations

---

**Navigation**: Return to [Library System](../README.md) | [Main Lab Documentation](../../README.md)
