# Strict Senior Review: `ana_err` Implementation

Date: 2026-02-27
Scope: `lib/gen/ana` (`ana_err`), `val/lib/gen/ana_err_test.sh`

## Validation executed

- `bash -n lib/gen/ana` -> pass
- `bash -n val/lib/gen/ana_err_test.sh` -> pass
- `./val/lib/gen/ana_err_test.sh` -> pass (6/6)
- `source lib/gen/ana && ana_err /home/es/lab/lib/ops/pve -j` -> generated JSON file
- `python3 -m json.tool /home/es/lab/.tmp/doc/lib_ops_pve.err.json` -> fail (invalid JSON)

## Status update (implemented)

### Resolved

1) Basic terminal output contract -> **resolved**
- Table output contains expected columns and entries for returns and aux logging calls.

2) Optional function-target filtering -> **resolved**
- Function-level filtering is operational for happy-path fixtures.

3) Baseline JSON file generation -> **resolved**
- JSON files are produced in `.tmp/doc` and contain expected top-level keys.

## Remaining findings by severity

### High

1) JSON validity regression in real module output
- Impact: generated JSON can be syntactically invalid for real-world input; `val/doc` consumers may fail.
- Evidence: `python3 -m json.tool` fails on generated `lib_ops_pve.err.json`.
- Recommended fix: add dedicated `_ana_err_json_escape` and emit JSON via `printf` only.

2) Delimiter-packed records are fragile
- Impact: storing records as `func|type|msg|line` breaks when message contains `|`, corrupting fields and JSON.
- Recommended fix: replace packed strings with parallel arrays or direct object emission.

### Medium

3) Function detection does not cover all valid Bash forms
- Impact: misses `function name()` and indented declarations, leading to false negatives.
- Recommended fix: broaden regex for optional `function` keyword and whitespace variants.

4) CLI contract still inconsistent with strict helper conventions
- Impact: raw error prints and weak option handling reduce consistency across `ana_*` functions.
- Recommended fix: align with `aux_use`/`aux_val` patterns and explicit option parsing.

## Top 3 fixes to do next

1. Replace delimiter-based record storage with structured fields.
2. Implement robust JSON escaping and add parse-validity checks in tests.
3. Expand function signature parsing to cover valid Bash declaration variants.
