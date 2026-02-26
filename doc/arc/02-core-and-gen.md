# 02 - Core Primitives and General Utilities

The repository's foundation is built upon two distinct layers beneath the operational infrastructure modules: **Core Primitives** (`lib/core`) and **General Utilities** (`lib/gen`). These domains provide standard patterns for logging, error handling, timing, and security.

## Core Primitives (`lib/core`)

The `lib/core/` directory contains the absolute minimum required functions to bootstrap the shell environment and safely load other modules. They are sourced immediately by `bin/ini` and `bin/orc`.

*   **`err` (Error Handling):** Centralized trap handling and fallback functions. It defines the standard behavior when commands fail during initialization.
*   **`lo1` (Level 1 Logging):** A highly performant, low-overhead logging system used exclusively during the bootstrap phase before the advanced `aux` logger is available.
*   **`tme` (Timing and Profiling):** Functions to capture monotonic and wall-clock times. It allows `bin/ini` to profile the exact millisecond cost of loading the framework into the shell.
*   **`ver` (Verification):** Tools for verifying system state, paths, file permissions, and parameter integrity. Used extensively by `bin/orc` to ensure scripts are safe to source.
*   **`col` (Terminal Colors):** Standardized ANSI escape sequences for terminal formatting.

## General Utilities (`lib/gen`)

Once the core is loaded, the orchestrator pulls in `lib/gen/`. This directory contains cross-cutting utilities utilized by the `lib/ops/` modules and deployment scripts.

### 1. `aux` (Auxiliary Operations & Advanced Logging)
The `aux` module is the backbone for standardizing behavior across all operational functions. It provides:
*   **Structured Logging:** Functions like `aux_info`, `aux_warn`, `aux_err`, `aux_audit`, and `aux_dbg`. It enforces the use of key-value pair context strings (e.g., `"component=network,status=up"`).
*   **Validation (`aux_val`):** A rigid parameter validation engine that checks types, formats (numeric, path, non-empty), and prevents injection.
*   **Dependency Checking (`aux_chk`):** Proactively ensures necessary binaries, file permissions, and variables exist before a function attempts to execute.

### 2. `sec` (Security & Credential Management)
The repository enforces a **Zero Hardcoded Secrets** policy. The `sec` module handles runtime generation and injection of passwords.
*   Generates cryptographically secure passwords natively in Bash using `/dev/urandom`.
*   Manages permissions tightly (e.g., `600` on files within `700` directories).
*   Interfaces closely with the Dependency Injection Container (DIC) to inject dynamically generated credentials into operational modules seamlessly.

### 3. `env` (Environment Management)
Provides context-switching helpers to detect and manage differences between `development`, `staging`, and `production` runtimes. It helps deployment scripts adapt logic based on current topological constraints.

### 4. `inf` (Infrastructure Definitions)
Standardized templating tools for creating VM and Container definitions. It prevents code duplication by offering generic structures for assigning IP addresses, VLANs, disk pools, and CPU core counts.

### 5. `ana` (Analytics)
Telemetry functions used primarily for performance profiling and auditing execution times across complex deployment orchestrations.