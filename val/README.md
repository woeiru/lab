# Validation & Testing System (`val/`)

The `val/` directory contains the quality assurance, system health verification, and automated testing suite for the infrastructure management system.

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
├── helpers/          # Test framework (test_framework.sh)
├── integration/      # End-to-end integration tests
├── lib/              # Library function tests (ops/, gen/)
├── src/              # Source component tests
└── run_all_tests.sh  # Master test runner
```

## Framework Basics

The testing framework (`val/helpers/test_framework.sh`) provides standardized testing capabilities:

- **Standardized functions**: `run_test()`, `test_function_exists()`, `test_file_exists()`, etc.
- **Performance timing**: Built-in benchmarking with configurable thresholds (`start_performance_test`, `end_performance_test`).
- **Test isolation**: Support for temporary environments and automatic cleanup.
- **Error handling**: Graceful failure management with standardized output formatting.

### Creating Tests

1. Source the framework: `source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_framework.sh"` (adjust path depth as needed).
2. Follow the naming pattern based on component location (e.g., `val/core/<category>/<component>_test.sh`).
3. Use standard framework functions for assertions.

---

**Navigation**: Return to [Main Lab Documentation](../README.md)
