# Dependency Injection Container (DIC)

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../../doc/README.md)

## Purpose
`src/dic/` provides the operational command layer (`ops`) that maps user intent to pure functions in `lib/ops/*` with adaptive parameter resolution.

## Quick Start
```bash
# Show available ops and usage
ops --help

# Hybrid mode: provide key args, inject the rest
ops pve vpt 100 on

# Injection mode: resolve from environment/config
ops pve vpt -j

# Debug parameter resolution
OPS_DEBUG=1 ops pve vpt 100 on
```

## Structure
- `src/dic/ops`: main DIC dispatcher and execution logic.
- `src/dic/*`: supporting resolution, mapping, and execution helpers.

## Common Tasks
- Run routine operations with hybrid mode (`ops <dom> <op> ...`).
- Use injection mode (`-j`) in automation where config is authoritative.
- Use `OPS_DEBUG=1` when troubleshooting missing or incorrect parameter injection.

## Troubleshooting
- If parameters are missing, verify environment variables and hostname-specific config under `cfg/env/*`.
- If operation lookup fails, validate domain/operation mapping and ensure `lib/ops/*` functions are loaded.
- Re-run `./go doctor` from repo root to verify bootstrap/runtime health.

## Related Docs
- [DIC Deep Dive (full reference)](../../doc/dev/dic-deep-dive.md)
- [Source Architecture Deep Dive](../../doc/arc/src-architecture-deep-dive.md)
- [Library Operations Architecture](../../lib/ops/README.md)
- [Documentation Hub](../../doc/README.md)
