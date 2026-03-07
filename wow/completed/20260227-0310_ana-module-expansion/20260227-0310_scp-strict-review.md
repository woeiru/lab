# Strict Senior Review: `ana_scp` Implementation

Date: 2026-02-27
Reviewer mode: strict senior reviewer
Scope reviewed: `lib/gen/ana` (`ana_scp`) and `val/lib/gen/ana_scp_test.sh`

## Goal
Assess the implementation quality of `ana_scp` (Variable Scope & Integrity Analysis) against correctness, edge cases, security, performance, maintainability, and test strength.

## Constraints Considered
- Follow repository Bash standards and function contract patterns (`-h/--help`, return codes, usage behavior).
- Keep output suitable for terminal and JSON consumers.
- Avoid regressions to existing `ana` behavior.

## Changed Files / Diff Reviewed
- `lib/gen/ana`
  - Added `ana_scp`
  - (Also includes appended `ana_dep` in current working diff)
- `val/lib/gen/ana_scp_test.sh`
  - New test suite for terminal and JSON mode

## Validation Run
- `bash -n lib/gen/ana` -> pass
- `bash -n val/lib/gen/ana_scp_test.sh` -> pass
- `./val/lib/gen/ana_scp_test.sh` -> pass (11/11)

## Findings (ranked by severity)

### Resolved (top 3)

1) Missing required CLI contract (`--help/-h`, invalid-option handling, usage helpers) -> **resolved**
- Implemented explicit `-h|--help` handling (`0`), invalid-option rejection (`1`), and strict argument-count validation.
- Integrated usage/error flow through `aux_use` and input validation via `aux_val`.
- Added tests for help and invalid-option behavior.

2) Helper functions declared inside `ana_scp` leak globally and are too generic -> **resolved**
- Replaced nested generic helpers with namespaced file-scope helpers: `_ana_scp_truncate_and_pad`, `_ana_scp_print_separator`, `_ana_scp_print_row`.
- Added regression test to verify generic helper names are not leaked.

3) JSON output generation does not escape JSON-sensitive characters -> **resolved**
- Added `_ana_scp_json_escape` for `\\`, `"`, and control-character escaping (`\n`, `\r`, `\t`, `\f`, `\b`).
- Switched JSON writes to `printf`-driven emission with escaped values.
- Added targeted tests covering quote/backslash and control-character escaping.

### Medium

4) Function scope detection is brittle (can mis-detect function end)
- Location: function start/end regex handling in parsing loop
- Impact: Standalone `}` within function bodies can prematurely reset context, producing false positives/negatives (e.g., mistaken global mutation or missed local leaks).
- Recommended fix: Track brace depth from function entry, or apply stricter parser state transitions.

5) Comment stripping is syntactically unsafe
- Location: `line="${raw_line%%#*}"`
- Impact: Strips `#` inside quoted strings; parser may misclassify lines and produce inaccurate findings.
- Recommended fix: Use quote-aware comment handling, or avoid manual stripping and rely on line-pattern filters.

### Low

6) Tests are narrow; they validate happy path but miss robustness gaps
- Location: `val/lib/gen/ana_scp_test.sh`
- Impact: Current suite passes despite important parser and output contract weaknesses.
- Recommended fix: Add coverage for:
  - `declare -g`, `export -f`, and multi-variable declarations
  - quoted/hash-containing assignments
  - nested/braced structures affecting scope state
  - JSON parse-validity checks of generated files

## Next 3 Fixes To Do

1. Harden function-scope tracking to avoid premature function-end detection on standalone `}`.
2. Replace naive comment stripping with quote-aware parsing logic.
3. Expand fixture coverage for `declare -g`, `export -f`, multi-variable declarations, and hash-in-string assignments.
