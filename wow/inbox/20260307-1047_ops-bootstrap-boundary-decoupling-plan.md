# Ops Bootstrap Boundary Decoupling Plan

- Status: inbox
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 10:47
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, doc/ref/module-dependencies.md, doc/arc/00-architecture-overview.md, bin/ini, bin/orc

## Goal

Reduce cross-layer coupling between ops modules and bootstrap/orchestration
surfaces by introducing clearer boundary adapters.

## Context

1. The architecture review identified dependency-direction pressure around
   runtime and bootstrap boundaries.
2. Cross-layer imports increase fragility and make phased refactors harder.
3. Decoupling requires a design pass to avoid breaking initialization and lazy
   load expectations.

## Scope

1. Identify boundary violations and classify by migration complexity.
2. Propose adapter/interface pattern for decoupled access paths.
3. Define migration sequence with compatibility checkpoints.
4. Update architecture docs and validation coverage for new boundaries.

## Risks

1. Boundary changes can break startup semantics if load-order assumptions are missed.
2. Over-abstraction can increase indirection and debugging friction.
3. Incomplete migration can leave dual-path confusion in docs and runtime behavior.

## Next Step

Prepare a triage-ready queue candidate after mapping concrete violation targets
and compatibility constraints.
