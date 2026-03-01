# OpenCode Terminal Color Palette Integration Plan

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-01
- Links: doc/pro/inbox/README.md, https://api.github.com/repos/anomalyco/opencode/contents/packages/opencode/src/cli/cmd/tui/context/theme?ref=dev, https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/opencode/src/cli/cmd/tui/context/theme/opencode.json

## Goal

Build a terminal-only theming pipeline that imports OpenCode palettes and exposes stable semantic colors (`primary`, `text`, `background`, `success`, etc.) for local Bash UI output.

## Why This Approach

- OpenCode theme files are already structured with `defs` and semantic `theme` mappings.
- Reusing semantic roles avoids hardcoded hex colors in scripts.
- A small local pipeline makes updates repeatable when upstream themes change.

## Scope

In scope:

1. Fetch and store OpenCode theme JSON files locally.
2. Resolve semantic roles to hex values for selected mode (`dark` first).
3. Provide reusable terminal color helpers (truecolor with fallback).
4. Add a preview command and simple validation checks.

Out of scope:

- Web/CSS theming.
- Runtime calls to live infrastructure operations.
- Modifying upstream OpenCode themes.

## Deliverables

1. `data/themes/opencode/*.json` local mirror of upstream theme files.
2. `utl/theme/sync_opencode_themes.sh` to fetch/update palettes.
3. `utl/theme/build_terminal_tokens.sh` to resolve semantic tokens.
4. `utl/theme/theme_runtime.sh` with `fg_hex`, `bg_hex`, `style_reset`, and semantic wrappers.
5. `utl/theme/preview_theme.sh` to visually inspect selected themes.
6. `doc/man/terminal-theme-usage.md` quick usage guide.

## Implementation Phases

### Phase 0 - Baseline and Folder Setup

1. Create local directories for source themes, generated tokens, and helpers.
2. Pick default mode (`dark`) and default theme (`opencode`).
3. Define a single semantic contract used by scripts:
   - `primary secondary accent text text_muted background panel element border error warning success info`

Done when:

- Directory layout exists and semantic contract is documented.

### Phase 1 - Theme Sync (Source Data)

1. Implement `sync_opencode_themes.sh`:
   - Query GitHub contents API for theme directory.
   - Download each `*.json` via `download_url`.
   - Save to `data/themes/opencode/`.
2. Store sync metadata (`synced_at`, source URL, count).
3. Fail with clear message if network or API call fails.

Done when:

- All available OpenCode theme files are mirrored locally from one command.

### Phase 2 - Token Resolver (Semantic Mapping)

1. Implement `build_terminal_tokens.sh`:
   - Read one theme JSON file.
   - Resolve `theme.<token>.<mode>` references through `defs`.
   - Output flat token map for terminal use (JSON or `KEY=VALUE`).
2. Validate every required semantic token exists.
3. Emit non-zero exit code on missing keys or invalid hex values.

Done when:

- Any synced theme can be converted into a complete semantic token map.

### Phase 3 - Terminal Runtime Helpers

1. Implement `theme_runtime.sh` with:
   - `fg_hex <#RRGGBB>`
   - `bg_hex <#RRGGBB>`
   - `style_reset`
2. Add semantic helpers sourced from generated tokens:
   - `c_primary`, `c_text`, `c_error`, etc.
3. Add graceful fallback strategy:
   - truecolor if supported
   - 256-color fallback map if not
   - plain text fallback as last resort

Done when:

- Any script can source one file and print themed output safely.

### Phase 4 - Preview and UX Checks

1. Implement `preview_theme.sh <theme> [dark|light]` to print swatches and sample statuses.
2. Add quick checks for readability pairs:
   - `text` on `background`
   - `text_muted` on `background`
   - `primary` on `background`
3. Flag low contrast pairs for manual review.

Done when:

- Theme quality is visually and programmatically checkable before adoption.

### Phase 5 - Tests and Verification

1. Syntax checks:
   - `bash -n utl/theme/sync_opencode_themes.sh`
   - `bash -n utl/theme/build_terminal_tokens.sh`
   - `bash -n utl/theme/theme_runtime.sh`
   - `bash -n utl/theme/preview_theme.sh`
2. Add focused tests under `val/` for:
   - missing token detection
   - invalid hex rejection
   - successful token resolution from a fixture theme
3. Run nearest test script directly after each phase.

Done when:

- Token generation and runtime behavior are covered by repeatable checks.

### Phase 6 - Adoption in Existing Terminal UI

1. Replace direct hex literals with semantic helpers in target scripts.
2. Keep output behavior identical except color source.
3. Add one config toggle to select theme name and mode.

Done when:

- Existing terminal output uses semantic theme tokens end-to-end.

## Operational Rules

- Never store API keys or secrets in theme files.
- Keep synced theme files read-only as external source snapshots.
- Do not edit upstream theme JSON manually; regenerate from sync.
- Use semantic names in code; avoid new hardcoded color literals.

## Acceptance Criteria

1. One command syncs all OpenCode theme palette files locally.
2. One command builds a valid terminal token map for a selected theme.
3. Runtime helpers colorize terminal output with truecolor + fallback.
4. Preview command clearly shows token usage and readability.
5. At least one existing terminal output path is migrated to semantic tokens.

## Execution Checklist (When You Start)

1. Move this file from `inbox/` to `queue/`.
2. Break implementation into 1-2 hour slices by phase.
3. After each phase, run syntax checks and one focused test.
4. Move to `active/` when coding starts.
5. Move to `completed/` with final verification notes.
