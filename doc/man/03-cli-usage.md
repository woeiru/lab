# 03 - CLI Usage and the DIC

This guide covers the operator CLI flow for `lib/ops/*` functions.
The primary interface is the DIC command: `ops` (`src/dic/ops`).

## Command Decision Flow

Use these decision maps to select the right invocation pattern before running
state-changing commands.

### Direct call vs DIC call

```mermaid
flowchart TD
    A["Need to run an ops function?"] --> B{"Ad-hoc debugging with full manual args?"}
    B -->|yes| C["Direct call\n<module>_<function> ..."]
    B -->|no| D["DIC call\nops <module> <function> ..."]

    C --> E["You provide all required arguments"]
    D --> F["DIC resolves missing values from config/env"]
```

| Command/mode | When to use | Side effects |
|--------------|-------------|--------------|
| Direct shell call (`gpu_ptd ...`) | Debugging or function-level testing when you want full manual control | Depends on target function; often state-changing |
| DIC call (`ops gpu ptd ...`) | Day-to-day operation and runbooks where injection reduces argument errors | Depends on target function; often state-changing |

### DIC execution mode selection

```mermaid
flowchart TD
    A["Using ops <module> <function>"] --> B{"Know the required arguments?"}
    B -->|no| P["Preview mode\nops <module> <function>"]
    B -->|yes| C{"Want full env-driven injection?"}

    C -->|yes| J["Injection mode\nops <module> <function> -j"]
    C -->|no| H["Hybrid mode\nops <module> <function> <arg1> ..."]

    J --> X{"Target function requires execute flag?"}
    H --> X
    X -->|yes| PX["Pass-through execute flag\n... -x"]
    X -->|no| R["Run selected mode"]

    P --> RO["Read-only preview output\nno execution"]
```

| Command/mode | When to use | Side effects |
|--------------|-------------|--------------|
| Preview (`ops <module> <function>`) | Inspect what DIC can inject before execution | Read-only preview |
| Hybrid (`ops <module> <function> <args...>`) | Provide known leading args and let DIC fill the rest | Executes target function; commonly state-changing |
| Injection (`ops <module> <function> -j`) | Full environment/config-driven execution (common in runbooks) | Executes target function; commonly state-changing |
| Pass-through (`... -x`) | Required when target function contract needs explicit execute flag | Enables execution path in target function |

### Dev session attribution decision flow

For attribution command selection (`osv`, `oae`, `orr`, `otr`), use the full
decision flow in [07 - Dev Session Attribution Workflow](07-dev-session-attribution-workflow.md)
instead of duplicating it here.

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

## 8. Dev Session Attribution Overview

The `dev` module supports auditable session attribution with strict defaults.

When `lab` is loaded, `cfg/ali/sta` defines an `opencode()` shell wrapper that
automatically emits `account_selected` events before launching OpenCode.
Those automatic rows appear with `SRC=shell_wrapper` in `ops dev osv`.

### View sessions with attribution confidence

```bash
ops dev osv -x
ops dev osv -x --best-effort
```

- Strict default (`ops dev osv -x`) only shows event-backed `CONF=high` identities.
- Best-effort mode (`--best-effort`) can surface `CONF=low` fallbacks and keeps provenance in `SRC`.

Common `SRC` values:
- `shell_wrapper`: automatic event emitted by the `opencode()` shell wrapper
- `opencode_runtime`: runtime/manual event emitted by `dev_oae`/`dev_orr`
- `connector_event`: connector token refresh event emitted by `dev_otr`
- `manual_switch`: account switch event emitted by `dev_oas`

### Emit runtime attribution events directly

```bash
ops dev oae -x
ops dev oae openai user@example.com account_selected opencode_runtime user@example.com
```

For `-x` mode, set:
- `OPENCODE_ATTR_PROVIDER_ID`
- `OPENCODE_ATTR_ACCOUNT_KEY`
- optional `OPENCODE_ATTR_ACCOUNT_LABEL`, `OPENCODE_ATTR_EVENT_TYPE`, `OPENCODE_ATTR_SOURCE`, `OPENCODE_ATTR_TRACE_ID`

### Wrapper-based request/refresh integration

Automatic default (with `lab` loaded):

```bash
opencode
oc
```

Manual helpers remain available when wrapper context is unavailable or explicit
provider/account overrides are needed:

```bash
ops dev orr openai user@example.com -- "summarize changes"
ops dev orr openai user@example.com --dry-run -- "summarize changes"
ops dev otr openai user@example.com user@example.com connector_event
```

- `dev_orr` emits `event_type=account_selected` immediately before `opencode run`.
- `dev_orr --dry-run` emits the same attribution event without executing `opencode run`.
- `dev_otr` emits `event_type=token_refreshed` for identity refresh transitions.

For full procedure, validation matrix, and troubleshooting, see:
- [07 - Dev Session Attribution Workflow](07-dev-session-attribution-workflow.md)

## 9. Related Docs

- Next: [04 - Deployments and Runbooks](04-deployments.md)
- DIC internals: [src/dic/README.md](../../src/dic/README.md)
- Architecture context: [doc/arc/04-dependency-injection.md](../arc/04-dependency-injection.md)
