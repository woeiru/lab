# Lib Architecture Review Result

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 10:47
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-plan.md, wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-evidence.md, doc/ref/functions.md, doc/ref/module-dependencies.md, doc/ref/reverse-dependecies.md, doc/ref/scope-integrity.md, doc/ref/error-handling.md, doc/ref/test-coverage.md, doc/ref/stats/actual.md

## Triage Decision

- Why now: This review defines the near-term architecture hardening sequence for `lib/`.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: The selected architecture priorities determine how follow-up changes are scoped, ordered, and validated.

## Conclusions

1. Layering intent is strong and still visible (`core -> gen -> ops`), but operational complexity is heavily concentrated in `ops`.
2. The helper platform (`gen/aux`) is the primary coupling hub and is both a strength (consistency) and a systemic risk (blast radius).
3. Quality risk is not uniform; it is concentrated in specific hotspots (`gen/ana`, `ops/dev`, and selected high-command-breadth ops modules).
4. Error-handling conventions are broadly standardized, which lowers semantic drift risk across modules.
5. Test traceability exists for most modules, but confidence signaling needs stronger runtime status gates.

## Prioritized Actions

1. Stabilize the shared helper contract in `gen/aux` (highest priority).
   - Rationale: it has the largest fan-in and widest impact surface.
2. Reduce cross-layer coupling around execution/bootstrap boundaries.
   - Rationale: dependency direction pressure (notably around ops/orchestration boundaries) increases architectural fragility.
3. Run hotspot-first decomposition on `ops/dev`, `ops/gpu`, and `gen/ana` while preserving public interfaces.
   - Rationale: complexity concentration is the primary maintainability driver.
4. Add scope-integrity hardening for modules with high mutation/leak findings.
   - Rationale: side-effect containment lowers regression risk in infrastructure operations.
5. Define and enforce a minimum confidence gate combining mapped tests plus run-status expectations.
   - Rationale: current mapping is useful but insufficient as a release-quality indicator.

## Decision-Ready Output

1. Recommendation: proceed with a focused architecture-hardening wave centered on helper contract stability, hotspot decomposition, and boundary decoupling.
2. Sequencing: `gen/aux` contract stabilization first, then hotspot decomposition, then broader coupling and confidence-gate upgrades.
3. Expected outcome: reduced blast radius for common helpers, clearer boundaries, and improved change safety for `lib/` evolution.
