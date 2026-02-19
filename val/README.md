# Lab Validation & Testing System

## Navigation
- [Repository Root](../README.md)
- [Documentation Hub](../doc/README.md)

## Purpose
`val/` contains the test framework and runners used to verify bootstrap behavior, library operations, and integration workflows.

## Quick Start
```bash
# Full suite
./val/run_all_tests.sh

# Useful modes
./val/run_all_tests.sh --list
./val/run_all_tests.sh --quick
./val/run_all_tests.sh core
./val/run_all_tests.sh lib
./val/run_all_tests.sh integration
```

## Structure
- `val/helpers/`: shared test framework utilities.
- `val/core/`: bootstrap/config/core module tests.
- `val/lib/`: domain library tests.
- `val/integration/`: end-to-end workflow tests.
- `val/run_all_tests.sh`: top-level test runner.

## Child READMEs
- Library integration suite: [val/lib/integration/README.md](./lib/integration/README.md)

## Common Tasks
- Run `--quick` during local iteration and full suite before merge.
- Add new tests next to the relevant layer (`core`, `lib`, or `integration`).
- Use shared framework helpers for consistent assertions/reporting.

## Troubleshooting
- If tests fail due to environment assumptions, verify repo-root execution and expected config.
- If hardware-dependent tests fail (for example GPU), mark/handle them by environment.
- Check `.log/` and test runner output for failing script paths and prerequisites.

## Related Docs
- [Validation System Deep Dive (full reference)](../doc/dev/validation-system-deep-dive.md)
- [Library Integration Tests](./lib/integration/README.md)
- [Developer Docs](../doc/dev/README.md)
- [Documentation Hub](../doc/README.md)
