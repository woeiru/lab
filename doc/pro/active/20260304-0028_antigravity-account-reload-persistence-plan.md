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
  - `lib/ops/dev` updated with denylist append helper, broader denylist enforcement hooks, and prune/remap logic.
  - `val/lib/ops/dev_test.sh` expanded to 49 passing tests, including denylist-before-render and denylisted-switch rejection coverage.
  - Syntax checks passed for edited files (`bash -n`).
  - Live config reconciled at least once by pruning denylisted emails from `/home/es/.config/opencode/antigravity-accounts.json`.
- In-flight:
  - Working tree has uncommitted changes in `lib/ops/dev` and `val/lib/ops/dev_test.sh`.
  - Runtime durability between external sync cycles still needs final verification under normal user workflow timing.
- Blockers:
  - External Antigravity account sync writes are outside this repo and can rewrite `antigravity-accounts.json` at arbitrary times.
  - No always-on in-repo enforcement hook currently guarantees immediate post-sync pruning when no dev wrapper commands are executed.
- Next steps:
  1. Add a lightweight, explicit reconcile command (manual trigger) that prunes denylisted accounts and prints deterministic before/after summary.
  2. Wire reconcile invocation into every account-management entry point (`dev_oar`, `dev_oad`, `dev_oas`, dashboards, wrapper path) with consistent logging.
  3. Add a regression test that simulates repeated external repopulation cycles and validates stable account count/routing after each reconcile.
  4. Run `./val/lib/ops/dev_test.sh` and targeted workflow validation, then capture verification evidence in this doc.
- Context:
  - Branch: `master`.
  - Repo changes pending: `lib/ops/dev`, `val/lib/ops/dev_test.sh`.
  - External state touched during debugging: `/home/es/.config/opencode/antigravity-accounts.json` and backup files.
  - Latest test status: 49/49 pass in `./val/lib/ops/dev_test.sh`.

## Execution Plan

### Phase 1 - Design Reconcile Contract

Define the canonical reconcile behavior (inputs, pruning rules, index remap invariants, log/output contract, and failure semantics) as the single source for all call sites.

Completion criterion: A written reconcile contract is added to this active doc and every touched function/test references the same invariants.

### Phase 2 - Implement Unified Reconcile Path

Refactor enforcement call sites to use one shared reconcile routine and remove any remaining duplicate/partial denylist behavior.

Completion criterion: All account-management paths call the same reconcile routine and no stale disable-only path remains.

### Phase 3 - Hardening and Regression Expansion

Add repeated-repopulation tests and verify routing/index stability across multiple cycles.

Completion criterion: New cycle/regression tests pass locally with no flaky failures.

## Exit Criteria

- Denylisted accounts do not remain in `antigravity-accounts.json` after any supported dev account-management operation.
- Repeated external repopulation + reconcile cycles keep routing indices valid and deterministic.
- Account-management commands produce consistent user-facing output and backups without index oscillation (`6` swapping behavior eliminated).
- `./val/lib/ops/dev_test.sh` passes with the new regression coverage included.
