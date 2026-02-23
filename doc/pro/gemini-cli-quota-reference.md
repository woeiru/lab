# Gemini CLI Quota: Unified Reference

## Goal

Provide one source of truth for Gemini CLI quota behavior across:

- plugin quota fetching and cache persistence,
- `dev_olb` dashboard rendering,
- model filtering policy,
- troubleshooting and hotfix procedures.

## Scope

This document replaces the previous split docs:

- `doc/pro/gemini-cli-quota-auto-refresh-plan.md`
- `doc/pro/gemini-cli-quota-dashboard-filter-plan.md`

## Current Architecture

### Data flow

1. Plugin fetches quota data from Antigravity endpoints.
2. Plugin writes account cache to `~/.config/opencode/antigravity-accounts.json`.
3. `dev_olb` reads cached fields and renders:
   - Antigravity Quota
   - Gemini CLI Quota

### Key cache fields

- `cachedQuota`
- `cachedQuotaUpdatedAt`
- `cachedGeminiCliQuota`

Expected Gemini CLI payload shape:

```json
{
  "cachedGeminiCliQuota": {
    "models": [
      { "modelId": "gemini-3.1-pro-preview", "remainingFraction": 1, "resetTime": "..." }
    ],
    "error": "optional"
  }
}
```

## Dashboard Rendering Policy (`dev_olb`)

### Allowed models in UI

The dashboard should only show the current Gemini CLI models:

- `gemini-3.1-pro-preview`
- `gemini-3.1-pro-preview_vertex`
- `gemini-3-pro-preview`
- `gemini-3-pro-preview_vertex`
- `gemini-3-flash-preview`
- `gemini-3-flash-preview_vertex`

### Empty-state behavior

If filtering removes all cached rows, keep existing graceful fallbacks:

- `(no Gemini CLI quota returned in last check)` when cache exists but no relevant rows.
- `(no Gemini CLI quota cached yet)` when no cache exists.

## Auto-Refresh Requirements

Gemini CLI quota must be refreshed and persisted on the same cadence/path as Antigravity quota.

Required behavior:

1. Background refresh updates both `cachedQuota` and `cachedGeminiCliQuota`.
2. Manual check and background refresh persist the same fields.
3. Reload from disk restores Gemini CLI cache without manual intervention.

## Recent Investigation and Findings (Latest)

### Observed issue

- `dev_olb` did not show any `gemini-3.1-*` rows even when 3.1 models were selectable in OpenCode.

### Root cause identified

In the loaded plugin build (`opencode-antigravity-auth@1.6.0` dist), Gemini CLI aggregation used:

```ts
modelId.startsWith("gemini-3-") || modelId === "gemini-2.5-pro"
```

This excludes `gemini-3.1-*` because `gemini-3.1-` does not match `gemini-3-`.

### Runtime hotfix applied (local)

Patched loaded dist to include 3.1:

```ts
modelId.startsWith("gemini-3-") ||
modelId.startsWith("gemini-3.1-") ||
modelId === "gemini-2.5-pro"
```

Patched file:

- `~/.cache/opencode/node_modules/opencode-antigravity-auth/dist/src/plugin/quota.js`

Also tested alternate Gemini CLI quota user-agent (`gemini-3.1-pro-preview`) in same file.

### Outcome after patch + refresh

- Local cache still returned only:
  - `gemini-2.5-pro`
  - `gemini-3-flash-preview`
  - `gemini-3-flash-preview_vertex`
  - `gemini-3-pro-preview`
  - `gemini-3-pro-preview_vertex`
- No `gemini-3.1-*` buckets were present in the persisted `cachedGeminiCliQuota.models`.

Interpretation:

- Filtering bug was real and is fixed locally.
- Current upstream quota response for the tested accounts/project still does not provide 3.1 buckets.

## Validation Checklist

### Repo-level checks

1. `bash -n lib/ops/dev`
2. `./val/lib/ops/dev_test.sh`

### Integration checks

1. Trigger real provider traffic (e.g. `opencode run -m google/antigravity-gemini-3.1-pro "..."`).
2. Inspect `~/.config/opencode/antigravity-accounts.json` for `cachedGeminiCliQuota.models`.
3. Run `dev_olb -x` and verify displayed model rows and empty states.

## Runbook: If 3.1 Still Missing

1. Confirm loaded plugin version and dist code path currently in use.
2. Verify aggregation filter includes `gemini-3.1-`.
3. Force a quota refresh by making real model requests.
4. Inspect raw cached model IDs in `cachedGeminiCliQuota.models`.
5. If 3.1 is still absent, treat as upstream/API payload gap (not dashboard rendering bug).

## Operational Notes

- Local dist patches are hotfixes and can be overwritten by plugin update/reinstall.
- Durable fix must live in plugin source and be released as a new plugin version.
- Dashboard should remain fail-open and keep clear empty/error states.
