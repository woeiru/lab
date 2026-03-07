# Workflow Completed Folder Chronology Checker Issue

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 15:32
- Links: wow/check-workflow.sh, val/core/workflow_checker_test.sh, wow/README.md, wow/completed/20260307-0948_workflow-checker-completed-timestamp-regression-issue/20260307-0914_workflow-checker-completed-timestamp-regression-issue.md

## Goal

Restore `wow/check-workflow.sh` pass status by resolving completed-folder
chronology mismatches in legacy completed topics.

## Context

1. Initial checker output reported chronology failures for two completed topics
   where file timestamp prefixes were newer than folder completion timestamps.
2. The affected topics were historical items under `wow/completed/`.
3. This issue is separate from active architecture migration work and should be
   fixed without coupling to runtime code changes.
4. A prior completed remediation (`20260307-0914_workflow-checker-completed-timestamp-regression-issue.md`) already locked chronology policy as canonical and removed git-history-based checker logic.
5. Current repository audit shows `49` completed topic folders and `0` chronology violations.
6. Fresh validation confirms `bash wow/check-workflow.sh` currently passes with no chronology failures.

## Scope

1. Confirm canonical policy for completed folder chronology checks.
2. Decide whether to fix by folder rename, file move normalization, or checker
   policy adjustment.
3. Apply minimal corrective change preserving workflow invariants.
4. Re-run checker and document outcome.

## Risks

1. Renaming completed topic folders can create noisy git history churn.
2. Weakening checker logic can allow invalid workflow states.
3. Mixed policy handling for old and new topics can reintroduce regressions.

## Triage Decision

- Why now: The workflow checker is currently failing on chronology invariants,
  so this must be triaged now to restore a trustworthy gating signal.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: There are multiple valid remediation paths and the selected
  approach determines checker policy behavior and future completed-folder
  normalization practices.

## Phase 1 Design Deliverable

### Interfaces and constraints

1. Enforcement interface: `bash wow/check-workflow.sh` via `check_completed_structure` must remain deterministic from filesystem state.
2. Policy interfaces: `wow/task/RULES.md` and `wow/README.md` define the canonical chronology invariant for completed topics.
3. Required invariant: completed folder timestamp (`yyyymmdd-hhmm_<topic>`) is greater than or equal to every completed file timestamp prefix inside that topic folder.
4. Historical repository path moves and git first-entry timestamps are non-authoritative for chronology validity.
5. Corrective actions should preserve invariants with minimal churn (targeted folder normalization only when real violations exist).

### Alternatives considered

1. Folder normalization only for violating topics.
   - Pros: keeps checker strict and changes only invalid data.
   - Cons: requires rename churn when violations exist.
2. Checker-policy adjustment to tolerate out-of-order chronology.
   - Pros: fewer folder renames.
   - Cons: weakens invariants and permits invalid completed states.
3. Mixed legacy exception policy (old topics relaxed, new topics strict).
   - Pros: avoids touching historical topics.
   - Cons: introduces dual semantics and long-term regression risk.

### Chosen approach

Keep chronology policy as the single canonical rule and apply targeted folder normalization only when a real violation is present; do not reintroduce git-history-derived timestamp semantics.

## Execution Plan

1. Phase 1 (Design lock) [complete]: Produce canonical chronology-remediation design before implementation work.
   Completion criterion: A documented design artifact in this plan defines interfaces, constraints, trade-offs, and the chosen approach.
2. Phase 2 (Implementation) [complete]: Apply the approved remediation path based on current audit evidence.
   Completion criterion: Either required folder normalizations are applied, or an explicit no-change implementation decision is recorded with supporting audit evidence.
3. Phase 3 (Validation and closeout) [complete]: Validate chronology invariants and closeout readiness.
   Completion criterion: Verification Plan commands pass and their outcomes are recorded in this item.

## Verification Plan

1. Run syntax checks on edited scripts with `bash -n <file>`.
2. Run targeted checker coverage with `./val/core/workflow_checker_test.sh` if checker logic changes.
3. Run end-to-end workflow validation with `./val/integration/complete_workflow_test.sh` when completed-folder behavior is modified.
4. Run the completed-folder chronology audit command and record violation count.
5. Run `bash wow/check-workflow.sh` and require a pass result before closeout.

## Exit Criteria

1. A single canonical chronology policy is documented and reflected in implementation.
2. Historical completed topics comply with the selected policy without introducing mixed-rule behavior.
3. Validation evidence includes passing workflow checker output and any required test runs.

## Progress Checkpoint

### Done

- Completed Phase 1 design lock with interfaces, constraints, alternatives, and chosen approach documented in this item.
- Confirmed canonical chronology policy already matches checker/docs behavior from prior completed remediation.
- Completed Phase 2 with a no-change implementation decision because no real chronology violations were found and canonical policy is already enforced.
- Ran completed-folder chronology audit across all current completed topic folders (`49` scanned, `0` violations).
- Completed Phase 3 validation: `bash wow/check-workflow.sh` passes.

### In-flight

- No active implementation work remains.

### Blockers

- None.

### Next steps

1. Move this item to `wow/completed/` with the recorded no-change decision and validation evidence.
2. Keep chronology monitoring via normal `bash wow/check-workflow.sh` usage in future workflow edits.
3. Optionally run `./val/run_all_tests.sh core` for broader confidence, though no checker code changed here.

## Next Step

Run `wow/task/completed-close` for this item with the no-change implementation
decision and recorded validation evidence.

## What changed

1. Finalized this workflow item with a no-change implementation decision because chronology policy and checker behavior are already aligned.
2. Kept canonical chronology invariant intact: completed folder timestamp must remain greater than or equal to every file timestamp prefix in its topic folder.
3. Transitioned the item lifecycle state from `active` to `completed` and prepared it for archival under `wow/completed/`.

## What was verified

1. `bash wow/check-workflow.sh` -> pass (no workflow structure or chronology violations).
2. Existing audit evidence in this item remains valid: completed-folder scan showed `49` topics with `0` chronology violations.

## What remains

1. No mandatory follow-up work remains.
2. Optional monitoring only: continue normal use of `bash wow/check-workflow.sh` during future workflow edits.
