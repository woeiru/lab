# Implementation Plan: Split Quota and Load Balancing Dashboards

## Goal

Separate the display of quota information from the load balancing dashboard. Currently, `dev_olb` does too much by displaying Accounts, Antigravity Quota, Gemini CLI Quota, Routing, and Model Usage. 

This plan outlines splitting `dev_olb` into two focused functions:
- `dev_olb`: Exclusively for load balancing (Accounts, Routing, Model Usage).
- `dev_oqu`: A new dashboard specifically for all quotas (Antigravity Quota, Gemini CLI Quota).

## Architecture Changes

### 1. `dev_olb` (Load Balancing Dashboard)
**Responsibility**: Show the current routing configuration and usage statistics to help the user understand how traffic is distributed.
**Contents**:
- Accounts List (status, last used, active status)
- Routing Map (default account, family-specific routes)
- Model Usage (sqlite database stats)
**Changes**:
- Remove the "Antigravity Quota" table.
- Remove the newly integrated "Gemini CLI Quota" table.
- Simplify `_dev_olb_render` to only process the remaining sections.

### 2. `dev_oqu` (Quota Dashboard)
**Responsibility**: Show API quota and rate limit status across all providers and accounts.
**Contents**:
- Antigravity Quota (remaining fraction, reset times, rate limits)
- Gemini CLI Quota (filtered list of models, remaining fraction, reset times)
**Features**:
- Must support `-x` (execute once) and `--watch <interval>` modes, matching `dev_olb`.
- Uses `_dev_oqu_render` (a new python helper) to parse `antigravity-accounts.json` and render the quota tables.
- Applies the existing `dev_olb` model filtering policy for Gemini CLI quotas (only show `gemini-3.1-*` and `gemini-3-*` models).

## Implementation Steps

### Phase 1: Create `dev_oqu`
1. **Add `_dev_oqu_render` helper**:
   - Copy the `Antigravity Quota` and `Gemini CLI Quota` rendering logic from `_dev_olb_render` into a new python script inside `_dev_oqu_render` in `lib/ops/dev`.
   - Ensure the formatting utilities (`bar`, `fmt_ts`, `fmt_reset`, `to_fraction`) are duplicated or handled cleanly within the python string block.
2. **Add `dev_oqu` main function**:
   - Mirror `dev_olb` for argument parsing (`-x`, `--watch`).
   - Call `_dev_oqu_render` with the accounts path.
3. **Register function**:
   - Document `dev_oqu` in `lib/ops/dev` with a proper technical description.

### Phase 2: Refactor `dev_olb`
1. **Clean up `_dev_olb_render`**:
   - Remove the `Antigravity Quota` and `Gemini CLI Quota` sections.
   - Retain Account summary, Routing summary, and Model Usage.
2. **Update docs**:
   - Update `dev_olb` technical description to remove references to quota data.

### Phase 3: Validation & Tests
1. **Update `val/lib/ops/dev_test.sh`**:
   - Add tests for `dev_oqu` (`test_dev_oqu_requires_flag`, `test_dev_oqu_renders_dashboard`, `test_dev_oqu_watch_requires_interval`).
   - Update existing `dev_olb` tests if they assert on quota string presence.
2. **Run test suite**:
   - Execute `./val/run_all_tests.sh` to ensure no regressions.

## Operational Notes
- Dashboards must remain fail-open and keep clear empty/error states if cache fields are missing.
- Ensure `dev_oqu` and `dev_olb` share the same visual style (`BOLD`, `DIM`, `RESET` colors).
