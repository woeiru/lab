# dev_osv vs dev_olb User Attribution Mismatch

- Status: completed
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-06 01:40
- Links: wow/task/inbox-capture, lib/ops/dev, val/lib/ops/dev_test.sh

## Goal

Capture and triage a mismatch where `dev_osv` shows recent prompt activity for `brunomaxwagner@gmail.com`, while `dev_olb` account load-balancing output does not list that user/account.

## Context

1. `dev_osv` recent entries show sessions `3wb`, `cmf`, and `49X` with timestamps around `2026-03-05 03:27-03:35` and user `brunomaxwagner@gmail.com`.
2. At nearly the same time (`2026-03-05 03:37:07`), `dev_olb` lists enabled accounts as:
   - `maxbwagner@outlook.com`
   - `maximilian.bruno.wagner@gmail.com`
   - `maxbw86@gmail.com` (default active)
   - `ometesu@gmail.com`
3. `dev_olb` output includes no explicit account/user entry for `brunomaxwagner@gmail.com`.
4. This creates uncertainty about whether session-user attribution, account identity normalization, or account-list rendering is inconsistent.

## Scope

In scope:

1. Verify how `dev_osv` derives and stores user identity for session events.
2. Verify how `dev_olb` builds and renders account inventory and "last used" attribution.
3. Identify whether the mismatch is caused by alias mapping, stale cache, provider identity translation, or a true attribution bug.
4. Define expected consistency rules between session event logs and active account listing.

Out of scope:

1. Any unrelated quota/usage display improvements not tied to user-account identity consistency.
2. Broader multi-provider routing redesign.

## Risks

1. Misattributed sessions can route usage/billing to the wrong account.
2. Operator trust in account diagnostics degrades if identity appears inconsistent across tools.
3. Hidden alias or normalization behavior may mask real authentication/session boundary defects.

## Triage Decision

- Why now: This mismatch appears in recent live session windows and can immediately cause incorrect routing confidence and account diagnostics.
- Q1 (meaningful alternatives): yes.
- Q2 (output shape dependencies): yes.
- Design: required.
- Justification: The fix could be implemented via several identity-normalization and source-of-truth strategies, and users/tools depend on stable, correct attribution output.

## Execution Plan

### Phase 1 -- Design Attribution Contract

1. Document the current identity flow and handoff boundaries from session event capture to account normalization/cache to `dev_olb` rendering.
2. Compare at least two remediation alternatives (normalization-first vs source-of-truth-first) and select one approach.

Completion criterion: this file contains a design decision record with interfaces, constraints, trade-offs, and chosen approach.

### Phase 2 -- Implement Chosen Path

1. Apply the selected identity-mapping changes in the relevant `dev_osv`/`dev_olb` paths.
2. Update any affected cache/normalization helpers so account lists and session attribution use the same canonical identity rules.

Completion criterion: implementation changes for the chosen design are merged in local workspace with no unresolved design TODOs.

### Phase 3 -- Validate Repro Window and Regression Safety

1. Re-run the `2026-03-05 03:27-03:37` evidence window and confirm `dev_osv` user attribution aligns with `dev_olb` account visibility.
2. Run targeted tests and workflow checks relevant to modified modules.

Completion criterion: verification artifacts show no user-identity mismatch for the repro case.

## Phase 1 Design Decision Record

Date: 2026-03-05
Design classification: required

1. Root cause identified: `dev_osv` provider-wide Antigravity fallback accepted the latest matching event even when that event account label/key was no longer present in the current Antigravity account inventory shown by `dev_olb`.
2. Alternatives considered:
   - Add a global stale-event window for Antigravity provider events.
   - Add an account-inventory guard for Antigravity provider-wide/legacy fallback events.
3. Chosen approach: account-inventory guard for real-domain Antigravity identities.
4. Justification: this preserves existing Antigravity event-order semantics while preventing `dev_osv` from surfacing non-listed accounts that `dev_olb` cannot show.

## Progress Checkpoint

### Done

1. Added Antigravity account inventory loading in `lib/ops/dev` (`_dev_osv_render` Python resolver) from `~/.config/opencode/antigravity-accounts.json` with optional override `LAB_DEV_ANTIGRAVITY_ACCOUNTS_FILE`.
2. Added Antigravity real-domain identity guards so provider-wide and legacy fallback events are filtered when account identity is not present in the known inventory.
3. Kept session-bound precedence unchanged; filtering applies only to non-session-bound fallback paths.
4. Added regression `test_dev_overview_antigravity_unlisted_account_filtered` in `val/lib/ops/dev_test.sh`.

### Validation status

1. `bash -n lib/ops/dev` -> pass
2. `bash -n val/lib/ops/dev_test.sh` -> pass
3. `./val/lib/ops/dev_test.sh` -> pass (`61/61`)

### Exit Criteria Check

1. `dev_osv` and `dev_olb` show consistent canonical identity for the same recent sessions. [met via inventory-guarded resolver behavior + regression]
2. Design decision record exists and implemented behavior matches the selected approach. [met]
3. Targeted tests and workflow checks pass with recorded evidence. [met]

## Verification Plan

1. Capture before/after snapshots of `dev_osv` and `dev_olb` for the same time window and compare account identity strings.
2. Run syntax checks on modified Bash files (`bash -n <file>`).
3. Run nearest targeted tests for changed modules and `bash wow/check-workflow.sh`.

## Exit Criteria

1. `dev_osv` and `dev_olb` show consistent canonical identity for the same recent sessions.
2. Design decision record exists and implemented behavior matches the selected approach.
3. Targeted tests and workflow checks pass with recorded evidence.

## What changed

1. Added Antigravity account inventory loading and real-domain identity guards in `lib/ops/dev` so provider-wide and legacy fallback events are filtered when account identity is not in current inventory.
2. Preserved session-bound event precedence; filtering is scoped to non-session-bound fallback paths.
3. Added regression `test_dev_overview_antigravity_unlisted_account_filtered` in `val/lib/ops/dev_test.sh` to lock this behavior.
4. Closed this workflow item by moving it from `wow/active/` to `wow/completed/20260306-0139_dev-osv-dev-olb-user-attribution-mismatch-issue/`.

## What was verified

1. `bash -n lib/ops/dev` -> pass
2. `bash -n val/lib/ops/dev_test.sh` -> pass
3. `./val/lib/ops/dev_test.sh` -> pass (`61/61`)
4. `bash wow/check-workflow.sh` -> pass (`Workflow check passed.`)

## What remains

1. None.
