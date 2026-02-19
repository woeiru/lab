# Source Architecture Deep Dive (`src/`)

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

## Purpose
`src/` is the execution layer of the platform and has two complementary concerns:
- `src/dic/`: runtime operations with intelligent parameter injection.
- `src/set/`: setup/deployment workflows that orchestrate grouped operations.

## Architectural Split

### Runtime Operations (`src/dic/`)
- Handles command dispatch (`ops ...`).
- Resolves parameters from user input + environment hierarchy.
- Calls pure functions from `lib/ops/*`.

### Deployment Workflows (`src/set/`)
- Encodes repeatable rollout procedures.
- Groups multiple DIC operations into ordered sections.
- Focuses on provisioning and environment bring-up.

## Operational Model

### Execution Path
1. User invokes `ops ...` or set workflow.
2. Runtime loads config hierarchy (`cfg/core/*`, `cfg/env/*`).
3. DIC resolves parameters and target function.
4. Pure operation executes in `lib/ops/*`.

### Configuration Hierarchy
Resolution order typically follows:
1. explicit user arguments
2. hostname-specific variables
3. global environment variables
4. function defaults

## Contract Between Layers

### `src/dic` -> `lib/ops`
- DIC owns parameter resolution and dispatch.
- `lib/ops` functions should remain explicit and testable.
- Avoid hidden global dependencies in operation functions.

### `src/set` -> `src/dic`
- set scripts should orchestrate DIC operations (`ops ... -j`) instead of calling pure functions directly.
- keeps deployment behavior aligned with runtime resolution logic.

## Example Patterns

### Runtime (hybrid)
ops pve vpt 100 on
User provides key arguments; DIC injects remaining values.

### Runtime (injection)
ops pve vpt -j
DIC resolves all parameters from environment/config.

### Deployment (section orchestration)
a_xall() {
  ops pve dsr -j
  ops usr adr -j
  ops pve rsn -j
}

## Failure Modes and Diagnostics
- Missing parameter mapping: run with `OPS_DEBUG=1` and inspect resolution trace.
- Wrong environment context: verify active `cfg/env/*` values and hostname-specific variables.
- Dispatch mismatch: validate domain/operation mapping in `src/dic` and function availability in `lib/ops/*`.

## Practical Guidance
- Use `src/dic` for day-2 operations and troubleshooting.
- Use `src/set` for consistent provisioning and rollout.
- Keep business logic in `lib/ops`; keep orchestration in `src/*`.

## Related Docs
- [DIC Deep Dive](../dev/dic-deep-dive.md)
- [Source README](../../src/README.md)
- [Deployment Guide](../iac/deployment.md)
- [Configuration Root](../../cfg/README.md)
- [Operations Library](../../lib/ops/README.md)
