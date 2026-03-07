# Workflow Parallel Orchestration Upgrade Plan

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06 23:52:07
- Links: wow/README.md, wow/task/inbox-capture, wow/task/active-split, wow/check-workflow.sh

## Goal

Upgrade the `doc/pro` workflow system so very large refactors can be decomposed
into coordinated child plans executed in parallel across separate LLM contexts,
with reliable orchestration and integration control.

## Context

1. Current workflow states (`inbox -> queue -> active -> completed/dismissed`)
   already support single-plan execution well.
2. Existing tasks (`active-split`, `active-checkpoint`, `active-resume`) provide
   partial handoff support but do not define parent/child orchestration.
3. Large refactors require multiple concurrent contexts, each owning a focused
   plan and reconverging through explicit dependency and merge gates.
4. Recommended rollout is process-first: introduce orchestration structure in
   markdown + checker before adding automation scripts.
5. Phase 1 design contract is now frozen in this item so documentation,
   templates, and checker updates can proceed without interface churn.
6. Phase 2 delivered orchestration docs/templates: `active-fanout`,
   `active-assign`, `active-sync`, and `active-converge`, plus README/RULES
   contract updates.
7. Phase 3 delivered checker enforcement for program sections, child
   orchestration metadata fields, dependency validity, duplicate workstream IDs,
   and dependency-cycle detection.
8. Phase 4 pilot completed with one parent program plan and two child
   workstreams, including assignment, sync snapshot, and convergence log.

## Triage Decision

- Why now: the need is immediate because upcoming large refactors will be
  harder to coordinate safely without explicit parent/child orchestration and
  dependency gates.
- Are there meaningful alternatives for how to solve this? Yes.
- Will other code or users depend on the shape of the output? Yes.
- Design: required.
- Justification: this change defines workflow contracts, task interfaces, and
  checker behavior that downstream planning and execution will rely on.

## Scope

1. Define a parent/child planning model for large initiatives (program plan +
   multiple workstream plans).
2. Specify required metadata for child plans (`Parent`, `Workstream-ID`,
   `Depends-On`, `Touch-Set`, `Merge-Gate`, `Branch/Worktree`).
3. Add new task templates for orchestration operations (fan-out, assign,
   sync, converge) while preserving existing workflow semantics.
4. Extend `wow/check-workflow.sh` with orchestration integrity checks
   (reference validity, dependency sanity, required fields).
5. Document operator guidance for running wave-based integration without
   immediate scripting automation.

## Risks

1. Orchestration metadata may become overhead for small tasks if not scoped to
   large initiatives only.
2. Dependency declarations can drift from reality unless checker rules are
   strict and consistently run.
3. Parallel workstreams may still collide on shared files if touch-set
   ownership boundaries are not explicit.
4. Premature automation could hide process flaws; this plan intentionally
   defers automation to a later phase.

## Execution Plan

### Phase 1 -- Define Parallel Orchestration Design Contract (completed)

- [x] Define the program-level artifact model (`*-program.md`) and child-plan
  contract fields for parallel execution.
- [x] Define dependency semantics (`Depends-On`), ownership semantics
  (`Touch-Set`), and integration gating semantics (`Merge-Gate`).
- [x] Define coordinator/worker operating cadence (fan-out, checkpoint sync,
  wave convergence) and state transitions.
- [x] Record final interfaces, constraints, trade-offs, and chosen approach in
  a dedicated design decision record within this active item.

Completion criterion: this document contains a finalized design decision record
covering interfaces, constraints, trade-offs, and the chosen orchestration
approach for large parallel refactors.

## Phase 1 Design Decision Record

Date: 2026-03-06
Design classification: required

1. Artifact model (chosen):
   - Parent initiative artifact uses filename form
     `yyyymmdd-hhmm_<topic>-program-plan.md` so it remains inbox-compatible and
     clearly distinct from ordinary `-plan` items.
   - Child workstream artifacts use
     `yyyymmdd-hhmm_<topic>-<workstream>-plan.md` and are linked to one parent.
   - Parent and child items continue using existing folder states (`queue`,
     `active`, `completed`, `dismissed`) with no new top-level states.
2. Parent contract (required sections):
   - `## Program Scope` (initiative boundary and non-goals).
   - `## Global Invariants` (rules every child must preserve).
   - `## Workstreams` (table of `Workstream-ID`, child path, owner,
     dependency list, touch-set summary, status).
   - `## Integration Cadence` (sync frequency, wave gates, convergence owner).
3. Child contract (required section + canonical keys):
   - `## Orchestration Metadata` with exactly these keys:
     - `Program: <path to parent program plan>`
     - `Workstream-ID: WS-<nn>`
     - `Depends-On: none | WS-..,WS-..`
     - `Touch-Set: <path prefixes or globs>`
     - `Merge-Gate: minimal | module | integration`
     - `Branch: <git branch name>`
     - `Worktree: <absolute path | none>`
4. Dependency semantics (chosen):
   - `Depends-On` references sibling `Workstream-ID` values in the same parent
     program only.
   - Dependency graph must be acyclic.
   - A child may begin implementation before upstream completion only when the
     parent marks the dependency as contract-stable in `## Workstreams` notes.
5. Ownership semantics (chosen):
   - `Touch-Set` is an ownership declaration, not just documentation.
   - Overlapping touch-sets are disallowed in the same wave unless explicitly
     listed by the parent under a shared-zone rule with an integration order.
6. Merge-gate semantics (chosen):
   - `minimal`: syntax + nearest targeted checks.
   - `module`: minimal + module/category tests relevant to the touch-set.
   - `integration`: module gate + cross-workstream integration checks.
   - Child close requires recording command evidence that satisfies its gate.
7. Coordinator/worker operating cadence (chosen):
   - Coordinator runs fan-out once, assignment once per child, then repeated
     sync/converge loops by wave.
   - Workers operate only on their assigned child plans and checkpoint at
     context boundaries.
   - Wave progression: fan-out -> active execution -> checkpoint sync ->
     converge -> next wave release.
8. Constraints and non-negotiables:
   - Preserve existing `doc/pro` status semantics and timestamp naming rules.
   - Do not require automation scripts for Phase 1 adoption.
   - Keep orchestration state human-readable and checker-enforced.
9. Alternatives considered and trade-offs:
   - Full automation first: faster execution but higher tooling/state-drift risk.
   - Single mega-plan: lower ceremony but poor parallel isolation and handoff.
   - Chosen approach adds metadata overhead but maximizes auditability and
     deterministic coordination.
10. Final choice rationale:
    - A process-first, checker-enforced orchestration contract gives reliable
      parallel scaling now, while leaving room to automate repetitive actions in
      a later phase without redesigning the control model.

### Phase 2 -- Add Workflow Templates and Guidance (completed)

- [x] Add orchestration task templates under `wow/task/` for fan-out,
  assignment, synchronization, and convergence.
- [x] Update `wow/README.md` with parent/child orchestration semantics,
  dependency modeling, and wave-based execution guidance.
- [x] Update `wow/task/README.md` and `wow/task/RULES.md` so task
  contracts and required fields are consistent with the new model.

Completion criterion: orchestration templates and documentation exist with one
consistent metadata contract and no unresolved TODO markers.

### Phase 3 -- Enforce Orchestration Integrity in Checker (completed)

- [x] Extend `wow/check-workflow.sh` to validate program/child references,
  required orchestration fields, and dependency declaration integrity.
- [x] Add actionable checker failures for missing/invalid orchestration
  metadata and relationship mismatches.
- [x] Ensure existing workflow checks remain intact and compatible with the
  upgraded model.

Completion criterion: checker enforces orchestration constraints and passes on a
board updated to the new required fields.

## Progress Checkpoint

### Done

1. Updated orchestration guidance in `wow/README.md` with parent/child
   model, required metadata, and wave operating cadence.
2. Added new orchestration task templates:
   `wow/task/active-fanout`, `wow/task/active-assign`,
   `wow/task/active-sync`, `wow/task/active-converge`.
3. Updated task-level docs and shared rules:
   `wow/task/README.md`, `wow/task/RULES.md`.
4. Extended `wow/check-workflow.sh` with orchestration checks for:
   - program section requirements (`Program Scope`, `Global Invariants`,
     `Workstreams`, `Integration Cadence`)
   - child metadata completeness and value validation
   - Program path validity and duplicate `Program + Workstream-ID`
   - dependency reference existence and dependency-cycle detection.
5. Validation run:
   - `bash -n wow/check-workflow.sh` -> pass
   - `bash wow/check-workflow.sh` -> pass.
6. Created pilot artifacts:
   - `wow/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-program-plan.md`
   - `wow/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-docs-workstream-plan.md`
   - `wow/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-checker-workstream-plan.md`
7. Pilot wave results:
   - dependency chain (`WS-02` depends on `WS-01`) validated
   - merge-gate diversity (`module` and `integration`) validated
   - parent assignment/sync/convergence sections exercised end-to-end.

### In-flight

1. No in-flight work remains for this scope.

### Blockers

1. None.

### Next steps

1. No further execution steps are required for this completed scope.
2. Capture any future automation phase as a separate inbox follow-up item.

### Context

1. New orchestration checks are opt-in by document shape: only `-program-plan`
   files and docs containing `## Orchestration Metadata` are enforced.
2. Existing non-orchestrated workflow docs remain compatible with the checker.
3. Pilot parent/child docs were archived in this completed topic folder as
   closure evidence.

### Phase 4 -- Pilot and Close (completed)

- [x] Run one representative pilot decomposition using the upgraded workflow
  model (program + multiple child plans).
- [x] Capture integration findings, friction points, and follow-up
  recommendations in the active item.
- [x] Finalize closeout sections and transition the item to completed.

Completion criterion: one pilot run is documented with verification evidence and
the workflow upgrade is closure-ready.

## Verification Plan

1. Run `bash -n wow/check-workflow.sh` after checker edits.
2. Run `bash wow/check-workflow.sh` before each state transition.
3. Validate new templates by creating at least one sample program item and
   child item in workflow-safe locations, then rerun checker.
4. Verify no regressions in existing workflow behavior by sampling current
   inbox/queue/active/completed items against the checker output.

## Exit Criteria

1. `doc/pro` documentation defines a clear, operator-usable parent/child
   orchestration model for large parallel efforts.
2. Required orchestration metadata fields are documented and enforced by
   `wow/check-workflow.sh`.
3. New orchestration task templates exist and align with shared rules.
4. At least one pilot run demonstrates practical end-to-end use of the upgraded
   flow.

## Next Step

Closed into completed archive:
`wow/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/`.

## What changed

1. Added large-initiative orchestration guidance to `wow/README.md` with
   parent/child model, required metadata, and wave cadence.
2. Added orchestration task templates:
   `wow/task/active-fanout`, `wow/task/active-assign`,
   `wow/task/active-sync`, and `wow/task/active-converge`.
3. Updated `wow/task/README.md` and `wow/task/RULES.md` to document the
   orchestration mode and metadata contract.
4. Extended `wow/check-workflow.sh` to enforce program sections, child
   orchestration metadata validity, dependency references, duplicate workstream
   IDs, and cycle detection.
5. Executed a pilot parent/child program run and archived pilot artifacts in
   this completed topic folder.

## What was verified

1. `bash -n wow/check-workflow.sh` -> pass.
2. `bash wow/check-workflow.sh` -> pass after orchestration updates and
   pilot artifact creation.
3. Pilot metadata validity verified through checker rules:
   - required parent sections present
   - required child `## Orchestration Metadata` keys present
   - dependency chain (`WS-02` -> `WS-01`) resolved without cycle
   - merge-gate values accepted (`module`, `integration`).

## What remains

1. Optional automation phase captured for future triage in
   `wow/inbox/20260306-2351_orchestration-worktree-automation-phase-plan.md`.
