# Configuration Directory (`cfg/`)

The `cfg/` directory serves as the central configuration management hub for the infrastructure system. It contains environment-specific settings, system aliases, and core parameters organized in a hierarchical structure.

## Directory Structure

```text
cfg/
├── ali/    # Alias Management
├── core/   # Core System Configuration Controllers
├── env/    # Environment-Specific Configurations
├── log/    # Logging System Configuration
└── pod/    # Container/Pod Configuration
```

## Subdirectories

### `ali/` - Alias Management
Manages system aliases for command-line efficiency.
- **`dyn`**: Dynamically generated aliases (auto-updated by scripts).
- **`sta`**: Static aliases for consistent command shortcuts.

### `core/` - Core System Configuration Controllers
Central control files that manage system-wide configuration parameters and initialization.
- **`ecc`**: Environment Configuration Controller (primary environment selector).
- **`mdc`**: Module Dependencies Management.
- **`rdc`**: Runtime Dependencies Configuration.
- **`ric`**: Runtime Initialization Constants.

### `env/` - Environment-Specific Configurations
Site and environment-specific configuration files that define parameters for different deployment targets (e.g., `site1`, `site1-dev`).

### `log/` - Logging System Configuration
Configuration files and documentation for the enhanced auxiliary logging system (Fluentd, Filebeat).

### `pod/` - Container/Pod Configuration
Configuration files for containerized applications and pod deployments (e.g., `qdev`, `shus`).

## Configuration Hierarchy

Configurations cascade through the system in a specific order:
1. **Core Controllers (`core/`)**: Load system-wide parameters and initialization constants.
2. **Environment Selection (`env/`)**: Apply settings specific to the active environment defined in `ecc`.
3. **Specialized Configs (`pod/`)**: Load component-specific configurations.
4. **Aliases (`ali/`)**: Apply command shortcuts and conveniences.

---

**Navigation**: Return to [Main Lab Documentation](../README.md)
