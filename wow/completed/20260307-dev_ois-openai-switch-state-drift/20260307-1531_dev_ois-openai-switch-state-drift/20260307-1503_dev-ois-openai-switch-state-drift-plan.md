# Dev OIS OpenAI Switch State Drift Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 15:31
- Links: lib/ops/dev, val/lib/ops/dev_test.sh, doc/man/07-dev-session-attribution-workflow.md

## Retroactive Capture

- Origin: The fix started as troubleshooting why `dev_ois` showed one active OpenAI account while new OpenCode instances used the other account.
- Escalation reason: Debugging exposed a deeper data-integrity bug where `dev_ois` could overwrite the wrong sidecar snapshot when `activeIndex` drifted from real `auth.json` state.
- Design classification:
  - Q1: Are there meaningful alternatives for how to solve this? Yes.
  - Q2: Will other code or users depend on the shape of the output? Yes.
  - Outcome: design required (recorded in `## Triage Decision`).
- Work so far: Root cause was reproduced, switch logic was hardened in `lib/ops/dev`, a regression test was added in `val/lib/ops/dev_test.sh`, and the full `./val/lib/ops/dev_test.sh` suite passed.

## Triage Decision

- Why now: The bug causes cross-account credential drift and makes account switching unreliable for new OpenCode sessions.
- Q1: Are there meaningful alternatives for how to solve this? Yes.
- Q2: Will other code or users depend on the shape of the output? Yes.
- Design: required
- Justification: Source-slot resolution strategy and sidecar reconciliation rules define data integrity behavior across all users who rely on `dev_ois` multi-account switching.

## Progress Checkpoint

### Done

1. Confirmed mismatch pattern between `openai-accounts.json` metadata and stored credentials during account switching.
2. Updated `_dev_ois_switch` to resolve the source snapshot by account identity matching instead of blindly trusting stale `activeIndex`.
3. Synced switched target account metadata from credential account id when present to reduce sidecar drift.
4. Added regression coverage: `test_dev_ois_switch_preserves_snapshot_with_stale_active_index`.
5. Ran verification: `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and `./val/lib/ops/dev_test.sh` (all passing).
6. Repaired live sidecar drift by restoring mismatched credentials from auth backups and writing a safety backup at `~/.config/opencode/openai-accounts.json.repair-backup.20260307_150703`.
7. Validated live switch flow with patched code (`dev_ois 2` then `dev_ois 1`): both sidecar entries remained aligned (`accountId == credentials.accountId`) and active `auth.json` ended on `b2b284d8-f750-4d1d-b832-30fdc45aa64c`.

### In-flight

1. Workflow closeout packaging remains: move this item to completed with links to remediation evidence.

### Blockers

1. None.

### Next steps

1. Capture command evidence in closeout notes for code validation, sidecar repair, and live switch verification.
2. Move this plan into `wow/completed/<timestamp>_dev-ois-openai-switch-state-drift/` with an updated completion timestamp.
3. Run `bash wow/check-workflow.sh` and address any completion-folder chronology or metadata issues.

### Context

1. Branch: `master`.
2. Modified files: `lib/ops/dev`, `val/lib/ops/dev_test.sh`.
3. Regression fixed path: stale `activeIndex` no longer clobbers non-target account credentials during switch.
4. Live sidecar repair backup: `~/.config/opencode/openai-accounts.json.repair-backup.20260307_150703`.
5. Live auth backups from remediation run: `~/.local/share/opencode/auth.json.backup.20260307_150738`, `~/.local/share/opencode/auth.json.backup.20260307_152607`, `~/.local/share/opencode/auth.json.backup.20260307_152608`.

## Execution Plan

1. Phase 1 - Finalize recovery design for already-corrupted sidecar state. [COMPLETE 2026-03-07 15:03]
   Completion criterion: A deterministic repair/validation procedure is documented for live account sidecars with drift.
2. Phase 2 - Apply and verify live sidecar remediation. [COMPLETE 2026-03-07 15:26]
   Completion criterion: Every saved OpenAI account entry has aligned `accountId` and `credentials.accountId`, and `dev_ois` switches produce expected `auth.json` identity.
3. Phase 3 - Close workflow item with evidence. [COMPLETE 2026-03-07 15:31]
   Completion criterion: Validation outputs are captured and the item is moved to `wow/completed/...` with links to changed code/tests.

## Exit Criteria

1. `_dev_ois_switch` no longer overwrites unrelated account snapshots when `activeIndex` is stale.
2. Regression coverage exists and passes in `val/lib/ops/dev_test.sh`.
3. Live sidecar drift remediation steps are executed and verified.
4. Workflow checker passes with the item tracked in `wow/completed/`.

## What changed

- Moved this workflow plan from `wow/active/` to `wow/completed/20260307-1531_dev-ois-openai-switch-state-drift/` and set status to completed.
- Preserved the original file timestamp prefix (`20260307-1503_`) while closing into a completion folder timestamped at `20260307-1531`.
- Captured completion metadata by finalizing Phase 3 and updating closeout criteria to completed-folder tracking.

## What was verified

- `bash -n lib/ops/dev` passed.
- `bash -n val/lib/ops/dev_test.sh` passed.
- `./val/lib/ops/dev_test.sh` passed.
- Live switch verification passed: `dev_ois 2` then `dev_ois 1` kept sidecar entries aligned (`accountId == credentials.accountId`) and ended `auth.json` on `b2b284d8-f750-4d1d-b832-30fdc45aa64c`.

## What remains

- No mandatory follow-up items remain.
- Default routing policy applies: if new follow-up work appears, create a new item in `wow/inbox/`.
