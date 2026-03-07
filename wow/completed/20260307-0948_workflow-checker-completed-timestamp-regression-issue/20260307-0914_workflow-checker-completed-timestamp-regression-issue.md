# Workflow Checker Completed Timestamp Regression Issue

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 09:48
- Links: wow/check-workflow.sh, val/core/workflow_checker_test.sh, wow/README.md, wow/task/active-start, wow/completed/

## Goal

Restore stable `wow/check-workflow.sh` pass behavior for historical
`wow/completed/` items by resolving false-positive completed-folder timestamp
failures.

## Context

1. Running `bash wow/check-workflow.sh` now reports many failures of type
   `completed folder move timestamp`.
2. Failures are workspace-wide across historical `wow/completed/*` topics and
   were observed while updating a separate active architecture item.
3. Reported mismatches reference `topic first completed-entry commit`
   timestamps rather than folder naming timestamps, indicating a checker-policy
   or migration-history interpretation regression.

## Scope

1. Reproduce and isolate the checker logic that computes completed-folder move
   timestamp expectations.
2. Decide the intended policy for historical moved content versus newly created
   completed topics.
3. Implement checker or data migration fix to eliminate false positives without
   weakening required workflow invariants.
4. Add regression coverage for completed-topic timestamp validation.

## Risks

1. Over-correcting checker logic may permit invalid completed-folder states.
2. Bulk folder renaming to satisfy transient logic can create high-noise git
   churn.
3. Inconsistent policy between docs and checker logic can reintroduce failures.

## Next Step

Keep chronology policy as canonical and monitor future workflow changes through
regression coverage.

## Triage Decision

- Why now: The checker is currently blocking workflow validation across historical completed items, so fixing the regression is needed immediately to restore reliable board operations.
- Are there meaningful alternatives for how to solve this? Yes.
- Will other code or users depend on the shape of the output? Yes.
- Design: required
- Design justification: There are multiple policy and implementation paths, and checker outcomes define workflow validity for all contributors, so the behavior must be explicitly designed.

## Phase 1 Design Deliverable

### Interface and constraints

1. `wow/check-workflow.sh` must validate completed-topic timestamps deterministically from repository filesystem state.
2. Validation must apply consistently to both historical topics and newly closed topics.
3. Validation must not depend on repository-root path history (`doc/pro` -> `wow`) because path moves should not rewrite semantic close-time intent.
4. Required invariant: completed folder timestamp must be greater than or equal to every completed file timestamp prefix in that topic.

### Alternatives considered

1. Git-entry-match policy: folder timestamp equals the first commit where topic enters `completed/`.
   - Pros: minute-level tie to git history.
   - Cons: brittle under root migrations and commit-time drift; caused broad false positives.
2. Chronology policy: folder timestamp is close time and must be >= every file timestamp prefix.
   - Pros: stable under path migrations, deterministic from file structure, and matches `wow/task/RULES.md`.
   - Cons: does not enforce exact first-entry commit minute.

### Chosen approach

Use chronology policy as the single canonical rule for completed timestamp validation, with checker/docs/test updates and targeted folder-timestamp migration only where chronology is truly violated.

## Execution Plan

1. Phase 1 (Design lock) [complete]: Define the canonical completed-topic timestamp policy, including interfaces, constraints, trade-offs, and chosen approach before coding starts; completion criterion: policy design is fully documented in this item and explicitly approved for implementation.
2. Phase 2 (Checker implementation) [complete]: Apply the locked policy in `wow/check-workflow.sh` for both historical moved topics and newly closed topics; completion criterion: checker logic reflects the chosen policy in one deterministic code path.
3. Phase 3 (Regression coverage) [complete]: Add or update workflow-checker tests for completed-folder timestamp validation across historical and new-topic cases; completion criterion: regression cases execute and pass in the relevant test script(s).
4. Phase 4 (Validation and closeout) [complete]: Run board-level and targeted validation to confirm the regression is resolved without weakening invariants; completion criterion: `bash wow/check-workflow.sh` passes with no false-positive completed-folder timestamp failures.

## Verification Plan

1. Run `bash -n wow/check-workflow.sh` after edits to verify shell syntax safety.
2. Run targeted checker/regression tests that cover completed-folder timestamp rules.
3. Run `bash wow/check-workflow.sh` and confirm completed-folder timestamp checks align with the locked policy.

## Exit Criteria

1. A single canonical completed-folder timestamp policy is documented and used by the checker.
2. Historical completed topics no longer trigger false-positive `completed folder move timestamp` failures.
3. Regression coverage exists for both historical moved topics and newly closed topics.
4. Workflow validation behavior is stable and consistent with `wow/task/RULES.md`.

## Progress Checkpoint

### Done

- Completed Phase 1 design lock and selected chronology policy (`folder timestamp >= file timestamp prefixes`) as canonical.
- Updated `wow/check-workflow.sh` to enforce completed-folder chronology directly and removed git-first-entry comparison logic.
- Added regression coverage in `val/core/workflow_checker_test.sh` for historical root-move resilience and chronology violation detection.
- Updated `wow/README.md` checker semantics/fixes to match the canonical chronology policy.
- Corrected two true chronology violations by renaming:
  - `wow/completed/20260225-0156_doc-overhaul` -> `wow/completed/20260227-0310_doc-overhaul`
  - `wow/completed/20260226-0224_dic-framework-tests-fix` -> `wow/completed/20260227-0310_dic-framework-tests-fix`
- Ran validations: `bash -n wow/check-workflow.sh`, `bash -n val/core/workflow_checker_test.sh`, `bash val/core/workflow_checker_test.sh`, and `bash wow/check-workflow.sh` (pass).

### In-flight

- No implementation work remains in this item.

### Blockers

- None.

### Next steps

1. Close this item with `wow/task/completed-close` now that all phases and exit criteria are satisfied.
2. If desired, run `./val/run_all_tests.sh core` for broader confidence beyond the targeted regression suite.

## What changed

1. Updated completed-topic timestamp validation in `wow/check-workflow.sh` to use chronology semantics (`folder timestamp >= file timestamp prefixes`) and removed git first-entry commit matching logic.
2. Updated `wow/README.md` to align completed-folder policy, checker behavior description, and remediation guidance with chronology enforcement.
3. Added targeted regression coverage in `val/core/workflow_checker_test.sh` for both historical completed-tree root moves and true chronology violations.
4. Renamed two historical completed folders to satisfy true chronology violations:
   - `wow/completed/20260225-0156_doc-overhaul` -> `wow/completed/20260227-0310_doc-overhaul`
   - `wow/completed/20260226-0224_dic-framework-tests-fix` -> `wow/completed/20260227-0310_dic-framework-tests-fix`

## What was verified

1. `bash -n wow/check-workflow.sh` passed.
2. `bash -n val/core/workflow_checker_test.sh` passed.
3. `bash val/core/workflow_checker_test.sh` passed (`2` tests, `0` failures).
4. `bash wow/check-workflow.sh` passed.

## What remains

1. No mandatory follow-up is required for this item.
2. Optional broader confidence run: `./val/run_all_tests.sh core`.
3. Optional backlog cleanup in inbox: triage potential overlap in `wow/inbox/20260307-0941_workflow-completed-folder-chronology-checker-issue.md`.
