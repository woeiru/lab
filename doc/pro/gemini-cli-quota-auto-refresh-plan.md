# Gemini CLI Quota Auto-Refresh Implementation Plan

## Objective

Make quota visibility fully automatic so `dev_olb` shows fresh data for both quota pools without requiring manual `opencode auth login -> Check quotas`.

Target behavior:

- Antigravity quota auto-refreshes (already present)
- Gemini CLI quota auto-refreshes on the same cadence
- Both quota caches are persisted to `~/.config/opencode/antigravity-accounts.json`
- `dev_olb` renders both from cache with clear freshness indicators

---

## Current State (Gap Analysis)

### What already works

- Manual `Check quotas` fetches both Antigravity and Gemini CLI quota data.
- `dev_olb` can render Gemini CLI quotas if cache exists.
- Antigravity background refresh runs after successful requests (`quota_refresh_interval_minutes`).

### Remaining gap

- Background refresh path persists Antigravity cache but does not consistently persist Gemini CLI cache.
- Result: dashboard can show `Gemini CLI Quota (no Gemini CLI quota cached)` until manual check is run.

---

## Scope

### In scope

1. Plugin automatic quota refresh persistence for Gemini CLI.
2. Storage schema support for Gemini CLI cached quota payload.
3. Dashboard freshness/observability improvements for CLI cache age and errors.
4. Tests for background refresh + persistence + reload behavior.
5. Documentation updates.

### Out of scope

- Redesigning account selection strategy.
- Changes to Google API behavior or quotas.
- Real-time (per-second) live quota polling.

---

## Design Principles

1. Keep one source of truth: `antigravity-accounts.json`.
2. Prefer fail-open for stale cache (do not block requests).
3. Keep refresh opportunistic (after successful traffic) to limit API overhead.
4. Maintain backward compatibility with older account files.

---

## Implementation Plan

## Phase 1: Data Model Hardening

### 1.1 Extend account storage metadata

File: external plugin repo `src/plugin/storage.ts`

Add/confirm field in `AccountMetadataV3`:

- `cachedGeminiCliQuota?: { models: { modelId: string; remainingFraction: number; resetTime?: string }[]; error?: string }`

Requirements:

- Optional field for backward compatibility.
- Preserve when loading and saving existing storage versions.
- **Time Format:** Standardize on ISO 8601 strings (or Unix epoch milliseconds) for `resetTime` and the cache update timestamp to ensure safe parsing by `jq` in Bash later.

### 1.2 Extend in-memory account model

File: external plugin repo `src/plugin/accounts.ts`

Add/confirm `ManagedAccount` field:

- `cachedGeminiCliQuota?: GeminiCliQuotaSummary`

Load/save mapping requirements:

- Load from stored account into `ManagedAccount`.
- Save only when payload is useful (`models.length > 0` or `error` present).
- Keep no-op behavior for accounts without CLI quota.

---

## Phase 2: Automatic Refresh Path Completion

### 2.1 Patch background refresh function

File: external plugin repo `src/plugin.ts`

Function: `triggerAsyncQuotaRefreshForAccount(...)`

Current behavior:

- Calls `checkAccountsQuota([singleAccount], ...)`
- Persists Antigravity cache via `accountManager.updateQuotaCache(...)`

Required behavior:

- Also persist Gemini CLI quota in the same refresh cycle.

Implementation options:

1. Preferred: add a dedicated account-manager API, e.g.:
   - `updateGeminiCliQuotaCache(accountIndex, geminiCliQuota)`
2. Acceptable: extend `updateQuotaCache(...)` to accept optional second payload.

Additional requirement:

- Persist to disk via existing `requestSaveToDisk()` path.

### 2.2 Patch manual quota-check path consistency

File: external plugin repo `src/plugin.ts` (auth menu handler)

Ensure both manual and automatic paths persist the same fields:

- `cachedQuota`
- `cachedQuotaUpdatedAt`
- `cachedGeminiCliQuota`

Goal:

- No divergence between manual and automatic cache behavior.

---

## Phase 3: Dashboard Enhancements

File: `lib/ops/dev` (this repo)

### 3.1 Keep dual-section rendering

- Antigravity Quota
- Gemini CLI Quota

### 3.2 Add CLI cache-age visibility

Add explicit CLI cache metadata display using either:

- shared `cachedQuotaUpdatedAt` (if plugin stores one timestamp for both), or
- dedicated `cachedGeminiCliQuotaUpdatedAt` (if added later).

Display rules:

- Green: <5m
- Yellow: 5m-30m
- Red: >30m

### 3.3 Improve empty-state messages

Differentiate:

- No cache yet
- Cache stale
- API returned CLI quota error

### 3.4 Bash Implementation Standards (lib/ops/dev)

- **Naming Conventions:** Follow ops module prefixing. Public functions like `dev_render_cli_quota`, internal helpers like `_dev_calculate_cache_age`.
- **JSON Parsing Safety:** Validate `~/.config/opencode/antigravity-accounts.json` exists and is readable before invoking `jq`.
- **Error Handling & Return Codes:** Fail gracefully (fail-open) if cache is unreadable. Return `0` for empty state rendering, and `2` if a core dependency like `jq` is missing.
- **Logging vs. UI:** Use `printf` with standard ANSI codes for the UI rendering (Green/Yellow/Red). For structural errors or missing dependencies, use standard structured logging (e.g., `aux_warn`, `aux_err` from `lib/gen/aux`).

---

## Phase 4: Testing

## 4.1 Plugin unit tests (external plugin repo)

Add tests for:

1. Background refresh persists Gemini CLI quota.
2. Saved storage includes `cachedGeminiCliQuota` after auto refresh.
3. Reload from disk restores `cachedGeminiCliQuota` into managed accounts.
4. Empty/no-bucket CLI responses persist structured `error` state.
5. Backward compatibility with old account files (missing new field).

Suggested files:

- `src/plugin/accounts.test.ts`
- `src/plugin/*.test.ts` near refresh logic

## 4.2 Repo-level validation (this repo)

1. Check syntax: `bash -n lib/ops/dev`
2. Run specific module tests (if available): `./val/lib/ops/dev_test.sh`
3. Run ops category suite: `./val/lib/run_all_tests.sh --ops`
4. Run full suite to ensure no broader regressions: `./val/run_all_tests.sh`

## 4.3 Manual integration test matrix

Run each scenario and verify `dev_olb` output:

1. Fresh login, no manual check, trigger normal successful request -> CLI quota appears automatically.
2. `quota_refresh_interval_minutes=0` -> CLI auto-refresh disabled by design.
3. Stale cache with no requests -> dashboard shows stale/old indicator.
4. API failure path -> dashboard shows stored CLI error text.

---

## Phase 5: Rollout Plan

1. Implement in plugin source branch.
2. Build and run plugin tests.
3. Publish plugin version (`beta` first recommended).
4. Update local OpenCode config plugin version.
5. Validate on one account, then multi-account setup.
6. Promote to stable once behavior is confirmed.

---

## Operational Notes

### Config knobs to review

- `quota_refresh_interval_minutes` (default 15)
- `soft_quota_cache_ttl_minutes` (default `auto`)
- `debug` / `debug_tui` for diagnosis

### Recommended defaults

- Keep `quota_refresh_interval_minutes=15` for balanced API load and freshness.
- Use manual `Check quotas` only for immediate spot-checking.

---

## Risks and Mitigations

1. Extra API load from more frequent quota refresh
   - Mitigation: retain interval gate and per-account in-progress guard.
2. Stale or inconsistent cache between fields
   - Mitigation: write both caches in one transaction/save path.
3. Plugin auto-update overwriting local hotfixes
   - Mitigation: publish/versioned plugin release rather than local cache patching.

---

## Acceptance Criteria

Feature is complete when all are true:

1. No manual quota check required to eventually populate Gemini CLI cache.
2. `dev_olb` shows Gemini CLI quota bars after normal usage + refresh interval.
3. Cache survives restart/reload.
4. Backward compatibility preserved for older account JSON.
5. Existing Antigravity behavior unchanged.

---

## Deliverables Checklist

- [ ] Plugin source code changes merged (storage + accounts + plugin refresh path)
- [ ] Tests added/updated and passing
- [ ] Plugin version published and referenced in OpenCode config
- [ ] Dashboard docs/help text updated if needed
- [ ] Manual validation evidence captured (sample output/screens)
