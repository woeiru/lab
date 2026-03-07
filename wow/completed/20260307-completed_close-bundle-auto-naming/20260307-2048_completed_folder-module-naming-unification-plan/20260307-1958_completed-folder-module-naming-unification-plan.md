# Completed Folder Module Naming Unification Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 20:48
- Links: wow/README.md, wow/task/RULES.md, wow/task/completed-close, wow/task/completed-close-bundle, wow/task/maintenance, wow/check-workflow.sh

## Goal

- Introduce a uniform completed folder naming convention that always includes a module key after the close timestamp.
- Enable deterministic post-hoc bundling and daily maintenance automation without manual folder triage.

## Context

1. The current standard close path creates folders as `yyyymmdd-hhmm_<topic>`.
2. Explicit module identity exists only in bundle folders (`yyyymmdd-hhmm-bundle-<module-slug>`).
3. Retrospective grouping of standard completed folders by module is currently heuristic and costly.
4. A maintenance workflow is desired to compact one day of module-related completed work into bundle outputs and produce a summary.
5. The completion timestamp in standard close folders is a key ordering signal
   and must remain immutable.
6. Daily/module bundling should reduce top-level noise without destroying exact
   completion chronology captured by close-time folder names.

## Scope

1. Define a v2 standard completed folder format with explicit module segment (example candidate: `yyyymmdd-hhmm_<module>__<topic>`).
2. Update workflow contracts and validation logic in:
   - `wow/README.md`
   - `wow/task/RULES.md`
   - `wow/check-workflow.sh`
   - `wow/task/completed-close` (and related close tasks if required)
3. Design a backward-compatible migration strategy for existing completed folders.
4. Define maintenance task behavior for day-scoped module bundling and summary generation.

## Risks

1. Partial rollout can desynchronize checker rules and task behavior.
2. Folder migrations can produce large rename diffs and merge friction.
3. Legacy folders without explicit module tags may require manual mapping.
4. Aggressive compaction can reduce traceability if summary metadata is incomplete.

## Next Step

Phase 2 and Phase 3 implementation/validation are complete; next step is
workflow closeout for this active plan.

## Triage Decision

- Why now: `wow/completed/` is growing quickly and current folder naming lacks
  deterministic module identity on standard close paths, which blocks safe
  post-hoc bundling and increases maintenance overhead.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: folder schema, checker contracts, and maintenance automation
  outputs are shared workflow surfaces that require a stable design contract.

## Documentation Impact

- Docs: required
- Target docs (initial): `wow/README.md`, `wow/task/RULES.md`,
  `wow/task/completed-close`, `wow/task/completed-close-bundle`,
  `wow/task/maintenance`, `doc/man/09-wow-workflow-board.md`

## Execution Plan

1. [complete] Phase 1 - Naming and bundling design baseline.
   Completion criterion met: this item includes the approved design artifact
   with interfaces, constraints, trade-offs, and chosen naming/bundling
   approach.
2. [complete] Phase 2 - Workflow contract and checker implementation.
   Completion criterion: task templates/checker/docs are updated to support the
   new folder schema and maintenance bundle model without breaking legacy paths.
3. [complete] Phase 3 - Validation and migration evidence.
   Completion criterion: checker/tests pass and migration notes are captured
   with explicit backward-compatibility behavior.

## Verification Plan

1. Run `bash -n wow/check-workflow.sh` if checker logic changes.
2. Run `bash wow/check-workflow.sh` after every workflow doc/state update.
3. Verify all target docs are updated consistently with the chosen schema.
4. If reference-visible structure changes, run `./utl/ref/run_all_doc.sh` and
   record output in this item.

## Exit Criteria

1. Standard close and maintenance-bundle naming contracts are explicitly
   defined, deterministic, and conflict-safe.
2. Checker and task surfaces enforce the new model while preserving readable
   compatibility for existing completed history.
3. Validation evidence is recorded with no unresolved structural regressions.

## Phase 1 Design Deliverable

## Interfaces (Contract)

1. Standard close output (immutable leaf):
   `wow/completed/<yyyymmdd-hhmm>_<module>_<task-slug>/`.
2. Maintenance bundle container (grouping folder):
   `wow/completed/<yyyymmdd>-<module>_<essence-slug>/`.
3. Maintenance operation:
   move existing immutable close folders into bundle containers without renaming
   leaf folders.
4. Summary artifact contract:
   each bundle container contains one summary markdown file describing grouped
   leaves, date window, and module essence.

## Constraints

1. Preserve full close timestamp (`yyyymmdd-hhmm`) for every leaf folder.
2. Never rewrite existing leaf timestamps during maintenance bundling.
3. Require module token for all new standard closes.
4. Support cross-cutting work via canonical module token (`multi`).
5. Keep migration backward-compatible for legacy completed folders.

## Trade-offs

1. Date+module bundle containers reduce root noise but add one nesting level.
2. Immutable leaf folders preserve chronology but require checker support for
   two-level completed layouts.
3. Essence slugs improve scanability but require deterministic generation rules
   to avoid rename churn.

## Chosen Approach

1. Use immutable timestamped leaf folders from `completed-close` with mandatory
   module segment: `<yyyymmdd-hhmm>_<module>_<task-slug>`.
2. Add maintenance bundling that groups leaf folders by day+module into
   `<yyyymmdd>-<module>_<essence-slug>` containers.
3. Keep leaf names unchanged when grouped; only container structure changes.
4. Update checker/task/docs in one rollout so close, maintenance, and
   validation contracts stay synchronized.

## Progress Log

1. Phase 1 design baseline completed in this item with explicit interfaces,
   constraints, trade-offs, and chosen approach.
2. Phase 2 started with implementation targets locked:
   `wow/check-workflow.sh`, `wow/task/completed-close`,
   `wow/task/completed-close-bundle`, `wow/task/maintenance`,
   `wow/README.md`, and `wow/task/RULES.md`.
3. Next implementation step is checker/rules support for nested bundle
   containers while preserving immutable close-time leaf folders.
4. Implemented Phase 2 contracts in `wow/check-workflow.sh`,
   `wow/task/completed-close`, `wow/task/completed-close-bundle`,
   `wow/task/maintenance`, `wow/task/RULES.md`, `wow/README.md`, and
   `doc/man/09-wow-workflow-board.md`.
5. Finalized backward-compatibility policy as dual-accept (new v2 layout plus
   legacy completed folder formats) with enforcement in checker rules/docs.
6. Added regression coverage for v2 container behavior in
   `val/core/workflow_checker_test.sh`.
7. Validation evidence captured: `bash -n wow/check-workflow.sh`,
   `bash -n val/core/workflow_checker_test.sh`,
   `bash val/core/workflow_checker_test.sh` (pass), and
   `bash wow/check-workflow.sh` (pass).

## Progress Checkpoint

### Done

1. Moved this item through workflow states and prepared it for execution:
   `wow/inbox/20260307-1958_completed-folder-module-naming-unification-plan.md`
   -> `wow/queue/20260307-1958_completed-folder-module-naming-unification-plan.md`
   -> `wow/active/20260307-1958_completed-folder-module-naming-unification-plan.md`.
2. Added `## Triage Decision`, `## Documentation Impact`, `## Execution Plan`,
   `## Verification Plan`, and `## Exit Criteria` for active execution.
3. Completed Phase 1 design deliverable with explicit immutable leaf naming,
   day+module bundle-container naming, and no leaf timestamp rewrites.
4. Locked module token policy direction (`<module>` required for new closes,
   `multi` as cross-cutting fallback) and bundle summary artifact expectation.
5. Validation run summary: `bash wow/check-workflow.sh` passed after state and
   plan updates.
6. Completed Phase 2 implementation updates across checker, workflow task
   templates, and docs for v2 naming + maintenance containers.
7. Completed Phase 3 validation and migration evidence capture with a
   dual-accept compatibility policy (v2 + legacy accepted).
8. Added/ran workflow checker regression tests covering valid v2 container
   layout and container-module mismatch rejection.

### In-flight

1. No active implementation work remains in this item.
2. Item is ready for closeout via `wow/task/completed-close`.

### Blockers

1. No blockers.

### Next steps

1. Close this active item with `wow/task/completed-close` when ready.
2. If desired before close, run broader workflow validation (`bash
   wow/check-workflow.sh` is already passing for this change set).

### Context

1. Branch: `master`.
2. Worktree is dirty with unrelated pre-existing edits in `doc/ref/*`,
   `lib/gen/ana`, `lib/ops/gpu`, and other workflow files; do not assume a
   clean baseline.
3. Legacy compatibility decision chosen and implemented as dual-accept in
   checker + docs (no forced migration of historical completed folders).
4. Latest workflow validation status for this item: checker pass and workflow
   checker regression suite pass.

## What changed

1. Implemented and documented the v2 completed naming contract with immutable
   leaf folders (`yyyymmdd-hhmm_<module>_<task-slug>`) and maintenance
   containers (`yyyymmdd-<module>_<essence-slug>`).
2. Updated workflow enforcement and templates:
   `wow/check-workflow.sh`, `wow/task/RULES.md`,
   `wow/task/completed-close`, `wow/task/completed-close-bundle`,
   `wow/task/maintenance`, and `wow/task/active-reopen`.
3. Added regression tests for v2 container behavior in
   `val/core/workflow_checker_test.sh`.
4. Documentation files updated:
   `wow/README.md`, `doc/man/09-wow-workflow-board.md`,
   `wow/task/RULES.md`, `wow/task/completed-close`,
   `wow/task/completed-close-bundle`, and `wow/task/maintenance`.

## What was verified

1. `bash -n wow/check-workflow.sh` -> pass.
2. `bash -n val/core/workflow_checker_test.sh` -> pass.
3. `bash val/core/workflow_checker_test.sh` -> pass (4/4 tests passed).
4. `bash wow/check-workflow.sh` -> pass.
5. Docs: updated (`wow/README.md`, `doc/man/09-wow-workflow-board.md`,
   `wow/task/RULES.md`, `wow/task/completed-close`,
   `wow/task/completed-close-bundle`, `wow/task/maintenance`).
6. `./utl/ref/run_all_doc.sh` not run (no `lib/` public function surface
   changes in this workflow-only update).

## What remains

1. No mandatory follow-up identified.
