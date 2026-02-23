# Source Code Architecture (`src/`)

The `src/` directory implements the operational execution layer of the infrastructure management system. It provides two complementary components for infrastructure lifecycle management:

- **`dic/`**: Dependency Injection Container. Advanced parameter resolution and execution wrapper for runtime operations.
- **`set/`**: Section-Based Deployment. Systematic initial setup and multi-node orchestration scripts.

## Architecture Overview

```text
┌────────────────────────────────────────────────────────┐
│                        src/                            │
│                                                        │
│  ┌─────────────────┐       ┌────────────────────────┐  │
│  │   dic/          │       │      lib/ops/          │  │
│  │   (Controller)  │───────▶   (Pure Functions)     │  │
│  └─────────────────┘       └────────────────────────┘  │
│           ▲                                            │
│           │                                            │
│  ┌─────────────────┐                                   │
│  │   set/          │                                   │
│  │   (Playbooks)   │                                   │
│  └─────────────────┘                                   │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────┐
│  cfg/ (Configuration)  │
└────────────────────────┘
```

## Subdirectories

### [dic/ (Dependency Injection)](dic/README.md)

The `src/dic/ops` wrapper provides intelligent parameter resolution for the pure functions in `lib/ops/`. It parses function signatures and automatically injects arguments from user input, hostname-specific variables, or the global configuration hierarchy.

**Key capabilities:**
- Hybrid execution (mixing manual arguments with environment variables)
- Auto-injection (`-j` flag) for zero-configuration automation
- Array-to-string conversion and automatic hostname sanitization

### set/ (Deployment Playbooks)

The `src/set/` directory contains host-specific deployment scripts (e.g., `h1`, `c1`, `t1`) organized into execution sections. These scripts use the DIC layer to orchestrate infrastructure provisioning and apply host-specific configurations.

**Key capabilities:**
- Section-based execution (e.g., `a_xall`, `b_xall`) for granular control
- Interactive menu-driven deployment via the `.menu` framework
- Consistent environment-aware execution when combined with DIC

## Examples

**DIC Operations:**
```bash
# Source the DIC wrapper
source src/dic/ops

# Execute with partial arguments (DIC fills the rest)
ops pve vpt 100 on

# Execute with full environment injection
ops pve vpt -j
```

**Set Deployment:**
```bash
# Interactive menu-driven setup
./src/set/h1

# Direct execution of a specific section
./src/set/h1 -x a_xall
```
