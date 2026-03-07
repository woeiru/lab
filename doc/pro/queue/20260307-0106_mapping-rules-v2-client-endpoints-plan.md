# Mapping Rules v2 Client Endpoints Plan

- Status: queue
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:06
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

## Next Step

Move this item to `active/` after apply-phase contract work begins, and produce a v2 rule decision record before implementation.
