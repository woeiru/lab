# Management Scripts (`src/mgt/`)

## 📋 Overview

The `src/mgt/` directory contains environment-aware management scripts that provide operational control interfaces for complex infrastructure components. These scripts serve as intelligent wrappers around core operations libraries, offering simplified, environment-aware access to advanced system management capabilities.

## 🗂️ Directory Contents

### 🎮 `gpu` - GPU Management Wrapper Scripts
Environment-aware GPU management interface providing simplified access to GPU passthrough and virtualization operations.

**Key Features:**
- **Wrapper Functions**: 9 environment-aware wrapper functions with `-w` suffix
- **Simplified Interface**: Easy-to-use commands for complex GPU operations
- **Environment Integration**: Automatic environment detection and configuration
- **Safety Controls**: Built-in validation and safety mechanisms

**Available Management Functions:**
```bash
# GPU management wrappers (examples)
gpu-status-w          # Environment-aware GPU status checking
gpu-passthrough-w     # Simplified GPU passthrough setup
gpu-reset-w          # Safe GPU reset operations
gpu-assignment-w     # VM GPU assignment management
```

### 🖥️ `pve` - Proxmox VE Management Wrapper Scripts
Proxmox Virtual Environment management interface providing streamlined access to cluster operations and VM management.

**Key Features:**
- **Cluster Management**: Simplified cluster node operations
- **VM Lifecycle**: Easy VM creation, management, and migration
- **Environment Awareness**: Automatic environment-specific configuration
- **Operations Wrapping**: User-friendly interface to complex PVE operations

**Management Capabilities:**
```bash
# PVE management operations (examples)
pve-cluster-status-w   # Environment-aware cluster status
pve-vm-deploy-w       # Simplified VM deployment
pve-node-maintenance-w # Node maintenance operations
pve-backup-schedule-w  # Backup scheduling management
```

## 🚀 Architecture & Design

### Wrapper Function Pattern
Management scripts follow a consistent wrapper architecture:

```bash
# Wrapper function pattern
function operation-name-w() {
    # 1. Environment detection and validation
    # 2. Parameter processing and defaults
    # 3. Safety checks and prerequisites
    # 4. Call to underlying lib/ops/ function
    # 5. Result processing and user feedback
}
```

### Integration Architecture
```
User Commands
     ↓
src/mgt/[module] (Management Layer)
     ↓
lib/ops/[module] (Operations Layer)
     ↓
System/Hardware (Infrastructure Layer)
```

### Environment Awareness
Management scripts automatically adapt to the current environment:
- **Configuration Loading**: Automatic loading of environment-specific settings
- **Parameter Defaults**: Environment-appropriate default parameters
- **Validation Rules**: Environment-specific validation and safety checks
- **Operational Modes**: Behavior adaptation based on environment characteristics

## 🔧 Usage Guidelines

### Accessing Management Functions
Management functions are automatically available after system initialization:

```bash
# System initialization loads management scripts
source bin/init

# Management functions immediately available
gpu-status-w
pve-cluster-status-w
```

### Command Patterns
All management commands follow consistent naming and usage patterns:
- **Suffix Convention**: All wrapper functions end with `-w`
- **Intuitive Naming**: Commands named for their primary function
- **Help Integration**: Built-in help and usage information
- **Error Reporting**: Clear, actionable error messages

### Environment Integration
```bash
# Environment-specific behavior
# In development environment:
gpu-passthrough-w --mode development --verbose

# In production environment:
gpu-passthrough-w --mode production --silent
```

## 🔗 Integration Points

### Core Integration
- **Operations Libraries**: Direct integration with `lib/ops/` for core functionality
- **Configuration System**: Automatic loading of environment-specific settings from `cfg/env/`
- **Error Handling**: Comprehensive error handling via `lib/core/err`
- **Logging Integration**: Full logging integration with `lib/core/lo1`

### System Dependencies
- **Binary System**: Management scripts loaded via `bin/core/comp` component orchestrator
- **Configuration Access**: Direct access to `cfg/core/ric` runtime initialization constants
- **Environment Detection**: Integration with `lib/utl/env` for environment awareness

### Operational Integration
```bash
# Management scripts integrate with deployment
source src/mgt/gpu    # GPU management capabilities
source src/mgt/pve    # PVE management capabilities

# Direct function calls
gpu-passthrough-w "device-id" "vm-id"
pve-vm-create-w "vm-name" "template"
```

## 📊 Performance & Optimization

### Operational Efficiency
- **Lazy Loading**: Management functions loaded on-demand
- **Parameter Optimization**: Intelligent parameter defaults and validation
- **Batch Operations**: Support for bulk operations where applicable
- **Resource Management**: Efficient resource utilization and cleanup

### User Experience Optimization
- **Command Simplification**: Complex operations simplified to single commands
- **Context Awareness**: Automatic detection of operational context
- **Error Prevention**: Proactive validation to prevent common errors
- **Feedback Quality**: Clear, informative feedback and progress reporting

## 🔐 Security Considerations

### Access Control
- **Privilege Validation**: Verification of required permissions before operations
- **Environment Isolation**: Proper isolation between different environments
- **Operation Auditing**: Comprehensive logging of all management operations
- **Safe Defaults**: Conservative default settings for security-sensitive operations

### Risk Management
- **Operation Validation**: Pre-operation validation and safety checks
- **Rollback Capability**: Automatic rollback mechanisms for failed operations
- **Impact Assessment**: Analysis of potential operation impacts before execution
- **Emergency Procedures**: Built-in emergency stop and recovery procedures

## 🧪 Development & Maintenance

### Development Standards
- **Wrapper Consistency**: Consistent interface and behavior across all wrappers
- **Documentation Integration**: Comprehensive inline documentation
- **Testing Requirements**: Thorough testing of all management functions
- **Error Handling**: Robust error handling and user feedback

### Maintenance Procedures
- **Regular Updates**: Regular updates to match underlying operations library changes
- **Compatibility Testing**: Testing across all supported environments
- **Performance Monitoring**: Monitoring and optimization of management function performance
- **User Feedback Integration**: Incorporation of user feedback into management interface improvements

---

**Navigation**: Return to [Source Code](../README.md) | [Main Lab Documentation](../../README.md)
