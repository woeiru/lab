# ana_dep strict senior review

Date: 2026-02-27
Scope: `lib/gen/ana` (`ana_dep` + `_ana_dep_truncate`), `val/lib/gen/ana_dep_test.sh`

## Validation executed

- `bash -n lib/gen/ana` -> pass
- `bash -n val/lib/gen/ana_dep_test.sh` -> pass
- `./val/lib/gen/ana_dep_test.sh` -> pass (13/13)

## Status update (implemented)

### Resolved

1) Invalid JSON risk due to missing escaping -> **resolved**
- Implemented `_ana_dep_json_escape` and applied escaping to generated JSON string fields.
- Added test coverage for escaping behavior to prevent regressions.

2) Wrong output root when called outside repo root -> **resolved**
- Replaced `LAB_DIR` fallback based on `$(pwd)` with dynamic repo-root resolution from `BASH_SOURCE[0]`.
- Added fallback behavior coverage in tests.

3) Weak CLI argument handling -> **resolved**
- Added explicit `-h|--help` handling.
- Unknown options are now rejected and argument count is enforced.
- Added negative tests for invalid argument combinations.

## Remaining findings by severity

### Medium

4) Script import parsing can misread valid source paths
- Impact: `awk '{print $1}'` + quote stripping can truncate or alter valid imports, causing false dependency output.
- Recommended fix: replace pipeline with a bash-aware parser/regex that preserves quoted paths and strips only delimiters intentionally.

5) Command dependency extraction is too narrow
- Impact: misses variants like quoted command checks or dynamic variables, under-reporting required binaries.
- Recommended fix: extend patterns for common forms and optionally label unresolved/dynamic dependencies explicitly.

### Low

6) Multiple full-file scans for one report
- Impact: unnecessary overhead on large files.
- Recommended fix: single-pass extraction for script and command dependencies.

7) Test coverage still has parser edge-case gaps
- Impact: regressions around import parsing and dynamic command extraction can still pass undetected.
- Recommended fix: add fixture-driven tests for quoted source paths, unreadable/missing targets, command-pattern variants, and dedup behavior.

## Top 3 fixes to do next

1. Fix script import parsing to preserve quoted and spaced source paths.
2. Broaden command dependency extraction for common shell variants.
3. Refactor extraction into a single-pass scan, then add focused parser edge-case tests.
