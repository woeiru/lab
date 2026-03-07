# DCL Staged Rollout Overlays Follow-up

- Status: inbox
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 15:45
- Links: wow/completed/20260307-1545_declarative-reconciliation-architecture/20260307-0906_declarative-reconciliation-architecture-plan.md, cfg/dcl/SCHEMA.md, cfg/dcl/README.md, doc/man/04-deployments.md

## Goal

Introduce staged rollout overlays in `cfg/dcl/` for environment promotion and
document schema-backed usage patterns.

## Context

1. Rollout policy is still concentrated in `cfg/dcl/site1`.
2. Promotion overlays for `dev/stg/prd` style progression are not yet modeled.
3. Schema and docs need concrete examples to support consistent adoption.

## Scope

1. Define overlay layout and merge precedence for staged promotion.
2. Update `cfg/dcl/SCHEMA.md` and `cfg/dcl/README.md` with normative examples.
3. Add/extend validation coverage for overlay parsing and promotion safety.

## Next Step

Create a queue-ready execution plan with example target topology and explicit
success criteria for schema, docs, and tests.
