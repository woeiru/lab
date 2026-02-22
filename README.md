# lab

Bash-based infrastructure automation platform for managing Proxmox VE clusters, containers, GPU passthrough, and multi-environment deployments. Pure Bash (4+), no external build system.

## Quick Start

```bash
# initialize shell integration (one-time setup)
./go init

# enable / disable integration
./go on
./go off

# check status
./go status

# run tests
./go validate
```

After running `./go on` and restarting your shell, all core modules and library functions are loaded automatically into every session.

## Requirements

- Bash 4+ or Zsh 5+
- Linux (developed on Proxmox VE / Debian)
- Standard UNIX utilities, systemd

## Repository Structure

```
lab/
├── go              Main CLI entry point
├── bin/
│   ├── ini         System initialization controller
│   └── orc         Component orchestrator (sequential module loader)
├── cfg/
│   ├── core/       Runtime constants, module dependencies, environment config
│   ├── ali/        Shell aliases (static and dynamic)
│   ├── env/        Environment definitions (site/env/node hierarchy)
│   ├── log/        Logging pipeline configs (Fluentd, Filebeat)
│   └── pod/        Container definitions
├── lib/
│   ├── core/       Foundational modules (col, err, lo1, tme, ver)
│   ├── gen/        General utilities (ana, aux, env, inf, sec)
│   └── ops/        Operational modules (dev, gpu, net, pbs, pve, srv, ssh, sto, sys, usr)
├── src/
│   ├── dic/        Dependency injection container
│   └── set/        Section-based deployment scripts
├── val/
│   ├── helpers/    Test framework
│   ├── core/       Core module tests
│   ├── lib/        Library tests
│   ├── integration/ Workflow tests
│   └── src/        DIC tests
├── doc/            Technical documentation (admin, CLI, dev, IaC, issues)
├── utl/            Utilities (doc generators, stats, alias tools)
└── arc/            Archive (fix guides, how-tos, network docs, AI strategy)
```

## Architecture

### Initialization Chain

```
./go init  -->  bin/ini  -->  bin/orc
                  │              │
                  │              ├── cfg/ali      (aliases)
                  │              ├── lib/ops      (operational modules)
                  │              ├── lib/gen      (general utilities)
                  │              ├── cfg/env      (environment config)
                  │              └── src/         (DIC + deployment)
                  │
                  ├── cfg/core/ric   (runtime constants)
                  ├── cfg/core/rdc   (runtime dependencies)
                  ├── cfg/core/mdc   (module dependencies)
                  └── lib/core/      (col, err, lo1, tme, ver)
```

`bin/ini` loads core configuration and modules first, then hands off to `bin/orc` which sources the remaining components in order. Each component is optional and timed.

### Core Modules (`lib/core/`)

| Module | Purpose |
|--------|---------|
| `col`  | Terminal color management with semantic palette and depth-based Viridis scale |
| `err`  | Error handling with codes, stack traces, error tracking, and ERR trap |
| `lo1`  | Logging with depth-based indentation, call stack analysis, and caching |
| `tme`  | Performance timing with nested timer hierarchy, tree reports, and sort modes |
| `ver`  | Verification of paths, variables, modules, and functions with dependency checks |

### General Utilities (`lib/gen/`)

| Module | Purpose |
|--------|---------|
| `ana`  | Code analysis: list functions, documentation, config variable usage (table + JSON) |
| `aux`  | Swiss-army helper: validation, checks, safe execution, structured logging, user input, tracing |
| `env`  | Environment switching: `env_switch`, `env_site_switch`, `env_status`, `env_validate` |
| `inf`  | Infrastructure config: container/VM definition with 19+ params, bulk creation, IP sequencing |
| `sec`  | Security: password generation (`/dev/urandom`), secure storage (chmod 600), no hardcoded secrets |

### Operational Modules (`lib/ops/`)

Ten domain-specific modules following strict naming and standards defined in `.spec` (958 lines) and `.guide` (303 lines):

| Module | Domain |
|--------|--------|
| `pve`  | Proxmox VE management |
| `gpu`  | GPU passthrough (detach/attach/status) |
| `sys`  | System operations (packages, users, hosts) |
| `net`  | Network configuration and routing |
| `sto`  | Storage management (Btrfs, ZFS, LVM) |
| `ssh`  | SSH configuration and key management |
| `pbs`  | Proxmox Backup Server |
| `srv`  | Service management |
| `dev`  | Development utilities |
| `usr`  | User account management |

All ops functions are stateless and parameterized. They follow the `module_name` convention (e.g., `gpu_ptd`, `pve_cdo`) and support `--help`, structured logging via `aux_info/warn/err/dbg`, and consistent return codes (`0` success, `1` usage error, `2` runtime failure, `127` missing command).

### Dependency Injection Container (`src/dic/`)

The DIC bridges stateless library functions with environment context. Instead of passing infrastructure parameters manually, the DIC resolves them automatically.

```bash
# direct library call (explicit parameters)
gpu_ptd "0000:01:00.0" "vfio-pci"

# DIC call (parameters resolved from environment)
ops gpu ptd
```

Three execution modes:
- **Hybrid** (default): user-supplied args supplemented by DIC resolution
- **Injection** (`-j`): full parameter resolution from environment
- **Explicit** (`-x`): function handles its own parameter sourcing

Resolution order: User Args > Hostname-specific vars > Global env vars > Function defaults.

### Environment Hierarchy

Configuration cascades through three layers:

```
cfg/env/site1          Base site configuration
    |
cfg/env/site1-dev      Environment override (dev/staging/prod)
    |
cfg/env/site1-w2       Node-specific settings (per hostname)
```

Switch environments at runtime with `env_switch`, `env_site_switch`, or `env_node_switch`.

### Deployment Scripts (`src/set/`)

Section-based scripts for orchestrating multi-step deployments:

```bash
# h1 = hypervisor setup script
# each letter is a section (a, b, c, ...)
src/set/h1    # interactive menu
```

Sections group related `ops` DIC calls into sequential operations (e.g., configure repos, install packages, setup networking, generate keys).

## Testing

```bash
# run everything
./val/run_all_tests.sh

# run by category
./val/run_all_tests.sh core
./val/run_all_tests.sh lib
./val/run_all_tests.sh integration
./val/run_all_tests.sh src

# list available tests
./val/run_all_tests.sh --list

# quick mode (skip slow tests)
./val/run_all_tests.sh --quick

# run a single test directly
./val/core/config/cfg_test.sh
./val/lib/ops/sys_test.sh

# library-specific runner with grouping
./val/lib/run_all_tests.sh --core
./val/lib/run_all_tests.sh --ops --gen
```

The test framework (`val/helpers/test_framework.sh`) provides `run_test`, `test_function_exists`, `test_file_exists`, `test_var_set`, `test_with_timeout`, `run_test_group`, BDD-style helpers, and color-coded output.

## Function Conventions

Functions are self-documenting. Three comment lines above a function definition are extractable as usage help via `aux_use`. A comment block inside the function body is extractable as technical docs via `aux_tec`.

```bash
# Create a container on the target node
# Usage: pve_cdo <vmid> <hostname> <ip>
# Returns: 0 on success, 2 on failure
pve_cdo() {
    # Technical: Uses pct create with template from CT_TEMPLATE
    # Validates VMID range 100-999 before execution
    # Requires: pct, pvesh
    ...
}
```

Naming: `module_name` for public functions, `_module_name` for internal helpers. All use `snake_case` and `local` for variables.

## Documentation

Detailed docs live in `doc/` organized by audience:

| Directory | Contents |
|-----------|----------|
| `doc/adm/` | Configuration and security administration |
| `doc/cli/` | Initialization flow and verbosity controls |
| `doc/dev/` | Function standards, logging, variables |
| `doc/iac/` | Deployment procedures and environment management |
| `doc/issue/` | Tracked issues and known bugs |

Additional references:
- `lib/ops/.spec` -- mandatory technical standards for ops modules
- `lib/ops/.guide` -- quality best practices and implementation checklist
- `arc/fix/` -- hardware-specific fix guides (AMDGPU, NVIDIA, GPU passthrough)
- `arc/how/` -- setup how-tos (sudoers, btrfs/snapper, git auth)

## Project Stats

<!-- AUTO-GENERATED SECTION: System Metrics -->
*Auto-updated system metrics with real-time analysis*

> **Last Updated**: 2026-02-15 22:44:20
> **Generated By**: `utl/doc/generators/stats`

| Directory | Files | Subdirs | Size (KB) |
| :--- | :---: | :---: | ---: |
| lib/core        |     5 |       1 |        84 |
| lib/ops         |    12 |       1 |       544 |
| lib/gen         |     5 |       1 |       132 |
| src/dic         |    10 |       4 |       192 |
| cfg/core        |     4 |       1 |        24 |
| cfg/pod         |     7 |       3 |        56 |
| utl/doc         |    13 |       5 |       108 |
| arc/ans         |     6 |       2 |        32 |
| arc/too         |    11 |       3 |        68 |
| val/core        |     6 |       4 |        64 |
| val/lib         |    23 |       4 |       252 |
| :--- | :---: | :---: | ---: |
| **TOTAL          ** | **  102** | **     29** | **     1556** |
<!-- END AUTO-GENERATED SECTION -->

Regenerate with `./utl/doc/generators/stats`.
