# Doc/Pro Workflow Improvements Plan

- Status: dismissed
- Owner: es
- Started: n/a
- Updated: 2026-03-01
- Links: wow/README.md, wow/check-workflow.sh

## Dismissal Reason

- Current workflow scale is small and stable, so added automation is not needed now.
- Proposed checks add maintenance overhead without enough immediate benefit.
- Revisit if backlog size or active-item churn increases.

## Goal

Track the next workflow-hardening improvements as actionable backlog work.

## Improvements to Implement

1. Add stale-item automation (for example, flag `active/` items with no update in 7 days).
2. Require each completed topic to include a short result section with verification evidence.
3. Add lightweight cycle-time metrics (`inbox` -> `completed`) for process tuning.

## Done Criteria

- Validation/checker behavior is updated or explicitly documented for each accepted rule.
- Related workflow docs are updated to match implemented behavior.
- Any new checks pass via `bash wow/check-workflow.sh`.
