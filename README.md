# Lab Environment Management System

## Navigation
- [Repository Root](README.md)
- [Documentation Hub](doc/README.md)

Shell-based infrastructure automation for multi-environment lab operations.

This repository provides:
- A user-facing CLI (`./go`) for initialization, shell integration, health checks, and validation.
- A runtime bootstrap/orchestration path (`bin/ini` -> `bin/orc`) that loads config, ops libraries, and aliases.
- A DIC-driven operations layer (`src/dic/ops`) that dispatches into domain libraries (`lib/ops/*`).
- Playbook-style deployment scripts (`src/set/*`) for environment setup workflows.

## Quick Start

# 1) First-time setup (saves settings to .tmp/go_settings)
./go init

# 2) Enable shell integration
./go on

# 3) Confirm readiness
./go status

# 4) Run preflight checks
./go doctor

# 5) Run validation suite
./go validate

To disable shell integration later:

./go off

## CLI Commands

`./go help` shows full usage. Main commands:

- `init`: Configure and persist shell integration settings.
- `on`: Inject managed shell block into the configured shell rc file.
- `off`: Remove managed shell block from the configured shell rc file.
- `status`: Check initialization state and integration status.
- `doctor`: Run bootstrap preflight checks (repo layout, deps, key mappings).
- `validate`: Run the validation/test runner.

## Architecture At A Glance

Runtime path:

1. `./go` (entrypoint and shell integration control)
2. `bin/ini` (bootstrap: runtime setup, module init)
3. `bin/orc` (orchestration: config, aliases, ops/gen loading)
4. `src/dic/ops` (dispatch and parameter resolution)
5. `lib/ops/*` (domain operation functions)

Deployment/playbook path:

1. `src/set/*` grouped workflow scripts
2. Calls into DIC operations (`ops ... -j`)

## Configuration Model

Environment context is hierarchical:

1. Base site config (`cfg/env/site1`)
2. Environment overlay (`cfg/env/site1-dev`)
3. Node-specific values (hostname-aware runtime resolution)

Core runtime/config files:

- `cfg/core/ric`
- `cfg/core/ecc`
- `cfg/core/mdc`
- `cfg/ali/sta`

## Repository Layout

bin/        bootstrap and orchestration scripts (ini, orc)
cfg/        core, environment, alias, and logging configuration
lib/core/   core runtime modules (err, lo1, tme, ver, col)
lib/ops/    domain operation libraries (pve, sys, gpu, net, sto, ...)
lib/gen/    generators/helpers (env, sec, inf, aux, ana)
src/dic/    operation dispatch and injection system
src/set/    section-based deployment/playbooks
val/        validation and test framework
doc/        main technical documentation hub
utl/        utility scripts

## Component READMEs

Non-documentation top-level README index (non-redundant tree):

- Bootstrap and runtime: [bin/README.md](bin/README.md)
- Configuration: [cfg/README.md](cfg/README.md)
- Libraries: [lib/README.md](lib/README.md)
- Source execution: [src/README.md](src/README.md)
- Utilities: [utl/README.md](utl/README.md)
- Validation: [val/README.md](val/README.md)

## Validation

Primary checks:

./go doctor
./go validate

Direct test runner:

./val/run_all_tests.sh
./val/run_all_tests.sh --list
./val/run_all_tests.sh --quick

## Documentation Map

Start here:
- `doc/README.md` (documentation hub/index)

Key guides:
- `doc/arc/architecture-map.md` (current architecture and dependency map)
- `doc/cli/initiation.md` (CLI initialization and usage)
- `doc/iac/deployment.md` (deployment workflows)
- `doc/iac/environment.md` (environment hierarchy)
- `doc/dev/functions.md` (developer-facing function reference)
- `doc/adm/configuration.md` and `doc/adm/security.md` (admin operations)

## Notes

- This is a sourced Bash platform, not a conventional compiled build system.
- Shell integration is managed through explicit begin/end markers in your shell config file.
- Run `./go help` anytime for the current command surface.

## Common Tasks
- Start with the quick-start or workflow sections in this file.
- From repo root, run `./go doctor` and `./go validate` after changes.

## Troubleshooting
- Confirm commands are run from the expected directory (usually repo root).
- Check generated logs under `.log/` and rerun `./go doctor` for diagnostics.

## Related Docs
- [Repository Root](README.md)
- [Documentation Hub](doc/README.md)
