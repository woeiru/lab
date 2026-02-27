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
| 3.1 | `ana_dep` | present | `2-ana-dep-strict-review.md` | `./val/lib/gen/ana_dep_test.sh`: 4 failing (9 passed / 13 total) | open |
| 3.2 | `ana_tst` | present | `2-ana-tst-strict-review.md` | `./val/lib/gen/ana_tst_test.sh`: 3 failing (5 passed / 8 total) | open |
| 3.3 | `ana_err` | present | `2-ana-err-strict-review.md` + `1-ana-implementation-review.md` | `./val/lib/gen/ana_err_test.sh`: pass (6/6); real-file JSON parse still fails | open |
| 3.4 | `ana_scp` | present | `2-ana-scp-strict-review.md` | pass (11/11) | mostly done |
| 3.5 | `ana_rdp` | present | `2-ana-rdp-strict-review.md` | pass (5/5) | mostly done |

## Confirmed unresolved item

`ana_err` JSON correctness in real files (not just fixture-level tests) remains unresolved, confirmed by direct parse validation, because:

1. historical notes flagged JSON/delimiter fragility;
2. current local test suite still does not enforce strict JSON parse validation against realistic `aux_*` message content;
3. direct parse validation on generated output currently fails (`python3 -m json.tool /home/es/lab/.tmp/doc/lib_ops_pve.err.json`).

## Next action order

1. Fix `ana_err` JSON serialization and add strict parse-validity tests.
2. Fix `ana_dep` argument parsing + JSON escaping regressions.
3. Fix `ana_tst` no-match counter, path mapping collisions, and strict `-j` cleanliness.
