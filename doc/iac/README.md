# 🏗️ Infrastructure as Code Documentation

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

Documentation for infrastructure teams and DevOps engineers managing deployment automation.

## 🎯 Target Audience

Infrastructure teams and DevOps engineers who need to:
- Implement standardized deployments using infrastructure utilities
- Manage environment-specific configurations and overrides  
- Extend deployment scripts with established automation patterns
- Orchestrate container and VM infrastructure at scale

## 📚 Documentation Index

### Infrastructure Management
- **[Infrastructure Guide](infrastructure.md)** - Comprehensive IaC deployment patterns, automation scripts, and infrastructure management
- **[Environment Management](environment-management.md)** - Multi-environment deployment patterns, configuration hierarchies, and automation

### Infrastructure Guidelines

#### Standardized Deployments
- **Infrastructure Utilities**: Use consistent deployment patterns for reliability
- **Container/VM Standardization**: 355+ lines of infrastructure utilities
- **Bulk Creation**: Colon-separated definition strings for rapid deployment
- **Configuration Validation**: Built-in validation and summary reporting

#### Environment Management
- **Environment-Specific Overrides**: Implement cascading configuration management
- **Multi-Environment Support**: dev, test, prod environment isolation
- **Node-Specific Settings**: Runtime configuration customization
- **Hierarchical Configuration**: base → environment → node cascade

#### Automation Patterns
- **Deployment Scripts**: Extend established patterns in `src/set/`
- **Service Orchestration**: Standardized service deployment automation
- **Infrastructure Provisioning**: Automated container and VM provisioning

## 🚀 Deployment Workflows

### Container Infrastructure
```bash
# Standardized container creation
source lib/gen/inf
define_containers "111:pbs:192.168.178.111:112:nfs:192.168.178.112"
validate_config && show_config_summary

# Set global defaults
set_container_defaults memory=4096 storage="local-lvm"

# Deploy with environment awareness
cd src/set/pve && ./pve q  # Create containers
```

### Proxmox VE Cluster Setup
```bash
cd src/set/pve
./pve a  # Configure repositories
./pve b  # Install packages  
./pve c  # Setup /etc/hosts
./pve d  # Generate SSH keys
```

### GPU Infrastructure Management
```bash
# GPU passthrough for infrastructure
gpu_pts-w    # Check GPU status
gpu_ptd-w 1  # Detach GPU for passthrough
gpu_pta-w 1  # Attach GPU back to host
```

## 🌍 Environment Management

### Configuration Hierarchy
```bash
# Environment configuration cascade
Base Configuration (cfg/env/site1)
    ↓
Environment Override (cfg/env/site1-dev)  
    ↓
Node-Specific Settings (runtime)
```

### Multi-Environment Deployment
```bash
# Development environment
export SITE="site1"
export ENVIRONMENT="dev"
export NODE="dev-node1"

# Production environment  
export SITE="site1"
export ENVIRONMENT="prod"
export NODE="prod-node1"
```

### Infrastructure Scaling
- **Multi-node cluster support** with QDevice integration
- **Automated IP management** and network planning
- **Storage backend flexibility** (Btrfs, ZFS, LVM)
- **Service replication** across cluster nodes

## 🔧 Infrastructure Utilities

### Core Infrastructure Functions
| Module | Purpose | Infrastructure Focus |
|--------|---------|---------------------|
| **pve** | Proxmox VE Management | Cluster orchestration, VM/container lifecycle |
| **gpu** | GPU Passthrough | Hardware resource allocation for compute workloads |
| **sys** | System Operations | Package management, user provisioning, host setup |
| **net** | Network Management | Network configuration, routing, connectivity |
| **sto** | Storage Management | Storage pools, filesystems, backup integration |

### Deployment Scripts
| Script | Purpose | Infrastructure Scope |
|--------|---------|---------------------|
| **c1, c2, c3** | Container Services | Multi-tier container deployment |
| **t1, t2** | Test Infrastructure | Test environment provisioning |
| **h1** | Hypervisor Setup | Development hypervisor configuration |

## 📊 Infrastructure Metrics

### Deployment Scale
- **355+ lines** of infrastructure utilities
- **19+ configurable parameters** per deployment
- **133 operational functions** in 19 library modules
- **8 service-specific deployment modules**

### Automation Coverage
- **Container orchestration** with standardized parameters
- **VM lifecycle management** with Proxmox VE integration
- **GPU resource allocation** for compute infrastructure
- **Network and storage provisioning** automation

## 🛡️ Infrastructure Security

### Secure Infrastructure Patterns
- **Zero hardcoded credentials** in infrastructure code
- **Environment-specific secret management**
- **Automated permission management** for infrastructure files
- **Network isolation** between environments

### Compliance and Auditing
- **Infrastructure as Code** principles for auditability
- **Comprehensive logging** for infrastructure operations
- **Change tracking** through git and deployment logs
- **Security validation** in deployment pipelines

## 🔄 Continuous Deployment

### Infrastructure Pipeline
1. **Configuration Validation**: Built-in validation before deployment
2. **Environment Preparation**: Hierarchical configuration loading
3. **Resource Provisioning**: Automated infrastructure creation
4. **Service Deployment**: Standardized service orchestration
5. **Health Validation**: Post-deployment testing and validation

### Monitoring and Maintenance
- **Performance monitoring** with built-in timing framework
- **Health checks** via comprehensive test suites
- **Automated backup** and disaster recovery procedures
- **Capacity planning** with resource utilization tracking

## 📖 Related Documentation

- **Developers**: See `../dev/` for library integration and architecture
- **System Administrators**: See `../adm/` for operational procedures  
- **End Users**: See `../user/` for user-facing procedures

## Common Tasks
- Start with the quick-start or workflow sections in this file.
- From repo root, run `./go doctor` and `./go validate` after changes.

## Troubleshooting
- Confirm commands are run from the expected directory (usually repo root).
- Check generated logs under `.log/` and rerun `./go doctor` for diagnostics.
