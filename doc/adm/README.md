# 🛠️ System Administrator Documentation

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

Documentation for system administrators managing the Lab Environment infrastructure.

## 🎯 Target Audience

System administrators who need to:
- Configure and manage system infrastructure
- Implement monitoring and performance tracking
- Manage security and credential systems

## 📚 Documentation Index

### Core Administration
- **[Configuration Management](configuration.md)** - Infrastructure configuration, IP allocation, naming conventions, and security practices
- **[Security Management](security.md)** - Comprehensive security framework, credential management, and access controls

### Administration Guidelines

#### Monitoring & Performance
- **Logging Systems**: Implement comprehensive logging and performance tracking
- **Performance Analysis**: Use built-in timing and monitoring tools
- **Health Checks**: Regular system validation and health monitoring

#### Security Management
- **Credential Management**: Follow established patterns in `lib/gen/sec`
- **Zero Hardcoded Secrets**: All credentials managed through secure utilities
- **Permission Management**: Automatic 600 permissions for sensitive files
- **Access Control**: Implement proper user and system access controls

## 🔧 Administrative Workflows

### System Configuration
```bash
# Environment setup
export SITE="site1"
export ENVIRONMENT="prod"
export NODE="admin-node"

# Load configuration hierarchy
# cfg/env/site1 → cfg/env/site1-prod → node-specific
```

### Monitoring Setup
```bash
# Enable comprehensive logging
export MASTER_TERMINAL_VERBOSITY="on"
export LO1_LOG_TERMINAL_VERBOSITY="on"

# Monitor system performance
tme_print_timing_report
```

### Security Management
```bash
# Credential management (via lib/gen/sec)
# - Automatic secure permissions
# - Fallback mechanisms
# - Zero hardcoded passwords
```

## 🏗️ Infrastructure Management

### Network Configuration
- **IP Allocation**: Standardized `192.168.178.0/24` network scheme
- **Container Services**: PBS, NFS, SMB service allocation
- **Cluster Management**: Multi-node cluster with QDevice integration

### Storage Management
- **Multiple Backends**: Btrfs, ZFS, and LVM support
- **Backup Systems**: Proxmox Backup Server integration
- **Data Protection**: Automated backup and snapshot management

### Container Orchestration
- **Standardized Deployment**: 19+ configurable parameters
- **Bulk Creation**: Colon-separated definition strings
- **Service Management**: PBS, NFS, SMB container management

## 📊 System Monitoring

### Health Checks
- **Quick Validation**: `./tst/validate_system`
- **Comprehensive Testing**: `./tst/test_environment`
- **Component Testing**: Module-specific validation scripts (see [Testing Framework](../dev/testing.md))

### Performance Metrics
- **Live Statistics**: `./utl/doc/generators/stats` for real-time metrics and README updates
- **Resource Monitoring**: Built-in performance analysis
- **Capacity Planning**: Infrastructure utilization tracking

## 🔐 Security Framework

### Credential Management
- **120+ lines** of secure credential handling
- **Zero hardcoded secrets** across the entire system
- **Automatic permissions** for sensitive configuration files
- **Graceful fallbacks** for missing credentials

### Access Control
- **Multi-environment isolation** (dev, test, prod)
- **Node-specific security** configurations
- **SSH key management** and distribution

## 📖 Related Documentation

- **Testing Infrastructure**: See `../dev/testing.md` for comprehensive testing framework documentation
- **Developers**: See `../dev/` for integration and architecture details
- **Infrastructure Teams**: See `../iac/` for deployment automation
- **End Users**: See `../user/` for user-facing procedures

## Common Tasks
- Start with the quick-start or workflow sections in this file.
- From repo root, run `./go doctor` and `./go validate` after changes.

## Troubleshooting
- Confirm commands are run from the expected directory (usually repo root).
- Check generated logs under `.log/` and rerun `./go doctor` for diagnostics.
