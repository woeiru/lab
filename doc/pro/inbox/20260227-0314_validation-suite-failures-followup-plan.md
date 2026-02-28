# Validation Suite Failures Follow-Up

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-02-27
- Links: none

## Context

This issue tracks non-blocking test and validation failures observed while verifying a small `dev_osv` table formatting change.

Runs performed:

- `./val/run_all_tests.sh`
- `./go validate`

## Current Status

`./val/run_all_tests.sh` summary:

- Total: 34
- Passed: 31
- Failed: 3

Failed tests:

- `gpu_std_compliance_test`
- `gpu_test`
- `complete_workflow_test`

`./go validate` summary:

- Total: 34
- Passed: 30
- Failed: 4

Failed tests:

- `sec_test`
- `gpu_std_compliance_test`
- `gpu_test`
- `complete_workflow_test`

## Notes from Output

- GPU failures include missing aux-integration/pure-function expectations.
- DIC and complete workflow failures are integration-level and appear unrelated to `dev_osv` display formatting.
- `sec_test` failed in one run (`Password complexity validation`) during `./go validate`.

## Follow-Up Plan

1. Re-run only failing tests individually to confirm reproducibility:
   - `./val/lib/ops/gpu_test.sh`
   - `./val/lib/ops/gpu_std_compliance_test.sh`
   - `./val/integration/complete_workflow_test.sh`
   - `./val/src/dic/dic_framework_test.sh`
   - `./val/src/dic/dic_integration_test.sh`
   - `./val/src/dic/dic_phase1_completion_test.sh`
   - `./val/lib/gen/sec_test.sh`
2. Capture first failing assertion per script.
3. Classify by type:
   - baseline/pre-existing
   - environment-dependent
   - regression
4. Create focused fixes in small PRs grouped by module (`gpu`, `dic`, `integration`, `sec`).
5. Re-run:
   - targeted module tests
   - `./val/run_all_tests.sh`

## Ownership / Next Session Checklist

- [x] Confirm failures are still present on fresh shell/session
- [x] Attach exact first-failure snippets for each test
- [ ] Prioritize `sec_test` if intermittent
- [ ] Address GPU compliance/function-wrapper gaps
- [x] Address DIC integration/phase1 workflow failures
- [ ] Re-validate full suite
