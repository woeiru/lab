# 07 - Dev Session Attribution Workflow

This guide is for operators using the `dev` module session attribution flow.
It explains why `USER` can show `(unknown)`, how to emit attribution events safely,
and how to validate strict vs best-effort reporting.

## 1. Prerequisites and Safety

Load runtime in the current shell:

```bash
lab
```

Verify required commands:

```bash
ops --list
opencode --help
```

Safety boundaries:
- `ops dev osv ...` is read-only reporting.
- `ops dev oae ...` and `ops dev otr ...` write local attribution events in the local OpenCode DB.
- `ops dev orr ...` writes an attribution event and then executes `opencode run`.
- `ops dev orr ... --dry-run -- ...` is the safest way to validate event wiring without running a real `opencode run` request.

## 2. Procedure

### Step 1: Capture strict baseline

```bash
ops dev osv -x -l 10
```

Expected baseline for older sessions is often:
- `USER=(unknown)`
- `SRC=none`
- `CONF=none`

This is expected when no pre-first-prompt attribution event exists.

### Step 2: Emit request-time event safely

```bash
ops dev orr openai user@example.com --dry-run -- "healthcheck"
```

This writes an `account_selected` event without running a live `opencode run` request.

### Step 3: Validate overview again

```bash
ops dev osv -x -l 10
ops dev osv -x -l 10 --best-effort
```

Interpretation:
- strict (`ops dev osv -x`) only displays event-backed `CONF=high` identities.
- best-effort (`--best-effort`) can show `CONF=low` when only post-first-prompt matching events exist.

### Step 4: Run attributed requests for future sessions

```bash
ops dev orr openai user@example.com -- "summarize current git diff"
```

For provider refresh transitions:

```bash
ops dev otr openai user@example.com user@example.com connector_event
```

### Optional: Emit events from runtime hook environment

```bash
export OPENCODE_ATTR_PROVIDER_ID="openai"
export OPENCODE_ATTR_ACCOUNT_KEY="user@example.com"
export OPENCODE_ATTR_ACCOUNT_LABEL="user@example.com"
export OPENCODE_ATTR_EVENT_TYPE="account_selected"
export OPENCODE_ATTR_SOURCE="opencode_runtime"
ops dev oae -x
```

## 3. Expected Outcomes and Validation

Use this confidence model:
- `CONF=high`: matching provider event exists at or before session first prompt time.
- `CONF=low`: only post-first-prompt event match exists (best-effort mode only).
- `CONF=none`: no qualifying event for that provider/session.

Quick DB validation:

```bash
sqlite3 "$HOME/.local/share/opencode/opencode.db" "SELECT datetime(time_ms/1000,'unixepoch','localtime') AS event_time, provider_id, account_key, event_type, source FROM opencode_account_event ORDER BY time_ms DESC LIMIT 20;"
```

## 4. Troubleshooting and Recovery

### `USER` still `(unknown)` in strict mode

Likely causes:
- no event exists before first prompt for that session
- event provider does not match session provider family
- event was emitted after the session already started

Safe recovery:
1. confirm session provider in `ops dev osv -x --best-effort`
2. emit event with matching provider using `ops dev orr ... --dry-run -- ...` or `ops dev oae ...`
3. validate new sessions moving forward (historical rows may remain unknown)

### Event emit command succeeds but no rows appear

Likely causes:
- runtime environment is not initialized (`lab` not loaded)
- `opencode` is not available in `PATH` for current shell
- local DB path is unavailable to the current user session

Safe recovery:

```bash
lab
opencode debug paths
ops dev oae openai user@example.com account_selected opencode_runtime user@example.com
```

Then rerun the sqlite query in section 3.

## 5. Related Docs

- Previous: [03 - CLI Usage and the DIC](03-cli-usage.md)
- Next: [04 - Deployments and Runbooks](04-deployments.md)
- Architecture context: [doc/arc/04-dependency-injection.md](../arc/04-dependency-injection.md)
- Logging and errors: [doc/arc/07-logging-and-error-handling.md](../arc/07-logging-and-error-handling.md)
