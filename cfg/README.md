# Configuration Directory (`cfg/`)

**The State Layer:** The `cfg/` directory serves as the central source of truth for the system's state. It contains environment-specific settings, system aliases, and core parameters organized in a cascading hierarchy. By isolating all environment-specific data here, the operational logic in `lib/ops/` remains completely stateless and portable.

## Directory Structure

```text
cfg/
├── ali/    # Alias Management (Static and Dynamic)
├── core/   # Core System Configuration Controllers
├── env/    # Environment-Specific Configurations
├── log/    # Logging System Configuration
└── pod/    # Container/Pod Configuration
```

## Configuration Hierarchy

Configurations cascade through the system in a strict resolution order:
1. **Core Controllers (`cfg/core/`)**: Load system-wide parameters and initialization constants (`ecc`, `mdc`, `rdc`, `ric`).
2. **Environment Selection (`cfg/env/`)**: Apply settings specific to the active environment defined in the `ecc` (Environment Configuration Controller). This is where site-bases and environment overrides exist.
3. **Specialized Configs (`cfg/pod/`)**: Load component-specific configurations (e.g., container or specialized pod deployments).
4. **Aliases (`cfg/ali/`)**: Apply command shortcuts and conveniences.

## Key Concepts

### Hostname Prefixing
Environment configuration relies heavily on hostname prefixing to map declarative state to individual nodes in a multi-node cluster. Variables typically look like `${hostname}_VARIABLE_NAME` (e.g., `h1_NODE_PCI0`, `w2_USB_DEVICES`). The execution layer (`src/dic/`) automatically resolves these during runtime based on the target execution host.

### Declarative Data
Complex configurations are often defined using Bash arrays. The framework automatically parses arrays into manageable parameter lists for operational tools.

### Security Notice
**Do not hardcode secrets here.** The `cfg/` directory is meant for non-sensitive declarative state. Use the secure utilities found in `lib/gen/sec` or a dedicated secrets manager to handle sensitive material like credentials and API keys.

## Further Reading

For detailed guides on how to properly set up environment configurations and structure variables, refer to the documentation:

- **Manual:** [02 - Configuration](../doc/man/02-configuration.md)
- **Architecture:** [05 - Deployment and Config](../doc/arc/05-deployment-and-config.md)
- **Reference:** [Variables Usage Reference](../doc/ref/variables.md)

---
**Navigation**: Return to [Main Lab Documentation](../README.md)
