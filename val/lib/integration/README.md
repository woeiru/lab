# Library Integration Tests

## Navigation
- [Repository Root](../../../README.md)
- [Documentation Hub](../../../doc/README.md)

## Purpose
`val/lib/integration/` is reserved for integration tests that validate interactions across multiple library domains in `lib/*`.

## Current Status
There are no active campaign-specific artifacts in this directory. Legacy function-renaming campaign content has been removed.

## Common Tasks
- Add cross-domain integration tests here when unit-level coverage in `val/lib/*` is not sufficient.
- Execute repository validation from root using `./val/run_all_tests.sh integration`.

## Troubleshooting
- Run tests from repository root so relative paths resolve correctly.
- If environment-dependent tests fail, verify required config and runtime setup before rerunning.

## Related Docs
- [Validation Root](../../README.md)
- [Developer Documentation](../../../doc/dev/README.md)
- [Repository Root](../../../README.md)
