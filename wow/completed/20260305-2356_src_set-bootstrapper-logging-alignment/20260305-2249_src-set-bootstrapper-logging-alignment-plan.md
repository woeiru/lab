# src/set Bootstrapper and Logging Alignment Plan

- Status: completed
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-05 23:54:18
- Links: src/set/.menu, src/set/h1, src/set/c1, src/set/c2, src/set/c3, src/set/t1, src/set/t2, bin/ini, bin/orc, lib/core/log, lib/gen/aux, doc/arc/07-logging-and-error-handling.md, doc/arc/src-set-bootstrapper-logging-alignment.md, val/src/dic/dic_set_menu_contract_test.sh

## Goal

Align `src/set` playbook execution with the revamped bootstrapper and logging
system so deployment scripts remain predictable, debuggable, and consistent
across interactive and execution modes.

## Context

1. The bootstrapper redesign changed how modules are sourced and initialized.
2. The logging redesign introduced stricter structured logging expectations and
   severity gating behavior.
3. Existing `src/set` assets still include legacy startup and output patterns,
   including plain debug prints and direct sourcing assumptions.
4. Without alignment, `src/set` may diverge from the current runtime contract,
   causing brittle execution or inconsistent operator feedback.
5. Execution audit found startup debug prints in all runbooks (`h1`, `c1`,
   `c2`, `c3`, `t1`, `t2`) that bypass structured logging controls.
6. Execution audit found `clean_exit` calls in all runbooks while only
   `err_clean_exit` is defined in core error handling.
7. Execution audit confirmed `.menu` currently mixes interactive UI rendering
   and operational diagnostics in the same output layer.
8. Execution audit confirmed `.menu` performs eager auto-sourcing by default,
   creating source-time side effects that should be made explicit and idempotent.
9. `.menu` now uses explicit setup orchestration (`menu_runtime_setup`) and no
   longer performs eager source-time auto-sourcing unless explicitly enabled via
   `LAB_MENU_AUTO_SOURCE_ON_SOURCE=1`.
10. `.menu` now provides `clean_exit` compatibility mapped to `err_clean_exit`
    where available, resolving the runbook exit helper mismatch.
11. All target runbooks now use a common bootstrap contract: source `.menu`,
    source `src/dic/ops`, call `menu_runtime_setup`, then dispatch through
    `setup_main`.
12. Added a dedicated alignment contract test at
    `val/src/dic/dic_set_menu_contract_test.sh` and updated logging architecture
    docs to capture the new `src/set` runtime/logging contract.
13. Validation results: `bash -n` passed for all updated `src/set` files;
    `./val/src/dic/dic_set_menu_contract_test.sh` passed; existing unrelated
    DIC suite failures remain in `./val/run_all_tests.sh src`.

## Scope

1. Audit all `src/set` runbooks and `.menu` for bootstrap dependency and source
   order assumptions against current bootstrap flow.
2. Replace legacy logging touchpoints in the `src/set` layer with the modern
   logging interfaces while preserving intentional menu/display output.
3. Standardize entrypoint behavior (`-i`, `-x`, usage, return codes, and setup)
   to match current bootstrap and runtime conventions.
4. Add or adjust validation coverage for `src/set` execution paths under current
   logging defaults and debug-level overrides.
5. Update related documentation so `src/set` behavior matches the current
   architecture narrative.

## Risks

1. Shared `.menu` changes can impact every host runbook at once.
2. Logging migration may accidentally suppress critical operator-visible details.
3. Bootstrap alignment may reveal hidden dependencies on legacy globals.
4. Interactive output quality could regress if menu rendering and structured
   logging are not cleanly separated.

## Triage Decision

1. Why now: `src/set` is directly exposed to the bootstrapper and logging
   revamps, so delaying alignment increases drift and raises operational risk.
2. Design classification questions:
   - Are there meaningful alternatives for how to solve this? Yes.
   - Will other code or users depend on the shape of the output? Yes.
3. Design: required
4. Justification: the migration has multiple viable implementation paths and its
   output contract affects runbooks, operators, and downstream tests/docs.

## Execution Plan

Phase 1: Produce a `src/set` alignment design note that defines target
interfaces, bootstrap/logging constraints, migration trade-offs, and the chosen
approach for `.menu` and runbooks.
Completion criterion: concrete deliverable committed at
`doc/arc/src-set-bootstrapper-logging-alignment.md`.
Status: done (2026-03-05 23:35). Criterion met.

Phase 2: Implement `.menu` alignment to the approved design, including startup
flow and structured logging boundaries for shared menu behavior.
Completion criterion: measurable target of zero legacy bootstrap/logging
patterns remaining in `src/set/.menu`.
Status: done (2026-03-05 23:46). Criterion met.

Phase 3: Implement runbook updates (`src/set/h1`, `src/set/c1`, `src/set/c2`,
`src/set/c3`, `src/set/t1`, `src/set/t2`) to match the approved design for
entrypoint behavior, sourcing, and logging usage.
Completion criterion: measurable target of all listed runbooks conforming to
the design-defined bootstrap and logging contract.
Status: done (2026-03-05 23:46). Criterion met.

Phase 4: Add or update validation coverage and workflow docs to codify the new
behavior under default and debug logging modes.
Completion criterion: concrete deliverable of updated tests/docs merged for the
`src/set` alignment scope.
Status: done (2026-03-05 23:46). Criterion met.

## Progress

- [x] Phase 1 / Step 1: Audited `src/set/.menu`, runbooks, bootstrapper, and
      logging architecture references.
- [x] Phase 1 / Step 2: Defined target interfaces, constraints, and
      alternatives for bootstrap/logging alignment.
- [x] Phase 1 / Step 3: Produced design deliverable at
      `doc/arc/src-set-bootstrapper-logging-alignment.md`.
- [x] Phase 2: Implemented `.menu` explicit setup and structured diagnostic
      logging alignment.
- [x] Phase 3: Updated all scoped runbooks to the standardized bootstrap and
      setup contract.
- [x] Phase 4: Added alignment validation coverage and updated architecture
      documentation.

## Verification Plan

1. Run syntax checks (`bash -n`) on each modified `src/set` file and any
   affected bootstrap/logging scripts.
2. Run focused test scripts that cover `src/set` execution and logging behavior,
   then run the relevant category in `./val/run_all_tests.sh` if multiple
   modules are touched.
3. Confirm interactive menu output remains intentionally user-facing while
   operational logs route through structured logging helpers.
4. Reconcile updated architecture/usage docs with implemented behavior and test
   coverage.

## Exit Criteria

The `src/set` layer executes through the current bootstrap contract, emits
logging through approved structured interfaces, preserves intentional interactive
menu output, and is backed by passing validation plus updated documentation that
matches runtime behavior.

## What changed

1. Finalized the `src/set` bootstrapper/logging alignment workflow item into
   completed state and moved it under a completion-timestamped topic folder.
2. Captured final implementation outcomes for `.menu`, all scoped runbooks, the
   alignment contract test, and architecture docs in a completed artifact.
3. Added a new inbox follow-up item for pre-existing DIC suite failures that
   were observed during verification but are outside this item's scope.

## What was verified

1. `bash -n src/set/.menu src/set/h1 src/set/c1 src/set/c2 src/set/c3 src/set/t1 src/set/t2` -> pass
2. `./val/src/dic/dic_set_menu_contract_test.sh` -> pass
3. `./val/run_all_tests.sh src` -> fail (known pre-existing failures in
   `dic_framework_test`, `dic_integration_test`, and
   `dic_phase1_completion_test`)
4. `bash wow/check-workflow.sh` -> pass

## What remains

1. Triage and resolve the pre-existing `src` DIC failures tracked in
   `wow/inbox/20260305-2354_src-dic-preexisting-failures-followup-plan.md`.
