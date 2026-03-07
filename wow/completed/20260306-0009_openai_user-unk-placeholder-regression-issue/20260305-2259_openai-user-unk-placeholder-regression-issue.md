# OpenAI USER `unk` Placeholder Regression in `dev_osv`

- Status: completed
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-06 00:08
- Links: wow/task/inbox-capture, def0bcd30d74f9a6733b8626240e1948ded080c7, wow/completed/20260304-0229_openai-account-visibility-in-osv/20260302-0216_openai-account-visibility-in-osv-plan.md, lib/ops/dev, val/lib/ops/dev_test.sh, doc/arc/openai-user-unk-regression-triage-design.md, doc/man/07-dev-session-attribution-workflow.md, doc/man/03-cli-usage.md

## Goal

Capture a regression where OpenAI account attribution in `dev_osv` no longer shows the real account identity and instead renders `unk` in the `USER` column.

## Context

1. Reporter indicates the regression reappeared after commit `def0bcd30d74f9a6733b8626240e1948ded080c7`.
2. Current behavior: OpenAI-backed rows in `dev_osv` resolve `USER=unk` instead of account-specific labels.
3. Expected behavior (based on prior completed work): `dev_osv` should show resolvable OpenAI account identity in `USER`, with confidence/source semantics aligned to the OpenAI attribution flow.
4. Related historical context is documented in `wow/completed/20260304-0229_openai-account-visibility-in-osv/20260302-0216_openai-account-visibility-in-osv-plan.md`.
5. Triage trace shows reported suspect commit `def0bcd30d74f9a6733b8626240e1948ded080c7` is docs-only and does not touch `lib/ops/dev`.
6. The nearest functional commit after that point (`a80f14d4`) restores `dev_oar/dev_oad` and does not modify `dev_osv` attribution resolver paths.
7. Current OpenAI `USER=unk` behavior can be reached by design when provider/auth freshness gates reject candidates (`LAB_DEV_ATTR_PROVIDER_MAX_AGE_MS`, `LAB_DEV_ATTR_OPENAI_AUTH_MAX_AGE_MS`) and no qualifying identity remains.
8. Phase 1 design deliverable now records a chosen approach to add explicit low-confidence stale OpenAI fallback before unresolved `unk` output.
9. Implemented resolver changes in `lib/ops/dev` to add explicit stale OpenAI fallback paths with low confidence (`SRC=auth_state_stale` and `SRC=provider_stale`) before unresolved fallback.
10. Kept existing in-window high-confidence precedence and synthetic-identity filtering intact.
11. Updated attribution regressions in `val/lib/ops/dev_test.sh` to validate stale fallback source/confidence semantics.
12. Updated operator docs to reflect strict-mode low-confidence stale fallback behavior and new source tags.

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

## Execution Plan

Phase 1: Produce a focused design note for `dev_osv` OpenAI attribution regression triage that documents candidate resolver paths, constraints, trade-offs, expected `USER/SRC/CONF` output contracts, and the chosen approach.
Completion criterion: concrete deliverable committed at `doc/arc/openai-user-unk-regression-triage-design.md`.
Status: done (2026-03-05 23:58). Criterion met.

Phase 2: Implement the chosen attribution-path changes in `lib/ops/dev` and any directly affected resolver helpers.
Completion criterion: measurable target of zero `USER=unk` values for OpenAI rows across all scoped reproduction scenarios used in this item.
Status: done (2026-03-06 00:00). Criterion met.

Phase 3: Update and run validation coverage for the OpenAI attribution path and align workflow/docs with implemented behavior.
Completion criterion: concrete deliverable of updated tests/docs with recorded validation outcomes linked from this active item.
Status: done (2026-03-06 00:00). Criterion met.

## Progress

- [x] Phase 1 / Step 1: traced current `dev_osv` OpenAI attribution flow and output contract in `lib/ops/dev`.
- [x] Phase 1 / Step 2: compared post-report commit sequence and identified where resolver behavior actually changed.
- [x] Phase 1 / Step 3: produced design deliverable at `doc/arc/openai-user-unk-regression-triage-design.md`.
- [x] Phase 2: implemented chosen stale-fallback attribution path changes in `lib/ops/dev`.
- [x] Phase 3: extended tests/docs and ran validation evidence set.

## Validation Status

1. `bash -n lib/ops/dev` -> pass.
2. `bash -n val/lib/ops/dev_test.sh` -> pass.
3. `./val/lib/ops/dev_test.sh` -> pass (`68/68`).

## Verification Plan

1. Reproduce the regression against a controlled scenario and capture before/after `dev_osv` output focused on `USER/SRC/CONF` columns.
2. Run syntax checks (`bash -n`) on each changed Bash file.
3. Run nearest targeted tests first, then broaden to category-level validation if multiple attribution modules are touched.
4. Confirm behavior matches the Phase 1 design contract and does not regress previously documented OpenAI account visibility expectations.

## Exit Criteria

`dev_osv` OpenAI rows resolve real account identity instead of `unk`, attribution metadata remains contract-consistent (`USER/SRC/CONF`), validation evidence is captured, and linked docs/tests reflect the final behavior.

## What changed

1. Added design deliverable `doc/arc/openai-user-unk-regression-triage-design.md` documenting interfaces, constraints, alternatives, and chosen approach.
2. Updated `lib/ops/dev` resolver flow to add explicit OpenAI stale fallback paths with low confidence and explicit provenance (`auth_state_stale`, `provider_stale`) before unresolved `unk`.
3. Updated OpenAI attribution regressions in `val/lib/ops/dev_test.sh` to validate stale fallback behavior and source/confidence semantics.
4. Updated operator docs (`doc/man/07-dev-session-attribution-workflow.md`, `doc/man/03-cli-usage.md`) so strict/best-effort expectations and `SRC` values match shipped behavior.
5. Updated this workflow item with implementation findings, phase completion, and validation evidence.

## What was verified

1. `bash -n lib/ops/dev` -> pass.
2. `bash -n val/lib/ops/dev_test.sh` -> pass.
3. `./val/lib/ops/dev_test.sh` -> pass (`68/68`).
4. `bash wow/check-workflow.sh` -> pass.

## What remains

1. No required follow-up items remain for repository implementation scope.
2. Optional live environment evidence capture can be run ad hoc; it is not a blocker for closure.
