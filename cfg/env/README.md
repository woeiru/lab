# Environment-Specific Configurations (`cfg/env/`)

## 📋 Overview

The `cfg/env/` directory contains environment-specific configuration files that provide tailored settings for different deployment environments. Each configuration file represents a complete environment definition with specific infrastructure settings, network configurations, and operational parameters.

## 🗂️ Directory Contents

### 🏢 `site1` - Base Site Configuration
Primary site configuration providing the foundational infrastructure definitions and baseline settings for the main deployment environment.

**Key Configuration Areas:**
- **Infrastructure Definitions**: Core infrastructure topology and resource allocation
- **Network Configuration**: Base network settings and connectivity parameters
- **Service Definitions**: Primary service configurations and deployment parameters
- **Security Settings**: Baseline security policies and access controls

### 🧪 `site1-dev` - Development Environment Configuration
Development environment configuration extending `site1` with development-specific settings, debugging features, and testing capabilities.

**Key Configuration Areas:**
- **Development Tools**: Enhanced debugging and development utilities
- **Testing Infrastructure**: Test environment resource allocation
- **Debug Settings**: Verbose logging and debugging configurations
- **Sandbox Isolation**: Safe development environment isolation

### 💼 `site1-w2` - Workstation 2 Environment Configuration
Specialized workstation configuration for secondary development and testing environments with specific hardware and performance optimizations.

**Key Configuration Areas:**
- **Hardware Optimization**: Workstation-specific performance tuning
- **Development Workflow**: Tailored development environment setup
- **Resource Allocation**: Optimized resource distribution for workstation use
- **Integration Settings**: Specific integration points for workstation workflows

## 🚀 Configuration Architecture

### Environment Hierarchy
Environment configurations follow an inheritance and override pattern:

```bash
# Configuration inheritance pattern
site1           # Base configuration (foundation)
├── site1-dev  # Development overrides and extensions
└── site1-w2   # Workstation-specific adaptations
```

### Loading Mechanism
Environment configurations are dynamically loaded based on the active environment:

```bash
# Environment-specific loading
source cfg/env/site1      # Base environment
source cfg/env/site1-dev  # Development extensions (if in dev mode)
```

## 🔧 Configuration Patterns

### Base Environment (site1)
Provides comprehensive infrastructure configuration including:
- **Network Topology**: VLAN definitions, bridge configurations, network addressing
- **Storage Layout**: ZFS pool configurations, dataset definitions, backup strategies
- **Service Definitions**: Container configurations, service orchestration, monitoring setup
- **Security Policies**: Firewall rules, access controls, certificate management

### Development Environment (site1-dev)
Extends base configuration with development-specific features:
- **Debug Capabilities**: Enhanced logging, verbose output, debugging tools
- **Testing Infrastructure**: Test containers, validation scripts, performance profiling
- **Development Tools**: IDE integration, code analysis, automated testing
- **Sandbox Features**: Isolated testing, safe experimentation, rollback capabilities

### Workstation Environment (site1-w2)
Specialized configuration for workstation environments:
- **Hardware Optimization**: GPU passthrough, storage optimization, performance tuning
- **User Experience**: Desktop integration, convenience features, workflow optimization
- **Resource Management**: Efficient resource utilization, power management, thermal control
- **Development Workflow**: Specialized development environment, tool integration

## 🔗 Integration Points

### System Integration
- **Core Configuration**: Builds upon `cfg/core/` foundation constants
- **Operations Libraries**: Environment-specific parameters for `lib/ops/` modules
- **Deployment Scripts**: Configuration consumed by `src/set/` deployment scripts
- **Management Layer**: Environment awareness in `src/mgt/` management scripts

### Dynamic Behavior
```bash
# Environment-aware operations
gpu-ptd "01:00.0" "x1" "cfg/env/site1" "0000:01:00.0" "0000:01:00.1" "nvidia"
pve-node-deploy "site1-dev"
storage-setup "site1-w2"
```

## 📊 Configuration Management

### Environment Switching
- **Dynamic Detection**: Automatic environment detection based on system characteristics
- **Manual Override**: Explicit environment specification for testing and development
- **Validation Checks**: Configuration validation before environment activation
- **Rollback Support**: Safe rollback to previous environment configuration

### Configuration Validation
```bash
# Environment validation pattern
1. Syntax validation of configuration files
2. Dependency checking for required resources
3. Compatibility verification with system capabilities
4. Integration testing with dependent services
```

## 🔐 Security Considerations

### Environment Isolation
- **Sandbox Boundaries**: Clear isolation between different environments
- **Access Controls**: Environment-specific access control policies
- **Secret Management**: Secure handling of environment-specific secrets
- **Audit Logging**: Comprehensive logging of environment-specific operations

### Security Policies
- **Network Security**: Environment-specific firewall rules and network policies
- **Access Management**: Role-based access control for different environments
- **Data Protection**: Environment-appropriate data protection measures
- **Compliance**: Environment-specific compliance and regulatory requirements

## 🧪 Development Guidelines

### Configuration Development
- **Incremental Development**: Small, testable configuration changes
- **Environment Testing**: Thorough testing in target environment before deployment
- **Rollback Planning**: Clear rollback procedures for configuration changes
- **Documentation**: Comprehensive documentation of environment-specific settings

### Best Practices
- **Configuration Templates**: Standardized templates for new environments
- **Version Control**: All environment configurations under version control
- **Change Management**: Formal change management for production environments
- **Monitoring**: Continuous monitoring of configuration effectiveness

### Environment Lifecycle
```bash
# Environment lifecycle management
1. Environment planning and design
2. Configuration development and testing
3. Deployment and validation
4. Monitoring and maintenance
5. Updates and optimization
6. Decommissioning and cleanup
```

---

**Navigation**: Return to [Configuration Management](../README.md) | [Main Lab Documentation](../../README.md)
