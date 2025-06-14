# Configuration Directory

The `cfg/` directory serves as the central configuration management hub for the entire infrastructure system. It contains environment-specific settings, automation configurations, system aliases, and deployment parameters organized in a hierarchical structure for maximum flexibility and maintainability.

## 🗂️ Directory Structure

```
cfg/
├── ali/          # Alias Management
├── core/         # Core System Configuration Controllers  
├── env/          # Environment-Specific Configurations
├── log/          # Logging System Configuration
└── pod/          # Container/Pod Configuration
```

## 📁 Subdirectories

### 🔗 `ali/` - Alias Management
Manages system aliases for improved command-line efficiency and standardization.

- **`dyn`** - Dynamically generated aliases (auto-updated by scripts)
- **`sta`** - Static aliases for consistent command shortcuts

**Purpose**: Centralizes command aliases for consistent user experience across different environments and provides dynamic alias generation for project-specific shortcuts.

### 🏗️ `core/` - Core System Configuration Controllers
Central control files that manage system-wide configuration parameters and initialization.

- **`ecc`** - Environment Configuration Controller (primary environment selector)
- **`mdc`** - Module/Management Configuration Controller
- **`rdc`** - Resource/Deployment Configuration Controller
- **`ric`** - Runtime/Infrastructure Configuration Controller

**Purpose**: Provides centralized control points for system-wide configuration management, ensuring consistent environment setup and resource allocation.

### 🌍 `env/` - Environment-Specific Configurations
Site and environment-specific configuration files that define parameters for different deployment targets.

- **`site1`** - Production site configuration
- **`site1-dev`** - Development environment configuration
- **`site1-w2`** - Workstation/testing environment configuration

**Purpose**: Enables multi-environment support with environment-specific variables, allowing the same codebase to operate across development, testing, and production environments.

### 📊 `log/` - Logging System Configuration
Configuration files and documentation for the enhanced auxiliary logging system.

- **`fluentd.conf`** - Fluentd configuration for centralized log collection
- **`filebeat.yml`** - Elastic Filebeat configuration for shipping to Elastic Stack
- **`usage_examples.md`** - Implementation examples and deployment patterns
- **`enhanced_logging_dev_summary.md`** - Complete development summary and technical details
- **`enhanced_logging_next_steps.md`** - Optional enhancement roadmap

**Purpose**: Provides ready-to-deploy configurations for enterprise-grade structured logging with cluster metadata support. Integrates with the enhanced auxiliary logging system (`lib/gen/aux`) to enable centralized log aggregation across distributed environments.

### 🐳 `pod/` - Container/Pod Configuration
Configuration files for containerized applications and pod deployments.

- **`qdev/`** - Development container configurations
- **`shus/`** - Production container configurations

**Purpose**: Manages container-specific configurations and deployment parameters for various containerized workloads.

## 🔧 Key Features

### Hierarchical Configuration Management
- **Environment-First Design**: Configurations cascade from environment-specific to component-specific
- **Modular Architecture**: Each subdirectory handles specific configuration domains
- **Cross-Reference Support**: Configurations can reference and inherit from other configuration files

### Dynamic Configuration Generation
- **Auto-Generated Aliases**: Dynamic alias generation based on project structure
- **Environment Detection**: Automatic environment detection and configuration loading
- **Template-Based Configs**: Template-driven configuration file generation

### Multi-Environment Support
- **Site Separation**: Distinct configurations for different sites and environments
- **Development Workflows**: Specialized configurations for development and testing
- **Production Ready**: Production-grade configuration management with validation

## 🚀 Usage Guidelines

### Configuration Loading Order
1. **Core Controllers** (`core/`) - Load system-wide parameters
2. **Environment Selection** (`env/`) - Apply environment-specific settings
3. **Specialized Configs** (`ans/`, `pod/`) - Load component-specific configurations
4. **Aliases** (`ali/`) - Apply command shortcuts and conveniences

### Environment Selection
Use the Environment Configuration Controller (`core/ecc`) to select and configure the target environment:

```bash
# Environment selection is handled automatically during initialization
# Manual override can be done by modifying core/ecc
```

### Adding New Configurations
1. **Environment Configs**: Add new files to `env/` following the site naming convention
2. **Container Configs**: Create new subdirectories in `pod/` for new container types
3. **Aliases**: Add static aliases to `ali/sta` or let dynamic generation handle project-specific ones

## 🔐 Security Considerations

- **Sensitive Data**: Avoid storing passwords or secrets directly in configuration files
- **Environment Isolation**: Ensure development configurations don't leak into production
- **Access Control**: Maintain appropriate file permissions for configuration files
- **Version Control**: Use git for configuration version management and change tracking

## 🔗 Integration Points

### Core System Integration
- **Initialization**: Loaded during system initialization via `bin/ini`
- **Library Integration**: Used by modules in `lib/` for environment-aware operations
- **Management Tools**: Referenced by DIC operations in `src/dic/` for operational tasks

### External Dependencies
- **Container Runtime**: Required for pod configurations (Podman/Docker)
- **Shell Environment**: Bash shell required for alias and environment configurations

## 📊 Maintenance

### Regular Tasks
- **Update Environment Configs**: Keep environment-specific settings current
- **Regenerate Dynamic Aliases**: Refresh auto-generated aliases when project structure changes
- **Review Access Permissions**: Ensure configuration files have appropriate security settings

### Troubleshooting
- **Environment Issues**: Check `core/ecc` for correct environment selection
- **Alias Problems**: Verify both `ali/sta` and `ali/dyn` are loading correctly
- **Container Issues**: Validate `pod/` configurations and Containerfile syntax

## 📈 Best Practices

1. **Consistency**: Maintain consistent naming conventions across all configuration files
2. **Documentation**: Document configuration changes and their impact
3. **Testing**: Test configuration changes in development before production deployment
4. **Backup**: Maintain backups of critical configuration files
5. **Validation**: Implement configuration validation where possible
6. **Modularity**: Keep configurations modular and loosely coupled for easier maintenance

---

> **Note**: This configuration directory is central to the entire system operation. Changes should be made carefully and tested thoroughly in non-production environments first.

---

**Navigation**: Return to [Main Lab Documentation](../README.md)
