# Binary Directory (`bin/`)

**The Entrypoint Layer:** The `bin/` directory serves as the framework's bootstrap mechanism and central hub for system initialization. It handles loading the modular architecture performantly into the user's interactive shell session without relying on a compiled build step.

## Directory Structure

```text
bin/
├── ini    # System Initialization Controller
└── orc    # Component Orchestrator
```

## Core Components

### `ini` - System Initialization Controller
The primary script that orchestrates the environment bootstrap process. It is executed automatically by the root `./go init` script during session activation.

**Initialization Flow:**
1. Sets boot-phase toggles (`LOG_DEBUG_ENABLED=0`, `LAB_BOOTSTRAP_MODE=1`) to reduce I/O overhead during startup.
2. Validates core dependencies and system requirements.
3. Sets up essential directories (`.log`, `.tmp`).
4. Loads and verifies core foundational modules (`col`, `err`, `lo1`, `tme`).
5. Sources the Component Orchestrator (`bin/orc`).
6. Initializes runtime system with configuration processing.
7. Registers and validates system functions.
8. Restores `LOG_DEBUG_ENABLED` and clears `LAB_BOOTSTRAP_MODE` on completion or failure.

### `orc` - Component Orchestrator
Manages the exact sequential execution and loading of system components with dependency awareness and status tracking. 

**Key Responsibilities:**
- **Configuration Loading**: Sources environment, controller, and alias configurations from `cfg/`.
- **Library Loading**: By default, registers lazy-load stub functions for operational (`lib/ops`) and auxiliary (`lib/gen`) libraries from a static function map (`cfg/core/lzy`); real modules are sourced on first use. When lazy loading is disabled, eagerly sources all modules at boot. Core utility libraries (`lib/core`) are always eagerly loaded.
- **Component Management**: Manages safe file sourcing (via coproc-based FD stderr capture), error handling, and performance profiling during initialization. Directory scanning uses shell-native globbing instead of external `find`/`sort` processes.

## Environment Variables

You can control initialization behavior through several environment variables, primarily defined before sourcing the environment:

- `LOG_DIR`: Custom directory for log files (default: `${LAB_DIR}/.log`)
- `TMP_DIR`: Custom directory for temporary files (default: `${LAB_DIR}/.tmp`)
- `MASTER_TERMINAL_VERBOSITY`: Control terminal output (`on`/`off`)
- `DEBUG_LOG_TERMINAL_VERBOSITY`: Control debug output (`on`/`off`)
- `PERFORMANCE_MODE`: Enable performance optimizations (`0`/`1`)
- `LAB_BOOTSTRAP_MODE`: Set to `1` during bootstrap, cleared after (transient; do not set manually)
- `LAB_OPS_LAZY_LOAD`: Enable lazy-load stubs for `lib/ops/*` modules (`0`/`1`, default `1`)
- `LAB_OPS_LAZY_MODULES`: Comma-separated list of ops modules to lazy-load, or `all` (default `all`)
- `LAB_GEN_LAZY_LOAD`: Enable lazy-load stubs for `lib/gen/*` modules (`0`/`1`, default `1`)
- `LAB_GEN_LAZY_MODULES`: Comma-separated list of gen modules to lazy-load, or `all` (default `all`)

## Further Reading

To understand how the bootstrapping architecture fits into the broader system, or how to integrate it into your environment, please consult the documentation:

- **Architecture:** [01 - Bootstrap and Orchestration](../doc/arc/01-bootstrap-and-orchestration.md)
- **Manual:** [01 - Installation & Setup](../doc/man/01-installation.md)
- **Architecture:** [00 - Architecture Overview](../doc/arc/00-architecture-overview.md)

---
**Navigation**: Return to [Main Lab Documentation](../README.md)
