<!-- 
    This documentation provides comprehensive analysis of variable usage across the lab environment.
    Variables are analyzed from configuration files and their usage patterns across different modules.
    
    The analysis covers:
    - cfg/env/  : Environment-specific configuration files
    - lib/ops/  : Operations function libraries
    - src/set/  : Deployment and setup automation scripts
-->

# Variable Usage Documentation

Comprehensive analysis of environment variables and their usage patterns across the Lab Environment Management System.

## 📚 Variable Categories

Variables in the lab environment are organized into several categories:

### Environment Configuration (`cfg/env/`)
- **Site Configuration**: Site-specific settings and parameters
- **Environment Overrides**: Development, testing, and production overrides
- **Node Configuration**: Node-specific infrastructure settings

### Operations Integration (`lib/ops/`)
- **Infrastructure Functions**: Variables used in infrastructure management
- **System Operations**: Variables for system-level operations
- **Service Management**: Variables for service configuration and management

### Deployment Scripts (`src/set/`)
- **Deployment Parameters**: Variables used in deployment automation
- **Setup Configuration**: Variables for environment setup and initialization
- **Runtime Constants**: Variables for runtime behavior control

<!-- AUTO-GENERATED SECTION: DO NOT EDIT MANUALLY -->

<!-- END AUTO-GENERATED SECTION -->

## 🔧 Variable Analysis Tools

- **[`utl/doc-var`](../utl/doc-var)** - Updates this variable usage documentation automatically using `aux-acu`
- **[`lib/gen/aux` (aux-acu)](../lib/gen/aux)** - Variable usage analysis function with JSON output support
- **[`utl/doc-func`](../utl/doc-func)** - Function metadata table generator
- **[`utl/doc-index`](../utl/doc-index)** - Documentation index generator

```bash
# Update variable usage documentation
./utl/doc-var

# Analyze variable usage manually
aux-acu "" cfg/env lib/ops src/set

# Generate variable analysis as JSON
aux-acu -j "" cfg/env lib/ops src/set

# View specific variable usage patterns
aux-acu -a cfg/env lib/ops src/set  # Alphabetical order
```

## 📖 Related Documentation

- **[Functions Reference](functions.md)** - Pure function documentation and metadata
- **[System Architecture](architecture.md)** - Complete system design and variable flow
- **[Configuration Guide](../adm/configuration.md)** - Configuration file formats and variable definitions
