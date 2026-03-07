# Integrate Default Active Account Control into `lib/ops/dev`

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06 01:35
- Links: wow/task/inbox-capture, wow/task/RULES.md, lib/ops/dev, /home/es/opencode-antigravity-auth/docs/MULTI-ACCOUNT.md, /home/es/opencode-antigravity-auth/src/plugin/ui/auth-menu.ts

## Goal

Add a first-class `lib/ops/dev` workflow to set the Antigravity default active account (`activeIndex`) in `antigravity-accounts.json`, not only per-family routing.

## Context

1. Current `lib/ops/dev` account switch tooling (`dev_oas`) updates `activeIndexByFamily`, but there is no direct operation for the global default active account.
2. The upstream `opencode-antigravity-auth` plugin does not expose a dedicated "set default active account" action in its auth/account menu flow.
3. The account store already tracks both `activeIndex` and `activeIndexByFamily`; operational workflows in this repo need an explicit and safe way to control `activeIndex`.
4. Existing `lib/ops/dev` account management functions already implement backup, validation, reroute, denylist, and event logging patterns that should be reused for consistency.

## Scope

In scope:

1. Define and add one new `lib/ops/dev` public operation to set global default active account by 1-based account number.
2. Apply current safety conventions: argument validation, enabled-account checks, backup creation, deterministic output, and structured `aux_*` logging.
3. Persist the default index update in `~/.config/opencode/antigravity-accounts.json` while preserving valid existing family mappings.
4. Emit attribution/audit event(s) consistent with existing account switch semantics.
5. Add/update tests in `val/lib/ops/dev_test.sh` for success, invalid index, disabled-target, and state preservation behavior.
6. Update docs/reference artifacts affected by new public function surface (`doc/ref/*`, and lazy-map update in `cfg/core/lzy` if required by loader contract).

Out of scope:

1. Changes to upstream plugin repository behavior or menu UX.
2. New account-selection strategies or runtime scheduling logic.
3. Refactoring unrelated `dev_o*` functions.

## Risks

1. Incorrect index handling can desynchronize `activeIndex` and family-specific routing.
2. Selecting disabled or denylisted accounts could break expected failover behavior.
3. Missing lazy-map/doc/test updates can cause function discoverability or regression gaps.
4. Ambiguous CLI naming may overlap existing `dev_oad` / `dev_oas` workflows.

## Triage Decision

- Why now: This gap blocks reliable operator control of account routing defaults and forces unsafe manual JSON edits for a common workflow.
- Design: required
- Justification: There are multiple viable interface and persistence choices, and the resulting command behavior/signature will be depended on by operators and adjacent tooling.

## Execution Plan

### Phase 1 -- Define Design Contract [done]

1. Document candidate public function names/signatures and select one final contract for setting global `activeIndex` by 1-based account number.
2. Specify validation matrix, persistence rules, backup/event expectations, and interaction boundaries with `activeIndexByFamily`.

Completion criterion: this file contains a concrete design decision record with interfaces, constraints, trade-offs, and chosen approach.

## Phase 1 Design Decision Record

Date: 2026-03-06
Design classification: required

1. Candidate interfaces considered:
   - Extend `dev_oas` with a reserved family token to mean global default (`activeIndex`).
   - Add a new dedicated command `dev_oaa <account_number>` for global default active account changes.
   - Reuse or rename `dev_oad` semantics to include default selection.
2. Trade-offs:
   - Extending `dev_oas` overloads family-routing behavior and creates hidden coupling between family and global-default semantics.
   - Reusing `dev_oad` is not viable because `dev_oad` already means disable-account and is user-facing.
   - A dedicated command keeps contracts explicit, avoids collisions with existing commands, and aligns with the `dev_oa*` account-management cluster.
3. Chosen approach: add new public function `dev_oaa <account_number>` (`opencode account activate-default`).
4. Final contract:
   - Input: one 1-based `account_number` target.
   - Validation: numeric positive integer, in-range, and target account must be enabled.
   - Return codes: `0` success, `1` usage/domain validation failure, `2` runtime/python failure, `127` missing `python3`.
   - Side effects: reconcile denylist first; create timestamped backup; set `activeIndex` to target index; emit account attribution event with `provider_id=antigravity`, `event_type=account_selected`, `source=manual_switch`.
   - Output: deterministic success lines with selected account identity and backup path.
5. Persistence invariants:
   - `data["accounts"]` ordering/content remains unchanged.
   - `data["activeIndex"]` is set to `account_number - 1` when validation passes.
   - Existing valid `data["activeIndexByFamily"]` entries are preserved and not rewritten for reroute by this command.
6. Required wiring updates:
   - Add `dev_oaa` to `cfg/core/lzy` (`ORC_LAZY_OPS_FUNCTIONS["dev"]`).
   - Add `dev_oaa` to function-existence coverage and main test run list in `val/lib/ops/dev_test.sh`.
   - Regenerate/update affected reference docs under `doc/ref/` after implementation (`./utl/doc/run_all_doc.sh`).
7. Exact test plan for implementation phase:
   - `test_dev_oaa_requires_params`: no args returns `1`.
   - `test_dev_oaa_rejects_bad_account`: non-numeric/invalid account input returns `1`.
   - `test_dev_oaa_sets_default_active_account`: success path sets `activeIndex` to selected 0-based index and reports selected email.
   - `test_dev_oaa_rejects_out_of_range`: out-of-range index returns `1` with no state mutation.
   - `test_dev_oaa_rejects_disabled_account`: disabled target returns `1` with unchanged `activeIndex`.
   - `test_dev_oaa_preserves_family_mappings`: `activeIndexByFamily` values remain unchanged after successful default switch.
   - `test_dev_oaa_creates_backup`: backup file is created before write.
   - `test_dev_oaa_records_account_event`: OpenCode DB receives `account_selected` event for selected account.

## Progress Checkpoint

### Done

1. Completed Phase 1 design decision with final `dev_oaa` contract and persistence invariants.
2. Implemented `dev_oaa` in `lib/ops/dev` with validation, backup, reconcile, deterministic output, and account-event emission.
3. Updated lazy-loading exposure in `cfg/core/lzy` for the new public function.
4. Added `dev_oaa` regression coverage and runner wiring in `val/lib/ops/dev_test.sh` (behavior + event tests).
5. Regenerated impacted reference artifacts under `doc/ref/`.

### In Progress

1. No remaining implementation work in this active item.

### Phase 2 -- Implement in `lib/ops/dev` [done]

1. Add the selected public operation and supporting helpers in `lib/ops/dev` using existing safety/logging/account-validation patterns.
2. Update loader/public-surface artifacts required for discoverability (including `cfg/core/lzy` if applicable).

Completion criterion: implementation for the selected contract is present with no unresolved design TODOs.

### Phase 3 -- Verify and Align Tests/Docs [done]

1. Add or update targeted cases in `val/lib/ops/dev_test.sh` for success, invalid index, disabled target, and state preservation.
2. Update impacted reference documentation under `doc/ref/` and run workflow validation checks.

Completion criterion: targeted verification artifacts show the new operation behavior is correct and documented.

### Validation status

1. `bash -n lib/ops/dev` -> pass
2. `bash -n cfg/core/lzy` -> pass
3. `bash -n val/lib/ops/dev_test.sh` -> pass
4. `./val/lib/ops/dev_test.sh` -> pass (`76/76`)
5. `./utl/doc/run_all_doc.sh` -> pass

## Verification Plan

1. Run syntax checks for modified Bash files (`bash -n <file>`).
2. Run targeted tests for the affected dev operations (`./val/lib/ops/dev_test.sh`).
3. Run `bash wow/check-workflow.sh` before handoff.

## Exit Criteria

1. A documented design decision record exists for the final function contract and persistence behavior. [met]
2. The new default-active-account operation updates `activeIndex` safely while preserving valid family mappings. [met]
3. Targeted tests and workflow checks pass with recorded evidence. [met]

## Next Step

No further action required; implementation and verification are complete.
