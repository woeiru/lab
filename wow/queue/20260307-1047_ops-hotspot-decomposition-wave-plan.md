# Ops Hotspot Decomposition Wave Plan

- Status: queue
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 11:19
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, doc/ref/functions.md, doc/ref/stats/actual.md, doc/ref/scope-integrity.md

## Goal

Decompose top `lib/ops` and `lib/gen` complexity hotspots into safer,
smaller units while preserving public behavior.

## Context

1. The architecture review highlighted concentrated complexity in modules such
   as `ops/dev`, `ops/gpu`, and `gen/ana`.
2. Large-function and mutation hotspots increase maintenance and regression
   risk during infrastructure automation changes.
3. A staged decomposition wave is needed but still requires detailed batching
   and sequencing design.

## Scope

1. Define hotspot decomposition batches and execution order.
2. Preserve externally visible function contracts during decomposition.
3. Add/expand targeted tests for decomposed areas.
4. Capture migration and rollback strategy for high-risk modules.

## Risks

1. Partial decomposition can increase temporary complexity if batching is poor.
2. Behavior drift can occur without explicit compatibility and regression gates.
3. Large patchsets can delay review and reduce delivery confidence.

## Triage Decision

- Why now: The architecture review already identified high-risk hotspots, so
  triaging this decomposition wave now prevents additional unsafe growth in the
  most complex ops/gen modules.
- Design classification Q1 (meaningful alternatives): Yes -- batching,
  sequencing, and rollback design choices materially affect implementation
  safety and reviewability.
- Design classification Q2 (output shape dependencies): Yes -- downstream
  maintainers and test plans depend on stable decomposition boundaries and
  documented compatibility gates.
- Design: required
- Justification: Both the decomposition strategy and its artifacts directly
  influence how future implementation waves are executed and validated.

## Next Step

Promote to `wow/active/` and execute Wave 1 decomposition planning against the
locked batch boundaries and compatibility gates.
