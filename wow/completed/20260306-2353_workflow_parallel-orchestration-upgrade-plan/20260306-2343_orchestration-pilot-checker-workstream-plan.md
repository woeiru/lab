# Orchestration Pilot Checker Workstream Plan

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06 23:47:00
- Links: wow/completed/20260306-2353_workflow_parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-program-plan.md, wow/task/RULES.md, wow/check-workflow.sh

## Goal

Validate checker-policy alignment with the new orchestration contract in the
pilot wave.

## Context

1. This workstream depends on WS-01 because checker semantics should follow the
   frozen documentation contract.
2. The pilot focuses on contract validation and convergence recording, not
   additional checker feature expansion.

## Triage Decision

- Why now: checker-policy alignment is required to prove the new orchestration
  workflow is enforceable.
- Are there meaningful alternatives for how to solve this? No.
- Will other code or users depend on the shape of the output? Yes.
- Design: required.
- Justification: this validation ensures the process contract and enforcement
  behavior remain coherent across future large initiatives.

## Orchestration Metadata

- Program: wow/completed/20260306-2353_workflow_parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-program-plan.md
- Workstream-ID: WS-02
- Depends-On: WS-01
- Touch-Set: wow/task/RULES.md,wow/check-workflow.sh
- Merge-Gate: integration
- Branch: pilot/ws-02-checker
- Worktree: /home/es/lab

## Scope

1. Confirm dependency and gate metadata are checker-valid.
2. Confirm integration-gate workstream can be represented and converged in the
   parent pilot plan.

## Execution Plan

### Phase 1 -- Dependency and Gate Validation (completed)

- [x] Validate `Depends-On: WS-01` resolves within the same program.
- [x] Validate `Merge-Gate: integration` handling in pilot convergence.

Completion criterion: dependency + integration gate semantics are represented
and accepted by workflow validation.

## Verification Plan

1. Run `bash -n wow/check-workflow.sh`.
2. Run `bash wow/check-workflow.sh` and inspect orchestration-related
   failures.
3. Confirm parent convergence log records integration-gate completion.

## Exit Criteria

1. Workstream dependency and merge-gate metadata are valid.
2. Parent convergence log captures this workstream as converged.

## Progress Checkpoint

### Done

1. WS-02 metadata validated as dependent on WS-01 and aligned with integration
   gate semantics.
2. Parent pilot convergence log includes WS-02 as converged.

### In-flight

1. None.

### Blockers

1. None.

### Next steps

1. Keep this workstream marked `done` in parent `## Workstreams`.
2. Use pilot findings in the main upgrade active item Phase 4 closeout notes.

### Context

1. Current board-level checker failure remains unrelated to this pilot topic.
