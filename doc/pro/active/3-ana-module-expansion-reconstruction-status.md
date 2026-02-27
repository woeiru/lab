# ana module expansion reconstruction status

Date: 2026-02-27

## Why this file exists

`doc/pro/active` was renamed with numeric prefixes (old names deleted, new names added), and review coverage became hard to track. This file reconstructs what exists, what was likely missing, and what is still open.

## Canonical active file set

- `doc/pro/active/0-ana-module-expansion-plan.md`
- `doc/pro/active/1-ana-implementation-review.md`
- `doc/pro/active/2-ana-module-expansion-review.md`
- `doc/pro/active/2-ana-dep-strict-review.md`
- `doc/pro/active/2-ana-tst-strict-review.md`
- `doc/pro/active/2-ana-err-strict-review.md`
- `doc/pro/active/2-ana-scp-strict-review.md`
- `doc/pro/active/2-ana-rdp-strict-review.md`
- `doc/pro/active/3-ana-module-expansion-reconstruction-status.md`

## Reconstructed missing review docs

- Added `doc/pro/active/2-ana-tst-strict-review.md`
- Added `doc/pro/active/2-ana-err-strict-review.md`

These were the two likely gaps after 3.1-3.5 review documents were moved into `active/`.

## 3.1 - 3.5 status snapshot (revalidated)

| Section | Function | Implementation | Review doc | Current test status | State |
|---|---|---|---|---|---|
| 3.1 | `ana_dep` | present | `2-ana-dep-strict-review.md` | `./val/lib/gen/ana_dep_test.sh`: pass (13/13) | resolved |
| 3.2 | `ana_tst` | present | `2-ana-tst-strict-review.md` | `./val/lib/gen/ana_tst_test.sh`: pass (8/8) | resolved |
| 3.3 | `ana_err` | present | `2-ana-err-strict-review.md` + `1-ana-implementation-review.md` | `./val/lib/gen/ana_err_test.sh`: pass (7/7), includes real-file JSON parse check | resolved |
| 3.4 | `ana_scp` | present | `2-ana-scp-strict-review.md` | `./val/lib/gen/ana_scp_test.sh`: pass (11/11) | resolved |
| 3.5 | `ana_rdp` | present | `2-ana-rdp-strict-review.md` | `./val/lib/gen/ana_rdp_test.sh`: pass (5/5) | resolved |

## Completed fixes

All previously open items called out for `ana_dep`, `ana_tst`, and `ana_err` have been addressed in code and revalidated.

Implemented/verified in this pass:

1. `ana_dep`
   - Added strict CLI argument handling (`--help`, unknown option rejection, positional-argument count guard).
   - Fixed JSON escaping for target path and dependency string values.
   - Fixed `LAB_DIR` fallback to resolve repo root when invoked outside repository cwd.

2. `ana_tst`
   - Fixed zero-match counter handling (no arithmetic on empty values).
   - Fixed mirrored target-to-test resolution to avoid basename-collision false matches.
   - Enforced strict `-j` cleanliness (no table output in JSON mode).

3. `ana_err`
   - Replaced delimiter-packed records with structured parallel arrays.
   - Added robust JSON escaping and improved function declaration matching.
   - Added real-file JSON parse-validity test (`python3 -m json.tool`) to prevent regressions.

## Remaining action order

1. `ana_scp`/`ana_rdp` strict revalidation is complete; keep rerunning their focused suites when `lib/gen/ana` changes.
2. `./val/run_all_tests.sh lib` was rerun after cleanup and now passes clean (`27/27`).
3. Optional closure step: run `./val/run_all_tests.sh` (full suite) before final merge if cross-category confidence is needed.
