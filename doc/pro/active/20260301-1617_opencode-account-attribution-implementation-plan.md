# OpenCode Account Attribution Implementation Plan

- Status: active
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-01 (resume execution)
- Links: lib/ops/dev, val/lib/ops/dev_test.sh, doc/pro/inbox/README.md

## Goal

Implement a real, auditable way to attribute each OpenCode session to the actual account in use at first prompt time, with provider-aware support for Antigravity and OpenAI.

## Triage Decision

Move to queue now because account attribution correctness is blocking trustworthy reporting and should be prioritized before more `dev_osv` output changes.

## Execution Start

Execution started now to implement strict, event-based session attribution in `dev_osv` and validate with `val/lib/ops/dev_test.sh`.

## Progress Checkpoint

### Done

- Implemented strict provider-aware attribution in `lib/ops/dev` for `dev_osv` using `opencode_account_event`, with strict default and `--best-effort` fallback mode.
- Added provenance output contract in `dev_osv` (`USER`, `SRC`, `CONF`) and kept strict behavior as default.
- Added runtime event persistence for explicit account switches in `dev_oas` via `_dev_record_account_event` and provider normalization helper.
- Expanded tests in `val/lib/ops/dev_test.sh` to cover strict/high attribution, best-effort/low fallback, provider mismatch no-cross-attribution, legacy `control_account` fallback, and event persistence.
- Added `dev_oae` runtime-hook emitter in `lib/ops/dev` for non-manual attribution event writes via `-x` + `OPENCODE_ATTR_*` env vars or explicit args.
- Added validated event-type support (`account_selected`, `token_refreshed`, `auth_switched`) plus optional `trace_id` persistence in `_dev_record_account_event`.
- Extended tests for deterministic repeated-event timeline resolution (latest-before-first-prompt) and runtime/token-refresh event emission paths.
- Added mixed event replay coverage for `account_selected` + `token_refreshed` across providers/sessions with deterministic latest-before-first-prompt assertions.
- Regenerated reference docs via `./utl/doc/run_all_doc.sh` so `doc/ref/functions.md` and related maps include `dev_oae` and updated metrics.
- Committed resume-session attribution updates in `866ac019`.
- Committed implementation in three commits: `2d5679f6`, `ffc451d9`, `2e12e5a2`.

### In-flight

- Current uncommitted follow-up change is test-only replay coverage in `val/lib/ops/dev_test.sh` from post-commit continuation.
- Remaining in-flight integration is wiring `dev_oae -x` into real OpenCode runtime request/auth hook points outside this repo.

### Blockers

- No hard blocker in this repo code path.
- Remaining uncertainty: definitive upstream OpenCode hook points for automatic request-time selection and token-refresh emission are still external to this repo, but `dev_oae` now defines the local ingestion contract.

### Next steps

1. Wire `dev_oae -x` into the actual OpenCode runtime request path so each request-time account choice emits `event_type=account_selected` automatically.
2. Wire `dev_oae -x` into the actual credential refresh path so identity changes emit `event_type=token_refreshed` with `OPENCODE_ATTR_TRACE_ID` when available.
3. Keep this active plan current through upstream hook wiring acceptance and final merge/commit steps.

### Context

- Branch: `master`.
- Relevant modified modules now include `lib/ops/dev`, `val/lib/ops/dev_test.sh`, and regenerated `doc/ref/` references.
- Latest local test result: `./val/lib/ops/dev_test.sh` passed `28/28`.
- Resume-session code/doc batch committed at `866ac019`; branch is now ahead with that commit.
- Reference docs regenerated successfully via `./utl/doc/run_all_doc.sh`.
- Branch currently includes additional doc/pro commits after the prior checkpoint; attribution state remains consistent.
- No temporary files or ad-hoc local fixtures are required to resume; tests create/clean their own temp environments.

## Execution Plan

Remaining execution scope only:

1. Complete upstream runtime wiring so `dev_oae` receives automatic request-time and token-refresh events.
2. Add one integration-style replay test covering mixed event types across providers.
3. Keep generated refs synchronized after each structural change.
4. Preserve strict mode as default in `dev_osv`; keep low-confidence signaling only behind `--best-effort`.

## Current Problem (Observed)

- `session` + `message` rows contain timing/model/provider data but no reliable account identity.
- `control_account` exists but is currently empty in the local DB, so historical attribution cannot be derived.
- `~/.config/opencode/antigravity-accounts.json` contains account inventory and routing, but not a guaranteed per-session event log.
- Result: attribution falls back to guesses unless we capture real events at runtime.

## Definition Of Done (What "Correct" Means)

A session row is "correct" only if all are true:

1. Account identity comes from a captured runtime event, not a fallback guess.
2. The captured event timestamp is less than or equal to session first user prompt timestamp.
3. Provider family is known (`antigravity`, `openai`, or another explicit provider id).
4. Attribution source is preserved (`opencode_event`, `connector_event`, etc.) for auditability.

## Strategy

Use a two-layer approach:

- Layer A (source-of-truth capture): instrument account selection/auth events where OpenCode or its provider connectors decide credentials.
- Layer B (query/reporting): map session first prompt time to the latest known account event for that provider.

No guessed attribution in strict mode.

## Implementation Phases

### Phase 0 - Baseline and Schema Audit

1. Document current DB schema and relevant JSON keys (`session`, `message`, `control_account`).
2. Confirm whether account identity appears anywhere in message payload over a representative sample.
3. Freeze a baseline `dev_osv -x` snapshot for before/after comparison.

Deliverable:
- `doc/pro/active/...` investigation note with verified fields and gaps.

### Phase 1 - Discover Real Account Decision Point In OpenCode

1. Identify the exact code path where provider credentials are chosen (Antigravity/OpenAI).
2. Verify whether OpenCode has hooks/events for auth/account switching.
3. If no hook exists, add a minimal instrumentation point at credential resolution.

Deliverable:
- Mapped call graph of account resolution path.
- Approved event payload schema.

### Phase 2 - Add Attribution Event Store

Create a local attribution log DB (or table in OpenCode DB if supported) with append-only semantics:

- `time_ms` (INTEGER, required)
- `provider_id` (TEXT, required)
- `account_key` (TEXT, required; email if safe, otherwise stable hash)
- `account_label` (TEXT, optional; human-readable email/mask)
- `event_type` (TEXT, required; `account_selected`, `token_refreshed`, `auth_switched`)
- `source` (TEXT, required; `opencode`, `connector`, `manual_switch`)
- `trace_id` (TEXT, optional)

Rules:

- Never store secrets/tokens.
- Writes are append-only.
- Timestamps use epoch milliseconds UTC.

### Phase 3 - Emit Events At Runtime

Instrument these transitions:

1. Account selected for request execution.
2. Explicit account switch commands.
3. Credential refresh that changes effective identity.

Provider-specific requirements:

- Antigravity: include family routing context when available.
- OpenAI: include organization/project context if available from runtime config.

### Phase 4 - Session Attribution Resolver

Add resolver logic for each session:

1. Compute `first_prompt_ms` from earliest user message in `message`.
2. Determine provider family for that session from message provider data.
3. Pick latest attribution event where:
   - same provider family
   - `event.time_ms <= first_prompt_ms`
4. Return `(user, source, confidence)` where confidence is:
   - `high`: direct event match
   - `low`: provider known but only post-first-prompt event exists
   - `none`: no event

Strict mode only displays `high`.

### Phase 5 - Update `dev_osv` Output Contract

Keep one user identity column and add provenance:

- `USER` (resolved account label)
- `SRC` (event source)
- `CONF` (`high|low|none`)

Mode behavior:

- strict default: `USER` is `(unknown)` unless `CONF=high`.
- optional best-effort flag can show `low` with explicit mark.

### Phase 6 - Tests

Add/extend tests in `val/lib/ops/dev_test.sh`:

1. Multiple account-switch events across time map correctly to sessions.
2. Provider mismatch does not cross-attribute users.
3. Empty event store returns `(unknown)` with `CONF=none`.
4. Best-effort mode surfaces `low` without pretending certainty.

Optional integration tests:

- Fixture DB + fixture attribution log replay.

### Phase 7 - Backfill and Rollout

1. Backfill policy: mark historical sessions as unknown by default.
2. Optional heuristic backfill as separate command with `heuristic` confidence label.
3. Rollout behind feature flag; compare old/new output for one week.

## Effort Estimate

- Phase 0-1 (discovery): 0.5-1.5 days
- Phase 2-4 (core implementation): 1-2 days
- Phase 5-6 (reporting + tests): 0.5-1 day
- Phase 7 (rollout/backfill): 0.5 day

Total: 2.5-5 days depending on OpenCode hook availability.

## Risks and Mitigations

- No hook point in OpenCode: patch connector layer where credentials are assembled.
- Multi-device account switches: rely on local runtime events only; do not infer remote activity.
- Privacy concerns around emails: support hashing + masked label display.
- Schema drift in OpenCode: keep attribution store decoupled and versioned.

## Acceptance Criteria

- New sessions are attributable with `CONF=high` when account events exist.
- `dev_osv` never shows fabricated certainty.
- Test suite covers positive, negative, and missing-data paths.
- Attribution metadata is auditable and secret-safe.

## Out Of Scope

- Perfect retroactive attribution for already-recorded sessions without event history.
- Cross-machine reconciliation without shared event transport.
