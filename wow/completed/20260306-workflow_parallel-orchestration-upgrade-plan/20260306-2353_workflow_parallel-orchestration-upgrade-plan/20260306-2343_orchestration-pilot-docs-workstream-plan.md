# Orchestration Pilot Docs Workstream Plan

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06 23:47:00
- Links: wow/completed/20260306-workflow_parallel-orchestration-upgrade-plan/20260306-2353_workflow_parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-program-plan.md, wow/README.md, wow/task/README.md

## Goal

Validate the parent/child orchestration documentation contract through a focused
pilot workstream.

## Context

1. This workstream provides the docs-facing half of the pilot wave.
2. Its outputs are a dependency for the checker-facing workstream.

## Triage Decision

- Why now: documentation contract clarity is required before checker policy
  validation can be trusted.
- Are there meaningful alternatives for how to solve this? No.
- Will other code or users depend on the shape of the output? Yes.
- Design: required.
- Justification: parent/child contract wording directly governs downstream
  workstream behavior and validation expectations.

## Orchestration Metadata

- Program: wow/completed/20260306-workflow_parallel-orchestration-upgrade-plan/20260306-2353_workflow_parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-program-plan.md
- Workstream-ID: WS-01
- Depends-On: none
- Touch-Set: wow/README.md,wow/task/README.md
- Merge-Gate: module
- Branch: pilot/ws-01-docs
- Worktree: /home/es/lab

## Scope

1. Confirm program-level section definitions are usable in real flow.
2. Confirm child metadata keys are explicit and actionable for workers.

## Execution Plan

### Phase 1 -- Contract Validation (completed)

- [x] Validate parent section contract and child metadata keys against pilot.
- [x] Confirm touch-set and dependency representation is clear.

Completion criterion: documentation contract is sufficient to guide worker
execution without ambiguity.

## Verification Plan

1. Verify parent includes required sections and populated workstream table.
2. Verify this child includes full `## Orchestration Metadata` key set.
3. Run `bash wow/check-workflow.sh` to confirm no metadata failures.

## Exit Criteria

1. Documentation contract can drive one full pilot wave.
2. No unresolved docs ambiguity remains for pilot convergence.

## Progress Checkpoint

### Done

1. Parent contract and child metadata schema were exercised through this pilot
   workstream.
2. Dependency-free workstream WS-01 completed and unblocked WS-02.

### In-flight

1. None.

### Blockers

1. None.

### Next steps

1. Keep this workstream as `done` in parent `## Workstreams`.
2. Proceed to convergence logging in parent program plan.

### Context

1. Workstream intentionally used `Merge-Gate: module` as lower-gate pilot case.
