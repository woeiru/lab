# OpenAI USER `unk` Placeholder Regression in `dev_osv`

- Status: queue
- Owner: es
- Started: n/a
- Updated: 2026-03-05 23:01
- Links: doc/pro/task/inbox-capture, def0bcd30d74f9a6733b8626240e1948ded080c7, doc/pro/completed/20260304-0229_openai-account-visibility-in-osv/20260302-0216_openai-account-visibility-in-osv-plan.md, lib/ops/dev

## Goal

Capture a regression where OpenAI account attribution in `dev_osv` no longer shows the real account identity and instead renders `unk` in the `USER` column.

## Context

1. Reporter indicates the regression reappeared after commit `def0bcd30d74f9a6733b8626240e1948ded080c7`.
2. Current behavior: OpenAI-backed rows in `dev_osv` resolve `USER=unk` instead of account-specific labels.
3. Expected behavior (based on prior completed work): `dev_osv` should show resolvable OpenAI account identity in `USER`, with confidence/source semantics aligned to the OpenAI attribution flow.
4. Related historical context is documented in `doc/pro/completed/20260304-0229_openai-account-visibility-in-osv/20260302-0216_openai-account-visibility-in-osv-plan.md`.

## Scope

In scope:

1. Preserve the reported symptom (`USER=unk` for OpenAI rows in `dev_osv`) and the suspected regression point (`def0bcd30d74f9a6733b8626240e1948ded080c7`).
2. Capture linkage to prior OpenAI account visibility work for continuity.
3. Define this as a triage-ready issue for attribution-path investigation.

Out of scope:

1. Implementing or validating a fix in this capture step.
2. Backfilling historical session rows.
3. Modifying runtime attribution behavior during inbox capture.

## Risks

1. Operators lose account-level observability when `USER` collapses to `unk`.
2. Session attribution confidence becomes harder to trust for debugging and audit workflows.
3. Reintroduced identity placeholders can hide regressions in provider-specific resolver logic.

## Triage Decision

- Why now: this regression reintroduces identity ambiguity in a core operator diagnostic view and can immediately degrade account-level debugging and trust.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: multiple resolver and fallback strategies are possible, and downstream tests/docs/operators depend on stable `USER/SRC/CONF` attribution behavior.

## Next Step

Promote this item from queue to active and perform focused regression triage around `dev_osv` OpenAI identity resolution paths changed since `def0bcd30d74f9a6733b8626240e1948ded080c7`, using the linked completed plan as baseline behavior.
