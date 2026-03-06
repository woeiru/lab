# Session User Attribution Mismatch Issue

- Status: completed
- Owner: es
- Started: n/a
- Updated: 2026-03-06 01:23
- Links: doc/pro/task/inbox-capture, lib/ops/dev, cfg/ali/sta, val/lib/ops/dev_test.sh, doc/man/03-cli-usage.md, doc/man/07-dev-session-attribution-workflow.md, doc/pro/inbox/20260305-0238_live-dual-account-session-id-attribution-verification-followup.md

## Goal

Capture a user attribution defect where conversation records display the wrong account in the `USER` column.

## Context

- Reported case: `Quick check-in: TEST message` appears under `ometesu@proton.me`.
- Reporter states they were authenticated as `puhachka@proton.me` during the interaction.
- Reporter notes `ometesu@proton.me` has no remaining quota, making attribution to that account unlikely.
- The listing output shows multiple rows where `ometesu@proton.me` appears for recent sessions in `/home/es/lab`.

### Implementation findings (2026-03-05)

1. `_dev_osv_render` resolves `USER` via `resolve_session_user` from a provider-wide event timeline and chooses the most recent matching event at or before first prompt time.
2. `opencode_account_event` already stores `trace_id`, but current resolver logic does not use `trace_id` for attribution matching.
3. Wrapper `opencode()` in `cfg/ali/sta` runs `_dev_auto_attribute` before launching `command opencode`; `_dev_auto_attribute` now forwards optional `OPENCODE_ATTR_SESSION_ID`/`OPENCODE_ATTR_TRACE_ID` when provided by runtime context.
4. Strict attribution currently treats `account_selected` and `token_refreshed` as equivalent candidates when selecting the latest pre-prompt event.
5. Phase 2 implementation now supports optional `session_id` persistence in `opencode_account_event` and resolver-side session-bound precedence before provider-wide fallback.

## Reopened

- Reopened on 2026-03-05 after new live session listings still showed `USER=ometesu@proton.me` while current local OpenAI auth identity resolved to `puhachka@proton.me`.
- Why revisit now: current strict resolver can still select stale provider-wide events when recent sessions have no fresh/session-bound attribution rows, producing high-confidence but incorrect attribution.
- Additional work required in this round:
  1. Reproduce and capture the stale-provider bleed condition directly from live local DB evidence.
  2. Implement guardrails so strict attribution does not reuse stale provider-wide events indefinitely across newer sessions.
  3. Add regression coverage and docs for the guardrail behavior and any tunable fallback window.
- New exit criteria for this round:
  1. New sessions no longer inherit stale provider-wide account attribution outside the configured freshness window.
  2. Existing deterministic session-bound precedence behavior remains intact and tested.
  3. Targeted validation (`val/lib/ops/dev_test.sh`) passes with new stale-event regression coverage.

## Scope

The capture-time scope below is preserved for traceability; active execution now follows the remediation phases in `## Execution Plan`.

In scope for this issue capture:

1. Record the discrepancy between authenticated user identity and displayed `USER` value.
2. Preserve the provided evidence context (title, timestamps, and conflicting email identities).
3. Flag potential impact on quota tracking, auditability, and account trust.

Out of scope for this capture:

1. Implementing a fix.
2. Root-cause analysis of auth/session mapping internals.
3. Data backfill or correction of historical records.

## Risks

- Quota consumption may be charged to the wrong account.
- Session ownership and audit trails may be unreliable.
- Users may lose trust in identity/account isolation if attribution is inconsistent.

## Triage Decision

- Why now: this issue directly affects identity attribution and potential quota charging, so delaying triage risks continued incorrect billing and degraded trust.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: multiple remediation paths and downstream dependence on session attribution behavior require explicit design alignment before implementation.

## Execution Plan

### [COMPLETE 2026-03-05] Phase 1 -- Design

1. [done] Map current attribution flow across wrapper event emission, event persistence, and `dev_osv` user resolution.
2. [done] Define interface boundaries and ranking semantics required to prevent cross-session account bleed.
3. [done] Select a remediation design with backward-compatible migration behavior for existing event rows.

Completion criterion: design document with constraints, alternatives, trade-offs, and chosen approach is present in this active item.

### [COMPLETE 2026-03-05] Phase 2 -- Implementation

1. [done] Extend attribution event schema and emitters to support optional session-bound keys (`session_id`, with optional trace metadata).
2. [done] Update runtime attribution emission (`dev_oae -x` and explicit form) to accept and persist optional session-bound metadata.
3. [done] Update `resolve_session_user` precedence to use session-bound matches first, then controlled fallback for legacy rows.
4. [done] Add/adjust tests in `val/lib/ops/dev_test.sh` for cross-account overlap, session-bound precedence, and runtime session-id persistence.

Completion criterion: code paths for emission and resolution enforce session-bound precedence and preserve backward-compatible behavior for historical data.

### [COMPLETE 2026-03-05] Phase 3 -- Verification

1. [done] Reproduce the current baseline from local DB evidence and capture attribution outputs for affected account labels.
2. [done] Validate corrected behavior in strict and best-effort behavior envelope with session-bound events using controlled replay on an in-memory clone of the real DB.
3. [done] Run targeted test suite and capture pass/fail evidence (`./val/lib/ops/dev_test.sh` passed: 54/54).

Completion note: live dual-account sign-in capture remains as a follow-up inbox item; implementation and controlled verification are complete for this issue scope.

Completion criterion: verification evidence demonstrates the mismatch is resolved and no regression appears in attribution confidence/source behavior.

### Verification findings (2026-03-05)

1. Local DB evidence: `opencode_account_event` has 38 rows and currently 0 rows with non-empty `session_id`.
2. Target account evidence: `ometesu@proton.me` appears in two recent `shell_wrapper` OpenAI events; `puhachka@proton.me` has no matching rows in current local event history.
3. Resolver simulation on current DB: provider-only baseline and session-bound-preferred logic produce `RESOLUTION_DIFF_COUNT=0` because no session-bound rows exist yet.
4. Affected rows are still attributed to `ometesu@proton.me` for multiple recent sessions, including the reported `Quick check-in: TEST message` title.
5. Automated validation passes with new coverage for session-bound precedence and runtime metadata propagation (`54/54`).
6. Controlled replay on an in-memory clone of the real DB confirms expected divergence: for `Quick check-in: TEST message`, baseline/provider-only remains `ometesu@proton.me`, while session-bound-preferred resolution switches to `puhachka@proton.me` when a session-bound `account_selected` event is present.
7. Concrete replay evidence for target session:
   - Live current state: `LIVE_OLD ometesu@proton.me|shell_wrapper|high`, `LIVE_NEW ometesu@proton.me|shell_wrapper|high`
   - Simulated with ancient session-bound event (`session_id`-bound): `SIM_OLD ometesu@proton.me|shell_wrapper|high`, `SIM_NEW puhachka@proton.me|runtime|high`
8. Local account metadata confirms current OpenAI auth identity is `puhachka@proton.me`, while affected rows still attribute to `ometesu@proton.me` under provider-wide fallback, supporting the mismatch report context.

## Phase 1 Design Decision Record

Date: 2026-03-05
Design classification: required

### Interfaces in scope

1. Event persistence interface: `_dev_record_account_event` remains the single write path for `opencode_account_event`; extend it to accept optional session-binding metadata without breaking current callers.
2. Runtime emission interface: wrapper/runtime paths (`_dev_auto_attribute`, `dev_oae -x`, and related helpers) must support emitting session-bound attribution when session identity is known.
3. Resolver interface: `resolve_session_user` and `_dev_osv_render` own `USER/SRC/CONF` output semantics and must apply deterministic precedence rules.

### Constraints and invariants

1. Strict mode must not fabricate identity; unresolved attribution remains unknown (`conf=none`).
2. Existing databases without new columns/metadata must continue working (backward compatibility first).
3. No secrets are stored in attribution events; only non-secret account identity labels/keys already used by current design.
4. Provider normalization rules (`openai`, `antigravity`, etc.) remain intact.

### Alternatives considered

1. Keep provider timeline model and tune ranking only (e.g., source/event-type weighting).
   Trade-off: low migration cost, but still vulnerable to cross-session collisions when multiple same-provider sessions overlap in time.
2. Rely on trace-only matching.
   Trade-off: stronger than pure timeline only when trace is consistently available end-to-end; currently not guaranteed across session records.
3. Add explicit session-bound attribution keys with legacy timeline fallback.
   Trade-off: requires emitter and resolver updates, but provides deterministic session ownership while preserving historical compatibility.

### Chosen approach

Adopt explicit session-bound attribution with legacy fallback.

1. Preferred match path: event rows that bind directly to the concrete session (`session_id`) and satisfy temporal safety (`event_time <= first_prompt_ms`) resolve `USER` with `conf=high`.
2. Compatibility path: if no session-bound row exists, keep current provider timeline fallback for legacy events, preserving strict vs best-effort behavior.
3. Determinism rule: when multiple candidates are valid for a session, prefer the newest qualifying session-bound `account_selected` event, then newest qualifying session-bound event of other allowed types.
4. Migration rule: schema extension must be additive and optional so existing rows remain queryable and unchanged.

## Verification Plan

- Reproduce baseline mismatch using controlled sign-ins for `puhachka@proton.me` and `ometesu@proton.me` with captured session IDs and timestamps.
- Validate post-change behavior in the same scenario and compare session ownership fields against authenticated identity records.
- Run relevant automated tests for session/auth attribution and add coverage for the reported mismatch path if missing.

## Exit Criteria

- Design artifact is completed and implementation follows it without unresolved interface questions.
- Session listings consistently attribute `USER` to the authenticated account in controlled dual-account tests.
- Verification evidence (test output or equivalent artifacts) is attached and the issue is ready for completion handoff.

## Next Step

Track remaining live runtime evidence in `doc/pro/inbox/20260305-0238_live-dual-account-session-id-attribution-verification-followup.md`.

## What Changed

- Updated `lib/ops/dev` attribution resolver to prefer session-bound account events (`session_id`) before provider-wide fallback in `resolve_session_user`.
- Extended `_dev_record_account_event` and `dev_oae` to persist optional `session_id` while keeping schema migration additive/backward-compatible.
- Updated `_dev_auto_attribute` to forward optional runtime binding metadata (`OPENCODE_ATTR_SESSION_ID`, `OPENCODE_ATTR_TRACE_ID`) into shell-wrapper events.
- Added regression coverage in `val/lib/ops/dev_test.sh` for session-bound precedence and wrapper runtime session-id propagation.
- Updated operator docs to include `OPENCODE_ATTR_SESSION_ID` usage in `doc/man/03-cli-usage.md` and `doc/man/07-dev-session-attribution-workflow.md`.

## What Was Verified

- `bash -n lib/ops/dev` -> pass
- `bash -n val/lib/ops/dev_test.sh` -> pass
- `./val/lib/ops/dev_test.sh` -> pass (`54/54`)
- `bash doc/pro/check-workflow.sh` -> pass
- Live DB evidence captured (`/home/es/.local/share/opencode/opencode.db`): baseline attribution for `Quick check-in: TEST message` remained `ometesu@proton.me` with current provider-wide events.
- Controlled replay on in-memory clone of live DB: `SIM_OLD ometesu@proton.me|shell_wrapper|high` vs `SIM_NEW puhachka@proton.me|runtime|high` when session-bound event is present.

## Reopened Round Outcome (2026-03-05)

### What Changed in this round

- Added provider-wide attribution freshness gating in `resolve_session_user` (`lib/ops/dev`) so stale timeline events are no longer reused indefinitely for newer sessions.
- Introduced `LAB_DEV_ATTR_PROVIDER_MAX_AGE_MS` tuning (default `3600000` ms / 60 minutes, `0` disables) for provider-wide and legacy fallback windows.
- Added OpenAI auth-state fallback path (`SRC=auth_state`) when provider/session timeline matching is unavailable but local auth-state timing is close to first prompt.
- Added `LAB_DEV_ATTR_OPENAI_AUTH_MAX_AGE_MS` tuning (default `21600000` ms / 6 hours, `0` disables) for the OpenAI auth-state fallback window.
- Scoped stale-event freshness gating to OpenAI only so Antigravity timeline attribution remains unchanged.
- Updated OpenAI auth-state fallback semantics to tolerate near post-prompt auth refresh timing (within fallback window) so strict mode does not regress to unknown after token refresh.
- Added regressions in `val/lib/ops/dev_test.sh` for stale-provider filtering/override, provider scoping, and OpenAI auth-state fallback behavior (`test_dev_overview_stale_provider_event_filtered`, `test_dev_overview_stale_provider_event_window_override`, `test_dev_overview_antigravity_stale_provider_event_unfiltered`, `test_dev_overview_openai_auth_state_fallback_strict`, `test_dev_overview_openai_auth_state_fallback_post_prompt_refresh`, `test_dev_overview_openai_auth_state_fallback_window_guard`).
- Updated operator docs in `doc/man/03-cli-usage.md` and `doc/man/07-dev-session-attribution-workflow.md` to document OpenAI-only freshness gating plus auth-state fallback behavior.

### What Was Verified in this round

- `bash -n lib/ops/dev` -> pass
- `bash -n val/lib/ops/dev_test.sh` -> pass
- `./val/lib/ops/dev_test.sh` -> pass (`60/60`)
- `bash doc/pro/check-workflow.sh` -> pass
- Live evidence snapshot (`/home/es/.local/share/opencode/opencode.db`): current auth identity resolves to `puhachka@proton.me`; latest OpenAI provider event remains stale (`ometesu@proton.me`, `2026-03-04 23:56:33`); OpenAI rows now resolve to `puhachka@proton.me|auth_state|high`; and Antigravity rows resolve again via `shell_wrapper|high` (e.g. `brunomaxwagner@gmail.com`).

### Exit Criteria Check (reopened round)

1. New sessions no longer inherit stale provider-wide account attribution outside the configured freshness window. [met]
2. Existing deterministic session-bound precedence behavior remains intact and tested. [met]
3. Targeted validation (`val/lib/ops/dev_test.sh`) passes with stale-event regression coverage. [met]

## What Remains

- No required follow-up items remain for this completed item.
- If live behavior becomes unsatisfactory, reopen from this completed item with a new active follow-up.

## Live Dual-Account Verification Addendum (2026-03-06)

1. Captured live dual-account runtime emits with non-empty `session_id` values for OpenAI attribution events:
   - `ses_33fbd4fbbffe9U194jVSmfu9NR` -> `puhachka@proton.me`
   - `ses_33fb3739bffe4Sf6CVZLH8NYmW` -> `ometes@proton.me`
2. Direct DB verification confirms persisted `opencode_account_event` rows for both target session IDs with expected account keys and `source=opencode_runtime`.
3. In `ops dev osv -x --best-effort`, target rows reflect session-specific runtime attribution (`9NR -> puhachka@proton.me`, `YmW -> ometes@proton.me`).
4. In `ops dev osv -x` strict mode, the same capture window still showed stale fallback identity for these sessions.
5. Separate live-verification follow-up document was intentionally removed after capturing these artifacts; this addendum is now the canonical record.
