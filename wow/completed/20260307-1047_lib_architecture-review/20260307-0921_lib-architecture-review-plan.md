# Lib Architecture Review Plan (Doc Ref Only)

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 10:47
- Links: wow/task/inbox-capture, wow/task/completed-close, doc/ref/README.md, doc/ref/functions.md, doc/ref/module-dependencies.md, doc/ref/error-handling.md, doc/ref/test-coverage.md, doc/ref/variables.md, doc/ref/scope-integrity.md, doc/ref/reverse-dependecies.md, wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-evidence.md, wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, wow/queue/20260307-1047_gen-aux-helper-contract-stabilization-plan.md, wow/inbox/20260307-1047_ops-hotspot-decomposition-wave-plan.md, wow/inbox/20260307-1047_ops-bootstrap-boundary-decoupling-plan.md, wow/active/20260307-1047_lib-confidence-gate-implementation-plan.md

## Goal

Produce a high-level architectural review of `lib/` using `doc/ref/` as the
primary source, without diving into implementation-level code details.

## Context

1. The request explicitly asks for an architecture-focused review.
2. The repository already provides generated reference material under
   `doc/ref/` covering functions, dependencies, variables, error handling,
   and test coverage.
3. The review should emphasize structure, boundaries, coupling, contracts,
   and maintainability signals rather than line-by-line code behavior.

## Scope

1. Assess `lib/` module organization and role separation (core, gen, ops).
2. Evaluate dependency direction, shared utilities usage, and coupling hotspots
   using reference maps.
3. Review consistency of public function surfaces, variable exposure,
   and error-handling patterns.
4. Evaluate architecture testability based on documented coverage mapping.
5. Deliver strengths, risks, and pragmatic recommendations.

## Triage Decision

- Why now: The architecture review is already requested and should shape near-term
  refactor and hardening priorities for `lib/`.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: The structure and decision framing of this review will directly
  influence follow-up engineering plans and implementation sequencing.

## Artifact Contract

- Profile: general
- Artifacts: evidence, result

## Execution Briefing

- Goal summary: deliver a decision-ready architecture review of `lib/` using only `doc/ref/` evidence.
- What I will do now (Phase 1 first 3 steps): (1) define review interfaces and constraints, (2) document trade-offs and method, (3) lock the chosen approach before analysis execution.
- Design classification: Design: required

## Phase 1 Design Brief

### Interfaces

1. Input interface: generated references in `doc/ref/` only, focused on function inventory, dependency maps, reverse dependencies, error handling, scope integrity, variable usage, and test mapping.
2. Output interface: (a) evidence artifact with traceable observations and open questions, and (b) result artifact with conclusions and prioritized recommendations.

### Constraints

1. No implementation-level deep code inspection for this item.
2. Every architecture claim must map to at least one explicit `doc/ref/*` source path.
3. Recommendations must stay at architecture and planning level, not per-line patch guidance.

### Trade-offs

1. Breadth over implementation detail improves system-level visibility but can miss local edge cases.
2. Generated references speed review and traceability but may lag latest source changes.
3. Quantified signals improve prioritization but can overweight hotspots with large historical surfaces.

### Chosen approach

Use a reference-first architecture signal synthesis: extract structural and coupling indicators from `doc/ref`, quantify hotspots, map strengths/risks by domain, then produce prioritized, decision-ready follow-up actions.

## Context Updates

1. `ops` is the dominant complexity surface by function count and size weight in `doc/ref/functions.md`.
2. `gen/aux` is the primary cross-module coupling hub in `doc/ref/reverse-dependecies.md`.
3. Scope and mutation risk is concentrated in `gen/ana` and selected `ops` modules in `doc/ref/scope-integrity.md`.
4. Error-handling pathways are broadly standardized via `return` plus `aux_err` patterns in `doc/ref/error-handling.md`.

## Execution Plan

1. Phase 1 (Design) [complete]: Define the review interface and method before any further analysis work; completion criterion: a design brief is documented in this item with interfaces, constraints, trade-offs, and the chosen approach.
2. Phase 2 (Reference Analysis) [complete]: Evaluate `lib/` architecture signals across `doc/ref/` datasets using the Phase 1 method; completion criterion: an evidence matrix exists with at least one architectural strength and one architectural risk per analyzed reference domain.
3. Phase 3 (Assessment Output) [complete]: Produce the architecture review result with actionable recommendations; completion criterion: a review output is published with prioritized recommendations and explicit rationale.

## Verification Plan

1. Confirm every claim in the review maps to at least one explicit `doc/ref/*` source path.
2. Confirm no recommendation depends on implementation-level code inspection.
3. Confirm the final output includes strengths, risks, and prioritized next actions.

## Exit Criteria

1. [met] Phase 1 design brief is complete and explicitly recorded.
2. [met] The evidence matrix for `doc/ref` architecture signals is complete.
3. [met] The final architecture review is published and accepted as execution-ready guidance for follow-up work.

## Risks

1. `doc/ref/` is generated context and may lag behind source changes.
2. Structural signals can hide implementation-specific edge cases.
3. Dependency maps may not fully express runtime dynamic behavior.

## Next Step

Run a reference-driven architecture review and publish a concise assessment
with prioritized follow-up actions.

## What changed

1. Completed the architecture-review control plane and moved the full artifact set (`plan`, `evidence`, `result`) from `wow/active/` into a single completed topic folder.
2. Locked the design-phase output and published a source-traceable architecture assessment for `lib/` using only `doc/ref/*` inputs.
3. Opened follow-up execution tracks for helper-contract stabilization, hotspot decomposition, boundary decoupling, and confidence-gate implementation.

## What was verified

1. `bash wow/check-workflow.sh` passed after artifact generation and again after completed-state finalization.
2. Evidence-to-conclusion traceability was preserved across `doc/ref/functions.md`, `doc/ref/module-dependencies.md`, `doc/ref/reverse-dependecies.md`, `doc/ref/scope-integrity.md`, `doc/ref/error-handling.md`, `doc/ref/test-coverage.md`, and `doc/ref/variables.md`.

## What remains

1. Follow-up in queue: `wow/queue/20260307-1047_gen-aux-helper-contract-stabilization-plan.md`.
2. Routing: queue (mandatory follow-up)
3. Rationale: `gen/aux` fan-in is the highest architecture risk with clear scope and priority locked by this review.
4. Follow-up in inbox: `wow/inbox/20260307-1047_ops-hotspot-decomposition-wave-plan.md`.
5. Follow-up in inbox: `wow/inbox/20260307-1047_ops-bootstrap-boundary-decoupling-plan.md`.
6. Confidence-gate follow-up has been promoted to active execution: `wow/active/20260307-1047_lib-confidence-gate-implementation-plan.md`.
