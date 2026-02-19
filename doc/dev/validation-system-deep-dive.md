# Validation System Deep Dive

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

## Purpose
This document describes the validation and testing framework under `val/`, including test categories, framework behavior, and maintenance patterns.

## Quick Start
```bash
./val/run_all_tests.sh
./val/run_all_tests.sh --list
./val/run_all_tests.sh --quick
./val/run_all_tests.sh core
./val/run_all_tests.sh lib
./val/run_all_tests.sh integration
```

## Architecture
```text
val/
├── helpers/            # shared framework helpers
├── core/               # bootstrap/config/runtime tests
├── lib/                # library domain tests
├── integration/        # cross-component tests
└── run_all_tests.sh    # master runner
```

## Framework Features
- standardized helper functions for assertions and setup/cleanup
- category-aware execution
- test isolation with temporary resources
- timing/performance helpers for threshold checks

## Development Patterns

### Test File Placement
- core tests: `val/core/<category>/<component>_test.sh`
- library tests: `val/lib/<category>/<component>_test.sh`
- integration tests: `val/integration/<feature>_test.sh`

### Typical Test Flow
```bash
source val/helpers/test_framework.sh

test_function_exists "my_function" "Description"
run_test "My behavior" command_to_test
```

## Migration and Maintenance
- keep legacy scripts isolated from active test paths
- prioritize deterministic tests for CI safety
- treat environment-dependent tests explicitly (for example GPU-specific tests)

## Known Risk Areas
- tests that require specific host environment state
- hardware-coupled scenarios (GPU, virtualization backends)
- assumptions about runtime-loaded shell context

## Related Docs
- [Validation Root](../../val/README.md)
- [Library Integration Tests](../../val/lib/integration/README.md)
- [Developer Docs Index](./README.md)
