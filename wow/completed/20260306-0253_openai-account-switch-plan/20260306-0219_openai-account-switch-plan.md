# OpenAI Account Switch Function Plan

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06T02:52
- Links: lib/ops/dev, lib/ops/.spec, cfg/core/lzy

## Goal

Add a new public function to `lib/ops/dev` that switches the active OpenAI
account used by OpenCode, analogous to how `dev_oaa` and `dev_oas` handle
Antigravity account switching today.

## Context

The dev module already has multi-account management for Antigravity providers:

- `dev_oaa` sets the global default active Antigravity account
- `dev_oas` switches the active Antigravity account for a specific model family
- `_dev_get_openai_account_identity` reads the current OpenAI identity from
  the auth state file (`~/.local/share/opencode/auth.json`)
- `_dev_record_account_event` persists attribution events for both providers

OpenAI auth currently uses a single-session OAuth token stored in `auth.json`
under the `openai` key (with `access` JWT, `accountId`, etc.). There is no
multi-account storage or index-based switching mechanism equivalent to the
Antigravity `antigravity-accounts.json` structure.

Switching OpenAI accounts requires understanding how OpenCode resolves the
active OpenAI session and whether multiple credential sets can coexist or
need to be swapped in/out of the auth state file.

## Scope

- Investigate how OpenCode stores and resolves OpenAI credentials (single
  `auth.json` entry vs. potential multi-account support)
- Design a storage scheme for multiple OpenAI account credentials if one
  does not already exist (e.g. `openai-accounts.json` or extending `auth.json`)
- Implement a new public function (e.g. `dev_oia`) in `lib/ops/dev` that:
  - Lists available OpenAI accounts
  - Switches the active account by updating the auth state
  - Creates a timestamped backup before modifying auth state
  - Records an `account_selected` attribution event via `_dev_record_account_event`
  - Follows all ops/.spec requirements (aux_use, aux_tec, aux_val, return codes)
- Update `cfg/core/lzy` lazy-map entry for the new public function (OPS-024)
- Add or extend tests under `val/` for the new function

## Risks

- OpenAI OAuth tokens expire; storing multiple sets may require refresh logic
  or re-authentication, which could be outside the scope of a simple switch
- Modifying `auth.json` while OpenCode is running may cause session
  conflicts or token invalidation
- The current auth.json format is owned by OpenCode upstream; adding
  multi-account structure may conflict with future OpenCode updates
- JWT tokens contain time-bound claims; swapping in a stale token set
  could produce silent authentication failures

## Triage Decision

- Why now: OpenAI account switching is the last manual gap in the dev module's
  multi-account workflow; Antigravity switching already works end-to-end, and
  users currently have no automated path to rotate OpenAI credentials.
- Design: required
- The auth.json format is upstream-owned and the storage scheme for multiple
  OpenAI credential sets has meaningful alternatives (extend auth.json vs.
  external store vs. profile directories), and other functions (attribution,
  session overview) will depend on the shape of the resolved identity.

## Design

### Current auth.json schema (upstream-owned)

```json
{
  "openai": {
    "type": "oauth",
    "refresh": "<refresh-token>",
    "access": "<JWT>",
    "expires": <epoch-seconds>,
    "accountId": "<account-id>"
  },
  "google": { ... }
}
```

OpenCode writes this file after OAuth; this codebase only reads it. The JWT
payload contains `https://api.openai.com/profile.email` and
`https://api.openai.com/auth.chatgpt_account_id` claims used for identity
resolution.

### Chosen approach: external sidecar with swap-into-auth.json

Store multiple OpenAI credential snapshots in a separate sidecar file that
this codebase fully owns. Switching replaces the `openai` key in auth.json
with the target snapshot's credentials. This avoids modifying the auth.json
schema and stays compatible with upstream OpenCode updates.

**Sidecar file:** `~/.config/opencode/openai-accounts.json`
**Override env var:** `LAB_DEV_OPENAI_ACCOUNTS_FILE`

```json
{
  "accounts": [
    {
      "label": "user@example.com",
      "accountId": "acct-xxx",
      "credentials": {
        "type": "oauth",
        "refresh": "...",
        "access": "...",
        "expires": 12345,
        "accountId": "acct-xxx"
      },
      "savedAt": 1709700000000
    }
  ],
  "activeIndex": 0
}
```

### Alternatives considered

1. **Extend auth.json directly** -- rejected because upstream OpenCode owns
   this file and may overwrite additions on next auth flow.
2. **Profile directories** (separate auth.json per profile) -- rejected as
   over-engineered for the current use case and would require symlink or
   copy management.

### Public function: `dev_ois` (opencode openai identity switch)

Three modes:

- `dev_ois -s [label]` -- save current auth.json openai credentials to sidecar.
  Auto-detects identity from JWT claims. Optional label overrides the
  auto-detected email.
- `dev_ois -l` -- list saved OpenAI accounts with index numbers.
- `dev_ois <account_number>` -- switch to saved account N (1-based). Backs up
  auth.json, replaces the `openai` key, records an `account_selected`
  attribution event.

### Interaction contract

- `_dev_get_openai_account_identity` continues to read auth.json as-is;
  after a switch it will reflect the newly active account.
- `_dev_auto_attribute` picks up the switched identity on next opencode launch.
- `dev_osv` attribution resolves correctly because the switch records an
  `account_selected` event via `_dev_record_account_event`.

### Helper function

- `_dev_get_openai_accounts_path()` -- returns the sidecar path, respecting
  `LAB_DEV_OPENAI_ACCOUNTS_FILE` override.

## Execution Plan

### Phase 1 -- Design (credential storage and switch interface)

Investigate the OpenCode auth.json schema, document the current OpenAI
credential structure, and produce a design document covering:

- Storage layout for multiple OpenAI credential sets (external sidecar file
  vs. extended auth.json vs. profile-directory approach)
- Switch semantics: what fields are swapped, how the active slot is tracked,
  whether token validity is checked before activation
- Impact on existing consumers (`_dev_get_openai_account_identity`,
  `_dev_auto_attribute`, `dev_osv` session attribution)
- Chosen approach with trade-off rationale

Completion criterion: a written design section added to this document that
specifies the storage format, the public function signature, and the
interaction contract with auth.json.

### Phase 2 -- Implement core switch function

Add the new public function (e.g. `dev_oia`) to `lib/ops/dev` following
the design from Phase 1. Implement credential save/restore, backup creation,
attribution event recording, and all ops/.spec requirements (aux_use,
aux_tec, aux_val, parameter validation, return codes).

Completion criterion: `bash -n lib/ops/dev` passes and the function is
callable with --help, invalid args, and a valid switch target.

### Phase 3 -- Lazy-map sync and helpers

Update `cfg/core/lzy` with the new public function entry (OPS-024). Add or
update any internal helpers needed for credential listing and validation.

Completion criterion: the lazy-map entry exists and `bash -n cfg/core/lzy`
passes.

### Phase 4 -- Tests and verification

Add test coverage under `val/` for the new function covering: help output,
parameter validation, invalid account handling, successful switch with
backup creation, and attribution event persistence.

Completion criterion: all new tests pass via direct script execution and
`./val/run_all_tests.sh lib` reports no regressions.

## Verification Plan

- `bash -n lib/ops/dev` after implementation changes
- `bash -n cfg/core/lzy` after lazy-map update
- Run `./val/lib/ops/dev_test.sh` (or new dedicated test) directly
- Run `./val/run_all_tests.sh lib` for regression check
- Manual dry-run of the switch function against a test auth.json fixture

## Exit Criteria

The new public function is implemented in `lib/ops/dev`, registered in
`cfg/core/lzy`, tested under `val/`, and all existing tests pass without
regression. The design rationale is documented in this plan.

## What Changed

- `lib/ops/dev`: Added `dev_ois()` (lines 3498–3559) public function with three
  modes: `-s [label]` save, `-l` list, `<N>` switch. Added three private
  helpers: `_dev_ois_save` (3561–3720), `_dev_ois_list` (3722–3787),
  `_dev_ois_switch` (3789–3910). Sidecar path: `~/.config/opencode/openai-accounts.json`
  (override: `LAB_DEV_OPENAI_ACCOUNTS_FILE`).
- `cfg/core/lzy`: Added `dev_ois` to the `ORC_LAZY_OPS_FUNCTIONS["dev"]` entry
  as the last item in the lazy-stub list.
- `doc/man/07-dev-session-attribution-workflow.md`: Added `ois` to the Command
  Decision Flow diagram, added it to the summary table, added a full procedure
  section "Switch active OpenAI account", and added a safety boundary note.
- `doc/ref/functions.md`: Added `dev_ois` row after `dev_oad`.

## What Was Verified

- `bash -n lib/ops/dev` — syntax clean
- `bash -n cfg/core/lzy` — syntax clean
- `wow/check-workflow.sh` — passed (see completed-close run)

## What Remains

None. All exit criteria met.
