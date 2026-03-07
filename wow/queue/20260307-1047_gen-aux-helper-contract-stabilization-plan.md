# Gen Aux Helper Contract Stabilization Plan

- Status: queue
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 10:47
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, doc/ref/reverse-dependecies.md, doc/ref/scope-integrity.md, lib/gen/aux

## Goal

Stabilize the `gen/aux` helper contract to reduce fan-in blast radius while
preserving current operational behavior.

## Context

1. The completed architecture review identified `gen/aux` as the highest
   coupling hotspot by reverse-dependency fan-in.
2. Contract drift in shared helpers can produce broad regressions across
   `lib/ops/*`, `lib/gen/*`, and supporting orchestration surfaces.
3. A bounded contract-first hardening pass is now prioritized for queue
   execution.

## Scope

1. Define the stable public helper surface for `gen/aux`.
2. Classify helpers into stable API vs internal-only utilities.
3. Add compatibility guidance and migration notes for high-risk helper changes.
4. Add validation checks/tests for contract conformance.

## Triage Decision

- Why now: `gen/aux` has the highest cross-module fan-in, so stabilizing its
  contract gives the largest immediate risk reduction.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: Multiple contract-boundary strategies exist and the chosen
  helper surface affects many modules and future refactor sequencing.

## Next Step

Move this item to `active/` and execute a design-first contract hardening plan.
