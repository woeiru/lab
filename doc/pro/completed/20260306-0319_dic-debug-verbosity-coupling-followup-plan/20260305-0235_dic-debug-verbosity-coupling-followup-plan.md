# DIC Debug Verbosity Coupling Follow-up Plan

- Status: completed
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-06 03:19
- Links: val/src/dic/dic_basic_test.sh, val/src/dic/dic_integration_test.sh, val/src/dic/dic_phase1_completion_test.sh, src/dic/ops, lib/gen/aux, lib/core/log, cfg/core/ric, doc/pro/completed/20260305-0235_logging-architectural-restructure/20260303-2246_logging-architectural-restructure-plan.md, doc/pro/completed/20260305-0235_logging-visual-output-redesign/20260303-2247_logging-visual-output-redesign-plan.md

## Goal

Stabilize DIC validation by removing coupling between DIC test pass/fail outcomes
and logging verbosity configuration, so DIC correctness is validated regardless
of terminal log level defaults.

## Context

1. DIC tests in `val/src/dic/*` currently assert on debug-string presence such as
   `Executing`, `Extracted parameters`, and `Using sanitized hostname`.
2. After the logging architectural/visual projects, debug emission is correctly
   gated by `_log_level_permits` and `LAB_LOG_LEVEL` (`normal` by default).
3. At default verbosity, DIC tests can report false negatives even when command
   execution and parameter injection behavior are correct.
4. Reproduced behavior:
   - `./val/run_all_tests.sh dic` fails selected DIC tests at default settings.
   - `LAB_LOG_LEVEL_AUX=debug ./val/run_all_tests.sh dic` passes all DIC tests.
5. Direct targeted run reproduction with explicit root confirms coupling:
   - `LAB_ROOT=/home/es/lab bash val/src/dic/dic_basic_test.sh` fails on debug-text assertions.
   - `LAB_ROOT=/home/es/lab LAB_LOG_LEVEL_AUX=debug bash val/src/dic/dic_basic_test.sh` passes those checks.
6. `OPS_DEBUG=1` is present across DIC tests, but debug text still depends on
   active log-level gating and is not guaranteed at default verbosity.
7. `val/src/dic/dic_basic_test.sh` currently increments `TESTS_PASSED` during
   setup (`log_success "Test environment setup complete"`) without a matching
   test counter increment, which can produce pass rates above 100%.
8. Debug-text checks are currently mixed with functional assertions in the same
   phase blocks, making diagnosis harder when verbosity changes.
9. Implemented behavior-first assertion updates in all three scoped test files:
   `val/src/dic/dic_basic_test.sh`, `val/src/dic/dic_integration_test.sh`, and
   `val/src/dic/dic_phase1_completion_test.sh`.
10. Added explicit debug preconditions (`LAB_LOG_LEVEL_AUX=debug`) only where
    debug-text diagnostics are intentionally validated.
11. Fixed summary-counter skew by removing setup-phase pass increments from
    `dic_basic` and `dic_integration`.
12. Added deterministic test-environment setup in `dic_phase1_completion` so
    hostname-specific injected values are available on non-cluster hostnames.
13. Verification results across both verbosity modes now pass for all three
    targeted scripts.

## Scope

1. Update DIC test assertions to validate functional outcomes and structured
   behavior contracts without depending on debug-terminal visibility.
2. Where debug text checks remain necessary, set explicit per-test logging
   preconditions (for example `LAB_LOG_LEVEL_AUX=debug`) inside the test scope.
3. Audit DIC test scripts for counter/reporting consistency (`TESTS_TOTAL`,
   `TESTS_PASSED`, and displayed pass-rate math) to avoid misleading summaries.
4. Document expected debug-gating behavior in DIC test notes/README context.

## Risks

1. Over-relaxing assertions could hide real DIC regressions if behavioral checks
   are replaced with weak output checks.
2. Test-local verbosity overrides can mask global configuration drift if not
   clearly scoped and documented.
3. Mixed legacy and modern DIC test expectations may create temporary confusion
   until all scripts align on the same pass criteria.

## Triage Decision

- Why now: DIC validation currently depends on verbosity-gated debug text, causing false negatives at default log levels and reducing trust in CI outcomes.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes -- assertions can be shifted to functional outcomes, debug checks can be scoped with explicit per-test log-level setup, or debug-output checks can be isolated into dedicated tests.
  2. Will other code or users depend on the shape of the output? Yes -- DIC test contracts and summaries are used by developers and CI to interpret behavior and regressions.
  - Design: required
- Justification: Multiple viable implementation paths affect shared test contracts, so this needs an explicit design choice to keep validation reliable.

## Execution Plan

### Phase 1 -- Design Decision Record for DIC Test Contracts

1. [x] Define the exact interface contracts each DIC test validates (functional behavior, error semantics, and reporting invariants) across `dic_basic`, `dic_integration`, and `dic_phase1_completion`.
2. [x] Document constraints (verbosity gating defaults, test portability, and CI readability) and alternatives for assertion strategy.
3. [x] Select the target contract shape and map each current debug-coupled assertion to its replacement strategy.

Completion criterion: this active item contains a concrete design decision record documenting interfaces, constraints, trade-offs, and the chosen approach before implementation starts.

## Phase 1 Design Decision Record

Date: 2026-03-06
Design classification: required

1. Interface contracts by test script:
   - `val/src/dic/dic_basic_test.sh`: remains a fast smoke suite; pass/fail must
     be based on command success/failure and stable functional outputs, not on
     visibility of debug-only log lines.
   - `val/src/dic/dic_integration_test.sh`: keeps broader behavior checks, but
     debug-dependent diagnostics are explicitly separated from functional
     contracts and run only under explicit debug preconditions.
   - `val/src/dic/dic_phase1_completion_test.sh`: preserves phase-1 regression
     intent while scoping any debug-text assertions to clearly debug-enabled
     checks.
2. Required invariants:
   - Default log-level runs must still validate DIC correctness.
   - Debug-level runs must validate optional diagnostic visibility without
     changing core correctness outcomes.
   - Summary counters must remain internally consistent (`TESTS_TOTAL`,
     `TESTS_PASSED`, `TESTS_FAILED`, and pass-rate math).
3. Constraints:
   - Logging output is now gated by `_log_level_permits` and
     `LAB_LOG_LEVEL_AUX`/`LAB_LOG_LEVEL` defaults.
   - Existing scripts are shell-native and should keep lightweight direct-run
     ergonomics (`bash val/src/dic/...`).
   - Assertions should avoid fragile coupling to formatting/details that are
     intended as diagnostics rather than contracts.
4. Alternatives considered:
   - Force debug globally in all DIC tests: easy migration, but it defeats the
     default-verbosity correctness requirement.
   - Keep debug-string assertions but downgrade most to warnings: reduces hard
     failures, but weakens contract clarity and can hide regressions.
   - Shift to behavior-first assertions and explicitly scope diagnostic checks
     under debug preconditions: strongest separation of correctness vs
     observability.
5. Chosen approach:
   - Adopt behavior-first assertions for pass/fail in default runs.
   - Keep targeted debug-output checks only where they provide specific value,
     and gate those checks with explicit per-test debug preconditions.
   - Fix counter accounting so setup steps are not counted as test passes.
6. Mapping from current debug-coupled checks:
   - `Executing.*sys_dpa.*-x` -> verify callable success and expected command
     effect/output contract for `sys dpa -x` without requiring debug text.
   - `Extracted parameters.*vm_id.*cluster_nodes` -> verify argument resolution
     behavior through exit/result conditions (and keep debug-line validation
     only in explicitly debug-scoped diagnostics).
   - `Using sanitized hostname.*<hostname>` -> verify hostname-dependent
     resolution behavior by functional outcome, not by debug-line presence.
7. Phase 1 completion status:
   - Completion criterion met: this design record now documents interfaces,
     constraints, trade-offs, and chosen approach; implementation starts in
     Phase 2.

### Phase 2 -- Implement Assertion and Reporting Updates

1. [x] Update DIC tests to assert on functional outcomes at default verbosity and keep debug-text assertions only where explicitly scoped within the test.
2. [x] Normalize pass/fail accounting and pass-rate math so summaries are internally consistent.
3. [x] Add concise test notes where needed to clarify expected debug-gating behavior.

Completion criterion: the scoped DIC test files are updated with no default-verbosity pass/fail coupling and with consistent summary counters.

### Phase 3 -- Verify Behavior Across Verbosity Modes

1. [x] Run targeted DIC tests with default logging and with explicit debug logging.
2. [x] Compare outcomes to confirm correctness checks are stable across verbosity settings.
3. [x] Capture verification evidence and remaining follow-up items, if any.

Completion criterion: planned verification commands complete successfully and demonstrate stable DIC correctness outcomes across default and debug verbosity modes.

Verification evidence:
- `LAB_ROOT=/home/es/lab bash val/src/dic/dic_basic_test.sh` -> pass (9/9).
- `LAB_ROOT=/home/es/lab bash val/src/dic/dic_integration_test.sh` -> pass (20/20).
- `LAB_ROOT=/home/es/lab bash val/src/dic/dic_phase1_completion_test.sh` -> pass (8/8).
- `LAB_ROOT=/home/es/lab LAB_LOG_LEVEL_AUX=debug bash val/src/dic/dic_basic_test.sh` -> pass (9/9).
- `LAB_ROOT=/home/es/lab LAB_LOG_LEVEL_AUX=debug bash val/src/dic/dic_integration_test.sh` -> pass with no failures (19 pass, 0 fail, 1 warning for non-deterministic cache timing).
- `LAB_ROOT=/home/es/lab LAB_LOG_LEVEL_AUX=debug bash val/src/dic/dic_phase1_completion_test.sh` -> pass (8/8).

## Verification Plan

1. Run `bash val/src/dic/dic_basic_test.sh` with `LAB_ROOT=/home/es/lab`.
2. Run `bash val/src/dic/dic_integration_test.sh` with `LAB_ROOT=/home/es/lab`.
3. Run `bash val/src/dic/dic_phase1_completion_test.sh` with `LAB_ROOT=/home/es/lab`.
4. Repeat the same three commands with `LAB_LOG_LEVEL_AUX=debug`.
5. Run `bash doc/pro/check-workflow.sh` before any further state move.

## Exit Criteria

1. Phase 1 design decision record is complete and implementation follows the selected contract approach.
2. DIC tests validate functional behavior independent of default terminal verbosity.
3. Any remaining debug-output assertions are explicitly scoped to debug-enabled test contexts.
4. Test summaries report consistent totals/pass/fail counts and accurate pass-rate math.
5. Targeted DIC verification passes in both default and debug verbosity runs.

## What changed

1. Updated DIC assertion strategy in `val/src/dic/dic_basic_test.sh`,
   `val/src/dic/dic_integration_test.sh`, and
   `val/src/dic/dic_phase1_completion_test.sh` to validate functional outcomes
   at default verbosity instead of requiring debug-text visibility.
2. Scoped retained debug-output checks behind explicit test-local debug
   preconditions (`LAB_LOG_LEVEL_AUX=debug`).
3. Fixed reporting consistency by removing setup-phase pass increments that were
   inflating pass-rate math.
4. Added deterministic test-environment setup in `dic_phase1_completion` so
   hostname-specific injected values are available during validation.
5. Completed the design-phase decision record and execution-phase tracking in
   this workflow artifact.

## What was verified

1. Syntax checks:
   - `bash -n val/src/dic/dic_basic_test.sh`
   - `bash -n val/src/dic/dic_integration_test.sh`
   - `bash -n val/src/dic/dic_phase1_completion_test.sh`
   - Result: pass.
2. Targeted dual-verbosity verification:
   - `LAB_ROOT=/home/es/lab bash val/src/dic/dic_basic_test.sh` -> pass (9/9).
   - `LAB_ROOT=/home/es/lab bash val/src/dic/dic_integration_test.sh` -> pass (20/20).
   - `LAB_ROOT=/home/es/lab bash val/src/dic/dic_phase1_completion_test.sh` -> pass (8/8).
   - `LAB_ROOT=/home/es/lab LAB_LOG_LEVEL_AUX=debug bash val/src/dic/dic_basic_test.sh` -> pass (9/9).
   - `LAB_ROOT=/home/es/lab LAB_LOG_LEVEL_AUX=debug bash val/src/dic/dic_integration_test.sh` -> pass with no failures (19 pass, 0 fail, 1 warning for non-deterministic cache timing).
   - `LAB_ROOT=/home/es/lab LAB_LOG_LEVEL_AUX=debug bash val/src/dic/dic_phase1_completion_test.sh` -> pass (8/8).
3. Category suite requested for closeout:
   - `./val/run_all_tests.sh dic` -> pass (5 tests, 0 failed).
4. Workflow validation:
   - `bash doc/pro/check-workflow.sh` -> pass.

## What remains

No additional follow-up items identified from this execution.
