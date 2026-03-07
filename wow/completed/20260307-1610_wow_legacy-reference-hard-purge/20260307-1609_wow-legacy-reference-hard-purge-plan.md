# WOW Legacy Reference Hard Purge Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 16:10
- Links: wow/task/active-capture, wow/task/completed-close, wow/check-workflow.sh, val/core/workflow_checker_test.sh, doc/ref/stats/actual.md, STATS.md

## Retroactive Capture

- Origin: This started as a quick cleanup request after the workflow board root migration.
- Escalation reason: The scope expanded from one manual page to a repository-wide purge of stale legacy board-path references across active docs, archives, tests, and generated snapshots.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  3. Design classification: required.
- Work so far:
  1. Updated active manuals, architecture docs, workflow docs, and renamed the board manual to `09-wow-workflow-board.md`.
  2. Updated completed and dismissed workflow artifacts that still used stale legacy board wording.
  3. Updated `val/core/workflow_checker_test.sh` fixture logic to preserve migration regression coverage without retaining a literal legacy board token.
  4. Regenerated `STATS.md` and `doc/ref/stats/actual.md`, then normalized legacy board references in historical stats snapshots.
  5. Re-ran workflow validation and regression checks.

## Triage Decision

- Why now: workflow migration integrity is incomplete while stale legacy board references remain in tracked artifacts.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: cleanup policy and scope decisions affect operator documentation trust, reference discoverability, and migration consistency across tooling artifacts.

## Progress Checkpoint

### Done

1. Captured and updated active and archived workflow docs to canonical `wow/` wording.
2. Updated workflow checker regression fixture to keep behavioral coverage while removing literal legacy token usage.
3. Normalized generated stats references and historical snapshot references to canonical `wow/` paths.

### In-flight

1. Final capture and closeout of this emergent cleanup work item.

### Blockers

1. None.

### Next steps

1. Validate the board with `bash wow/check-workflow.sh`.
2. Close this active item to completed with explicit verification evidence.
3. Ensure repository-wide reference scans no longer return legacy board-path matches.

### Context

1. Branch is dirty with unrelated in-progress repository changes.
2. This cleanup touched both active docs and historical archives by design.
3. Workflow regression checks for completed-folder chronology remain green.

## Execution Plan

1. Phase 1 (Design lock): confirm hard-purge scope and exclusions for legacy board references across active docs, archives, tests, and generated artifacts.
   Completion criterion: a single unambiguous purge policy is documented in this item and used consistently.
2. Phase 2 (Implementation closeout): apply final reference replacements and migration-safe fixture updates in any remaining files.
   Completion criterion: no remaining literal legacy board-path tokens in tracked repository content.
3. Phase 3 (Verification and closure): run workflow checker and targeted regression tests, then close to completed with evidence.
   Completion criterion: checker passes and regression suite results are captured in closeout notes.

## Exit Criteria

1. Legacy board-path references are removed from tracked repository files.
2. Workflow board validation passes after cleanup.
3. Regression coverage for root-move chronology behavior remains passing.
4. Completed closeout documents what changed, what was verified, and what remains.

## What changed

1. Replaced stale legacy board-path wording with canonical `wow/` wording across active docs, workflow task docs, and selected historical workflow artifacts.
2. Renamed the workflow board manual to `doc/man/09-wow-workflow-board.md` and updated all linked references.
3. Updated `val/core/workflow_checker_test.sh` to keep root-move regression coverage without retaining a literal legacy board-path token.
4. Regenerated stats outputs and normalized legacy board-path entries in historical `doc/ref/stats/*.json` snapshots.

## What was verified

1. `bash wow/check-workflow.sh` -> pass.
2. `bash -n val/core/workflow_checker_test.sh` -> pass.
3. `bash val/core/workflow_checker_test.sh` -> pass (2 tests, 0 failures).
4. Repository-wide scans for legacy board tokens -> no matches in tracked content trees.

## What remains

1. No mandatory follow-up items.
2. Optional hygiene: continue using canonical `wow/` wording in future historical snapshots and migration notes.
