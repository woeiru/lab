# Ops Hotspot Decomposition Wave Plan

- Status: active
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 15:45
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

Execute Phase 1 design to lock decomposition interfaces, constraints, and
batch boundaries before implementation work begins.

## Execution Plan

1. Phase 1 - Decomposition design baseline.
   Completion criterion: `wow/active/20260307-1047_ops-hotspot-decomposition-wave-design.md`
   is created with documented interfaces, constraints, trade-offs, and the
   chosen hotspot decomposition approach.
2. Phase 2 - Wave 1 decomposition implementation.
   Completion criterion: The modules assigned to Wave 1 are decomposed with
   unchanged public function signatures, documented in a before/after signature
   matrix attached to this plan.
3. Phase 3 - Compatibility verification and rollback hardening.
   Completion criterion: A verification record is added to this plan showing
   passing targeted tests for touched hotspots and rollback steps for each
   high-risk module.

## Verification Plan

1. Run syntax checks on changed Bash sources with `bash -n <file>`.
2. Run nearest module tests for each touched hotspot area under `val/`.
3. Run `./val/lib/confidence_gate.sh --risk medium <changed files>` before
   closeout to validate decomposition safety at library scope.

## Exit Criteria

- The design baseline exists and is used as the reference for all Wave 1
  decomposition changes.
- Wave 1 hotspot modules are decomposed without public contract drift.
- Targeted regression checks and confidence-gate validation pass with recorded
  evidence linked from this plan.
