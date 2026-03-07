# Ops Hotspot Decomposition Wave Plan

- Status: inbox
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 10:47
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

## Next Step

Run queue triage to lock scope boundaries, dependency order, and design
classification before promotion to execution.
