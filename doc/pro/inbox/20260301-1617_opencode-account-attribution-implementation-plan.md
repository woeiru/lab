# OpenCode Account Attribution Implementation Plan

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-01
- Links: lib/ops/dev, val/lib/ops/dev_test.sh, doc/pro/inbox/README.md

## Goal

Implement a real, auditable way to attribute each OpenCode session to the actual account in use at first prompt time, with provider-aware support for Antigravity and OpenAI.

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
