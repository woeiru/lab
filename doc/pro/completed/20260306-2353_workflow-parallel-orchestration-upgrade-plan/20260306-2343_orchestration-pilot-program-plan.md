# Orchestration Pilot Program Plan

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06 23:47:00
- Links: doc/pro/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/20260306-2331_workflow-parallel-orchestration-upgrade-plan.md, doc/pro/task/active-fanout, doc/pro/task/active-assign, doc/pro/task/active-sync, doc/pro/task/active-converge

## Goal

Run one end-to-end pilot of the new parallel orchestration workflow using a
parent program plan plus multiple child workstream plans.

## Context

1. The workflow upgrade introduced a parent/child orchestration contract and
   new active orchestration task templates.
2. The pilot validates documentation structure, metadata contract, and checker
   enforcement behavior without requiring automation scripts.

## Triage Decision

- Why now: this validates the upgraded workflow in a realistic execution shape
  before declaring the upgrade complete.
- Are there meaningful alternatives for how to solve this? Yes.
- Will other code or users depend on the shape of the output? Yes.
- Design: required.
- Justification: the parent/child schema and merge gates define how future
  large initiatives will be coordinated.

## Program Scope

1. Create two pilot child workstreams with explicit dependency ordering.
2. Record assignment, sync, and convergence artifacts in this parent plan.
3. Confirm checker compatibility with the new orchestration metadata contract.

## Global Invariants

1. Child plans must not overlap touch-sets in the same wave.
2. Child plans must use unique `Workstream-ID` values under this parent.
3. Dependency links must remain acyclic.
4. Every child must provide merge-gate verification evidence before convergence.

## Workstreams

| Workstream-ID | Child Plan | Depends-On | Touch-Set | Merge-Gate | Owner | Status | Notes |
|---|---|---|---|---|---|---|---|
| WS-01 | doc/pro/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-docs-workstream-plan.md | none | doc/pro/README.md, doc/pro/task/README.md | module | es | done | Parent/child docs guidance drafted and validated. |
| WS-02 | doc/pro/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-checker-workstream-plan.md | WS-01 | doc/pro/task/RULES.md, doc/pro/check-workflow.sh | integration | es | done | Checker policy alignment validated after docs contract froze. |

## Integration Cadence

1. Single-wave pilot cadence:
   - fan-out and assign at wave start
   - sync after child checkpoints
   - converge once all merge gates are satisfied
2. Convergence owner: program plan owner (`es`).
3. Gate policy: no convergence if any required dependency is blocked.

## Execution Plan

### Phase 1 -- Fan-out and Assignment (completed)

- [x] Create child plans for WS-01 and WS-02.
- [x] Assign owner, branch, and worktree metadata in each child.

Completion criterion: all child plans exist and contain complete orchestration
metadata.

### Phase 2 -- Child Progress and Sync (completed)

- [x] Capture child execution/verification progress in each child plan.
- [x] Record synchronized parent status snapshot.

Completion criterion: parent reflects current child states, blockers, and
ready-to-converge candidates.

### Phase 3 -- Converge and Record Findings (completed)

- [x] Validate merge-gate evidence for all pilot workstreams.
- [x] Record convergence outcome and release decision.

Completion criterion: one full wave convergence result is recorded.

## Verification Plan

1. Run `bash doc/pro/check-workflow.sh` and confirm no orchestration-specific
   failures for pilot files.
2. Validate dependency references and merge-gate values in child metadata.
3. Confirm parent required sections are present and complete.

## Exit Criteria

1. Parent and child documents satisfy the orchestration contract.
2. At least one full wave sync/converge cycle is recorded.
3. Pilot outcomes are linked back to the main upgrade active item.

## Assignment Snapshot

Timestamp: 2026-03-06 23:44

1. Assigned workstreams:
   - WS-01 -> owner `es`, branch `pilot/ws-01-docs`, worktree `/home/es/lab`
   - WS-02 -> owner `es`, branch `pilot/ws-02-checker`, worktree `/home/es/lab`
2. Unassigned workstreams: none.
3. Immediate blockers: none.

## Sync Snapshot

Timestamp: 2026-03-06 23:45

1. Completed this sync: WS-01, WS-02.
2. Blocked items: none.
3. Ready-to-converge candidates: WS-01, WS-02.

## Convergence Log

### Wave 1 -- 2026-03-06 23:46

1. Converged workstreams: WS-01, WS-02.
2. Integration checks reviewed:
   - Orchestration metadata schema compliance in both children.
   - Parent section completeness for program contract.
   - Workflow checker behavior after orchestration updates.
3. Unresolved conflicts: none.
4. Next wave release decision: no further waves required for this pilot.
