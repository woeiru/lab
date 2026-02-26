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
1. Validates core dependencies and system requirements.
2. Sets up essential directories (`.log`, `.tmp`).
3. Loads and verifies core foundational modules (`err`, `lo1`, `tme`).
4. Sources the Component Orchestrator (`bin/orc`).
5. Initializes runtime system with configuration processing.
6. Registers and validates system functions.

### `orc` - Component Orchestrator
Manages the exact sequential execution and loading of system components with dependency awareness and status tracking. 

**Key Responsibilities:**
- **Configuration Loading**: Sources environment, controller, and alias configurations from `cfg/`.
- **Library Loading**: Sequentially sources operational (`lib/ops`), auxiliary (`lib/gen`), and core utility libraries (`lib/core`).
- **Component Management**: Manages safe file sourcing, error handling, and performance profiling during initialization.

## Environment Variables

You can control initialization behavior through several environment variables, primarily defined before sourcing the environment:

- `LOG_DIR`: Custom directory for log files (default: `${LAB_DIR}/.log`)
- `TMP_DIR`: Custom directory for temporary files (default: `${LAB_DIR}/.tmp`)
- `MASTER_TERMINAL_VERBOSITY`: Control terminal output (`on`/`off`)
- `DEBUG_LOG_TERMINAL_VERBOSITY`: Control debug output (`on`/`off`)
- `PERFORMANCE_MODE`: Enable performance optimizations (`0`/`1`)

## Further Reading

To understand how the bootstrapping architecture fits into the broader system, or how to integrate it into your environment, please consult the documentation:

- **Architecture:** [01 - Bootstrap and Orchestration](../doc/arc/01-bootstrap-and-orchestration.md)
- **Manual:** [01 - Introduction](../doc/man/01-introduction.md)
- **Manual:** [02 - Installation & Setup](../doc/man/02-installation.md)
- **Architecture:** [00 - Architecture Overview](../doc/arc/00-architecture-overview.md)

---
**Navigation**: Return to [Main Lab Documentation](../README.md)
