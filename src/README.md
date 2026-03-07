# Source Execution Architecture (`src/`)

**The Runtime Bridge:** The `src/` directory bridges declarative intent and runtime execution. During migration, `src/set/*` remains the operator-facing compatibility surface, but execution now routes through `src/run/dispatch` with plan-aware contracts from `src/rec/`.

## Architecture Overview

```text
cfg/dcl/* (desired intent)
        |
        v
src/rec/* (reconcile + compile)
        |
        v
src/run/* (dispatch + enforcement)
        |
        v
src/set/* (compat runbook entrypoints)
        |
        v
src/dic/ops (injection)
        |
        v
lib/ops/* (infrastructure actions)

cfg/env/* provides runtime context to src/rec and src/dic
```

## Subdirectories

### `dic/` (Dependency Injection Container)
The DIC is an intelligent parameter resolution engine (`src/dic/ops`). It parses the required signatures of functions in `lib/ops/`, matches them with data available in `cfg/env/`, and automatically injects variables seamlessly.

**Key capabilities:**
- **Hybrid Execution:** Mix manual arguments with environment variables seamlessly.
- **Auto-Injection:** Use the `-j` flag for zero-configuration, fully automated parameter mapping.
- **Dynamic Resolution:** Auto-resolves arrays to strings and intelligently routes variables based on the active target hostname.

### `set/` (Deployment Playbooks)
The `set/` directory contains host-specific deployment scripts (e.g., `h1`, `c1`) acting as compatibility runbooks. These scripts keep section ergonomics (`a_xall`, `b_xall`) while defaulting to `src/run/dispatch` before section execution.

**Key capabilities:**
- **Section-Based Execution:** Provides granular control over exactly what tasks to run during a setup workflow.
- **Interactive Prompts:** Uses the `.menu` framework for user-friendly execution flow (`-i` mode).
- **Headless Mode:** Capable of running non-interactively for direct CI/CD pipeline integration (`-x` mode).

### `rec/` (Reconciliation)
`rec/` is the new compile/reconcile boundary. It validates declarative input from
`cfg/dcl/` and prepares deterministic artifacts for execution.

### `run/` (Runbook Execution)
`run/` is the new execution boundary for applying reconciled plans. During migration,
`src/set/*` entrypoints are retained and delegated through `src/run/dispatch`.
When `--plan` is supplied, dispatch can enforce dependency/order/policy metadata
using strict runtime flags or stage defaults (`--enforcement-stage`) resolved
from CLI/env/plan metadata.

## Examples

**Executing via DIC:**
```bash
# Source the DIC wrapper
source src/dic/ops

# Execute with partial arguments (DIC handles the rest)
ops pve vpt 100 on

# Execute with full environment injection
ops pve vpt -j

# Execute one command with reconcile preflight enabled
ops --reconcile pve vpt -j

# Migration bridge: compile + dispatch through rec/run
src/dic/run h1 -i
```

**Executing a Set Deployment:**
```bash
# Interactive menu-driven setup
./src/set/h1

# Direct, headless execution of a specific section
./src/set/h1 -x a_xall
```

## Further Reading

- **Manual:** [03 - CLI Usage](../doc/man/03-cli-usage.md)
- **Manual:** [04 - Deployments](../doc/man/04-deployments.md)
- **Architecture:** [04 - Dependency Injection](../doc/arc/04-dependency-injection.md)
- **Reference:** [Functions Reference](../doc/ref/functions.md)

---
**Navigation**: Return to [Main Lab Documentation](../README.md)
