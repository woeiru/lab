# Mapping Apply-Phase Tooling Plan

- Status: queue
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 01:04
- Links: doc/pro/active/20260307-0005_planning-workspace-session-plan.md, utl/pla/map/runs/20260307-0057_present-showcase1/approved-mapping.json, utl/pla/cli

## Goal

Define and implement a safe apply-phase workflow that can ingest
`approved-mapping.json` and materialize planning entities/state bindings without
direct infrastructure side effects.

## Context

1. Artifact-first mapping is now established under `utl/pla/map/`.
2. Pilot run artifacts exist and include approved mapping output.
3. No apply mechanism exists yet to convert approved artifacts into planning DB
   entity/state records in a controlled, auditable way.

## Scope

1. Define apply contract inputs and validation rules.
2. Add dry-run and apply semantics for DB-level changes only.
3. Enforce collision checks, duplicate prevention, and explicit error outputs.
4. Define rollback/recovery behavior for partial failures.

## Risks

1. Incorrect apply behavior could corrupt planning-model consistency.
2. Weak validation could allow low-confidence or malformed mappings into DB.
3. Hidden coupling to current JSON shape could break future rule versions.

## Triage Decision

- Why now: Mapping artifacts are now produced and reviewed, but without an apply step they cannot be operationalized within the planning model.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes -- direct SQL scripts, CLI subcommand, or staged import utility with strict validation.
  2. Will other code or users depend on the shape of the output? Yes -- apply behavior becomes a core interface between mapping artifacts and planning DB state.
  - Design: required
- Justification: Multiple implementation paths and high downstream dependency on import semantics require an explicit design phase.

## Next Step

Move this item to `active/` and begin with a design-phase contract for apply validation, idempotency, and rollback behavior.
