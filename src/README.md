# Source Code Architecture (`src/`)

## Navigation
- [Repository Root](../README.md)
- [Documentation Hub](../doc/README.md)

## Purpose
`src/` is the execution layer of the lab platform. It combines:
- `src/dic/`: runtime operations with intelligent parameter injection.
- `src/set/`: set-based deployment workflows that orchestrate DIC operations.

## Quick Start
# Run health checks before source-layer changes
./go doctor
./go validate

# Typical runtime operation via DIC
ops sys ipa -j

# Example set workflow (depends on environment setup)
# source src/set/<target>

## Structure
- `src/dic/`: DIC command surface and parameter resolution engine.
- `src/set/`: grouped deployment sections and orchestration scripts.

## Child READMEs
- DIC operations layer: [src/dic/README.md](./dic/README.md)
- Set deployment workflows: [doc/iac/deployment.md](../doc/iac/deployment.md)

## Common Tasks
- Use `src/dic/` for day-2 operations and maintenance.
- Use `src/set/` for initial provisioning and repeatable section-based rollout.
- Keep deployment logic in set scripts and call `ops ... -j` instead of directly calling pure functions.

## Troubleshooting
- If set workflows fail, verify required config exists in `cfg/` for the active environment.
- If DIC operations fail, run with `OPS_DEBUG=1` to inspect resolution and dispatch.
- Confirm initialization path is healthy (`./go on`, `./go status`, `./go doctor`).

## Related Docs
- [Source Architecture Deep Dive (full reference)](../doc/arc/src-architecture-deep-dive.md)
- [DIC README](./dic/README.md)
- [Deployment and IaC Docs](../doc/iac/README.md)
- [Documentation Hub](../doc/README.md)
