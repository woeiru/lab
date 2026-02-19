# DIC Deep Dive

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

## Purpose
The Dependency Injection Container (DIC) provides a consistent operational interface (`ops`) that maps user intent to pure functions while resolving parameters from environment context.

## Core Responsibilities
- parse operation target (`domain`, `operation`, flags)
- inspect function signature requirements
- resolve/inject parameter values
- execute target function with deterministic argument order
- provide debug trace for resolution and dispatch

## Execution Modes

### 1. Hybrid Mode
ops pve vpt 100 on
- user supplies initial arguments
- DIC fills remaining required parameters

### 2. Injection Mode (`-j`)
ops pve vpt -j
- DIC resolves all required parameters from config/env
- useful for automation and repeatable workflows

### 3. Explicit/Pass-through Mode (`-x`)
ops gpu pts -x
- control flags pass through to function-level validation behavior

## Resolution Hierarchy
DIC resolves each parameter using prioritized sources:
1. explicit CLI arguments
2. hostname-specific variables
3. global variables
4. function defaults

This enables both manual overrides and zero-config automation.

## Signature and Mapping Behavior
- signature extraction combines comments/local-variable patterns/function parsing.
- resolved values are positioned to match the function’s expected argument order.
- array values are normalized (for example to space-separated strings) when required.

## Debugging Workflow
Use resolution tracing for any unexpected behavior:
OPS_DEBUG=1 ops pve vpt 100 on
Check for:
- resolved variable source (user/hostname/global/default)
- final argument list and call target
- missing-variable fallback path

## Typical Failure Cases
- required parameter unresolved and no default available
- hostname variable mismatch due to naming/sanitization differences
- operation mapped to missing or renamed function

## Performance Notes
- signature caching reduces repeated analysis overhead.
- environment-first injection minimizes repetitive manual argument entry.
- explicit mode remains available for targeted troubleshooting.

## Integration Boundaries
- `src/set/*` should orchestrate `ops ... -j` calls, not direct pure function calls.
- `lib/ops/*` should remain explicit, predictable, and independently testable.

## Related Docs
- [Source README](../../src/README.md)
- [Source Architecture Deep Dive](../arc/src-architecture-deep-dive.md)
- [Operations Library](../../lib/ops/README.md)
- [Deployment Guide](../iac/deployment.md)
