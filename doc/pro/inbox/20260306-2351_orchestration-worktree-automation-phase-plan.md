# Orchestration Worktree Automation Phase Plan

- Status: inbox
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06
- Links: doc/pro/completed/20260306-2353_workflow-parallel-orchestration-upgrade-plan/20260306-2331_workflow-parallel-orchestration-upgrade-plan.md, doc/pro/task/active-assign, doc/pro/task/active-sync, doc/pro/task/active-converge

## Goal

Design and implement an optional automation layer that accelerates the new
parallel orchestration workflow (especially branch/worktree setup and status
rollups) without changing the process contract.

## Context

1. The process-first orchestration upgrade is completed and checker-enforced.
2. Large initiatives can now run safely with parent/child plans, but repeated
   operational steps are still manual.
3. The next phase should automate toil while preserving human-readable control
   and existing `doc/pro` semantics.

## Scope

1. Define automation boundaries for safe helper scripts (setup/sync/report), not
   autonomous state transitions.
2. Add helper tooling for creating/attaching per-workstream branches and
   worktrees from child metadata.
3. Add status-rollup tooling that reads child plans and updates/prints parent
   sync data in a reviewable format.
4. Define guardrails and fallback behavior when metadata is incomplete or stale.
5. Add verification workflow and minimal tests for automation scripts.

## Risks

1. Tooling can diverge from documented workflow semantics if scripts encode
   hidden assumptions.
2. Worktree automation can mis-target branches when metadata is stale.
3. Over-automation can reduce operator awareness at merge/convergence points.
4. Script errors may create perceived workflow state drift if not validated
   against checker outputs.

## Next Step

Move this item to `queue/` and perform triage to decide whether automation
starts as helper scripts only or includes a thin CLI wrapper in the first cut.
