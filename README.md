# lab

Bash-native infrastructure automation framework. No external tooling, no build system, no dependencies beyond coreutils. Manages real infrastructure -- virtual machines, GPUs, networking, storage, and system services -- through pure, stateless functions wired together at runtime by a purpose-built Dependency Injection Container.

Ships with 20 composable library modules across three tiers (core, general, ops), a hierarchical configuration system with hostname-aware parameter resolution, section-based deployment runbooks, and a full BDD-style test harness.

## Quick Start

```bash
# one-time setup -- injects helper functions into ~/.bashrc
./go init

# enable auto-load in every new shell
lab-on

# or activate in current shell only (no bashrc change)
lab

# check framework status
./go status

# run the test suite
./go validate
```

After `lab-on`, restart your shell. All modules and functions are loaded automatically. `lab-on` and `lab-off` can be run from any directory after `./go init`. Use `lab-off` to disable, `./go purge` to remove shell integration entirely.

## Requirements

- Bash 4+ (or Zsh 5+)
- Linux (developed on Debian; some modules target Proxmox VE)
- Standard UNIX utilities, systemd

## Repository Structure

```
lab/
├── go                CLI entrypoint
├── bin/
│   ├── ini           Initialization controller
│   └── orc           Component orchestrator
├── cfg/
│   ├── core/         Runtime constants and module dependencies
│   ├── ali/          Shell aliases (static and dynamic)
│   ├── env/          Environment definitions (site / env / node hierarchy)
│   ├── log/          Logging pipeline configs (Fluentd, Filebeat)
│   └── pod/          Container definitions
├── lib/
│   ├── core/         Foundational primitives (col, err, lo1, tme, ver)
│   ├── gen/          General utilities (ana, aux, env, inf, sec)
│   └── ops/          Operational modules (dev, gpu, net, pbs, pve, srv, ssh, sto, sys, usr)
├── src/
│   ├── dic/          Dependency injection container
│   └── set/          Section-based deployment runbooks
├── val/              BDD-style test framework and test suites
├── doc/              Architecture references, user guides, and auto-generated API docs
└── utl/              Out-of-band tooling (doc generators, analysis)
```

Most files under `lib/` and `bin/` have **no file extension** -- they are sourced Bash scripts, not standalone executables.

## How It Works

### Initialization Chain

```
./go  -->  bin/ini  -->  bin/orc
             |               |
             |               ├── cfg/ali      (aliases)
             |               ├── lib/ops      (operational modules)
             |               ├── lib/gen      (general utilities)
             |               ├── cfg/env      (environment config)
             |               └── src/         (DIC + deployment)
             |
             ├── cfg/core/    (runtime constants + dependencies)
             └── lib/core/    (col, err, lo1, tme, ver)
```

`bin/ini` loads core configuration and primitives first, then hands off to `bin/orc` which sources the remaining components in dependency order. Each component is optional and timed.

### Three-Layer Execution Model

The system separates **what** to do, **how** to resolve parameters, and **where** state lives:

```
  src/set/*  (deployment runbooks)
      |
      v
  src/dic/ops  (dependency injection)
      |
      v
  lib/ops/*  (pure functions)  <----  cfg/env/*  (environment state)
```

1. **Pure Functions** (`lib/ops/`) -- stateless, parameterized operations. Accept explicit arguments, return standardized codes, log through `aux_*` helpers.
2. **Dependency Injection** (`src/dic/`) -- analyzes function signatures, resolves parameters from the environment hierarchy, and injects them automatically.
3. **Deployment Runbooks** (`src/set/`) -- hostname-mapped scripts that group DIC calls into sequential sections with interactive or headless execution.

### The DIC in Practice

```bash
# direct call -- all parameters explicit
gpu_ptd "0000:01:00.0" "vfio-pci"

# DIC call -- parameters resolved from cfg/env/
ops gpu ptd -j
```

Three execution modes:
- **Hybrid** (default) -- user-supplied args supplemented by DIC resolution
- **Injection** (`-j`) -- full parameter resolution from environment
- **Explicit** (`-x`) -- function handles its own parameter sourcing

Run any `ops` command without arguments to see a parameter preview showing what will be injected and what requires manual input.

### Configuration Hierarchy

Environment state cascades through three layers:

```
cfg/env/site1          Base site configuration
    |
cfg/env/site1-dev      Environment override (dev / staging / prod)
    |
cfg/env/site1-w2       Node-specific settings (per hostname)
```

Variables use hostname prefixes for multi-node clusters (e.g., `h1_NODE_PCI0`, `w2_USB_DEVICES`). The DIC resolves them automatically based on the target host.

## Library Modules

### Core Primitives (`lib/core/`)

| Module | Purpose |
|--------|---------|
| `col`  | Terminal color management with semantic palette and depth-based Viridis scale |
| `err`  | Error handling with codes, stack traces, and ERR trap |
| `lo1`  | Logging with depth-based indentation and call stack analysis |
| `tme`  | Performance timing with nested hierarchy, tree reports, and sort modes |
| `ver`  | Verification of paths, variables, modules, and functions |

### General Utilities (`lib/gen/`)

| Module | Purpose |
|--------|---------|
| `ana`  | Code analysis: function listing, documentation, config variable usage |
| `aux`  | Validation, checks, safe execution, structured logging, tracing |
| `env`  | Environment switching and status (`env_switch`, `env_status`) |
| `inf`  | Infrastructure config: container/VM definitions, bulk creation, IP sequencing |
| `sec`  | Password generation, secure storage, no hardcoded secrets |

### Operational Modules (`lib/ops/`)

| Module | Domain |
|--------|--------|
| `dev`  | Development utilities |
| `gpu`  | GPU passthrough (detach / attach / status) |
| `net`  | Network configuration and routing |
| `pbs`  | Proxmox Backup Server |
| `pve`  | Proxmox VE management |
| `srv`  | Service management |
| `ssh`  | SSH configuration and key management |
| `sto`  | Storage management (Btrfs, ZFS, LVM) |
| `sys`  | System operations (packages, users, hosts) |
| `usr`  | User account management |

All ops functions follow strict standards defined in `lib/.spec` (canonical global + quality standards for all `lib/` modules) and `lib/ops/.spec` (ops/DIC-specific execution contract): three-letter prefix naming (`gpu_ptd`, `pve_cdo`), mandatory parameter validation, self-documenting comment blocks, structured `aux_*` logging, and standardized return codes (`0` success, `1` usage error, `2` runtime failure, `127` missing command).

## Testing

```bash
# full suite
./val/run_all_tests.sh

# by category
./val/run_all_tests.sh core
./val/run_all_tests.sh lib
./val/run_all_tests.sh integration
./val/run_all_tests.sh src

# options
./val/run_all_tests.sh --list       # list available tests
./val/run_all_tests.sh --quick      # skip slow tests
./val/run_all_tests.sh --verbose    # detailed output

# run a single test directly
./val/core/config/cfg_test.sh
./val/lib/ops/sys_test.sh

# library-specific runner with grouping
./val/lib/run_all_tests.sh --core
./val/lib/run_all_tests.sh --ops --gen
```

The test framework (`val/helpers/test_framework.sh`) provides `run_test`, `test_function_exists`, `test_file_exists`, `test_var_set`, `test_with_timeout`, BDD-style helpers, and color-coded output. Tests run in isolated temporary environments to prevent host contamination.

## Documentation

The `doc/` directory contains the full documentation set, organized by audience:

| Section | Audience | Contents |
|---------|----------|----------|
| [`doc/man/`](doc/man/) | Operators, admins | Operator manuals for installation, configuration, CLI, runbooks, module authoring, security, attribution, and planning workspace usage |
| [`doc/arc/`](doc/arc/) | Developers, architects | Architecture references for bootstrap, DI, deployment/config, validation, logging/error handling, workflow, and planning subsystem design |
| [`doc/ref/`](doc/ref/) | Module authors, agents | Auto-generated compressed reference maps (functions, variables, dependencies, tests, error handling) |
| [`doc/fix/`](doc/fix/) | Hardware ops | Incident runbooks: GPU passthrough, ACPI reset, driver fixes |
| [`wow/`](wow/) | Contributors | Project planning documents (inbox, active, completed, dismissed, experiments) |

Start with [doc/man/01-installation.md](doc/man/01-installation.md) for an operational walkthrough, or [doc/arc/00-architecture-overview.md](doc/arc/00-architecture-overview.md) for the system design.

Reference contract:
- `doc/ref/` is the canonical generated reference layer for fast codebase navigation and retrieval.
- `wow/` is planning state and is not a runtime/reference source.
- When reference docs and code disagree, treat source code as authoritative and regenerate reference docs.
- Regenerate with `./utl/doc/run_all_doc.sh` after structural changes.
- Generate repository metrics with `./utl/doc/run_all_doc.sh stats` (writes `STATS.md`).

Each subdirectory in the repository also has its own README with focused context and links into the relevant documentation.
