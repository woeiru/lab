# Integrate Default Active Account Control into `lib/ops/dev`

- Status: queue
- Owner: es
- Started: n/a
- Updated: 2026-03-05 23:03
- Links: doc/pro/task/inbox-capture, doc/pro/task/RULES.md, lib/ops/dev, /home/es/opencode-antigravity-auth/docs/MULTI-ACCOUNT.md, /home/es/opencode-antigravity-auth/src/plugin/ui/auth-menu.ts

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

## Next Step

Move this item to `doc/pro/queue/` and produce an implementation-ready contract (final function name/signature, validation matrix, persistence rules, and exact test cases) before coding in `lib/ops/dev`.
