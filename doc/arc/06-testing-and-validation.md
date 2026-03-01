# 06 - Testing and Validation

The `val/` directory contains a standardized quality assurance and automated testing framework built natively in Bash. It validates both core system health and operational library compliance, ensuring high reliability across the infrastructure automation stack.

## Directory Structure

The validation suite mirrors the repository's logical architecture:
*   `val/core/`: Tests for foundational bootstrapping, module loading (`bin/ini`, `bin/orc`), and core configs.
*   `val/lib/`: Tests for specific operational libraries (`lib/ops/`) and general utilities (`lib/gen/`).
*   `val/src/`: Tests for the Dependency Injection Container (`src/dic`).
*   `val/integration/`: End-to-end integration workflows validating cross-component interactions.
*   `val/helpers/`: Houses the foundational BDD testing framework (`test_framework.sh`).

## Testing Framework (`test_framework.sh`)

The system avoids external testing dependencies (like `BATS`) by providing a bespoke, zero-dependency BDD-style testing framework.

Key features include:
1.  **BDD-Style Assertions:** Provides structured, color-coded execution logs and assertion helpers such as `run_test`, `describe`, `it`, `pass`, and `test_file_exists`.
2.  **Test Isolation:** Automatically generates secure temporary environments (`/tmp/val_test_*`) for destructive file-system operations, ensuring tests do not corrupt the host. Test environments are rigorously cleaned up using trap handlers.
3.  **Performance Profiling:** Built-in benchmarking utilities (`start_performance_test`, `end_performance_test`) assert that critical core modules initialize within defined millisecond thresholds.

## Master Test Runner (`run_all_tests.sh`)

The `val/run_all_tests.sh` script acts as the central orchestrator for the suite. It dynamically discovers and executes tests based on the `*_test.sh` file pattern.

*   **Granular Execution:** Allows running subsets of tests by category (e.g., `./val/run_all_tests.sh core`, `./val/run_all_tests.sh lib`).
*   **Speed Profiling:** The `--quick` flag allows developers to skip slow integration tests during rapid iteration.
*   **Matrix Discovery:** The `--list` flag prints the discovered testing matrix without executing tests.

### Running a Single Test

While `run_all_tests.sh` is the primary CI entrypoint, developers are encouraged to run individual test scripts directly during development to accelerate feedback loops:
```bash
# Preferred method: execute directly
./val/core/config/cfg_test.sh

# If script permissions are not set:
bash val/lib/ops/sys_test.sh
```

## Linting and Syntax Validation

The system does not mandate a dedicated third-party linter (like `shellcheck`) in the core pipeline, but it enforces Bash syntax checks during validation runs:
```bash
find . -type f \( -name '*.sh' -o -name 'go' \) -print0 | xargs -0 -r bash -n
```
Because this repository uses many extensionless Bash modules (especially under `bin/` and `lib/`), extension-aware checks should be augmented with an extensionless pass over script directories:

```bash
find bin lib/core lib/gen lib/ops src/dic/lib src/dic/ops src/set utl/doc/generators \
  -type f ! -name '*.md' -print0 | xargs -0 -r bash -n
bash -n go
```

Additionally, `val/lib/ops/std_compliance_test.sh` acts as a specialized linter for operational modules, enforcing naming conventions, parameter validation, and documentation standards.
