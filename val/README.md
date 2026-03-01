# Validation & Testing System (`val/`)

**The Quality Assurance Layer:** The `val/` directory contains a bespoke, zero-dependency BDD-style testing framework tailored specifically for Bash. It houses unit, integration, and performance tests that mirror the repository's structure (`val/core`, `val/lib`, `val/src`). It ensures system health by running assertions in securely isolated temporary environments to prevent host corruption during destructive operations.

## Quick Start

```bash
# Run all tests
./val/run_all_tests.sh

# Run specific categories  
./val/run_all_tests.sh core           # Core system tests
./val/run_all_tests.sh lib            # Library function tests
./val/run_all_tests.sh integration    # End-to-end integration tests
./val/run_all_tests.sh src            # Source component tests
./val/run_all_tests.sh dic            # Dependency injection tests

# Test options
./val/run_all_tests.sh --list         # List available tests
./val/run_all_tests.sh --quick        # Skip slow tests
./val/run_all_tests.sh --help         # Show usage
```

## Directory Structure

```text
val/
├── core/             # Core system tests (ini, modules, config)
├── helpers/          # Test framework primitives
├── integration/      # End-to-end integration tests
├── lib/              # Library function tests (ops/, gen/)
├── src/              # Source component tests
└── run_all_tests.sh  # Master test runner
```

## Testing Framework Basics

The framework (`val/helpers/test_framework.sh`) provides standardized testing capabilities:
- **Standardized Assertions**: `run_test`, `test_function_exists`, `test_var_set`, `test_file_exists`, etc.
- **Performance Timing**: Built-in benchmarking with configurable thresholds (`start_performance_test`, `end_performance_test`).
- **Test Isolation**: Secure support for temporary environments and automatic cleanup, ensuring the local machine's state remains untouched.
- **Error Handling**: Graceful failure management with standardized output formatting.

## Development Requirement

A strict framework rule mandates that **any new operational module or core library addition must include a corresponding test script**. For example, creating `lib/ops/mymodule` requires creating `val/lib/ops/mymodule_test.sh`.

### Creating Tests
1. Source the framework: `source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"` (adjust path depth accordingly).
2. Name the test based on the component's location: `val/core/<category>/<component>_test.sh`.
3. Use the framework assertions within standard bash test functions.

## CI Validation

For continuous integration or fully automated environments, you can use the top-level script wrapper:

```bash
./go validate
```
This wrapper checks initialization states and forwards the run to the appropriate `val/` tests.

## Further Reading

- **Architecture:** [06 - Testing and Validation](../doc/arc/06-testing-and-validation.md)
- **Manual:** [05 - Writing Modules](../doc/man/05-writing-modules.md) (covers testing new modules)

---
**Navigation**: Return to [Main Lab Documentation](../README.md)
