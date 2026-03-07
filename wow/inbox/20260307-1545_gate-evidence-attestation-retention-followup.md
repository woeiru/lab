# Gate Evidence Attestation Retention Follow-up

- Status: inbox
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 15:45
- Links: wow/completed/20260307-1545_declarative-reconciliation-architecture/20260307-0906_declarative-reconciliation-architecture-plan.md, src/run/gate-evidence, src/run/dispatch, doc/man/04-deployments.md

## Goal

Define and implement durable attestation persistence and retention conventions
for strict-run gate evidence, including operator audit retrieval guidance.

## Context

1. Strict-run gate-evidence production and consumption are implemented.
2. Evidence retention is still manual/out-of-band.
3. Missing retention conventions weaken auditability and repeatability.

## Scope

1. Select canonical storage location and lifecycle policy for gate evidence artifacts.
2. Define naming/metadata requirements for retrieval and audit traceability.
3. Update runbook documentation and add validation coverage for retention behavior.

## Next Step

Prepare a queue-ready implementation plan with concrete retention policy defaults
and migration-safe rollout steps.
