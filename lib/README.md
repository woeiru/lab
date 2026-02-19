# Library Modules (`lib/`)

## Navigation
- [Repository Root](../README.md)
- [Documentation Hub](../doc/README.md)

Shell library layer for runtime services, infrastructure operations, and shared generators.

This folder provides:
- Core runtime modules used during bootstrap (`lib/core/*`).
- Domain operation libraries used by DIC dispatch (`lib/ops/*`).
- Shared generator/helper libraries for config, security, and infrastructure data (`lib/gen/*`).

## Quick Start

Typical usage in this repository is through `./go` + runtime bootstrap:

```bash
# Initialize and enable shell integration
./go init
./go on

# Validate repository and test suite
./go doctor
./go validate
```

For direct operation dispatch (after runtime is loaded):

```bash
# Example DIC call into lib/ops
ops srv nfs_set -j
```

## Architecture At A Glance

Library execution path:

1. `bin/ini` initializes runtime modules.
2. `bin/orc` sources configuration, aliases, and libraries.
3. `src/dic/ops` resolves/injects parameters.
4. Target functions execute from `lib/ops/*`.

Library domains:

1. `lib/core/*`: foundational runtime services (error handling, logging, timing, verbosity).
2. `lib/ops/*`: operational domain functions (system, storage, network, GPU, PVE, services, users, etc.).
3. `lib/gen/*`: shared generators/utilities (environment, security, infra definitions, analysis helpers).

## Folder Layout

```text
lib/core/
  col  err  lo1  tme  ver

lib/ops/
  gpu  net  pbs  pve  srv  ssh  sto  sys  usr
  .spec  .guide  README.md

lib/gen/
  ana  aux  env  inf  sec
```

## Child READMEs

- Operations library: [lib/ops/README.md](./ops/README.md)

## Core Modules

Primary runtime services:

- `lib/core/err`: error and warning handling helpers.
- `lib/core/lo1`: logging and log control utilities.
- `lib/core/tme`: timing/performance measurement and reporting.
- `lib/core/ver`: verbosity control.
- `lib/core/col`: terminal color helpers.

## Operations Modules

`lib/ops/*` contains operational functions called via DIC and playbooks.

Examples:
- `lib/ops/srv`: service operations (including NFS/SMB related functions).
- `lib/ops/pve`: Proxmox operations.
- `lib/ops/gpu`: GPU and passthrough helpers.
- `lib/ops/sys`, `lib/ops/net`, `lib/ops/sto`, `lib/ops/usr`, `lib/ops/ssh`, `lib/ops/pbs`.

Detailed ops architecture:
- `lib/ops/README.md`

## Generator Modules

Shared support libraries:

- `lib/gen/env`: environment loading/management helpers.
- `lib/gen/sec`: security and credential-related helpers.
- `lib/gen/inf`: infrastructure definition helpers.
- `lib/gen/aux`: auxiliary/shared utility functions.
- `lib/gen/ana`: analysis/helper tooling functions.

## Validation

Repository-level checks:

```bash
./go doctor
./go validate
```

Targeted library tests:

```bash
./val/run_all_tests.sh lib
./val/run_all_tests.sh --list
```

## Related Docs

- `README.md` (repository entrypoint and workflow)
- `doc/arc/architecture-map.md` (runtime architecture map)
- `doc/dev/functions.md` (function reference)
- `doc/iac/deployment.md` (playbook/deployment usage)
- `lib/ops/README.md` (ops-specific architecture details)

## Notes

- `lib/` is sourced Bash code, not a compiled package.
- Preferred operational entrypoint is `ops ...` via runtime bootstrap, not direct ad-hoc sourcing.
- Keep new library functions parameterized and compatible with DIC dispatch patterns in `src/dic/ops`.

## Common Tasks
- Start with the quick-start or workflow sections in this file.
- From repo root, run `./go doctor` and `./go validate` after changes.

## Troubleshooting
- Confirm commands are run from the expected directory (usually repo root).
- Check generated logs under `.log/` and rerun `./go doctor` for diagnostics.
