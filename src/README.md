# Source Execution Architecture (`src/`)

**The Bridging Layer:** The `src/` directory bridges the gap between the stateless, pure functions in `lib/ops/` and the declarative environment state in `cfg/env/`. It executes operations and orchestrates multi-node deployments.

## Architecture Overview

```text
┌─────────────────────────────────────────┐
│                  src/                   │
│                                         │
│  ┌──────────────┐   ┌──────────────┐    │
│  │  dic/        │   │  set/        │    │
│  │  (Controller)│   │  (Playbooks) │    │
│  └──────┬───────┘   └──────────────┘    │
└─────────┼───────────────────────────────┘
          │
          ▼
┌──────────────────┐   ┌────────────────────────┐
│  lib/ops/        │   │  cfg/ (Configuration)  │
│  (Pure Functions)│   └────────────────────────┘
└──────────────────┘
```

## Subdirectories

### `dic/` (Dependency Injection Container)
The DIC is an intelligent parameter resolution engine (`src/dic/ops`). It parses the required signatures of functions in `lib/ops/`, matches them with data available in `cfg/env/`, and automatically injects variables seamlessly.

**Key capabilities:**
- **Hybrid Execution:** Mix manual arguments with environment variables seamlessly.
- **Auto-Injection:** Use the `-j` flag for zero-configuration, fully automated parameter mapping.
- **Dynamic Resolution:** Auto-resolves arrays to strings and intelligently routes variables based on the active target hostname.

### `set/` (Deployment Playbooks)
The `set/` directory contains host-specific deployment scripts (e.g., `h1`, `c1`) acting as infrastructure runbooks. These scripts group tasks logically into discrete blocks (e.g., `a_xall`, `b_xall`) and lean on the DIC to execute operations.

**Key capabilities:**
- **Section-Based Execution:** Provides granular control over exactly what tasks to run during a setup workflow.
- **Interactive Prompts:** Uses the `.menu` framework for user-friendly execution flow (`-i` mode).
- **Headless Mode:** Capable of running non-interactively for direct CI/CD pipeline integration (`-x` mode).

## Examples

**Executing via DIC:**
```bash
# Source the DIC wrapper
source src/dic/ops

# Execute with partial arguments (DIC handles the rest)
ops pve vpt 100 on

# Execute with full environment injection
ops pve vpt -j
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
