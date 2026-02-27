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
- `./val/lib/gen/ana_scp_test.sh` -> pass (6/6)

## Findings (ranked by severity)

### High

1) Missing required CLI contract (`--help/-h`, invalid-option handling, usage helpers)
- Location: `lib/gen/ana` around argument parsing and input guard in `ana_scp`
- Impact: Violates repository standards for user-facing functions; inconsistent behavior for operators and downstream scripts.
- Recommended fix: Add explicit `-h|--help` handling (return `0`), unknown-option failure path (return `1`), and integrate `aux_use`/`aux_tec`/`aux_val` patterns used by this codebase.

2) Helper functions declared inside `ana_scp` leak globally and are too generic
- Location: nested helper definitions `truncate_and_pad`, `print_separator`, `print_row`
- Impact: Bash nested function definitions are global; names can collide with other module functions and alter behavior after first call.
- Recommended fix: Move helpers out to namespaced private functions (`_ana_scp_*`) or inline formatting logic to avoid globally registered generic names.

3) JSON output generation does not escape JSON-sensitive characters
- Location: JSON writer block in `ana_scp -j`
- Impact: Invalid JSON when values contain `"` or `\\` (or control chars), which can break documentation/API consumers.
- Recommended fix: Add `_ana_scp_json_escape` and write fields with escaped content; use `printf` for controlled emission.

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
  - `-h/--help` and invalid option behavior
  - `declare -g`, `export -f`, and multi-variable declarations
  - quoted/hash-containing assignments
  - nested/braced structures affecting scope state
  - JSON escaping and parse-validity checks

## Top 3 Fixes To Do First

1. Implement safe JSON escaping for `ana_scp -j` output.
2. Replace nested generic helpers with namespaced `_ana_scp_*` helpers.
3. Add standards-compliant argument handling (`--help/-h`, unknown options, proper usage/errors).
