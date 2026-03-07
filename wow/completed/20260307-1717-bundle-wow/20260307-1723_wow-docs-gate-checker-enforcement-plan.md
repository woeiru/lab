# WOW Docs Gate Checker Enforcement Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 17:23
- Links: wow/task/RULES.md, wow/task/active-move, wow/task/active-capture, wow/task/active-start, wow/task/active-promote, wow/task/active-fanout, wow/task/active-reopen, wow/task/completed-close, wow/task/README.md, wow/README.md, wow/active/README.md, wow/check-workflow.sh, doc/man/09-wow-workflow-board.md

## Documentation Impact

- Docs: required
- Target docs (initial): `wow/task/RULES.md`, `wow/task/README.md`, `wow/README.md`, `wow/active/README.md`, `doc/man/09-wow-workflow-board.md`

## Retroactive Capture

- Origin: The work began as a request to stop manual post-upgrade documentation cleanup by making docs handling a default workflow contract.
- Escalation reason: The scope expanded to checker-level enforcement and active item backfill to prevent future drift.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes - prompt policy only vs checker-enforced validation.
  2. Will other code or users depend on the shape of the output? Yes - all workflow operators and automation rely on the close/verification contract.
  Design: required
- Work so far: Added docs gate policy across workflow tasks/docs, updated active plans with `## Documentation Impact`, and enforced docs tokens in `wow/check-workflow.sh`.

## Triage Decision

- Why now: workflow close quality and docs currency were drifting because docs checks were policy-only and not checker-enforced.
- Design classification Q1 (meaningful alternatives): Yes - enforcement scope and backward-compatibility behavior had multiple valid options.
- Design classification Q2 (output shape dependencies): Yes - task templates, active plans, and completed closeouts depend on stable token contracts.
- Design: required
- Justification: This change defines a cross-workflow contract and validator behavior that impacts all future workflow items.

## Progress Checkpoint

### Done

1. Added documentation impact/outcome contract text to task prompts and workflow docs.
2. Added checker validations for active docs impact tokens and completed docs outcome tokens.
3. Updated in-flight active plans to include `## Documentation Impact` with canonical token.
4. Ran checker validation after each stage.

### In-flight

1. Capture this untracked session as a workflow item and close it with bundle-aware routing.

### Blockers

1. None.

### Next steps

1. Close this active capture via `completed-close-bundle auto module=wow`.
2. Reuse existing `*-bundle-wow` folder and preserve registry consistency.
3. Record completion evidence and docs outcome token in closeout sections.

### Context

1. Branch/worktree: local repository at `/home/es/lab`.
2. Validation status before close: `bash -n wow/check-workflow.sh` pass and `bash wow/check-workflow.sh` pass.

## Execution Plan

1. Phase 1 - Retroactive capture record [done].
   Completion criterion: this active file records origin, design classification, and progress checkpoint.
2. Phase 2 - Bundle closeout [in progress].
   Completion criterion: item is moved to the resolved `*-bundle-wow` completed folder with final sections and verification evidence.

## Verification Plan

1. Confirm checker syntax validity with `bash -n wow/check-workflow.sh`.
2. Confirm workflow integrity with `bash wow/check-workflow.sh` before and after close.
3. Confirm docs-contract coverage is present in task templates, workflow manuals, and active/close files.

## Exit Criteria

1. Checker enforces docs token contracts for active and completed plans.
2. Workflow docs and task templates consistently describe the enforced behavior.
3. This session is captured and closed in a stable `wow` completed bundle with verification evidence.

## What changed

1. Added docs gate policy and docs token requirements to workflow task contracts.
2. Added checker-level validation for `## Documentation Impact` in active plan docs and docs outcome tokens in completed plan docs.
3. Updated workflow operator docs to reflect the enforced checker behavior.
4. Updated current active workstream plans to include canonical `## Documentation Impact` sections.
5. Documentation files updated: `wow/task/RULES.md`, `wow/task/README.md`, `wow/README.md`, `wow/active/README.md`, `doc/man/09-wow-workflow-board.md`, `wow/task/active-move`, `wow/task/active-capture`, `wow/task/active-start`, `wow/task/active-promote`, `wow/task/active-fanout`, `wow/task/active-reopen`, `wow/task/completed-close`.

## What was verified

1. `bash -n wow/check-workflow.sh` -> pass.
2. `bash wow/check-workflow.sh` -> pass after capture and before close.
3. Bundle resolution check: reused existing folder `wow/completed/20260307-1717-bundle-wow/` for slug `wow`.
4. Docs: updated (`wow/task/RULES.md`, `wow/task/README.md`, `wow/README.md`, `wow/active/README.md`, `doc/man/09-wow-workflow-board.md`, `wow/check-workflow.sh`, `wow/task/active-move`, `wow/task/active-capture`, `wow/task/active-start`, `wow/task/active-promote`, `wow/task/active-fanout`, `wow/task/active-reopen`, `wow/task/completed-close`).

## What remains

1. None.
