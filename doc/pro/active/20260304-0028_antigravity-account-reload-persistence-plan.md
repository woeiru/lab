# Antigravity Account Reload Persistence

- Status: active
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04 01:16
- Links: lib/ops/dev, cfg/core/lzy, val/lib/ops/dev_test.sh, val/core/initialization/orc_test.sh, /home/es/.config/opencode/antigravity-accounts.json, /home/es/.config/opencode/antigravity-account-denylist.txt

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
  - Corrected local version audit: installed auth plugin is `opencode-antigravity-auth` `1.6.0` (cache/runtime), while `opencode --version`/`@opencode-ai/plugin` reports the core OpenCode package line (`1.2.16`).
  - Resumed checkpoint verification: `git status` clean on `master`, reconcile/test symbols still present in `lib/ops/dev` and `val/lib/ops/dev_test.sh`, and `./val/lib/ops/dev_test.sh` re-ran green (`51/51`).
  - Captured a naturally occurring external repopulation pre-reconcile state from `/home/es/.config/opencode/antigravity-accounts.json` (denylisted entries reappeared as disabled accounts).
  - Captured live shell evidence for the same cycle: `dev_oac -x` returned `command not found` before `dev` module lazy-load, while `dev_olb -x` triggered lazy module sourcing and rendered a stable 5-account dashboard with expected routing markers.
  - Verified post-`dev_olb -x` local file state: `/home/es/.config/opencode/antigravity-accounts.json` now has `accounts_total=5` and `denylisted_present=0`.
  - Implemented lazy-load map fix so `dev_oac` is registered as a `dev` lazy stub (`cfg/core/lzy`) and added a regression test (`test_source_lib_ops_dev_reconcile_stub_is_lazy_loadable`) in `val/core/initialization/orc_test.sh`.
  - Validated lazy-load fix: `bash -n cfg/core/lzy`, `bash -n val/core/initialization/orc_test.sh`, and `./val/core/initialization/orc_test.sh` (`7/7` pass).
- In-flight:
  - In-repo changes are pending for lazy-load registration/test updates (`cfg/core/lzy`, `val/core/initialization/orc_test.sh`, this plan file).
  - External-sync evidence is partially complete for this cycle (pre-sync capture + post-`dev_olb` reconcile evidence captured; explicit `dev_oac -x` output contract still missing due initial lazy-stub gap now fixed).
- Blockers:
  - External Antigravity account sync writes are outside this repo and can rewrite `antigravity-accounts.json` at arbitrary times.
  - No always-on in-repo enforcement hook currently guarantees immediate post-sync pruning when no dev wrapper commands are executed.
  - Capturing explicit `dev_oac -x` evidence for a naturally repopulated state now depends on the next external repopulation event timing.
- Next steps:
  1. Reload shell bootstrap (`lab`) and verify `dev_oac -x` now resolves via lazy stub; record deterministic output lines for current local state.
  2. On the next naturally occurring repopulation event, capture paired evidence in sequence (`dev_oac -x` then `dev_olb -x`) and append before/after counters + routing markers.
  3. Decide automation path for immediate post-sync pruning (options: user cron wrapper or shell hook invocation).
  4. Implement the selected automation path in `lib/ops/dev` and add/adjust tests in `val/lib/ops/dev_test.sh` if automation is chosen.
- Context:
  - Branch: `master`.
  - Last commit: `6a36f493`.
  - Repo changes pending: this active plan only.
  - External state touched during debugging: `/home/es/.config/opencode/antigravity-accounts.json` and backup files.
  - Latest test status: `./val/lib/ops/dev_test.sh` `51/51` pass; `./val/core/initialization/orc_test.sh` `7/7` pass.
  - Runtime plugin version confirmed: `opencode-antigravity-auth` `1.6.0` in `/home/es/.cache/opencode/node_modules/opencode-antigravity-auth/package.json`.
  - Versioning nuance: `opencode --version` and `@opencode-ai/plugin` (`1.2.16`) describe OpenCode core package versions, not the external antigravity auth plugin release stream.
  - Manual verification evidence (2026-03-04):
    - Cycle 1: `before_count=7` -> `status=UPDATED` -> `after_count=5`, removed `mbwagner123@gmail.com,agent.mbw@gmail.com`, fallback `maxbwagner@outlook.com`, denylisted present after reconcile: `0`.
    - Cycle 2: `before_count=5` -> `status=NO_CHANGE` -> `after_count=5`, denylisted present: `0`.
    - Cycle 3: `before_count=5` -> `status=NO_CHANGE` -> `after_count=5`, denylisted present: `0`.
    - `dev_olb -x` executed each cycle; final marker check: `status=0`, routing/account markers present.
  - External repopulation capture (2026-03-04 01:09 local):
    - `accounts_total=7`, `denylist_entries=2`, `denylisted_present=2`, `denylisted_enabled=0`.
    - Reappeared denylisted emails in file: `mbwagner123@gmail.com` (index `5`, disabled) and `agent.mbw@gmail.com` (index `6`, disabled).
    - Current markers before reconcile: `activeIndex=1`, `activeIndexByFamily={"claude":1,"gemini":4}`.
  - Live command evidence from user shell (2026-03-04 01:13 local):
    - `dev_oac -x` failed before module load: `bash: dev_oac: command not found` and command-not-found warning logged.
    - `dev_olb -x` lazy-loaded `dev`/`aux` modules, rendered 5 enabled accounts, and reported routing markers `default=account 2`, `claude=account 2`, `gemini=account 5`.
    - Post-`dev_olb -x` file check: `accounts_total=5`, `denylisted_present=0`, `activeIndex=1`, `activeIndexByFamily={"claude":1,"gemini":4}`.

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
