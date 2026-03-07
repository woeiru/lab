# Mapping Rules v2 Client Endpoints Plan

- Status: active
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:29
- Links: doc/pro/active/20260307-0005_planning-workspace-session-plan.md, utl/pla/map/rules/cfg-env-v1.yaml, utl/pla/map/reports/unmapped-findings.md, cfg/env/site1

## Goal

Define v2 mapping rules for unresolved client-endpoint semantics (for example
`CL_IPS`) and fold them into governed artifact-first mapping runs.

## Context

1. Pilot run identified `CL_IPS[t1]` as unresolved by v1 rules.
2. Current rule set intentionally leaves client endpoint semantics unmapped.
3. Unknown findings should be reduced in controlled increments.

## Scope

1. Determine canonical type mapping for client endpoints.
2. Extend rule schema and extraction logic where needed.
3. Define confidence and evidence expectations for new v2 rules.
4. Validate v2 behavior on at least one existing snapshot run.

## Risks

1. Misclassification can distort planning model semantics.
2. Rule broadening can introduce false positives.
3. Type decisions may require upstream model adjustments.

## Triage Decision

- Why now: A concrete unresolved finding is already tracked, and leaving it unresolved blocks trusted-plan maturity for broader automation.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes -- classify as host, classify as service, or introduce a refined type policy for endpoint semantics.
  2. Will other code or users depend on the shape of the output? Yes -- entity typing and keys influence planning diffs, exports, and future apply behavior.
  - Design: required
- Justification: This change affects model semantics and downstream workflows, so type decisions need explicit design review.

## Execution Plan

1. Phase 1 -- Design decision record for client-endpoint mapping semantics.
   Completion criterion: A committed decision document defines interfaces,
   constraints, trade-offs, and the chosen mapping approach.
2. Phase 2 -- Implement v2 rule schema and extraction changes from Phase 1.
   Completion criterion: Mapping code and rule artifacts are updated in-tree for
   client-endpoint semantics with no unresolved TODO markers.
3. Phase 3 -- Run governed validation on an existing snapshot and review output.
   Completion criterion: One validation run completes and records the
   client-endpoint result classification in its report artifact.

## Verification Plan

1. Execute the mapping pipeline against a known snapshot previously containing
   `CL_IPS` unresolved findings.
2. Confirm expected entity type and key output align with the Phase 1 design.
3. Compare before/after unknown findings and document deltas in the run report.

## Exit Criteria

1. A design decision record is approved and linked from this item.
2. v2 client-endpoint rule changes are merged with tests or validation evidence.
3. The targeted unresolved client-endpoint finding is resolved or explicitly
   reclassified with rationale in artifacts.
