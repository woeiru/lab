# Restore `dev_oar` and `dev_oad` Functions Plan

- Status: completed
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-05 22:50:15
- Links: commit 35551b7c4da093d87e866186358b94e1e0bfab17, doc/pro/task/inbox-capture

## Goal

Reintroduce the `dev_oar` and `dev_oad` functions that were extracted/removed,
while preserving compatibility with the current module state.

## Context

1. The functions `dev_oar` and `dev_oad` existed before and were removed in
   commit `35551b7c4da093d87e866186358b94e1e0bfab17`.
2. The user now needs both functions back in the active codebase.
3. There is explicit risk that surrounding module code has changed since the
   extraction, so a direct revert/cherry-pick may introduce drift or breakage.
4. Commit archaeology confirms removal touched `lib/ops/dev`, `cfg/core/lzy`,
   and `val/lib/ops/dev_test.sh`; no additional runtime modules were changed.
5. Current helper contracts used by the historical implementations still exist
   (`_dev_get_antigravity_accounts_path`, `_dev_reconcile_antigravity_accounts`,
   `_dev_add_antigravity_denylist_entry`, `_dev_record_account_event`).
6. Restoration was implemented as an adapted selective transplant to keep
   current module ordering and validation style while preserving behavior.
7. Local verification after restoration: `bash -n` for touched files and
   `./val/lib/ops/dev_test.sh` passed (`68/68`).

## Triage Decision

- Why now: This request is immediate and unblocker-level because the user needs
  `dev_oar` and `dev_oad` restored now, and delayed triage would prolong missing
  functionality.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Classification rationale: The restoration can be implemented via straight
  revert, selective transplant, or compatibility adaptation, and the selected
  behavior/contract will directly affect downstream callers and module stability.

## Scope

1. Locate the historical definitions of `dev_oar` and `dev_oad` in the cited
   commit and capture their behavior contracts (inputs, outputs, return codes,
   logging style, and dependencies).
2. Diff the current target module(s) against the historical context to identify
   interface or dependency changes introduced after extraction.
3. Reintroduce both functions by adapting internals to current conventions,
   preserving original intent while avoiding regressions in updated paths.
4. Update any related wiring or references required by current lazy-loading,
   function maps, usage/help docs, and tests.
5. Validate with syntax checks and the nearest relevant test coverage before
   promoting beyond inbox planning.

## Risks

1. Hidden dependency drift can cause runtime errors if old helper calls no
   longer exist or have changed signatures.
2. Reintroduced behavior may conflict with newer module responsibilities or
   naming conventions introduced after extraction.
3. Missing updates to lazy-load maps/docs/tests can leave functions present in
   source but inaccessible or unverified in normal workflows.

## Execution Plan

### Phase 1 -- Design Restoration Contract [done]

1. Recover `dev_oar` and `dev_oad` behavior from commit
   `35551b7c4da093d87e866186358b94e1e0bfab17` and compare it to current module
   interfaces/dependencies.
2. Decide and document the restoration strategy (revert, selective transplant,
   or adapted reimplementation) with explicit interfaces, constraints,
   trade-offs, and chosen approach.

Completion criterion: this file contains a completed design decision record for
`dev_oar` and `dev_oad` restoration with the chosen approach. [met]

### Phase 2 -- Implement Chosen Restoration [done]

1. Reintroduce `dev_oar` and `dev_oad` in the current module using the chosen
   design approach.
2. Update any required wiring (for example lazy-load maps and related
   references) so both functions are callable in the current loading model.

Completion criterion: both functions exist in the active code path and resolve
correctly with no unresolved restoration TODOs. [met]

### Phase 3 -- Verify Behavior and Regression Safety [done]

1. Run syntax checks for touched Bash files.
2. Run the nearest relevant tests for the affected module(s) and confirm the
   restored functions do not break current behavior.

Completion criterion: verification evidence shows syntax checks and targeted
tests pass for the restored functionality. [met]

## Phase 1 Design Decision Record

Date: 2026-03-05
Design classification: required

1. Interfaces:
   - Public functions restored: `dev_oar <account_number>`,
     `dev_oad <account_number>`.
   - Return semantics preserved: `0` success, `1` usage/domain validation,
     `2` runtime/python failure, `127` missing python.
2. Constraints:
   - Preserve existing account JSON/reroute semantics used by account switch,
     quota, and load-balance workflows.
   - Keep lazy-load availability aligned via `cfg/core/lzy` updates.
   - Keep tests deterministic in isolated temp HOME environments.
3. Alternatives considered:
   - Straight revert of full commit range touching these functions.
   - Selective transplant of just removed function/test/lazy-map hunks.
   - New implementation from scratch using newer abstractions only.
4. Chosen approach: selective transplant with compatibility validation.
5. Justification: this restores known user-facing behavior quickly while
   minimizing risk of reintroducing unrelated legacy state and ensuring current
   module wiring/test expectations remain intact.

## Progress Checkpoint

### Done

1. Restored `dev_oar` and `dev_oad` implementations in `lib/ops/dev`.
2. Restored lazy stubs for `dev_oar` and `dev_oad` in `cfg/core/lzy`.
3. Restored targeted regression coverage and function-existence assertions in
   `val/lib/ops/dev_test.sh`.

### Validation status

1. `bash -n lib/ops/dev` -> pass
2. `bash -n cfg/core/lzy` -> pass
3. `bash -n val/lib/ops/dev_test.sh` -> pass
4. `./val/lib/ops/dev_test.sh` -> pass (`68/68`)

## Verification Plan

1. Run `bash -n` on each modified Bash file.
2. Run the nearest targeted tests covering the restored module behavior.
3. Run `bash doc/pro/check-workflow.sh` before any status transition.

## Exit Criteria

1. `dev_oar` and `dev_oad` are restored in current module code with design
   rationale captured. [met]
2. Required loader/wiring references are updated so both functions are usable.
   [met]
3. Syntax checks, targeted tests, and workflow validation are all passing.
   [met]

## What changed

1. Restored `dev_oar` and `dev_oad` function implementations in `lib/ops/dev`.
2. Restored lazy-load map wiring for `dev_oar`/`dev_oad` in `cfg/core/lzy`.
3. Restored function existence assertions and dedicated regression tests in
   `val/lib/ops/dev_test.sh`.
4. Completed workflow state transition from active execution to completed
   artifact for this restoration request.

## What was verified

1. `bash -n lib/ops/dev` -> pass
2. `bash -n cfg/core/lzy` -> pass
3. `bash -n val/lib/ops/dev_test.sh` -> pass
4. `./val/lib/ops/dev_test.sh` -> pass (`68/68`)
5. `bash doc/pro/check-workflow.sh` -> pass

## What remains

No follow-up items are required for this restoration request.
