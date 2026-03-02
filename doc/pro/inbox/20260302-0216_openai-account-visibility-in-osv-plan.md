# OpenAI Account Visibility in OSV Plan

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-02
- Links: lib/ops/dev, cfg/ali/sta, val/lib/ops/dev_test.sh, doc/man/07-dev-session-attribution-workflow.md, doc/man/03-cli-usage.md

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

## Implementation Approach

### Phase 0 - Source Discovery and Contract

1. Identify stable local source for the active OpenAI account (preferred order):
   - runtime env (if exposed by OpenCode hooks),
   - OpenCode local auth/account state file,
   - explicit operator override env var.
2. Define a strict contract for returned identity fields:
   - `provider_id=openai`
   - `account_key` (stable key)
   - `account_label` (human-readable value for `USER` column)
3. Require fail-open behavior: if source is unavailable, emit no OpenAI event and continue launch.

Done when:

- A single documented, deterministic resolver order exists for OpenAI identity.

### Phase 1 - OpenAI Resolver Helper in `lib/ops/dev`

1. Add internal helper (for example `_dev_get_openai_account_identity`) that:
   - reads the chosen local source(s),
   - validates non-empty account key/label,
   - prints a machine-safe payload for caller parsing.
2. Keep helper side-effect free (read-only, no writes).
3. Return success only on reliable identity extraction.

Done when:

- Helper can resolve active OpenAI account identity in a reproducible way.

### Phase 2 - Wrapper Attribution Integration

1. Extend `_dev_auto_attribute` to invoke the OpenAI resolver in addition to current Antigravity logic.
2. Emit OpenAI `account_selected` event via `_dev_record_account_event` before `command opencode "$@"`.
3. Preserve existing behavior:
   - no launch blocking,
   - no recursion,
   - no duplicate event spam from one launch.
4. Keep source tagging explicit (`shell_wrapper`) for auditability.

Done when:

- A normal wrapper-launched OpenAI session gets a pre-first-prompt event with real identity.

### Phase 3 - `dev_osv` USER Display Usability

1. Adjust table rendering width policy for `USER` in `_dev_osv_render` to reduce aggressive truncation.
2. Keep TSV (`-x`) unchanged and full-fidelity.
3. Preserve placeholder compaction rules only for obvious synthetic labels (`@example.com`), without affecting real domains.

Done when:

- `-t` output makes the OpenAI account recognizable in the `USER` column.

### Phase 4 - Tests

Add/extend tests in `val/lib/ops/dev_test.sh`:

1. OpenAI resolver success path from fixture data.
2. OpenAI resolver missing-source path (silent, no emitted event).
3. Wrapper emits OpenAI `account_selected` event with expected provider/key/label/source.
4. `dev_osv` strict mode resolves OpenAI session to expected `USER` and `CONF=high` when event is pre-first-prompt.
5. Table-mode visibility regression test for `USER` width/clip behavior.

Done when:

- New OpenAI attribution paths are covered for positive and missing-data scenarios.

### Phase 5 - Docs and Operator Guidance

1. Update `doc/man/07-dev-session-attribution-workflow.md` with OpenAI automatic attribution behavior.
2. Update `doc/man/03-cli-usage.md` examples to avoid placeholder labels and show OpenAI-real-label flow.
3. Document optional override env var (if implemented) for controlled/manual labels.

Done when:

- Operator docs explain exactly how OpenAI account identity reaches `osv`.

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

## Acceptance Criteria

1. New OpenAI sessions launched through wrapper have non-placeholder `USER` values.
2. Strict mode (`ops dev osv -x`) resolves OpenAI user at `CONF=high` for properly timed events.
3. Missing OpenAI identity source does not break `opencode` launch.
4. Test suite covers resolver, wrapper integration, and output behavior.

## Estimated Effort

1. Discovery + contract: 30-60 min
2. Resolver + wrapper integration: 1-2 hours
3. Tests + docs + validation: 1-2 hours

Total: ~3-5 hours depending on where OpenAI active-account state is sourced.

## Execution Checklist (When Starting)

1. Move this file from `inbox/` to `queue/`.
2. Implement Phase 0 contract first (no coding before source-of-truth is confirmed).
3. Land Phase 1-2 with tests in same change set.
4. Run syntax/tests/validation commands.
5. Update docs and move plan to `completed/` with validation notes.
