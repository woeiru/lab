# Declarative Docs Alignment Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 16:19
- Links: wow/completed/20260307-1545_declarative-reconciliation-architecture/20260307-0906_declarative-reconciliation-architecture-plan.md, README.md, doc/README.md, doc/arc/00-architecture-overview.md, doc/arc/05-deployment-and-config.md, doc/man/02-configuration.md, doc/man/04-deployments.md, doc/man/08-planning-workspace.md, src/README.md, src/dic/README.md

## Retroactive Capture

- Origin: The work started as a targeted request to review outdated docs around declarative reconciliation architecture.
- Escalation reason: The scope expanded from two docs to a repository-wide consistency pass across architecture docs, manuals, and root/module READMEs.
- Design classification Q1 (meaningful alternatives): Yes - there were multiple ways to define migration language and boundary ownership between `cfg/dcl`, `cfg/env`, `src/rec`, and `src/run`.
- Design classification Q2 (output shape dependencies): Yes - operators, contributors, and future automation depend on stable doc contracts and cross-link structure.
- Design: required
- Work so far: Updated architecture/manual/reference hub docs, aligned sandbox-vs-authoritative planning language, and created docs commit `7a65f717` (`docs: align declarative rec/run architecture narrative`).

## Progress Checkpoint

### Done

1. Completed and committed the declarative reconciliation documentation alignment set.
2. Verified updated cross-links and migration wording in touched docs.
3. Prepared closeout path for workflow capture and completion.

### In-flight

1. None.

### Blockers

1. None.

### Next steps

1. Run `bash wow/check-workflow.sh` after status transition and fix any reported issue.

### Context

1. Branch: `master`.
2. Commit: `7a65f717` contains the docs alignment changes.
3. Working tree includes unrelated pre-existing staged/unstaged changes outside this captured item.

## Execution Plan

1. [pending] Phase 1 - Closeout design confirmation.
   Completion criterion: Follow-up routing policy and close timestamp strategy are documented and applied for this item.
2. [pending] Phase 2 - Completed-close transition.
   Completion criterion: This file is moved into a valid `wow/completed/yyyymmdd-hhmm_<topic>/` folder and updated to `Status: completed` with required final sections.
3. [pending] Phase 3 - Workflow integrity verification.
   Completion criterion: `bash wow/check-workflow.sh` passes with no structural errors after closeout.

## Exit Criteria

1. Retroactive capture exists with all required sections and headers.
2. Item is closed under `wow/completed/` with timestamp-valid folder structure and completed status.
3. Checker output is recorded as passing after closeout.

## What changed

1. Completed a cross-doc alignment for declarative reconciliation architecture and committed it as `7a65f717`.
2. Captured this emergent scope retroactively and then closed it into `wow/completed/20260307-1618_declarative-docs-alignment/`.
3. Added this closeout record with explicit migration-boundary context (`cfg/dcl` authority, `src/rec` compile, `src/run` dispatch, `src/set` compatibility).

## What verified

1. `git show --stat --oneline 7a65f717` -> confirmed docs commit summary (`17 files changed, 603 insertions(+), 168 deletions(-)`).
2. `bash wow/check-workflow.sh` -> `Workflow check passed.`

## What remains

1. None.
