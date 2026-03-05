# OpenAI `USER=unk` Regression Triage Design

## 1. Objective

Define and lock a safe resolver contract that prevents avoidable `USER=unk`
results for OpenAI-backed `dev_osv` rows while preserving attribution safety
(`USER/SRC/CONF`) and stale-event guardrails.

## 2. Scope and Inputs

In scope:

- `lib/ops/dev` (`_dev_osv_render` Python resolver path)
- `val/lib/ops/dev_test.sh` (OpenAI attribution regressions)
- Docs that define resolver behavior and troubleshooting expectations

Primary inputs reviewed:

- `doc/pro/active/20260305-2259_openai-user-unk-placeholder-regression-issue.md`
- `doc/pro/completed/20260304-0229_openai-account-visibility-in-osv/20260302-0216_openai-account-visibility-in-osv-plan.md`
- `lib/ops/dev` (OpenAI resolver + fallback flow)
- `val/lib/ops/dev_test.sh`
- `doc/man/07-dev-session-attribution-workflow.md`

Out of scope for this phase:

- Runtime provider API calls
- Historical data backfill/migration

## 3. Current Resolver Interface and Contract

Resolver entrypoint:

- `resolve_session_user(session_id, first_prompt_ms, provider_id, attribution_events, legacy_events, antigravity_known_accounts=None, allow_best_effort=False)` inside `_dev_osv_render`.

Current OpenAI path order:

1. Session-bound `opencode_account_event` match (`high`/`low` based on timing + mode).
2. Provider-wide event timeline with freshness gate for OpenAI (`LAB_DEV_ATTR_PROVIDER_MAX_AGE_MS`, default 60m).
3. Legacy `control_account` (best-effort only) with same freshness gate.
4. Local auth-state fallback (`SRC=auth_state`) with timing gate (`LAB_DEV_ATTR_OPENAI_AUTH_MAX_AGE_MS`, default 6h).
5. Unknown fallback (`USER=unk`, `SRC=none`, `CONF=none`).

Output contract:

- `USER`: compacted account label
- `SRC`: attribution source (`shell_wrapper`, `runtime`, `auth_state`, etc.)
- `CONF`: `high | low | none`

## 4. Findings from Triage

1. Reported suspect commit `def0bcd30d74f9a6733b8626240e1948ded080c7` is docs-only and does not modify resolver code.
2. First functional commit after that timestamp (`a80f14d4`) restores `dev_oar/dev_oad` and does not touch `dev_osv` attribution logic.
3. `cd12a9ae` introduced OpenAI provider/auth freshness gates and tests that explicitly allow strict-mode OpenAI rows to resolve as unknown when outside windows.
4. Current resolver can return `USER=unk` even when a non-synthetic OpenAI identity exists but fails freshness gating.
5. This behavior is internally consistent with current tests/docs, but it is inconsistent with the newly reported operator expectation for active OpenAI visibility.

## 5. Constraints and Invariants

1. No network calls during resolver execution.
2. Keep deterministic precedence; avoid random/stochastic selection.
3. Do not regress anti-bleed safety (avoid stale wrong-account dominance).
4. Preserve existing `high` confidence meaning for pre-first-prompt deterministic matches.
5. Any expanded fallback must use explicit provenance in `SRC` and non-high confidence.

## 6. Alternatives Considered

### A) Keep current behavior and require operator env tuning

Pros:

- No code changes.
- Preserves strict anti-stale behavior.

Cons:

- Leaves reported regression unresolved in default behavior.
- Requires manual operator intervention for routine diagnostics.

### B) Disable/relax OpenAI freshness gates globally

Pros:

- Fast path to fewer unknown rows.

Cons:

- Reintroduces stale cross-session attribution risk.
- Weakens previously intentional safety contract.

### C) Add explicit stale-identity fallback tier for OpenAI (chosen)

Pros:

- Reduces avoidable `USER=unk` while preserving high-confidence semantics.
- Keeps stale usage explicit via new low-confidence provenance.

Cons:

- Expands resolver complexity.
- Requires doc/test updates and careful source semantics.

## 7. Chosen Approach

Implement a bounded, explicit stale fallback tier for OpenAI only, after current
high-confidence paths are exhausted:

1. Keep existing session-bound/provider-window/auth-window logic unchanged for
   `CONF=high` and normal `CONF=low` behavior.
2. When those paths fail for OpenAI, evaluate stale-but-non-synthetic fallback
   candidates and return low-confidence identity instead of `unk` when safe.
3. Emit explicit stale provenance in `SRC`:
   - `auth_state_stale` for auth-state identity outside freshness window.
   - `provider_stale` for provider timeline identity outside freshness window.
4. Keep unknown fallback (`unk|none|none`) only when no safe non-synthetic
   identity exists.

Selection rules for stale fallback:

1. Candidate identities must be non-synthetic (`unknown`, `audit-session*`,
   `*@example.*` excluded).
2. Prefer stale auth-state identity first (represents currently authenticated
   local account state).
3. If no stale auth identity, use most recent stale provider event identity.
4. All stale fallback returns use `CONF=low`.

## 8. Implementation Touchpoints

1. `lib/ops/dev` (`_dev_osv_render` Python block):
   - add OpenAI stale fallback helpers,
   - extend `resolve_session_user` final OpenAI path.
2. `val/lib/ops/dev_test.sh`:
   - add/adjust regressions for stale fallback source and confidence semantics,
   - retain tests that guard synthetic-placeholder rejection.
3. Docs:
   - `doc/man/07-dev-session-attribution-workflow.md`
   - `doc/man/03-cli-usage.md`

## 9. Verification Plan for Implementation Phase

1. `bash -n lib/ops/dev`
2. `bash -n val/lib/ops/dev_test.sh`
3. Run targeted tests for stale/openai attribution behavior in
   `./val/lib/ops/dev_test.sh`
4. `bash doc/pro/check-workflow.sh`

## 10. Decision Summary

Proceed with Alternative C: preserve existing deterministic high-confidence
contracts, add explicit OpenAI stale fallback (`CONF=low` + explicit stale `SRC`),
and reserve `USER=unk` for truly unresolved/non-safe cases.
