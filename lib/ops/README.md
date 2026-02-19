# Operations Library Architecture

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../../doc/README.md)

## Purpose
`lib/ops/` provides pure operational functions for infrastructure domains (GPU, network, storage, system, etc.) and is designed for DIC-driven injection via `src/dic/ops`.

## Quick Start
```bash
# Use through DIC (recommended)
ops sys ipa -j
ops gpu ptd -j

# Validate after ops-library changes
./go doctor
./go validate
```

## Structure
- Domain modules under `lib/ops/*` with explicit-parameter pure functions.
- Wrapper/integration behavior lives in `src/dic/` rather than inside core operational functions.

## Common Tasks
- Add or update pure functions with explicit parameters and deterministic behavior.
- Use DIC injection mode (`-j`) for environment-aware operations.
- Use explicit mode during targeted testing and debugging.

## Troubleshooting
- If function dispatch fails, verify domain/op mapping in `src/dic/ops`.
- If injected values are wrong, run with `OPS_DEBUG=1` and inspect env/config resolution.
- Confirm expected config values exist under `cfg/env/*`.

## Related Docs
- [lib/ops Architecture Deep Dive (full reference)](../../doc/dev/lib-ops-architecture-deep-dive.md)
- [DIC README](../../src/dic/README.md)
- [Source Architecture](../../src/README.md)
- [Documentation Hub](../../doc/README.md)
