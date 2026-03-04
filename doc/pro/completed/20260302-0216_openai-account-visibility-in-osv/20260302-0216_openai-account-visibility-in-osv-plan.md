# OpenAI Account Visibility in OSV Plan

- Status: completed
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04 02:28
- Links: lib/ops/dev, cfg/ali/sta, val/lib/ops/dev_test.sh, doc/man/07-dev-session-attribution-workflow.md, doc/man/03-cli-usage.md

## Triage Decision

- Why now: `ops dev osv` is currently surfacing placeholder OpenAI account labels for new sessions, which reduces auditability and blocks reliable operator debugging workflows.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Classification justification: this change defines identity-resolution contracts and output semantics (`USER`, `CONF`, `SRC`) that downstream tests, docs, and operators depend on.

## Goal

Ensure `ops dev osv` shows the real connected OpenAI account in the `USER` column for new OpenAI sessions, instead of placeholders like `audit-session@example.com`.

## Current Problem (Observed)

1. `USER` in `dev_osv` is sourced from local `opencode_account_event` rows, not directly from OpenAI APIs.
2. Placeholder/manual labels can be written into attribution events and later shown in `osv`.
3. Automatic wrapper attribution currently reads only `antigravity-accounts.json`; there is no equivalent OpenAI resolver in `_dev_auto_attribute`.
4. Table mode (`-t`) has a narrow `USER` column, so longer values can be truncated.

## Desired Behavior

For OpenAI provider sessions:

1. The wrapper emits an `account_selected` event with a real OpenAI identity label before session start.
2. `ops dev osv -x` shows that label in `USER` with `CONF=high` and `SRC=shell_wrapper` (or explicit source agreed by implementation).
3. `ops dev osv -t` displays enough of `USER` to identify the account reliably.

## Scope

In scope:

1. Add an OpenAI account resolver path for automatic pre-session attribution.
2. Integrate OpenAI resolver into the existing wrapper-based attribution flow.
3. Improve `USER` display ergonomics in table mode.
4. Add tests for OpenAI auto-attribution and output visibility.

Out of scope:

1. Retroactive correction of historical sessions that already started without attribution.
2. Any external changes to OpenAI/OpenCode upstream services.
3. Runtime network calls to OpenAI during `opencode` launch.

## Execution Plan

### Phase 1 - OpenAI Identity Design Contract

1. Confirm deterministic local resolver order for active OpenAI identity (runtime env hook, local auth/account state file, explicit override env var).
2. Define the resolver interface and output contract for provider/key/label/source/confidence semantics used by wrapper attribution and `dev_osv`.
3. Document constraints and trade-offs (offline/no-network launch behavior, fail-open behavior when source is missing, and privacy boundaries for persisted data).
4. Record the chosen approach before any implementation phase starts.

Completion criterion:

- This item contains a concrete design note that specifies interfaces, constraints, trade-offs, resolver order, and chosen approach.

### Phase 1 Design Note (Completed)

Chosen resolver contract and order:

1. Interface: internal helper `_dev_get_openai_account_identity` returns one line payload `account_key|account_label|identity_source` and exits `0` only when all required fields are non-empty.
2. Resolver order (highest precedence first):
   1. explicit operator override env (`LAB_DEV_OPENAI_ACCOUNT_KEY_OVERRIDE` / `LAB_DEV_OPENAI_ACCOUNT_LABEL_OVERRIDE`)
   2. runtime hook env (`OPENCODE_ATTR_PROVIDER_ID=openai`, `OPENCODE_ATTR_ACCOUNT_KEY`, optional `OPENCODE_ATTR_ACCOUNT_LABEL`)
   3. local OpenCode auth state (`LAB_DEV_OPENAI_AUTH_FILE` fallback `~/.local/share/opencode/auth.json`), extracting stable account key (`accountId` preferred) and human-readable label (profile email preferred)

Constraints and invariants:

1. Read-only resolver: no file writes, no network calls, no shell mutation.
2. Fail closed in helper: if identity data is incomplete/invalid, return non-zero and emit no payload.
3. Fail open in wrapper path: `_dev_auto_attribute` must still return success (`0`) so `opencode` launch never blocks.
4. Event source semantics: wrapper-emitted OpenAI attribution keeps `source=shell_wrapper` for stable `dev_osv` reporting contracts.

Trade-offs:

1. Parsing auth-state JWT payload is local/offline and gives reliable account labels, but claims can change format upstream.
2. Using explicit override first improves operator recovery/debugging for broken local state, but can intentionally mask file-derived identity.
3. Persisting account key + label (for example account id + email) improves auditability while avoiding persistence of tokens/secrets.

Chosen approach record:

1. Implement helper-based resolver in `lib/ops/dev` and call it once per wrapper launch in `_dev_auto_attribute`.
2. Emit at most one OpenAI `account_selected` event per launch when resolver succeeds.
3. Keep strict `dev_osv -x` semantics unchanged except ensuring OpenAI sessions resolve to `CONF=high` when the wrapper event is emitted before first prompt.

### Phase 2 - OpenAI Resolver Helper Implementation

1. Add an internal helper in `lib/ops/dev` (for example `_dev_get_openai_account_identity`) to read the chosen source(s) and validate non-empty account key/label.
2. Keep the helper read-only and side-effect free.
3. Return success only for reliable identity extraction and fail closed at helper level (no payload) when data is incomplete.

Completion criterion:

- A reproducible helper exists in `lib/ops/dev` that yields machine-safe identity payloads for valid sources and no payload for missing/invalid sources.

### Phase 3 - Wrapper Attribution Integration

1. Extend `_dev_auto_attribute` to invoke the OpenAI resolver alongside current Antigravity attribution flow.
2. Emit OpenAI `account_selected` events via `_dev_record_account_event` before `command opencode "$@"` when resolver output is valid.
3. Preserve wrapper safety invariants: no launch blocking, no recursion, and no duplicate event emission for one launch.

Completion criterion:

- Wrapper-launched OpenAI sessions record exactly one pre-session `account_selected` event with real identity and explicit source tagging.

### Phase 4 - `dev_osv` USER Display Usability

1. Adjust `_dev_osv_render` table-mode width policy so `USER` values remain operator-identifiable.
2. Keep TSV mode (`-x`) full-fidelity and unchanged.
3. Preserve placeholder compaction only for synthetic labels (`@example.com`) without affecting real domains.

Completion criterion:

- Table mode output for OpenAI sessions keeps `USER` readable enough to distinguish the active account in normal operator workflows.

### Phase 5 - Tests

Add/extend coverage in `val/lib/ops/dev_test.sh` for:

1. OpenAI resolver success from fixture data.
2. OpenAI resolver missing-source behavior (silent/no emitted event).
3. Wrapper emission of OpenAI `account_selected` with expected provider/key/label/source.
4. `dev_osv` strict mode resolution of OpenAI sessions with `CONF=high` when event timing is pre-first-prompt.
5. Table-mode `USER` visibility regression behavior.

Completion criterion:

- The new OpenAI attribution and display tests are present and pass in `./val/lib/ops/dev_test.sh`.

### Phase 6 - Docs and Operator Guidance

1. Update `doc/man/07-dev-session-attribution-workflow.md` with OpenAI automatic attribution behavior.
2. Update `doc/man/03-cli-usage.md` examples to show real OpenAI account labels in `osv` output.
3. Document override env behavior if an explicit manual-label override is implemented.

Completion criterion:

- Operator-facing docs describe the final OpenAI identity flow into `ops dev osv` with examples aligned to implementation behavior.

## Progress Checkpoint

### Done

1. Completed Phase 1 design contract and recorded resolver/interface/trade-off decisions in this plan.
2. Implemented `_dev_get_openai_auth_state_path` and `_dev_get_openai_account_identity` in `lib/ops/dev` with fail-closed helper semantics.
3. Integrated OpenAI identity emission into `_dev_auto_attribute` with `source=shell_wrapper` and kept wrapper launch fail-open behavior.
4. Improved `_dev_osv_render` table-mode `USER` visibility by widening the column while preserving full TSV output.
5. Added OpenAI-focused tests in `val/lib/ops/dev_test.sh` for resolver success/missing behavior, wrapper emission, strict confidence, and table visibility.
6. Updated operator docs in `doc/man/07-dev-session-attribution-workflow.md` and `doc/man/03-cli-usage.md` including override env behavior.

### Validation status

1. `bash -n lib/ops/dev` passed.
2. `bash -n cfg/ali/sta` passed.
3. `bash -n val/lib/ops/dev_test.sh` passed.
4. `./val/lib/ops/dev_test.sh` passed (`56/56`).
5. `bash doc/pro/check-workflow.sh` passed.

### Current phase

Phase 6 implementation and workflow validation are complete; optional manual live-shell validation remains.

## Safety and Privacy Rules

1. Do not persist secrets/tokens; persist only stable non-secret account identity fields.
2. Prefer labels already visible to operator (email or configured handle).
3. Keep write path append-only through existing `opencode_account_event` table.

## Verification Plan

1. Syntax checks:
   - `bash -n lib/ops/dev`
   - `bash -n cfg/ali/sta`
   - `bash -n val/lib/ops/dev_test.sh`
2. Focused suite:
   - `./val/lib/ops/dev_test.sh`
3. Manual validation:
   - start a fresh OpenAI session via wrapper path,
   - run `ops dev osv -x -l 10` and confirm `USER=<real-openai-account>`, `SRC=shell_wrapper`, `CONF=high`.
4. Workflow check:
   - `bash doc/pro/check-workflow.sh`

## Exit Criteria

1. New OpenAI sessions launched through wrapper have non-placeholder `USER` values.
2. Strict mode (`ops dev osv -x`) resolves OpenAI user at `CONF=high` for properly timed events.
3. Missing OpenAI identity source does not break `opencode` launch.
4. Test suite covers resolver, wrapper integration, and output behavior.
5. Operator docs reflect the shipped OpenAI attribution and visibility behavior.

## Estimated Effort

1. Discovery + contract: 30-60 min
2. Resolver + wrapper integration: 1-2 hours
3. Tests + docs + validation: 1-2 hours

Total: ~3-5 hours depending on where OpenAI active-account state is sourced.

## What changed

1. Implemented OpenAI identity resolution in `lib/ops/dev` so wrapper launches can resolve stable account key/label data from local sources without network calls.
2. Integrated resolver output into `_dev_auto_attribute` so OpenAI sessions emit pre-session `account_selected` events with explicit source semantics.
3. Improved `ops dev osv -t` rendering ergonomics so `USER` remains operator-identifiable while preserving unchanged full-fidelity TSV behavior in strict mode.
4. Added focused regression coverage in `val/lib/ops/dev_test.sh` for resolver behavior, wrapper emission, strict confidence resolution, and table visibility.
5. Updated operator-facing documentation in `doc/man/07-dev-session-attribution-workflow.md` and `doc/man/03-cli-usage.md` to reflect shipped behavior and override guidance.

## What was verified

1. `bash -n lib/ops/dev` passed.
2. `bash -n cfg/ali/sta` passed.
3. `bash -n val/lib/ops/dev_test.sh` passed.
4. `./val/lib/ops/dev_test.sh` passed (`56/56`).
5. `bash doc/pro/check-workflow.sh` passed.

## What remains

1. No required follow-up items remain for repository implementation scope.
2. Optional operator live-shell verification can be run ad hoc to capture additional runtime evidence, but it is not a blocker for closure.
