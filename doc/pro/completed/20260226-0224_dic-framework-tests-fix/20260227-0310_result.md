# DIC Framework Test Fixes

## Goal
Identify whether the validation-suite follow-up issue was already fixed, then focus only on the DIC framework failures and leave other failing suites (GPU, complete workflow, etc.) untouched.

## Instructions
- User asked to start with DIC framework only: "we start with the dic framework. let the others sit".
- Do not work on non-DIC failures yet.
- Determine current failure state first, then fix DIC framework-related failing tests.
- Continue execution directly without asking permission each step.

## Discoveries
- The tracking doc `doc/pro/active/validation-suite-failures-followup.md` was read and confirmed still-current failures:
  - `gpu_std_compliance_test`
  - `gpu_test`
  - `complete_workflow_test`
  - `dic_framework_test`
  - `dic_integration_test`
  - `dic_phase1_completion_test`
- Initial rerun of `./val/run_all_tests.sh` confirmed the same 6 failures remained.
- `dic_framework_test` path in doc was outdated for one script:
  - actual script is `val/src/dic_framework_test.sh` (not `val/src/dic/dic_framework_test.sh`).
- DIC subtests appeared "truncated" because:
  - `source bin/ini` emits large init logs to stderr.
  - more importantly, tests exited early before assertions due to shell behavior.
- Root cause of early exit:
  - `bin/orc` (sourced via `bin/ini`) enables `set -eo pipefail` for non-interactive shells.
  - test scripts used arithmetic increments like `((TESTS_TOTAL++))`.
  - in bash, `((var++))` returns status 1 when expression evaluates to 0 (e.g., first increment from 0), which triggers exit under `set -e`.
- Additional integration-test bug found:
  - dynamic variable check used invalid indirect expansion pattern `if [[ -z "${!hostname}_NODE_PCI0" ]]; then` which did not correctly test `${hostname}_NODE_PCI0`.
- Another `set -e` trip point in integration test:
  - performance section called `src/dic/ops pve vck 100` directly; non-zero command status could abort script.
- After fixes, DIC tests pass.
- A cosmetic inconsistency remained in wrapper output where `dic_framework_test` stated `Status: SOME TESTS FAILED` despite 0 failures.

## Accomplished & Verified
- Confirmed issue was not previously fixed (same failing tests persisted).
- Focused on DIC framework-related scripts and fixed the early-exit defects.
- Edited `val/src/dic/dic_integration_test.sh`:
  - changed counter increments from `((...++))` to safe arithmetic assignments.
  - added `set +e` immediately after `source bin/ini` to honor script intent of graceful error handling.
  - fixed hostname PCI var check.
  - made performance probe non-fatal with `|| true`.
- Edited `val/src/dic/dic_phase1_completion_test.sh`:
  - changed `((...++))` increments to safe arithmetic assignments.
- Fixed `val/src/dic_framework_test.sh`:
  - fixed `print_test_summary` in the test framework missing the total tests count (`FRAMEWORK_TESTS_RUN++`).
  - fixed regex to strip ANSI escape codes and properly tally passed/failed from DIC output text, eliminating the `(0/0 passed)` or incorrect numbering.
- Validation performed:
  - `bash -n` syntax checks for edited scripts passed.
  - `bash val/src/dic/dic_integration_test.sh` returned `EXIT:0`.
  - `bash val/src/dic/dic_phase1_completion_test.sh` returned `EXIT:0`.
  - `./val/src/dic_framework_test.sh` returned `EXIT:0` and all DIC component tests reported success with accurate counts.
  - Global `./val/run_all_tests.sh` confirmed `dic_*` tests are officially passing. Remaining failures are restricted to `gpu` and `complete_workflow`.

## Relevant files / directories
- `doc/pro/active/validation-suite-failures-followup.md` (Updated)
- `val/src/dic_framework_test.sh`
- `val/src/dic/dic_integration_test.sh`
- `val/src/dic/dic_phase1_completion_test.sh`
