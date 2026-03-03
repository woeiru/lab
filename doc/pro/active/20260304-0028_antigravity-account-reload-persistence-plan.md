# Antigravity Account Reload Persistence

- Status: active
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04
- Links: lib/ops/dev, val/lib/ops/dev_test.sh, /home/es/.config/opencode/antigravity-accounts.json, /home/es/.config/opencode/antigravity-account-denylist.txt

## Retroactive Capture

- Origin: This started as a quick fix to remove one blocked Antigravity account from the active pool (`dev_oar 6`).
- Escalation reason: The provider sync process reloaded removed accounts, so a one-time remove was not durable and account index `6` kept mapping to newly reintroduced blocked entries.
- Design: required.
  1. Are there meaningful alternatives for how to solve this? Yes (disable-only, prune-on-read/write, background watcher, or denylist-only reconciliation).
  2. Will other code or users depend on the shape of the output? Yes (account count/order, family routing indices, and `dev_oar` semantics are user-visible and script-visible).
- Work so far:
  - Added persistent denylist append on successful `dev_oar` removal.
  - Expanded denylist application call sites to quota/load-balance/switch paths.
  - Reworked denylist enforcement from disable-only to prune (remove denylisted accounts), with safe active index/family index remap.
  - Added and updated regression tests for denylist persistence and post-sync behavior.
  - Applied live-state cleanup to remove denylisted accounts from the local accounts file and created timestamped backups.

## Progress Checkpoint

- Done:
  - Implemented canonical reconcile path in `lib/ops/dev` (`_dev_reconcile_antigravity_accounts`) and exposed manual trigger `dev_oac -x`.
  - Unified reconcile call sites across wrapper/dashboard/account-management paths (`_dev_auto_attribute`, `dev_oqu`, `dev_olb`, `dev_oas`, `dev_oar`, `dev_oad`).
  - Added regression coverage in `val/lib/ops/dev_test.sh` (`test_dev_oac_requires_execute_flag`, `test_dev_oac_reconciles_repopulation_cycles`) and registered both in main suite.
  - Ran validation successfully: `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, `./val/lib/ops/dev_test.sh` (`51/51` pass).
  - Performed live manual verification (`dev_oac -x` + `dev_olb -x`) across 3 cycles with stable post-reconcile state and no denylisted accounts remaining.
  - Committed the implementation on `master` as `6a36f493` (`feat(dev): unify antigravity reconcile path and add dev_oac`).
  - Verified upstream context: issue `NoeFabris/opencode-antigravity-auth#336` is closed and release `v1.5.0` notes include the account-deletion persistence fix.
- In-flight:
  - No in-repo code changes are in flight; working tree is clean after commit.
  - External-sync timing observation is still pending (need at least one naturally occurring provider repopulation event captured with before/after evidence).
- Blockers:
  - External Antigravity account sync writes are outside this repo and can rewrite `antigravity-accounts.json` at arbitrary times.
  - No always-on in-repo enforcement hook currently guarantees immediate post-sync pruning when no dev wrapper commands are executed.
- Next steps:
  1. Capture one naturally occurring external sync/repopulation event by recording pre-reconcile state from `/home/es/.config/opencode/antigravity-accounts.json`.
  2. Run `dev_oac -x` immediately after that event and append exact before/after counters, removed emails, and backup path in this plan.
  3. Run `dev_olb -x` and record routing/account marker evidence to confirm stable indices after the same event.
  4. Decide automation path for immediate post-sync pruning (options: user cron wrapper or shell hook invocation).
  5. Implement the selected automation path in `lib/ops/dev` and add/adjust tests in `val/lib/ops/dev_test.sh` if automation is chosen.
- Context:
  - Branch: `master`.
  - Last commit: `6a36f493`.
  - Repo changes pending: this active plan only.
  - External state touched during debugging: `/home/es/.config/opencode/antigravity-accounts.json` and backup files.
  - Latest test status: 51/51 pass in `./val/lib/ops/dev_test.sh`.
  - Local OpenCode plugin baseline in this environment: `@opencode-ai/plugin` `1.2.16` in `/home/es/.config/opencode/package.json`.
  - Manual verification evidence (2026-03-04):
    - Cycle 1: `before_count=7` -> `status=UPDATED` -> `after_count=5`, removed `mbwagner123@gmail.com,agent.mbw@gmail.com`, fallback `maxbwagner@outlook.com`, denylisted present after reconcile: `0`.
    - Cycle 2: `before_count=5` -> `status=NO_CHANGE` -> `after_count=5`, denylisted present: `0`.
    - Cycle 3: `before_count=5` -> `status=NO_CHANGE` -> `after_count=5`, denylisted present: `0`.
    - `dev_olb -x` executed each cycle; final marker check: `status=0`, routing/account markers present.

## Reconcile Contract

- Inputs: `${HOME}/.config/opencode/antigravity-accounts.json` plus denylist `${LAB_DEV_ANTIGRAVITY_DENYLIST_FILE:-${HOME}/.config/opencode/antigravity-account-denylist.txt}`.
- Prune rule: remove any account whose normalized email matches a normalized non-comment denylist line.
- Safety invariant: if pruning would leave no enabled account, skip mutation and log `NO_ENABLED_FALLBACK`.
- Index invariant: preserve account order for survivors; remap `activeIndex` and every integer entry in `activeIndexByFamily`; reroute invalidated indices to first enabled survivor.
- Mutation invariant: create timestamped backup before write when and only when a mutation occurs.
- Output contract (`dev_oac -x`): deterministic lines with `status`, `before/after/removed`, and optional `removed_emails`, `fallback_email`, `rerouted_targets`, `backup`.
- Failure semantics: automatic call sites never hard-fail workflows on reconcile errors (warn + continue); explicit `dev_oac -x` reports state deterministically for manual intervention.

## Execution Plan

### Phase 4 - External Sync Evidence Capture

Capture one naturally occurring provider sync/repopulation cycle and verify reconcile behavior on real local state.

Completion criterion: this doc includes pre-sync and post-reconcile evidence (`dev_oac -x` + `dev_olb -x`) from at least one external sync event.

### Phase 5 - Post-Sync Enforcement Strategy

Choose and optionally implement a lightweight automation path so reconcile can run immediately after sync without manual intervention.

Completion criterion: decision is documented; if implementation is selected, code/tests are updated and validated.

## Exit Criteria

- Denylisted accounts do not remain in `antigravity-accounts.json` after any supported dev account-management operation.
- Repeated external repopulation + reconcile cycles keep routing indices valid and deterministic.
- Account-management commands produce consistent user-facing output and backups without index oscillation (`6` swapping behavior eliminated).
- `./val/lib/ops/dev_test.sh` passes with the new regression coverage included.
