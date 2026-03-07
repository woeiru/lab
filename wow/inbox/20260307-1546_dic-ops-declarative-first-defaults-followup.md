# DIC Ops Declarative-first Defaults Follow-up

- Status: inbox
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 15:45
- Links: wow/completed/20260307-1545_declarative-reconciliation-architecture/20260307-0906_declarative-reconciliation-architecture-plan.md, src/dic/ops, src/dic/run, cfg/dcl/README.md

## Goal

Make `src/dic/ops` declarative-first by default while preserving explicit
compatibility paths for legacy direct-mode behavior.

## Context

1. Reconcile-first execution is not yet default end-to-end.
2. `src/dic/ops` still sources injected values primarily from `cfg/env/site1`.
3. Declarative-first defaults are required to align runtime flow with the
   architecture contract (`cfg/dcl` -> `src/rec` -> `src/run`).

## Scope

1. Define default-path selection rules in `src/dic/ops` and bridge surfaces.
2. Add compatibility toggle/opt-out behavior with explicit operator signaling.
3. Extend tests for default-path behavior and guardrails.

## Next Step

Draft a queue candidate that locks target behavior, compatibility flags, and
validation commands before implementation.
