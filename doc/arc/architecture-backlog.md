# Architecture Backlog

Backlog created from `doc/arc/architecture-map.md`.

## Priority Order

1. Fix set-to-ops module mismatch (`P0`)
- Problem: `src/set/c1` and `src/set/c2` call `ops nfs set -j` / `ops smb set -j`, but no `lib/ops/nfs` or `lib/ops/smb` module exists.
- Actions:
  - Decide target interface (`ops srv nfs_set` / `ops srv smb_set`) or add compatibility modules.
  - Update affected set scripts and validate command resolution in `src/dic/ops`.
- Done when: all referenced `ops` modules/functions resolve and execute without missing-module errors.

2. Add bootstrap preflight command `./go doctor` (`P0`)
- Problem: runtime assumptions are not checked early, causing failures later in workflows.
- Actions:
  - Add a doctor command in `go`.
  - Validate expected directories, key env vars, and required module files.
  - Report actionable errors/warnings (including optional components like `src/aux`).
- Done when: `./go doctor` exits non-zero on hard failures and clearly reports remediation steps.

3. Resolve `src/aux` drift (`P1`)
- Problem: `cfg/core/ric` exports `SRC_AUX_DIR`, but `src/aux` does not exist.
- Actions:
  - Either create and use `src/aux`, or stop exporting/loading it.
  - Align `bin/orc` behavior with chosen approach.
- Done when: startup no longer references missing aux paths.

4. Standardize `ini` vs `init` naming (`P1`)
- Problem: docs and runtime names diverge (`bin/init` vs `bin/ini`).
- Actions:
  - Normalize naming in `README.md`, `bin/README.md`, and command help text.
  - Keep one canonical bootstrap name and document it consistently.
- Done when: docs and runtime entrypoints match exactly.

5. Remove insecure credential defaults (`P1`)
- Problem: plaintext dev credentials and weak defaults remain in tracked config.
- Actions:
  - Replace hardcoded defaults with generated secret flow from `lib/gen/sec`.
  - Remove committed plaintext passwords from environment overlays.
  - Add guardrails to fail on insecure defaults.
- Done when: no hardcoded default passwords exist in committed runtime config.

6. Harden test harness bootstrap (`P2`)
- Problem: `val/run_all_tests.sh` depends on preloaded `LAB_ROOT`.
- Actions:
  - Derive repo root from script location at runtime.
  - Keep `LAB_ROOT` override optional.
- Done when: tests run from a clean shell without manual env bootstrapping.

## Suggested Execution Plan

1. Complete items 1-2 in one change set (runtime correctness + preflight).
2. Complete items 3-4 in one change set (consistency and doc/runtime alignment).
3. Complete items 5-6 in one change set (security + test reliability).
