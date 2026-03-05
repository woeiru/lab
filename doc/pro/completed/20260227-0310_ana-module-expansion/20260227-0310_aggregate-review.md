# Strict Senior Review: ana module expansion implementation (status update)

## Scope reviewed
- `lib/gen/ana` (`ana_dep`, `ana_tst`, `ana_err`, `ana_scp`, `ana_rdp`)
- `val/lib/gen/ana_dep_test.sh`
- `val/lib/gen/ana_tst_test.sh`
- `val/lib/gen/ana_err_test.sh`
- `val/lib/gen/ana_scp_test.sh`
- `val/lib/gen/ana_rdp_test.sh`

## Validation executed
- `bash -n /home/es/lab/lib/gen/ana` (pass)
- `bash /home/es/lab/val/lib/gen/ana_dep_test.sh` (pass)
- `bash /home/es/lab/val/lib/gen/ana_tst_test.sh` (pass)
- `bash /home/es/lab/val/lib/gen/ana_err_test.sh` (pass)
- `bash /home/es/lab/val/lib/gen/ana_rdp_test.sh` (pass)
- `bash /home/es/lab/val/lib/gen/ana_scp_test.sh` (pass, parser/escaping/helper-namespace assertions added)

## Completed outcomes
- `ana_dep` implemented and stabilized with terminal output + strict `-j` JSON mode.
- `ana_tst` implemented with corrected test mapping/count behavior and JSON-safe output.
  - Fixed count parsing bug causing runtime numeric errors.
  - Replaced broad basename scanning with mirrored path resolution for accurate test traceability.
  - Hardened JSON generation with proper string escaping and clean output in `-j` mode.
- `ana_err` implemented with robust parsing and JSON mode suitable for `val/doc` consumers.
- Argument parsing and edge handling (`--help`, `-h`, invalid options, missing args) were aligned for `ana_dep`, `ana_tst`, and `ana_err`.
- `ana_scp` now aligned with CLI contract (`--help`/`-h`, invalid option rejection, usage on missing args).
- `ana_scp` JSON output now uses dedicated escaping helper and `printf`-based emission.
- `ana_scp` generic nested helper leakage removed via namespaced `_ana_scp_*` helpers.

## Remaining findings (current)

### Low

1) Regression guard gap for parser consistency across ana functions
- **Location:** `val/lib/gen/ana_scp_test.sh` and shared `ana_*` parsing expectations
- **Impact:** `ana_scp` now has parser guards, but equivalent parser-contract assertions are still not unified across all `ana_*` entrypoints.
- **Recommended fix:** Add/align a shared parser-contract test matrix for all `ana_*` functions.

2) Remaining parser robustness gaps in `ana_scp`
- **Location:** `lib/gen/ana` (`ana_scp` parsing loop)
- **Impact:** Scope and comment parsing can still misclassify edge cases (`}` nesting, `#` inside quoted strings).
- **Recommended fix:** Introduce brace-depth tracking and quote-aware comment handling; add fixture tests.

## Top next fix

1. Add shared parser-contract assertions for all `ana_*` entrypoints (not just `ana_scp`).
2. Harden `ana_scp` scope/comment parser (`}` depth + quote-aware `#` handling).
3. Add fixture-driven `ana_scp` tests for `declare -g`, `export -f`, quoted/hash assignments, and nested braces.
4. Re-run `ana_scp` suite and then the `gen`-level test subset.
