# Environment Management Guide

Comprehensive guide for managing multi-environment deployments and configuration hierarchies.

## 🌍 Environment Architecture

The Lab Environment Management System implements a sophisticated **hierarchical configuration system** that supports multiple environments with automatic configuration cascading.

### Environment Hierarchy
```
Base Configuration (cfg/env/site1)
    ↓
Environment Override (cfg/env/site1-dev)  
    ↓
Node-Specific Settings (runtime)
```

### Supported Environments
- **Development (`dev`)**: Development and testing workloads
- **Testing (`test`)**: Staging and integration testing
- **Production (`prod`)**: Production workloads
- **Workstation (`w1`, `w2`)**: Individual workstation configurations

## 🏗️ Environment Configuration

### Base Site Configuration (`cfg/env/site1`)
```bash
# Infrastructure definitions
export CLUSTER_NODES=("w1" "w2" "x1" "x2")
export HYPERVISOR_NODES=("w1:192.168.178.110" "w2:192.168.178.120")
export NETWORK_BASE="192.168.178"
export STORAGE_BACKEND="local-lvm"

# Container service definitions
export PBS_NODES=("w1:111:192.168.178.111" "w2:121:192.168.178.121")
export NFS_NODES=("w1:112:192.168.178.112" "w2:122:192.168.178.122")
export SMB_NODES=("w1:113:192.168.178.113" "w2:123:192.168.178.123")
```

### Environment-Specific Overrides

#### Development Environment (`cfg/env/site1-dev`)
```bash
# Development environment overrides
export CLUSTER_NODES=("dev-node1" "dev-node2")
export VM_DEFAULT_MEMORY=2048
export CT_DEFAULT_CORES=2
export STORAGE_BACKEND="local"

# Development-specific networking
export NETWORK_BASE="192.168.178"
export DEVELOPMENT_MODE="true"
export DEBUG_ENABLED="true"
```

#### Workstation Environment (`cfg/env/site1-w2`)
```bash
# Workstation-specific configuration
export NODE_ROLE="workstation"
export GPU_PASSTHROUGH="enabled"
export DESKTOP_SERVICES="true"
export DEVELOPMENT_TOOLS="enabled"

# Workstation resource allocation
export VM_DEFAULT_MEMORY=8192
export CT_DEFAULT_CORES=4
```

### Node-Specific Runtime Configuration
```bash
# Automatic node detection and configuration
export SITE="site1"
export ENVIRONMENT="dev"  
export NODE="$(hostname)"

# Node-specific overrides loaded at runtime
# Based on hostname and environment context
```

## 🚀 Environment Deployment Patterns

### Standardized Deployments

#### Infrastructure Utilities Pattern
```bash
# Environment-aware infrastructure deployment
source lib/utl/inf

# Set environment-specific defaults
set_container_defaults \
    memory="${VM_DEFAULT_MEMORY}" \
    storage="${STORAGE_BACKEND}" \
    cores="${CT_DEFAULT_CORES}"

# Deploy with environment context
define_containers "${ENVIRONMENT_CONTAINER_DEFINITIONS}"
validate_config && show_config_summary
```

#### Multi-Environment Container Deployment
```bash
# Development environment
export ENVIRONMENT="dev"
define_containers "101:web-dev:192.168.178.101:102:db-dev:192.168.178.102"

# Testing environment  
export ENVIRONMENT="test"
define_containers "201:web-test:192.168.179.101:202:db-test:192.168.179.102"

# Production environment
export ENVIRONMENT="prod"
define_containers "301:web-prod:192.168.180.101:302:db-prod:192.168.180.102"
```

### Environment-Specific Resource Allocation

#### Development Resources
- **Memory**: 2-4GB per container/VM
- **CPU**: 2 cores per workload
- **Storage**: Local storage for fast iteration
- **Network**: Shared development network

#### Testing Resources
- **Memory**: 4-6GB per container/VM
- **CPU**: 2-4 cores per workload
- **Storage**: SSD storage for performance testing
- **Network**: Isolated testing network

#### Production Resources
- **Memory**: 8-16GB per container/VM
- **CPU**: 4-8 cores per workload
- **Storage**: Redundant storage (RAID, ZFS)
- **Network**: Dedicated production network with QDevice

## 🔧 Environment Management Operations

### Environment Switching
```bash
# Switch to development environment
export SITE="site1"
export ENVIRONMENT="dev"
source ~/.bashrc  # Reload environment

# Switch to production environment
export SITE="site1"
export ENVIRONMENT="prod"
source ~/.bashrc  # Reload environment
```

### Environment Validation
```bash
# Validate current environment configuration
./tst/validate_system

# Test environment-specific functionality
./tst/test_environment

# Environment-specific deployment testing
cd src/set/pve && ./pve  # Interactive mode for environment testing
```

### Configuration Override Management
```bash
# View current environment hierarchy
echo "Site: $SITE"
echo "Environment: $ENVIRONMENT"
echo "Node: $NODE"
echo "Cluster Nodes: ${CLUSTER_NODES[*]}"
echo "Default Memory: $VM_DEFAULT_MEMORY"
```

## 🏭 Infrastructure Environment Patterns

### Development Infrastructure
- **Purpose**: Rapid development and testing
- **Resources**: Minimal resource allocation
- **Networking**: Single network segment
- **Storage**: Local storage for speed
- **Monitoring**: Debug logging enabled

### Testing Infrastructure
- **Purpose**: Integration and system testing
- **Resources**: Production-like resource allocation
- **Networking**: Isolated test networks
- **Storage**: Performance-optimized storage
- **Monitoring**: Comprehensive logging and metrics

### Production Infrastructure
- **Purpose**: Live production workloads
- **Resources**: Full resource allocation with redundancy
- **Networking**: Segmented production networks
- **Storage**: Redundant, backed-up storage
- **Monitoring**: Full monitoring, alerting, and audit trails

## 📊 Environment Automation

### Automated Environment Provisioning
```bash
# Environment-specific deployment scripts
cd src/set/pve

# Development environment setup
export ENVIRONMENT="dev" && ./pve a b c d

# Testing environment setup  
export ENVIRONMENT="test" && ./pve a b c d

# Production environment setup
export ENVIRONMENT="prod" && ./pve a b c d
```

### Environment-Aware Service Management
```bash
# Service deployment with environment context
cd src/set/c1  # Container service 1
export ENVIRONMENT="dev" && ./c1

cd src/set/c2  # Container service 2
export ENVIRONMENT="prod" && ./c2
```

### Cross-Environment Operations
```bash
# Multi-environment deployment
for env in dev test prod; do
    export ENVIRONMENT="$env"
    source ~/.bashrc
    cd src/set/pve && ./pve q  # Deploy containers
done
```

## 🔍 Environment Monitoring

### Environment Health Checks
```bash
# Environment-specific validation
export ENVIRONMENT="dev" && ./tst/validate_system
export ENVIRONMENT="test" && ./tst/validate_system  
export ENVIRONMENT="prod" && ./tst/validate_system
```

### Resource Utilization Monitoring
- **Development**: Resource usage tracking for optimization
- **Testing**: Performance metrics for validation
- **Production**: Comprehensive monitoring with alerting

### Environment Compliance
- **Configuration Drift Detection**: Automated configuration validation
- **Environment Consistency**: Cross-environment configuration comparison
- **Policy Enforcement**: Automated policy compliance checking

## 📋 Environment Best Practices

### Configuration Management
1. **Hierarchical Configuration**: Use base → environment → node override pattern
2. **Environment Isolation**: Separate resources and networks by environment
3. **Consistent Naming**: Use environment prefixes in resource names
4. **Documentation**: Document environment-specific configurations

### Deployment Practices
1. **Environment Promotion**: Deploy through dev → test → prod pipeline
2. **Configuration Validation**: Validate configurations before deployment
3. **Rollback Procedures**: Maintain rollback capabilities for each environment
4. **Change Management**: Track configuration changes across environments

### Security Practices
1. **Environment-Specific Credentials**: Separate credentials per environment
2. **Network Segmentation**: Isolate environments at network level
3. **Access Controls**: Role-based access per environment
4. **Audit Trails**: Track access and changes per environment

## 📖 Related Documentation

- **[Infrastructure Guide](infrastructure.md)** - Deployment automation patterns
- **[Configuration Management](../adm/configuration.md)** - Detailed configuration options
- **[Security Management](../adm/security.md)** - Environment security practices
