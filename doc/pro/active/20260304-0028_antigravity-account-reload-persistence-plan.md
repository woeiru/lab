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
  - Added canonical reconcile contract and implemented `_dev_reconcile_antigravity_accounts` as the single prune/remap path.
  - Added explicit reconcile command `dev_oac -x` with deterministic before/after output (`status`, `before/after`, `removed`, `fallback`, `backup`).
  - Rewired reconcile invocation across wrapper/dashboard/account-management paths (`_dev_auto_attribute`, `dev_oqu`, `dev_olb`, `dev_oas`, `dev_oar`, `dev_oad`).
  - Added regression coverage for repeated external repopulation cycles via `test_dev_oac_reconciles_repopulation_cycles`.
  - Validation run complete: `bash -n lib/ops/dev`, `bash -n val/lib/ops/dev_test.sh`, and `./val/lib/ops/dev_test.sh` (51/51 pass).
  - Manual live verification run completed (3 cycles) with `dev_oac -x` + `dev_olb -x` on real local config.
  - Live config reconciled at least once by pruning denylisted emails from `/home/es/.config/opencode/antigravity-accounts.json`.
- In-flight:
  - Working tree now contains current reconcile implementation changes in `lib/ops/dev` and `val/lib/ops/dev_test.sh`.
  - Runtime durability with externally triggered sync timing still needs observation in normal workflow windows.
- Blockers:
  - External Antigravity account sync writes are outside this repo and can rewrite `antigravity-accounts.json` at arbitrary times.
  - No always-on in-repo enforcement hook currently guarantees immediate post-sync pruning when no dev wrapper commands are executed.
- Next steps:
  1. Observe at least one naturally occurring external sync event, then run `dev_oac -x` and capture before/after evidence in this plan.
  2. Optionally add a lightweight scheduled/user-hook invocation path if immediate post-sync prune is required without manual commands.
- Context:
  - Branch: `master`.
  - Repo changes pending: `lib/ops/dev`, `val/lib/ops/dev_test.sh`, this active plan.
  - External state touched during debugging: `/home/es/.config/opencode/antigravity-accounts.json` and backup files.
  - Latest test status: 51/51 pass in `./val/lib/ops/dev_test.sh`.
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

### Phase 1 - Design Reconcile Contract

Define the canonical reconcile behavior (inputs, pruning rules, index remap invariants, log/output contract, and failure semantics) as the single source for all call sites.

Completion criterion: A written reconcile contract is added to this active doc and every touched function/test references the same invariants.

Status: completed.

### Phase 2 - Implement Unified Reconcile Path

Refactor enforcement call sites to use one shared reconcile routine and remove any remaining duplicate/partial denylist behavior.

Completion criterion: All account-management paths call the same reconcile routine and no stale disable-only path remains.

Status: completed.

### Phase 3 - Hardening and Regression Expansion

Add repeated-repopulation tests and verify routing/index stability across multiple cycles.

Completion criterion: New cycle/regression tests pass locally with no flaky failures.

Status: completed for in-repo regression coverage; live external-sync timing validation remains in Next steps.

## Exit Criteria

- Denylisted accounts do not remain in `antigravity-accounts.json` after any supported dev account-management operation.
- Repeated external repopulation + reconcile cycles keep routing indices valid and deterministic.
- Account-management commands produce consistent user-facing output and backups without index oscillation (`6` swapping behavior eliminated).
- `./val/lib/ops/dev_test.sh` passes with the new regression coverage included.
