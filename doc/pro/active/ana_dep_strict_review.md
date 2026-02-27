# ana_dep strict senior review

Date: 2026-02-27
Scope: `lib/gen/ana` (`ana_dep` + `_ana_dep_truncate`), `val/lib/gen/ana_dep_test.sh`

## Validation executed

- `bash -n lib/gen/ana` -> pass
- `bash -n val/lib/gen/ana_dep_test.sh` -> pass
- `./val/lib/gen/ana_dep_test.sh` -> pass (5/5)

## Findings by severity

### High

1) Invalid JSON risk due to missing escaping
- Location: `lib/gen/ana:1912`, `lib/gen/ana:1924`
- Impact: JSON can break when dependency values contain quotes, backslashes, or control chars; `val/doc` ingestion may fail or produce corrupted data.
- Recommended fix: introduce `_ana_dep_json_escape` and apply it to all JSON string fields (`target_file`, `scripts[]`, `commands[]`).

2) Wrong output root when called outside repo root
- Location: `lib/gen/ana:1843`, `lib/gen/ana:1904`
- Impact: with `LAB_DIR` unset, fallback uses `$(pwd)`, so `.tmp/doc` may be written in the caller's working directory instead of repo root.
- Recommended fix: resolve repo root from `BASH_SOURCE[0]` (consistent with sibling analyzers) and use that for output pathing.

### Medium

3) Weak CLI argument handling
- Location: `lib/gen/ana:1846`
- Impact: unknown flags and multiple positional args are silently accepted; wrong target can be analyzed without error.
- Recommended fix: support `-h|--help`, reject unknown options, and enforce exactly one positional target argument.

4) Script import parsing can misread valid source paths
- Location: `lib/gen/ana:1877`
- Impact: `awk '{print $1}'` + quote stripping can truncate or alter valid imports, causing false dependency output.
- Recommended fix: replace pipeline with a bash-aware parser/regex that preserves quoted paths and strips only delimiters intentionally.

5) Command dependency extraction is too narrow
- Location: `lib/gen/ana:1884`, `lib/gen/ana:1891`
- Impact: misses variants like quoted command checks or dynamic variables, under-reporting required binaries.
- Recommended fix: extend patterns for common forms and optionally label unresolved/dynamic dependencies explicitly.

### Low

6) Multiple full-file scans for one report
- Location: `lib/gen/ana:1873-1901`
- Impact: unnecessary overhead on large files.
- Recommended fix: single-pass extraction for script and command dependencies.

7) Tests are mostly happy-path and text-grep based
- Location: `val/lib/gen/ana_dep_test.sh`
- Impact: parser/JSON regressions can pass undetected.
- Recommended fix: add fixture-driven tests for escaping, unknown flags, missing/unreadable file, dedup, and path resolution behavior.

## Top 3 fixes to do first

1. Add robust JSON escaping and validate generated JSON format.
2. Fix LAB_DIR fallback to always resolve repo root correctly.
3. Harden CLI argument validation and add negative tests.
