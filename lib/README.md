# Libraries & Operations (`lib/`)

**The Functional Engine:** The `lib/` directory contains the core logic and operational heart of the framework. It is composed entirely of pure, stateless Bash functions that accept explicit parameters rather than relying on hidden global state.

## Directory Structure

The library is strictly tiered by level of responsibility:

```text
lib/
├── core/   # Core Primitives
├── gen/    # General Utilities
└── ops/    # Operational Modules
```

### `core/` (Core Primitives)
The absolute foundational minimum tools loaded first. These modules handle basic error reporting (`err`), low-level logging (`lo1`), terminal coloring (`col`), and high-performance timing/profiling (`tme`).

### `gen/` (General Utilities)
Cross-cutting utilities used across the entire framework.
- **`aux`**: Advanced auxiliary structured logging (`aux_info`, `aux_warn`, `aux_err`) and parameter validation (`aux_val`).
- **`sec`**: Security and credential generation helpers.
- **`env`**: Environment parsers and evaluators.

### `ops/` (Operational Modules)
Stateless, atomic pure functions that execute real infrastructure changes (e.g., managing Proxmox VMs, networking, GPU passthrough). They are the functional building blocks for deployment runbooks.

## Architectural Rules

Modules in this directory must adhere to strict guidelines outlined in `lib/.spec` and `lib/ops/.spec`:
`lib/.spec` is the canonical merged baseline/quality standard for all `lib/` modules, while `lib/ops/.spec` defines additional ops and DIC-specific contracts.
`lib/.standards` is retired and fully merged into `lib/.spec`.
1. **Strict Naming Conventions**: Public functions must be prefixed with their module's three-letter abbreviation (e.g., `pve_cdo`, `gpu_ptd`).
2. **Explicit Parameters**: Operations must execute purely based on explicit arguments to ensure DIC (Dependency Injection Container) compatibility.
3. **Structured Logging**: Raw `echo` or `printf` commands are forbidden for operational messages. Functions must utilize the `aux_*` structured logging tools.
4. **Self-Documentation**: All functions must contain a 3-line usage header (`aux_use`) and a detailed technical block (`aux_tec`). These are dynamically parsed by the help system and out-of-band documentation generators.
5. **Standardized Return Codes**: Functions must utilize `0` (success), `1` (parameter error), `2` (runtime failure), or `127` (missing command).

## Further Reading

Before developing new modules or modifying existing ones, consult the relevant developer manuals:

- **Manual:** [05 - Writing Modules](../doc/man/05-writing-modules.md)
- **Manual:** [06 - Security and Logging](../doc/man/06-security-and-logging.md)
- **Architecture:** [02 - Core and Gen](../doc/arc/02-core-and-gen.md)
- **Architecture:** [03 - Operational Modules](../doc/arc/03-operational-modules.md)
- **Reference:** [Functions Reference](../doc/ref/functions.md)

---
**Navigation**: Return to [Main Lab Documentation](../README.md)
