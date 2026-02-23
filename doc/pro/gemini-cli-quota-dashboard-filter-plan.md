# Gemini CLI Quota Dashboard Filter Refinement

## Goal
Update the Gemini CLI Quota rendering in the `dev_olb` dashboard script (located in `/home/es/lab/lib/ops/dev`) to only display the "most actual" (currently relevant) Gemini CLI models. 

## Rationale
Currently, the `opencode-antigravity-auth` plugin caches all Gemini 3.0, 3.1, and 2.5 Pro models. While the plugin will continue to cache this data to ensure the underlying storage has a complete picture, the dashboard UI should be streamlined to only show the models the user actively cares about, reducing visual clutter.

## Requirements
- Target script: `/home/es/lab/lib/ops/dev` (specifically the embedded Python block handling `dev_olb`).
- The dashboard must filter the `cachedGeminiCliQuota.models` array.
- The filter must *only* permit models that are considered "most actual":
  - `gemini-3.1-pro-preview`
  - `gemini-3.1-pro-preview_vertex`
  - `gemini-3-pro-preview`
  - `gemini-3-pro-preview_vertex`
  - `gemini-3-flash-preview`
  - `gemini-3-flash-preview_vertex`
- Older models (like `gemini-2.5-pro`) should be filtered out from the final UI table, even if present in `antigravity-accounts.json`.

## Implementation Steps

1. **Locate the Render Block**
   - Open `/home/es/lab/lib/ops/dev` and find the Python block around line 465 where `cli_models` is initialized.

2. **Add a UI-Level Filter**
   - Introduce an `ALLOWED_CLI_MODELS` list or set containing the strings for the most actual models.
   - Example allowed list: `{"gemini-3.1-pro-preview", "gemini-3.1-pro-preview_vertex", "gemini-3-pro-preview", "gemini-3-pro-preview_vertex", "gemini-3-flash-preview", "gemini-3-flash-preview_vertex"}`
   - Alternatively, use a prefix match (`startswith(("gemini-3.1-", "gemini-3-"))`) if we want to automatically catch future `3.x` model string additions, but strictly exclude `2.5`.

3. **Apply the Filter**
   - Modify the loop that iterates over `cli_models` (around line 480).
   - Before printing the row, check if `model_id` passes the filter condition. If not, `continue`.

4. **Verify Empty State Handling**
   - Ensure that if the filter removes *all* cached models, the UI gracefully displays a message indicating no relevant models were found (or falls back to the existing empty state message).

5. **Test the Changes**
   - Run `opencode load balance` (or `. go init && lab && dev_olb`) to view the dashboard.
   - Verify that `gemini-2.5-pro` is hidden, and only the 3.0 and 3.1 models appear in the Gemini CLI Quota section.
