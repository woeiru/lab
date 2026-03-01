# OpenCode Account Attribution Implementation Plan

- Status: active
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-01 (reopened for Phase 8 - automatic attribution wiring)
- Links: lib/ops/dev, val/lib/ops/dev_test.sh, cfg/ali/sta, doc/man/07-dev-session-attribution-workflow.md

## Current Status (Exact)

- Overall state: reopened. Phases 0-7 completed. Phase 8 (automatic attribution wiring) is new required work.
- Code state: phases 0-7 committed and clean. Phase 8 is design-only, no code changes yet.
- Test state: `./val/lib/ops/dev_test.sh` passing (`31/31`).
- Problem observed: all sessions spawned via normal `opencode` invocation show `USER=(unknown)` because no attribution event is emitted automatically. Only sessions launched via explicit `ops dev orr` get attributed -- and nobody uses that path in practice.
- Root cause: the implementation built the storage, reporting, and manual emit primitives but never wired automatic emission into the actual opencode launch path.

### Phase Position

- Phase 0-6: done (storage, reporting, manual emitters, tests).
- Phase 7: done (backfill policy decided -- historical sessions stay unknown).
- Phase 8: new -- automatic attribution wiring. Design complete, execution pending.

## What Remains

Phase 8: automatic attribution wiring via shell function wrapper and internal helper.

## Why This Was Reopened

The Phase 0-7 implementation delivered working primitives (`dev_oae`, `dev_orr`,
`dev_otr`, `dev_osv`) but left a critical gap: **no automatic path exists**.
The operator must explicitly use `ops dev orr` instead of `opencode` for every
session, or manually run `ops dev oae` before launching opencode. In practice
nobody does either, so every session shows `USER=(unknown)`.

The original plan deferred this as "optional upstream hook replacement" but
the investigation found that:

1. OpenCode's plugin SDK exposes 16+ hooks (including `chat.message` and
   `event`) but modifying the external `opencode-antigravity-auth` plugin is
   out of repo scope.
2. A shell function wrapper in `cfg/ali/sta` can solve this entirely within
   this repo, with zero external dependencies, using infrastructure that
   already exists.

The wrapper approach was never explored -- the plan went straight to "we need
upstream support" and stopped. This phase corrects that.

## Phase 8 - Automatic Attribution Wiring

### 8.0 - Approach: Shell Function Wrapper

The approach uses two components:

1. **A shell function `opencode()`** in `cfg/ali/sta` that overrides the PATH
   binary. Shell functions take precedence over PATH lookups and aliases, so
   when `lab` is loaded, every `opencode` invocation (including `oc` alias
   expansion) routes through the wrapper. When `lab` is not loaded, the raw
   binary is used directly -- no interference.

2. **An internal helper `_dev_auto_attribute`** in `lib/ops/dev` that reads
   the active account configuration and emits `account_selected` events for
   all active provider families before the session starts.

### 8.1 - Shell Function Wrapper (`cfg/ali/sta`)

Add under the existing `# Development` section (after the `osv` and `olb`
aliases):

```bash
# Automatic session attribution wrapper
# Emits account_selected events before launching opencode so sessions
# are attributed with CONF=high in dev_osv strict mode
opencode() {
    if declare -f _dev_auto_attribute >/dev/null 2>&1; then
        _dev_auto_attribute
    fi
    command opencode "$@"
}
```

Design constraints:
- `command opencode` bypasses the function and calls the real binary via PATH.
- `declare -f` guard means: if `lib/ops/dev` is not loaded (lab not active),
  skip attribution silently and just run the binary.
- The wrapper adds no flags, no arguments, no env vars -- pure passthrough
  after the event emission.
- The `oc` alias in `~/.bashrc` (`alias oc='opencode'`) expands to `opencode`,
  which then resolves to this function. No alias change needed.

### 8.2 - Internal Helper (`lib/ops/dev`)

Add `_dev_auto_attribute` as an internal helper function in `lib/ops/dev`,
near the other `_dev_` helpers (after `_dev_record_account_event`):

```bash
_dev_auto_attribute() {
    local accounts_path
    accounts_path=$(_dev_get_antigravity_accounts_path) || return 0

    if ! aux_chk "command" "python3" 2>/dev/null; then
        return 0
    fi

    local py_output
    py_output=$(python3 - "$accounts_path" <<'PY'
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    accounts = data.get("accounts", [])
    active_by_family = data.get("activeIndexByFamily", {})
    for family, idx in active_by_family.items():
        if 0 <= idx < len(accounts):
            email = accounts[idx].get("email", "")
            if email:
                print(f"{family}|{email}")
except Exception:
    pass
PY
    ) || return 0

    [ -z "$py_output" ] && return 0

    local line family email provider_id
    while IFS='|' read -r family email; do
        [ -z "$family" ] || [ -z "$email" ] && continue
        provider_id=$(_dev_provider_from_family "$family")
        _dev_record_account_event "$provider_id" "$email" "$email" \
            "account_selected" "shell_wrapper" 2>/dev/null
    done <<< "$py_output"
}
```

Design constraints:
- Every failure path returns 0 silently -- the wrapper must never block or
  break the opencode launch.
- Uses `_dev_get_antigravity_accounts_path` (existing helper, line 70-79) to
  resolve the accounts file.
- Uses `_dev_provider_from_family` (existing helper, line 789-800) to map
  family names to normalized provider IDs.
- Uses `_dev_record_account_event` (existing helper, line 833-924) to persist
  the event.
- Source tag is `shell_wrapper` -- distinguishes automatic events from manual
  `dev_oae` (`opencode_runtime`) and `dev_oas` (`manual_switch`) events in
  the audit trail.
- Emits events for ALL active families (both `claude` and `gemini` entries
  from `activeIndexByFamily`). The session attribution resolver already
  matches by provider family, so extra events for unused families are
  harmless -- they simply get ignored for sessions that use a different
  provider.

### 8.3 - Event Semantics

| Field | Value | Rationale |
|---|---|---|
| `provider_id` | normalized via `_dev_provider_from_family` | matches existing resolver expectations |
| `account_key` | email from `antigravity-accounts.json` | same key format as `dev_oae` and `dev_oas` |
| `account_label` | same as `account_key` | consistent with existing pattern |
| `event_type` | `account_selected` | standard pre-session event type |
| `source` | `shell_wrapper` | new source tag, distinguishes from manual paths |

The `shell_wrapper` source tag must be added to any reporting filters or
documentation that enumerate valid source values.

### 8.4 - Why This Produces CONF=high

The attribution resolver in `dev_osv` grants `CONF=high` when a matching
event exists with `event.time_ms <= first_prompt_ms`. The wrapper emits
events synchronously *before* launching opencode (before `command opencode`).
The first prompt cannot occur until opencode starts and the user types.
Therefore the event timestamp is always before the first prompt timestamp,
guaranteeing `CONF=high` in strict mode.

### 8.5 - Scope and Non-Interference

| Scenario | Behavior |
|---|---|
| `lab` loaded, user runs `opencode` | wrapper emits events, then launches binary |
| `lab` loaded, user runs `oc` | alias expands to `opencode`, wrapper fires |
| `lab` loaded, user runs `opencode run "..."` | wrapper emits events, passes `run "..."` to binary |
| `lab` not loaded, user runs `opencode` | shell function doesn't exist, PATH binary runs directly |
| subagent session spawned by opencode | runs in subprocess inheriting shell, wrapper fires if function exported |
| `ops dev orr` | calls `opencode run` directly (line 1069 in dev), does NOT call the wrapper because `dev_orr` uses the binary name inside a function -- `command opencode` must be verified here |
| `antigravity-accounts.json` missing | `_dev_get_antigravity_accounts_path` returns non-zero, helper exits silently |
| `python3` not available | `aux_chk` fails, helper exits silently |
| all accounts disabled | python script emits nothing, helper exits silently |

**Important: `dev_orr` interaction.** `dev_orr` (line 1069) calls
`opencode run "$@"` -- this is a bare command name inside a function body,
so if the shell function `opencode()` is defined, it will be called
recursively. This must be verified and potentially changed to
`command opencode run "$@"` in `dev_orr` to avoid double event emission.

### 8.6 - Tests

Add to `val/lib/ops/dev_test.sh`:

1. **`test_dev_auto_attribute_emits_for_active_families`**
   - Create a fixture `antigravity-accounts.json` with 2 accounts and
     `activeIndexByFamily: { claude: 0, gemini: 1 }`.
   - Call `_dev_auto_attribute`.
   - Verify 2 events in the DB: one for `antigravity` provider with account 0
     email, one for `antigravity` provider with account 1 email.
   - Verify both have `source=shell_wrapper` and
     `event_type=account_selected`.

2. **`test_dev_auto_attribute_silent_on_missing_accounts_file`**
   - Point `_dev_get_antigravity_accounts_path` at a nonexistent path.
   - Call `_dev_auto_attribute`.
   - Verify return code 0, no events emitted, no stderr output.

3. **`test_dev_auto_attribute_silent_on_empty_active_families`**
   - Create a fixture with `activeIndexByFamily: {}`.
   - Call `_dev_auto_attribute`.
   - Verify return code 0, no events emitted.

4. **`test_opencode_wrapper_calls_auto_attribute`**
   - Source `cfg/ali/sta` in test environment.
   - Mock `command opencode` to no-op.
   - Call `opencode`.
   - Verify `_dev_auto_attribute` was invoked (check events in DB).

5. **`test_dev_orr_no_double_emission`**
   - Verify that `dev_orr` does not trigger the wrapper function (uses
     `command opencode` internally).

### 8.7 - Documentation Updates

1. **`doc/man/07-dev-session-attribution-workflow.md`**
   - Add a section explaining that attribution is automatic when `lab` is
     loaded. The manual `dev_oae`/`dev_orr` paths remain available for
     non-lab environments or explicit overrides.
   - Update the mermaid decision flow to show the automatic path as the
     default.

2. **`doc/man/03-cli-usage.md`**
   - Note that `opencode` invocations with `lab` loaded automatically emit
     attribution events.
   - Document the `shell_wrapper` source tag.

3. **`doc/ref/functions.md`**
   - Regenerate via `./utl/doc/run_all_doc.sh` after adding
     `_dev_auto_attribute`.

### 8.8 - Execution Checklist

1. [ ] Add `_dev_auto_attribute` helper to `lib/ops/dev` (after line ~924).
2. [ ] Add `opencode()` wrapper function to `cfg/ali/sta` (after line 456).
3. [ ] Verify `dev_orr` line 1069 uses `command opencode` to avoid recursion.
4. [ ] Add `shell_wrapper` to `_dev_is_supported_account_event_type` if
       source validation exists (verify current validation scope).
5. [ ] Write tests per 8.6.
6. [ ] Run `bash -n lib/ops/dev` and `bash -n cfg/ali/sta`.
7. [ ] Run `./val/lib/ops/dev_test.sh` -- all tests pass.
8. [ ] Manually validate: `lab && opencode`, then `ops dev osv -x -l 5`
       shows `CONF=high` with `SRC=shell_wrapper` for the new session.
9. [ ] Update `doc/man/07-dev-session-attribution-workflow.md`.
10. [ ] Update `doc/man/03-cli-usage.md`.
11. [ ] Regenerate refs: `./utl/doc/run_all_doc.sh`.
12. [ ] Run `bash doc/pro/check-workflow.sh`.

### 8.9 - Effort Estimate

- Implementation (helper + wrapper + dev_orr fix): ~1 hour
- Tests: ~1 hour
- Doc updates + ref regeneration: ~30 minutes
- Manual validation: ~15 minutes

Total: ~3 hours

### 8.10 - Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Wrapper adds latency to every opencode launch | user-visible delay | Python JSON read + SQLite insert is <100ms; benchmark during validation |
| `dev_orr` recursive call through wrapper | double event emission | Change line 1069 to `command opencode run "$@"` |
| Subagent processes inherit wrapper | extra events per subagent | harmless -- resolver picks latest event before first prompt per session |
| Account switch between wrapper emit and first prompt | wrong account attributed | window is seconds at most; `dev_oas` already emits its own `manual_switch` event which would be picked as latest-before-prompt |
| Future opencode versions change binary name or behavior | wrapper breaks | `command opencode "$@"` passthrough means any new flags/subcommands work transparently |

---

## Original Phases (0-7) -- Completed

All content below is preserved from the completed implementation for
reference and traceability.

### What Changed (Phases 0-7)

- Implemented provider-aware session attribution in `lib/ops/dev` with strict-default `dev_osv` resolution using `opencode_account_event`.
- Added runtime event emitters/wrappers (`dev_oae`, `dev_orr`, `dev_otr`) including `dev_orr --dry-run` for safe wiring checks.
- Expanded attribution coverage in `val/lib/ops/dev_test.sh` to include strict/best-effort behavior, provider safety, event timeline ordering, and wrapper paths.
- Updated operator documentation (`doc/man/03-cli-usage.md`) and added a dedicated workflow manual (`doc/man/07-dev-session-attribution-workflow.md`).
- Regenerated/kept references synchronized and updated this plan through completion.

### What Was Verified (Phases 0-7)

- `./val/lib/ops/dev_test.sh` -> pass (`31/31`).
- `bash doc/pro/check-workflow.sh` -> pass.
- `bash -lc 'export PATH="/home/es/.opencode/bin:$PATH"; source "/home/es/lab/bin/ini" >/dev/null 2>&1; dev_orr openai audit-session@example.com audit-session@example.com --dry-run -- status'` -> pass (event emitted without `opencode run`).
- `bash -lc 'export PATH="/home/es/.opencode/bin:$PATH"; source "/home/es/lab/bin/ini" >/dev/null 2>&1; dev_osv -x -l 8 --best-effort'` -> pass (post-event `SRC=opencode_runtime`, `CONF=low` for matching provider sessions).
- `bash -lc 'export PATH="/home/es/.opencode/bin:$PATH"; source "/home/es/lab/bin/ini" >/dev/null 2>&1; dev_osv -x -l 3'` -> pass (strict default remained `(unknown)`/`CONF=none` when no pre-first-prompt event existed).

### Original Goal

Implement a real, auditable way to attribute each OpenCode session to the actual account in use at first prompt time, with provider-aware support for Antigravity and OpenAI.

### Triage Decision

Move to queue now because account attribution correctness is blocking trustworthy reporting and should be prioritized before more `dev_osv` output changes.

### Definition Of Done (What "Correct" Means)

A session row is "correct" only if all are true:

1. Account identity comes from a captured runtime event, not a fallback guess.
2. The captured event timestamp is less than or equal to session first user prompt timestamp.
3. Provider family is known (`antigravity`, `openai`, or another explicit provider id).
4. Attribution source is preserved (`opencode_event`, `connector_event`, etc.) for auditability.

### Strategy

Use a two-layer approach:

- Layer A (source-of-truth capture): instrument account selection/auth events where OpenCode or its provider connectors decide credentials.
- Layer B (query/reporting): map session first prompt time to the latest known account event for that provider.

No guessed attribution in strict mode.

### Implementation Phases

#### Phase 0 - Baseline and Schema Audit (done)

1. Document current DB schema and relevant JSON keys (`session`, `message`, `control_account`).
2. Confirm whether account identity appears anywhere in message payload over a representative sample.
3. Freeze a baseline `dev_osv -x` snapshot for before/after comparison.

#### Phase 1 - Discover Real Account Decision Point In OpenCode (done)

1. Identify the exact code path where provider credentials are chosen (Antigravity/OpenAI).
2. Verify whether OpenCode has hooks/events for auth/account switching.
3. If no hook exists, add a minimal instrumentation point at credential resolution.

#### Phase 2 - Add Attribution Event Store (done)

Created `opencode_account_event` table in the OpenCode SQLite DB with append-only semantics:

- `time_ms` (INTEGER, required)
- `provider_id` (TEXT, required)
- `account_key` (TEXT, required; email if safe, otherwise stable hash)
- `account_label` (TEXT, optional; human-readable email/mask)
- `event_type` (TEXT, required; `account_selected`, `token_refreshed`, `auth_switched`)
- `source` (TEXT, required; `opencode_runtime`, `connector_event`, `manual_switch`)
- `trace_id` (TEXT, optional)

#### Phase 3 - Emit Events At Runtime (done)

Implemented manual emitters: `dev_oae`, `dev_orr`, `dev_otr`.

#### Phase 4 - Session Attribution Resolver (done)

Resolver logic in `dev_osv` maps `first_prompt_ms` to latest matching event.

#### Phase 5 - Update `dev_osv` Output Contract (done)

Added `USER`, `SRC`, `CONF` columns with strict/best-effort modes.

#### Phase 6 - Tests (done)

31 tests covering strict/best-effort, provider safety, timeline ordering.

#### Phase 7 - Backfill and Rollout (done)

Historical sessions marked unknown by default. No heuristic backfill.

### Commits (Phases 0-7)

`ffc451d9`, `2e12e5a2`, `866ac019`, `a5e1725a`, `a1150082`, `e8f65518`, `6a465da5`.

### Acceptance Criteria

- New sessions are attributable with `CONF=high` when account events exist.
- `dev_osv` never shows fabricated certainty.
- Test suite covers positive, negative, and missing-data paths.
- Attribution metadata is auditable and secret-safe.
- **Phase 8 addition:** sessions launched via normal `opencode` invocation with `lab` loaded are automatically attributed without manual intervention.

### Out Of Scope

- Perfect retroactive attribution for already-recorded sessions without event history.
- Cross-machine reconciliation without shared event transport.
- Modifying the external `opencode-antigravity-auth` plugin (upstream scope).
