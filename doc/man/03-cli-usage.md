# 03 - CLI Usage and the DIC

This guide covers the operator CLI flow for `lib/ops/*` functions.
The primary interface is the DIC command: `ops` (`src/dic/ops`).

## 1. Prerequisites and Safety

Load the runtime first in your current shell:

```bash
lab
```

If you skip this, `ops` usually fails with missing runtime variables (for example `LIB_OPS_DIR`).

Safety note:
- `ops --list`, `ops <module> --list`, and `ops <module> <function> --help` are read-only discovery.
- Many `ops` executions are state-changing infrastructure actions. Validate context before execution.

## 2. Quick Discovery Commands

```bash
ops --list
ops pve --list
ops pve vpt --help
```

Use these first when exploring available modules/functions.

## 3. Direct Function Calls vs `ops`

Two interfaces exist:

1. **Direct call** in shell (e.g., `gpu_ptd ...`): full argument handling is on you.
2. **DIC call** (e.g., `ops gpu ptd ...`): resolves and injects missing values from environment/config conventions.

For day-to-day operations and deployment scripts, prefer `ops`.

## 4. DIC Execution Modes

### Preview mode (no arguments)

```bash
ops gpu ptd
```

Shows a usage preview with parameter placeholders:
- `<param:value>` means auto-injection value is available.
- `<param>` means manual input is still required.

### Hybrid mode (default when args are provided)

```bash
ops pve vpt 100 on
```

Provided arguments fill early parameters, and DIC resolves remaining parameters.

### Injection mode (`-j`)

```bash
ops pve vpt -j
```

Executes with full environment-driven injection (common in `src/set/*` runbooks).

### Explicit pass-through flag (`-x`)

```bash
ops gpu pts -x
```

`-x` is passed to the target function for contracts that require explicit execute flags.

## 5. Resolution Behavior (Practical View)

In normal operation, resolution follows this pattern:
1. user-supplied CLI arguments,
2. hostname-scoped variables (for example `<hostname>_NODE_PCI0`),
3. broader globals (for example `VM_ID`),
4. function defaults (when defined).

Array-like values are converted into callable argument forms when needed.

## 6. Debugging and Validation

Enable DIC debug tracing:

```bash
OPS_DEBUG=1 ops pve vpt -j
```

Optional behavior controls:

```bash
OPS_VALIDATE=strict OPS_CACHE=1 OPS_METHOD=auto ops pve vpt -j
```

## 7. Return Codes and Troubleshooting

Standard return code contract used by the framework:
- `0` success
- `1` usage/validation error
- `2` runtime/dependency failure
- `127` required command missing

Common issues:

### `Environment not initialized. Please run 'source bin/ini' first.`

Run:

```bash
lab
```

### `Module '<name>' not found`

- Verify module exists under `lib/ops/`.
- Use `ops --list` to confirm available module names.

### Injection not resolving expected values

- Check `cfg/env/*` variable names and hostname prefixes.
- Run preview mode (`ops <module> <function>`) to inspect what DIC sees.
- Retry with `OPS_DEBUG=1` for detailed resolution logs.

## 8. Related Docs

- Next: [04 - Deployments and Runbooks](04-deployments.md)
- DIC internals: [src/dic/README.md](../../src/dic/README.md)
- Architecture context: [doc/arc/04-dependency-injection.md](../arc/04-dependency-injection.md)
