# 03 - Environment and Configuration

The framework utilizes a hierarchical, cascading configuration system located inside the `cfg/` directory. Configuration dictates what parameters the Dependency Injection Container (DIC) will use when executing operational modules.

There are no hardcoded hostnames or IPs in the scripts themselves; everything is defined in the configuration environment.

## The Configuration Hierarchy

The framework uses three cascading layers of state:

1. **`cfg/core/ecc` (Environment Configuration Controller):** The global toggle that sets the active context (Site, Environment, and Node).
2. **`cfg/env/<site_name>` (Base Site Configuration):** The foundational configuration for a specific physical location or cluster.
3. **`cfg/env/<site_name>-<env>` (Environment Override):** Environment-specific overrides (e.g., `dev`, `staging`, `prod`).

## 1. Setting the Active Context

Before executing any commands, the system needs to know *where* it is operating. This is configured in `cfg/core/ecc`.

The essential variables are:
- `SITE_NAME`: The identifier for your infrastructure (e.g., `site1`).
- `ENVIRONMENT_NAME`: The tier (e.g., `dev`, `prod`).
- `NODE_NAME`: The specific machine name. This is automatically detected via the `hostname` command, but can be overridden.

You can switch environments interactively at runtime using the `env_switch`, `env_site_switch`, or `env_node_switch` functions (provided by the `lib/gen/env` module). Alternatively, you can run `env_status` to see your current context.

## 2. Defining Infrastructure State

The actual state of your infrastructure is defined in the environment files (e.g., `cfg/env/site1`). These are plain Bash scripts sourced by the orchestrator.

### Hostname-Specific Variables

Because a single site file often describes a multi-node cluster, the framework uses a variable prefixing convention based on the short hostname.

For example, if your cluster has nodes `h1` and `w2`, your `site1` file might look like this:

```bash
# Node h1 specific configuration
h1_NODE_PCI0="0000:01:00.0"
h1_USB_DEVICES=("1234:5678" "abcd:ef01")

# Node w2 specific configuration
w2_NODE_PCI0="0000:3b:00.0"
w2_CORE_COUNT_ON=10
```

When the framework runs on `h1`, the DIC will automatically resolve `NODE_PCI0` to `"0000:01:00.0"`.

### Declarative Arrays and Defaults

Complex configurations, such as container or virtual machine definitions, are typically handled via Bash arrays and declarative functions.

```bash
# Example from an environment file defining Proxmox containers
h1_CT_TEMPLATE="local:vztmpl/debian-12-standard.tar.zst"

# A declarative function often used to group definitions
set_container_defaults() {
    local -A ctd=()
    ctd[vmid]="100"
    ctd[hostname]="web01"
    ctd[ip]="192.168.1.100"
    # ...
}
```

## 3. Creating a New Environment

To provision a completely new infrastructure environment:

1. Copy an existing environment file in `cfg/env/` to a new name (e.g., `cp cfg/env/site1 cfg/env/site2`).
2. Adjust the hardware, networking, and service variables inside the new file. Use the short hostname of the target machines as variable prefixes (e.g., `newnode1_...`).
3. Update `cfg/core/ecc` to point `SITE_NAME` to `site2`.
4. Re-source the framework (e.g., by running `lab`) to load the new configuration.

Continue to [04 - CLI Usage and the DIC](04-cli-usage.md) to see how the framework executes commands using this configuration.
