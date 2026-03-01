# 06 - Writing Modules

The framework is highly extensible. Operational logic resides in parameter-driven Bash functions located in `lib/ops/`. This directory contains domain-specific modules (e.g., `pve`, `gpu`, `sys`, `net`, `sto`, `ssh`, `pbs`, `srv`, `dev`, `usr`).

## Module Conventions

To ensure consistency and compatibility with the Dependency Injection Container (DIC), all modules must adhere to strict guidelines defined in `lib/.spec` and `lib/ops/.spec`.
`lib/.spec` is the canonical merged standards document for all `lib/` modules; `lib/ops/.spec` remains the DIC-specific contract for operational functions.
There is no separate `lib/.standards` file anymore; it was merged into `lib/.spec`.

### 1. Naming

- **Public Functions:** Must use the `module_name` convention (e.g., `gpu_ptd`, `pve_cdo`).
- **Internal Helpers:** Should be prefixed with a leading underscore (e.g., `_gpu_helper`).
- **Variables:** Use `snake_case` consistently for all functions and local variables. Global constants should be `UPPERCASE`.

### 2. Parameters and Validation

All user-facing functions must validate their parameters.
- **Help Flag:** The `--help` or `-h` flag should immediately return success (`0`) and print technical usage documentation.
- **Invalid Parameters:** If an argument is missing or invalid, show the usage and return `1`.
- **Action Functions:** Do not create user-facing functions with zero parameters. Use an explicit execute flag pattern (typically `-x`) for action-style flows.

### 3. Return Codes and Error Semantics

Follow standard return codes strictly:
-   `0`: Success.
-   `1`: Parameter or usage error.
-   `2`: System, dependency, or runtime failure.
-   `127`: Required command missing (e.g., `pct` or `zfs` is not installed).

Prefer explicit `return` values over implicit status codes in multi-step functions.

### 4. Self-Documenting Comments

Functions should be self-documenting using the established comment blocks. The DIC and help systems consume these comments dynamically.

- **Usage (`aux_use`):** The three comment lines directly above a function definition are extractable as usage help.
- **Technical Docs (`aux_tec`):** A comment block inside the function body is extractable as technical documentation.

```bash
# Example user-facing function with explicit validation and return codes
# Usage: net_fas <service>
# Returns: 0 on success, 1 on invalid usage, 2 on runtime failure, 127 on missing dependency
net_fas() {
    local service="${1:-}"

    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        aux_use
        return 0
    fi

    if ! aux_val "$service" "not_empty"; then
        aux_err "Service name cannot be empty"
        return 1
    fi

    if ! aux_chk "command" "firewall-cmd"; then
        aux_err "firewall-cmd command not found"
        return 127
    fi

    # operation logic...
    return 0
}
```

### 5. Dependency Checks

Before executing any commands, verify that the required binaries are available using standard Bash tools or the `lib/gen/aux` helpers. Fail fast if a dependency is missing (`return 127`).

### 6. Writing Tests

Every new function or module requires corresponding tests. The validation framework is located in `val/`.

- **Module Tests:** Place tests for `lib/ops/mymodule` in `val/lib/ops/mymodule_test.sh`.
- **Test Framework:** Use provided helpers (`run_test`, `test_function_exists`, `test_file_exists`, `test_var_set`) from `val/helpers/test_framework.sh`.
- **Running Tests:** Execute a specific test script directly (for example `./val/lib/ops/mymodule_test.sh`) or run the full suite (`./val/run_all_tests.sh`).

Continue to [07 - Security and Logging](07-security-and-logging.md) to understand how to handle sensitive data and monitor framework activity.
