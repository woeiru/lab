# Source DIC Pre-existing Failures Follow-up Plan

- Status: completed
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-06 03:13:20
- Links: val/src/dic_framework_test.sh, val/src/dic/dic_integration_test.sh, val/src/dic/dic_phase1_completion_test.sh, val/run_all_tests.sh, wow/completed/20260305-2356_src-set-bootstrapper-logging-alignment/20260305-2249_src-set-bootstrapper-logging-alignment-plan.md

## Goal

Resolve known pre-existing `src` DIC test failures so category-level validation
is green at default project settings.

## Context

1. During `src/set` bootstrapper/logging alignment verification, `./val/run_all_tests.sh src` reported failures in `dic_framework_test`, `dic_integration_test`, and `dic_phase1_completion_test`.
2. These failures predate and are outside the scoped implementation changes for
   the `src/set` alignment item.
3. The alignment contract test added for `src/set` passed, so follow-up should
   focus on existing DIC suite assumptions and regressions.
4. Reproduced baseline failures at default logging (`LAB_LOG_LEVEL_AUX` unset):
   - `bash val/src/dic/dic_integration_test.sh` -> 3 failures (`Simple function execution`, `Signature Detection`, `Variable Resolution`).
   - `bash val/src/dic/dic_phase1_completion_test.sh` -> 3 failures (environment config/debug inheritance/hostname injection checks).
5. Reproduced debug-enabled behavior (`LAB_LOG_LEVEL_AUX=debug`):
   - `bash val/src/dic/dic_integration_test.sh` -> 0 failures.
   - `bash val/src/dic/dic_phase1_completion_test.sh` -> 0 failures.
   This confirms pass/fail coupling to debug visibility instead of functional behavior in several assertions.
6. `LAB_ROOT=/home/es/lab bash val/src/dic/dic_basic_test.sh` fails 3 debug-coupled checks at default logging but passes with `LAB_LOG_LEVEL_AUX=debug`.
7. `val/src/dic/dic_basic_test.sh` currently depends on pre-set `LAB_ROOT` (`cd $LAB_ROOT`) and can fail direct runs when unset; its summary also reports impossible counts (`10` passed out of `9` total) because setup increments `TESTS_PASSED`.
8. Implemented Phase 2 test-side fixes:
   - `val/src/dic/dic_basic_test.sh` now self-resolves `LAB_ROOT` from script location and no longer requires pre-exported `LAB_ROOT` for direct runs.
   - DIC assertion checks across the scoped scripts are behavior-first at default verbosity, with debug-text diagnostics scoped explicitly where retained.
9. Syntax validation completed:
   - `bash -n val/src/dic/dic_basic_test.sh`
   - `bash -n val/src/dic/dic_integration_test.sh`
   - `bash -n val/src/dic/dic_phase1_completion_test.sh`
10. Verification results are now green:
    - `bash val/src/dic_framework_test.sh` -> all DIC suites passed.
    - `./val/run_all_tests.sh src` -> 6/6 tests passed.

## Scope

1. Reproduce failing DIC tests in isolation and capture root-cause categories.
2. Distinguish true runtime regressions from brittle assertion or logging-level
   coupling issues.
3. Implement fixes and update tests/docs as needed.
4. Re-run `./val/run_all_tests.sh src` to confirm the category passes.

## Risks

1. DIC failures may involve shared bootstrap/logging behavior with wide blast
   radius.
2. Test-only fixes could mask real runtime defects if not paired with behavior
   validation.

## Triage Decision

- Why now: `src` category validation is not green, which blocks reliable regression verification for recent and upcoming `src/set` and DIC changes.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: Multiple remediation paths exist (runtime logic, injection behavior, or brittle test assumptions), and the resulting DIC/logging contract shape affects shared tests and downstream usage.

## Execution Plan

1. Phase 1 - Produce a DIC remediation design baseline before implementation begins. (Done)
   Completion criterion: This workflow item contains a concrete design note covering interfaces, constraints, trade-offs, and the chosen approach for each failing DIC test category.
2. Phase 2 - Apply implementation changes in DIC runtime/tests to match the approved design. (Done)
   Completion criterion: All intended code edits are complete and each modified Bash file passes `bash -n`.
3. Phase 3 - Verify `src` category stability after implementation. (Done)
   Completion criterion: `./val/run_all_tests.sh src` exits with code 0.

## Phase 1 Design Baseline

Date: 2026-03-06
Design classification: required

1. Failing category: debug-visibility-coupled assertions in DIC tests.
   - Interfaces affected: `val/src/dic/dic_basic_test.sh`, `val/src/dic/dic_integration_test.sh`, and `val/src/dic/dic_phase1_completion_test.sh` currently mix functional pass/fail with checks for debug strings (`Executing`, `Extracted parameters`, `Using sanitized hostname`, `Sourcing environment config`).
   - Constraints: `src/dic/ops` debug emission is intentionally gated by logging policy (`LAB_LOG_LEVEL_AUX` / `_log_level_permits`), so `OPS_DEBUG=1` does not guarantee terminal visibility at default verbosity.
   - Trade-offs: (a) force debug globally for tests, (b) downgrade debug checks to warnings, or (c) split behavior correctness from debug-observability checks.
   - Chosen approach: adopt (c) behavior-first assertions for default runs; keep any debug-line checks only in explicitly debug-scoped blocks (with test-local `LAB_LOG_LEVEL_AUX=debug`).
2. Failing category: direct-run bootstrap fragility in `dic_basic_test`.
   - Interfaces affected: direct invocation contract for `bash val/src/dic/dic_basic_test.sh` should not require callers to pre-export `LAB_ROOT`.
   - Constraints: script must continue to run correctly from framework wrapper (`val/src/dic_framework_test.sh`) and from root-level/category runners.
   - Trade-offs: (a) require all callers to export `LAB_ROOT`, or (b) normalize script bootstrap to self-resolve root via `SCRIPT_DIR` fallback like other DIC scripts.
   - Chosen approach: adopt (b), aligning `dic_basic_test` bootstrap with `dic_integration_test`/`dic_phase1_completion_test` (`SCRIPT_DIR` + computed `LAB_ROOT` + `cd "$LAB_ROOT"`).
3. Failing category: inaccurate summary counters in `dic_basic_test`.
   - Interfaces affected: summary contract (`Total Tests`, `Passed`, `Failed`, pass-rate) consumed by `val/src/dic_framework_test.sh` parsing and human triage.
   - Constraints: keep existing human-readable format and simple counter model.
   - Trade-offs: treat setup as a counted test vs keep setup outside test counters.
   - Chosen approach: keep setup outside test counters; only increment pass/fail within numbered tests so totals remain internally consistent.
4. Implementation ordering mandated by design:
   - Update tests first (assertion contracts + bootstrap + counters) before any runtime DIC behavior changes, because current evidence indicates false negatives dominated by test contract coupling rather than runtime injection breakage.
5. Phase 1 completion status:
   - Completion criterion met: this item now includes interfaces, constraints, trade-offs, and chosen approaches for each identified failing category.

## Verification Plan

1. Reproduce and compare isolated DIC tests before/after fixes:
   - `bash val/src/dic_framework_test.sh`
   - `bash val/src/dic/dic_integration_test.sh`
   - `bash val/src/dic/dic_phase1_completion_test.sh`
2. Run category validation target: `./val/run_all_tests.sh src`.
3. Run workflow integrity check: `bash wow/check-workflow.sh`.

## Exit Criteria

1. Design phase is completed and recorded with clear DIC interface/behavior decisions.
2. Planned implementation changes are merged into the working tree with syntax checks passing.
3. `src` category test run is green and captured in this item's update trail.

## Next Step

Completed and moved to `wow/completed/`.

## What changed

1. Test contracts were stabilized around behavior-first assertions at default verbosity in `val/src/dic/dic_basic_test.sh`, `val/src/dic/dic_integration_test.sh`, and `val/src/dic/dic_phase1_completion_test.sh`.
2. `val/src/dic/dic_basic_test.sh` bootstrap was hardened to self-resolve `LAB_ROOT` from script location so direct execution no longer depends on pre-exported `LAB_ROOT`.
3. Debug-only visibility checks were scoped to explicit debug preconditions where retained (`LAB_LOG_LEVEL_AUX=debug`) instead of driving default pass/fail.
4. Basic-suite summary consistency was restored by keeping setup logging informational rather than incrementing pass counters.

## What was verified

1. `bash -n val/src/dic/dic_basic_test.sh` -> pass.
2. `bash -n val/src/dic/dic_integration_test.sh` -> pass.
3. `bash -n val/src/dic/dic_phase1_completion_test.sh` -> pass.
4. `bash val/src/dic/dic_basic_test.sh` -> pass (`9/9`, 100%).
5. `bash val/src/dic/dic_integration_test.sh` -> pass (`20/20`, 100%).
6. `bash val/src/dic/dic_phase1_completion_test.sh` -> pass (`8/8`, COMPLETE).
7. `bash val/src/dic_framework_test.sh` -> pass (all DIC suites).
8. `./val/run_all_tests.sh src` -> pass (`6/6`).

## What remains

No additional follow-up items were identified for this scope.
