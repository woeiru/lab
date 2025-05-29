# Lab Environment Management System

A sophisticated, production-ready infrastructure automation and environment management platform built for enterprise-scale deployment and development operations.

## 🎯 System Overview

This is a comprehensive environment management framework designed for complex infrastructure automation, featuring hierarchical configuration management, modular deployment patterns, and enterprise-grade security controls. The system has evolved into a mature platform supporting Proxmox VE clusters, container orchestration, GPU passthrough management, and multi-environment deployment scenarios.

### ✨ Key Capabilities

- **🏗️ Infrastructure as Code**: Standardized container/VM deployment with 19+ configurable parameters
- **🔧 Modular Architecture**: Pure function libraries with wrapper pattern for enhanced testability  
- **🌍 Environment-Aware**: Hierarchical configuration loading (base → environment → node)
- **🔐 Security-First**: Zero hardcoded passwords with secure credential management
- **📊 Performance Monitoring**: Comprehensive timing and performance analysis tools
- **🧪 Testing Framework**: 375+ lines of validation logic for system reliability
- **📚 Enterprise Documentation**: Complete technical guides and operational runbooks

## 🚀 Quick Start

### Environment Setup
```bash
# Initialize the environment (supports bash/zsh)
./entry.sh

# Verify installation  
./bin/validate_system

# Check system status
./bin/test_environment
```

### Basic Usage
```bash
# Source core system (automatic after setup)
source ~/.bashrc  # or ~/.zshrc

# Available core modules:
# - err: Advanced error handling and stack traces
# - lo1: Module-specific debug logging  
# - tme: Performance timing and monitoring
# - Environment hierarchy management
```

## 🏛️ Architecture Overview

### Directory Structure
```
lab/
├── bin/          # Executables and core initialization
│   ├── init      # Main system initialization (487 lines)
│   ├── core/comp # Component orchestrator  
│   └── env/rc    # Shell environment configuration
├── cfg/          # Hierarchical configuration system
│   ├── core/     # Runtime constants and system definitions
│   ├── env/      # Environment-specific configurations
│   └── ans/      # Ansible playbooks for automation
├── lib/          # Modular libraries (stateless design)
│   ├── core/     # Essential modules (err, lo1, tme, ver)
│   ├── ops/      # Operations libraries (pve, gpu, sys, net)
│   └── utl/      # Utilities (infrastructure, security, environment)
├── src/          # Source code and deployment scripts
│   ├── set/      # Service deployment (pve, nfs, pbs, smb)
│   └── mgt/      # Management wrappers for pure functions
├── doc/          # Comprehensive documentation ecosystem
│   ├── man/      # Technical manuals and guides
│   ├── dev/      # Development session summaries
│   └── imp/      # Implementation completion records
└── too/          # Specialized tools and utilities
```

### Core Design Patterns

#### 🎯 Function Separation Pattern
```bash
# Pure Functions (lib/ops/) - Testable, parameterized
pve-vmc() {
    local vm_id="$1"
    local cluster_nodes="$2" 
    # Pure logic with explicit parameters
}

# Wrapper Functions (src/mgt/) - Environment integration  
pve-vmc-w() {
    local cluster_nodes="${CLUSTER_NODES[*]}"
    pve-vmc "$vm_id" "$cluster_nodes"
}
```

#### 🌐 Environment Hierarchy
```bash
Base Configuration (cfg/env/site1)
    ↓
Environment Override (cfg/env/site1-dev)  
    ↓
Node-Specific Settings (runtime)
```

## 🛠️ System Components

### Infrastructure Management
- **Container/VM Standardization**: 355+ lines of infrastructure utilities
- **Bulk Creation**: Colon-separated definition strings for rapid deployment
- **IP Management**: Automatic sequence generation and network planning
- **Configuration Validation**: Built-in validation and summary reporting

### Security Framework  
- **Password Management**: 120+ lines of secure credential handling
- **Zero Hardcoded Secrets**: All credentials managed through `lib/utl/sec`
- **Proper Permissions**: Automatic 600 permissions for sensitive files
- **Fallback Mechanisms**: Graceful handling of missing credentials

### Deployment System
```bash
# Interactive deployment
cd src/set/pve && ./pve

# Direct execution  
cd src/set/pve && ./pve a  # Execute specific task

# Environment context automatically loaded:
# SITE=site1, ENVIRONMENT=dev, NODE=current_hostname
```

### Operations Libraries

| Module | Purpose | Functions |
|--------|---------|-----------|
| **pve** | Proxmox VE Management | 15 functions (9 parameterized) |
| **gpu** | GPU Passthrough | 9 functions with `-w` wrappers |
| **sys** | System Operations | Package, user, host management |
| **net** | Network Management | Configuration and routing |
| **sto** | Storage Management | Filesystem and storage pools |


## 🔧 Advanced Features

### Configuration Management
```bash
# Hierarchical environment loading
export SITE="site1"
export ENVIRONMENT="dev"  
export NODE="workstation-1"

# Automatic configuration cascade:
# cfg/env/site1 → cfg/env/site1-dev → node-specific overrides
```

### Performance Monitoring
```bash
# Built-in timing system
tme_start_timer "DEPLOYMENT_TASK"
# ... perform operations ...
tme_end_timer "DEPLOYMENT_TASK" "success"
tme_print_timing_report
```

### Infrastructure Utilities
```bash
# Standardized container creation
source lib/utl/inf
define_containers "111:pbs:192.168.178.111:112:nfs:192.168.178.112"
validate_config && show_config_summary
```

## 🎓 Usage Examples

### Container Deployment
```bash
# Set global defaults
set_container_defaults memory=4096 storage="local-lvm"

# Bulk container creation
define_containers "101:web:192.168.1.101:102:db:192.168.1.102"

# Deploy with environment awareness
cd src/set/pve && ./pve q  # Create containers
```

### GPU Passthrough Management
```bash
# Environment-aware GPU management
gpu-pts-w    # Check GPU status (wrapper function)
gpu-ptd-w 1  # Detach GPU for passthrough
gpu-pta-w 1  # Attach GPU back to host
```

### Proxmox Cluster Setup
```bash
cd src/set/pve
./pve a  # Configure repositories
./pve b  # Install packages  
./pve c  # Setup /etc/hosts
./pve d  # Generate SSH keys
```

## 📋 System Requirements

- **Operating System**: Linux (tested on Proxmox VE)
- **Shell**: Bash 4+ or Zsh 5+
- **Dependencies**: Standard UNIX utilities, systemd
- **Network**: Multi-node cluster support with QDevice integration
- **Storage**: Btrfs, ZFS, and LVM support

## 🔍 Configuration Examples

### Environment Configuration (cfg/env/site1-dev)
```bash
# Development environment overrides
export CLUSTER_NODES=("dev-node1" "dev-node2")
export VM_DEFAULT_MEMORY=2048
export CT_DEFAULT_CORES=2
```

### Container Definition
```bash
# Traditional approach (deprecated)
CT_101_ID=101
CT_101_HOSTNAME="webserver"
CT_101_IP="192.168.1.101"
# ... 16 more variables per container

# Modern approach (current)
define_container 101 "webserver" "192.168.1.101"
```

## 🧪 Testing & Validation

```bash
# Quick system validation
./bin/validate_system

# Comprehensive testing
./bin/test_environment

# Component-specific testing  
cd test && ./test_complete_refactor.sh
```

## 📚 Documentation

- **[Architecture Guide](doc/man/architecture.md)**: Complete system design overview
- **[Configuration Manual](doc/man/configuration.md)**: Detailed configuration options
- **[Infrastructure Guide](doc/man/infrastructure.md)**: Deployment and IaC patterns
- **[User Guide](doc/man/initiation.md)**: User interaction and runtime controls
- **[Logging System](doc/man/logging.md)**: Monitoring and debugging

## 🤝 Integration Points

### For Developers
- **Library Integration**: Import stateless functions with explicit parameters
- **Environment Awareness**: Use hierarchical configuration for context
- **Testing Framework**: Leverage existing validation infrastructure

### For System Administrators
- **Ansible Integration**: Use playbooks in `cfg/ans/` for automation
- **Monitoring**: Implement logging and performance tracking
- **Security**: Follow established credential management patterns

### For Infrastructure Teams  
- **Standardized Deployments**: Use infrastructure utilities for consistency
- **Environment Management**: Implement environment-specific overrides
- **Automation**: Extend deployment scripts with established patterns


## 📊 System Metrics

### 🏗️ Codebase Statistics
- **Total Files**: 111 files across 40 directories
- **Library Functions**: 133 operational functions in 19 library modules
- **Operations Code**: 5,323 lines of infrastructure automation
- **Utility Libraries**: 1,417 lines of reusable components
- **Wrapper Functions**: 18 environment-integration wrappers

### 📚 Documentation & Configuration
- **Technical Documentation**: 2,453 lines across 39 markdown files
- **Configuration Files**: 22 environment and system config files
- **Deployment Scripts**: 8 service-specific deployment modules
- **Container Variables**: 108 container configuration parameters

### 🧪 Quality Assurance
- **Test Framework**: 499 lines of comprehensive validation logic
- **Function Separation**: Pure functions with management wrappers
- **Security Coverage**: Zero hardcoded credentials with secure management
- **Environment Support**: Multi-tier configuration hierarchy

> 💡 **Live Metrics**: These statistics are generated in real-time using `./stats.sh`. Run it anytime to get current codebase metrics in formatted, markdown, or raw output.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Quick Commands:**
```bash
./entry.sh                    # Initial setup
./bin/validate_system         # Quick validation  
cd src/set/pve && ./pve      # Interactive deployment
source lib/utl/inf           # Infrastructure utilities
```

For detailed documentation, start with [`doc/man/architecture.md`](doc/man/architecture.md) for system overview or [`doc/man/initiation.md`](doc/man/initiation.md) for user guide.
