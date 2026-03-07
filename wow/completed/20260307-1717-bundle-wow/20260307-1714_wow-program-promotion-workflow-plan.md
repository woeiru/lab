# WOW Program Promotion Workflow Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 17:17
- Links: wow/task/active-capture, wow/task/completed-close-bundle, wow/task/active-promote, wow/task/active-fanout, wow/task/active-split, wow/task/README.md, wow/README.md, doc/man/09-wow-workflow-board.md, doc/arc/08-workflow-architecture.md

## Documentation Impact

Docs: required

Initial doc targets:

1. `wow/task/active-promote`
2. `wow/task/active-fanout`
3. `wow/task/active-split`
4. `wow/task/README.md`
5. `wow/README.md`
6. `doc/man/09-wow-workflow-board.md`
7. `doc/arc/08-workflow-architecture.md`

## Retroactive Capture

- Origin: This started as a meta-workflow clarification about when active plans should become program plans.
- Escalation reason: The clarification turned into a concrete workflow contract update across task templates and operator docs to make promotion explicit and repeatable.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  3. Design: required
- Work so far: Added `active-promote`, updated `active-fanout`/`active-split` guidance, and updated workflow docs to include the promote -> fanout sequence.

## Triage Decision

- Why now: Parallel orchestration adoption was blocked by unclear promotion timing and missing first-class guidance for converting active plans into program parents.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: Task flow and operator behavior depend on deterministic promotion semantics before fanout.

## Bundle Close Metadata

- Module: wow

## Progress Checkpoint

### Done

1. Added `wow/task/active-promote` with explicit parent-reshaping contract.
2. Updated `wow/task/active-fanout` to fail-fast and route invalid parents to `active-promote`.
3. Updated `wow/task/active-split` to clarify inbox decomposition vs parallel active fanout.
4. Updated workflow docs in `wow/task/README.md`, `wow/README.md`, `doc/man/09-wow-workflow-board.md`, and `doc/arc/08-workflow-architecture.md`.
5. Ran `bash wow/check-workflow.sh` and confirmed pass after edits.

### In-flight

1. None.

### Blockers

1. None.

### Next steps

1. None.

### Context

1. Worktree is dirty with unrelated user changes; this capture is scoped to workflow/task docs changed in this session.
2. Changes are workflow-contract and documentation updates, not infrastructure runtime execution changes.
3. Bundle close mode is requested to group WOW workflow update outcomes under a stable module bundle.

## Execution Plan

1. Phase 1 (Design lock) [complete]: define promotion as an explicit operation between active planning and fanout orchestration.
   Completion criterion: promotion workflow is represented by a dedicated task and referenced in fanout/split guidance.
2. Phase 2 (Closeout) [complete]: capture emergent work and complete bundle-aware close routing.
   Completion criterion: item is moved to a stable `*-bundle-wow` completed folder with verification evidence and docs outcome token.

## What changed

1. Captured this session retroactively in active state to preserve explicit workflow state/history before closeout.
2. Added `wow/task/active-promote` to formalize normal active plan -> program parent promotion.
3. Updated `wow/task/active-fanout` and `wow/task/active-split` to route users to the correct split vs fanout path.
4. Updated workflow docs in `wow/task/README.md`, `wow/README.md`, `doc/man/09-wow-workflow-board.md`, and `doc/arc/08-workflow-architecture.md` to include promotion sequencing.
5. Closed this item into `wow/completed/20260307-1717-bundle-wow/` using bundle mode `auto` with module key `wow`.

## What was verified

1. `bash wow/check-workflow.sh` after capture -> pass.
2. `bash wow/check-workflow.sh` after bundle close -> pass.
3. Docs: updated (`wow/task/active-promote`, `wow/task/active-fanout`, `wow/task/active-split`, `wow/task/README.md`, `wow/README.md`, `doc/man/09-wow-workflow-board.md`, `doc/arc/08-workflow-architecture.md`).

## What remains

1. None for this workflow improvement; no mandatory follow-up item was created.

## Verification Plan

1. Run `bash wow/check-workflow.sh` after active capture and after completed bundle close.
2. Verify `active-promote` sequencing appears in `wow/task/README.md`, `wow/README.md`, `doc/man/09-wow-workflow-board.md`, and `doc/arc/08-workflow-architecture.md`.
3. Verify bundle close artifacts include one stable `*-bundle-wow` folder and a matching entry in `wow/completed/.bundle-registry.tsv`.

## Exit Criteria

1. Active-to-program promotion is explicit, documented, and routable by task contract.
2. Fanout and split guidance clearly separate parallel execution from inbox decomposition.
3. This session work is captured and closed with checker-pass evidence.
