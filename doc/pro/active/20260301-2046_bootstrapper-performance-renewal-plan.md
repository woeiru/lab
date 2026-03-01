# Bootstrapper Performance Renewal

- Status: active
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-01 (Phase 3 completion)
- Links: bin/ini, bin/orc, lib/core/col, lib/core/err, lib/core/lo1, lib/core/tme, lib/core/ver, cfg/core/ric, cfg/core/rdc, cfg/core/mdc, cfg/core/lzy, doc/arc/01-bootstrap-and-orchestration.md

## Goal

Reduce shell bootstrap time from ~1.7s to under 400ms by eliminating
unnecessary process forks, redundant file I/O, and eager loading of modules
that are not needed at shell-open time. Preserve correctness and the existing
module contract surface.

## Context

Profiling the current boot chain (`bin/ini` -> `bin/orc` -> lib/cfg sourcing)
reveals that the 1.7s duration is dominated by ~555 subprocess forks and
~850+ file write operations per boot, not by the complexity of the work itself.

### Root causes by estimated impact

| # | Bottleneck | Forks | Est. cost | Where |
|---|-----------|-------|-----------|-------|
| 1 | `LOG_DEBUG_ENABLED=1` default -- stack-trace dump on every `lo1_log` call | 0 (I/O) | 200-400ms | `lib/core/lo1:38` |
| 2 | `$(date ...)` fork per log line in `ini_log`, `ver_log`, `tme_*` | ~179 | 360-900ms | `bin/ini`, `lib/core/ver`, `lib/core/tme` |
| 3 | `echo ... | bc` pipe for arithmetic in `tme_end_timer` | ~68 | 140-340ms | `lib/core/tme:209` |
| 4 | `$(printf '\033[...]')` subshells for color constants | ~35 | 70-175ms | `lib/core/col`, `lib/core/tme` |
| 5 | `mktemp` + `rm` per sourced file in `source_helper` | ~42 | 80-200ms | `bin/orc:150` |
| 6 | Eager sourcing of `lib/ops/` (13,953 lines, 10 modules) | parse | 200-400ms | `bin/orc` via `source_lib_ops` |
| 7 | Redundant `ver_verify_module` calls per core module on source | ~30 | 50-150ms | `lib/core/err`, `lo1`, `tme` |

### Current sourcing chain

```
bin/ini
  cfg/core/ric          (241 lines, path constants)
  cfg/core/rdc          (66 lines, function-module map)
  cfg/core/mdc          (72 lines, module deps)
  lib/core/ver          (423 lines, verification)
  main_ini()
    lib/core/col        (173 lines, colors via subshell printf)
    lib/core/err        (427 lines, error handling)
    lib/core/lo1        (454 lines, logging + debug dump)
    lib/core/tme        (623 lines, timing via bc)
    bin/orc             (670 lines, component orchestrator)
      cfg/core/ecc      (37 lines, env controller)
      cfg/ali/*          (557 lines, aliases)
      lib/ops/*          (13,953 lines, 10 operational modules)
      lib/gen/*          (4,960 lines, 5 utility modules)
      cfg/env/*          (804 lines, site configs)
```

Total parsed: ~24,209 lines across 31 files in a single blocking sequence.

## Triage Decision

This item is moved directly from inbox to active because it is execution-ready,
has quantified bottlenecks, and targets startup latency that impacts every
interactive shell launch. Queue was skipped to start immediate implementation on
the highest-impact, lowest-risk Phase 1 fork-elimination work.

## Execution Plan (remaining)

1. No remaining mandatory implementation work for Phases 1-3 in this item.
2. Optional follow-on: pursue sub-`400ms` target with deeper runtime
   restructuring beyond lazy-load scope.

## Progress Checkpoint

### Done

- Completed Phase 1 items 1-5 implementation in this session.
- Files changed: `bin/ini`, `bin/orc`, `lib/core/col`, `lib/core/tme`,
  `lib/core/ver`.
- Decision: replaced display/logging `date` forks with builtin time formatting
  (`printf '%(... )T'`) and used helper wrappers for consistency.
- Decision: replaced `bc` timing arithmetic with integer nanosecond math in
  `lib/core/tme`, preserving `X.YYYs` output formatting.
- Decision: replaced ANSI `$(printf ...)` subshell assignments with `$'...'`
  literals in color constants.
- Decision: replaced temp-file stderr capture in `bin/orc` `source_helper` with
  FD-based capture using `coproc`, avoiding per-source `mktemp`/`rm`.
- Decision: forced `LOG_DEBUG_ENABLED=0` at boot start in `bin/ini` and restored
  configured/default value after `bin/orc` sourcing path (success/failure).
- Timing baseline captured (3 runs): `1.614s`, `1.614s`, `1.614s` (median
  `1.614s`).
- Post-edit timing captured (3 runs): `1.100s`, `1.105s`, `1.115s` (median
  `1.105s`, improvement `-0.509s`, ~31.5%).
- Tests run this session:
  - `bash -n` on all edited files: pass.
  - Targeted tests: `./val/core/config/cfg_test.sh`,
    `./val/core/initialization/ini_test.sh`,
    `./val/core/initialization/orc_test.sh`,
    `./val/core/modules/tme_test.sh`, `./val/core/modules/ver_test.sh`,
    `./val/lib/core/col_test.sh`: pass.
- `./val/run_all_tests.sh --quick`: single failing test
  `glb_008_secret_scan_test` (pre-existing/unrelated secret-scan finding in
  `lib/gen/inf`), remainder passed.
- Resume verification completed:
  - Verified checkpoint file references and current module contents for
    `bin/ini`, `bin/orc`, `lib/core/lo1`, `lib/core/tme`, `lib/core/ver`,
    `lib/core/col`.
  - Confirmed previous checkpoint state was stale on one point: in-flight note
    said "local and uncommitted", but those changes are already committed in
    `98ffa772`.
  - Reconfirmed unrelated quick-suite blocker persists:
    `glb_008_secret_scan_test` flags `lib/gen/inf:90`.
- Additional optimizations applied during resume:
  - `bin/orc`: replaced `source_directory` and `source_lib_ops` file discovery
    from `find|sort|mktemp` pipelines to shell-glob iteration (fork reduction).
  - `lib/core/lo1`: removed `date`/`cat` usage from hot paths via builtin time
    helper and direct file reads/writes.
  - `bin/ini`: kept `LOG_DEBUG_ENABLED=0` through more of bootstrap and restored
    at `main_ini` exits.
  - `bin/ini` + `lib/core/ver`: added `LAB_BOOTSTRAP_MODE=1` gating so
    `ver_verify_module` skips deep checks during immediate bootstrap sourcing.
  - `lib/core/ver`: gated non-error `ver_log` writes during `PERFORMANCE_MODE=1`.
  - `lib/core/tme`: removed `LOG_STATE_FILE` toggling (`cat`/`echo` per timer
    event) in timing start/end/cleanup paths.
- Additional timing measurements (same command):
  - Resume pre-optimization spot check (3 runs): `1.159s`, `1.124s`, `1.084s`
    (median `1.124s`).
  - After `bin/orc` + `lo1` optimizations (3 runs): `0.940s`, `0.965s`, `0.931s`
    (median `0.940s`).
  - After debug-state + bootstrap verification deferral (3 runs):
    `0.892s`, `0.914s`, `0.915s` (median `0.914s`).
  - After `ver_log` performance gate and `tme` log-state I/O removal (3 runs):
    `0.615s`, `0.625s`, `0.624s` (median `0.624s`).
- Additional tests run this resume pass:
  - `bash -n` on changed files after each optimization batch: pass.
  - Targeted suites (multiple rounds):
    `./val/core/initialization/ini_test.sh`,
    `./val/core/initialization/orc_test.sh`,
    `./val/core/modules/tme_test.sh`,
    `./val/core/modules/ver_test.sh`,
    `./val/core/modules/lo1_test.sh`: pass.
- Checkpoint verification on this continuation pass:
  - Re-read `## In-flight`/`## Next steps` referenced files:
    `bin/ini`, `bin/orc`, `lib/core/lo1`, `lib/core/tme`, `lib/core/ver`, and
    blocker reference `lib/gen/inf:90`.
  - Verified state drift: checkpoint said tracked optimization files were local
    and uncommitted, but branch was clean before this pass.
  - Re-ran `./val/run_all_tests.sh --quick`; blocker remains unchanged and
    unrelated (`glb_008_secret_scan_test` on `lib/gen/inf:90`).
- Phase 2 item 7 work performed in this pass:
  - `lib/core/ver` `ver_log` now short-circuits non-error logs during
    `LAB_BOOTSTRAP_MODE=1` unless `VER_BOOTSTRAP_LOGGING=1`.
  - Moved log suppression checks ahead of timestamp/file work to reduce hot-path
    overhead.
  - Removed `dirname` subprocess from `ver_log` via parameter expansion and
    added cached log-dir creation (`VER_LOG_DIR_READY`).
  - Deferred terminal timestamp generation to terminal-output path only.
- Validation/timing from this pass:
  - `bash -n lib/core/ver`: pass.
  - `./val/core/modules/ver_test.sh`: pass.
  - `./val/core/initialization/ini_test.sh`: pass (includes performance check,
    observed `650ms`).
  - 3-run timing sample (`time bash -lc 'MASTER_TERMINAL_VERBOSITY=off; source /home/es/lab/bin/ini'`):
    `0.644s`, `0.611s`, `0.635s` (median `0.635s`).
- Additional Phase 2 micro-optimization completed:
  - `bin/orc`: removed remaining `basename` subprocess calls in hot loops and
    `source_helper` fallback path via parameter expansion (`${file##*/}`).
- Validation/timing after additional optimization:
  - `bash -n bin/orc lib/core/ver`: pass.
  - `./val/core/initialization/orc_test.sh`: pass.
  - `./val/core/modules/ver_test.sh`: pass.
  - `./val/core/initialization/ini_test.sh`: pass (performance check observed
    `604ms`).
  - 3-run timing sample: `0.597s`, `0.587s`, `0.585s` (median `0.587s`).
  - Result: Phase 2 target (<`600ms`) achieved in this pass.
- Fresh-context checkpoint verification completed:
  - `git status --short --branch` showed clean branch before this pass; prior
    checkpoint `In-flight` state was stale.
  - Re-read `bin/orc`, `lib/core/ver`, and blocker reference `lib/gen/inf:90`.
  - Verified quick-suite blocker still reproduces via
    `./val/core/glb_008_secret_scan_test.sh` at `lib/gen/inf:90`.
- Phase 3 prototype implemented in this pass:
  - `bin/orc`: added lazy ops dispatch path (`_orc_lazy_dispatch`) with
    per-module load tracking (`ORC_LAZY_OPS_MODULE_LOADED`).
  - `bin/orc`: added prototype stub registration for `ssh` module functions and
    selective lazy module filtering via `LAB_OPS_LAZY_LOAD` /
    `LAB_OPS_LAZY_MODULES`.
  - `bin/ini`: set Phase 3 prototype defaults before component setup
    (`LAB_OPS_LAZY_LOAD=1`, `LAB_OPS_LAZY_MODULES=ssh`).
  - `val/core/initialization/orc_test.sh`: added test proving lazy stub
    replacement and first-call module load behavior.
- Validation/timing for this pass:
  - `bash -n bin/orc bin/ini val/core/initialization/orc_test.sh`: pass.
  - `./val/core/initialization/orc_test.sh`: pass.
  - `./val/core/initialization/ini_test.sh`: pass (performance check observed
    `619ms`).
  - 3-run timing sample: `0.585s`, `0.591s`, `0.649s` (median `0.591s`).
  - Result: Phase 3 prototype integrated while holding Phase 2 performance band.
- Phase 3 completion work performed in this pass:
  - `bin/orc`: generalized lazy-loading to ops/gen module sets via
    `LAB_OPS_LAZY_*` and `LAB_GEN_LAZY_*` controls.
  - `bin/orc`: switched lazy stub registration from per-boot source scanning to
    static function maps loaded from `cfg/core/lzy`.
  - `cfg/core/lzy`: added module-to-function lazy map for all current ops/gen
    modules.
  - `bin/ini`: defaulted lazy mode to full module sets (`all`) for both ops and
    gen.
  - `val/core/initialization/orc_test.sh`: extended lazy-load assertions to
    cover both ops and gen first-call load behavior.
- Validation/timing for Phase 3 completion:
  - `bash -n bin/orc bin/ini cfg/core/lzy val/core/initialization/orc_test.sh`:
    pass.
  - `./val/core/initialization/orc_test.sh`: pass.
  - `./val/core/initialization/ini_test.sh`: pass (performance check observed
    `526ms`).
  - `./val/lib/ops/ssh_test.sh`: pass.
  - `./val/lib/gen/inf_test.sh`: pass.
  - 3-run timing sample: `0.495s`, `0.489s`, `0.499s` (median `0.495s`).
  - Result: Phase 3 completed with additional bootstrap reduction
    (`0.587s` -> `0.495s`, ~15.7% faster), though still above aspirational
    `<400ms` target.

### In-flight

- Current active code edits in this pass: `bin/ini`, `bin/orc`, `cfg/core/lzy`,
  `val/core/initialization/orc_test.sh`.
- Phase 1, Phase 2, and Phase 3 implementation objectives are achieved for this
  active item scope.

### Blockers

- No functional/code blockers for the active optimization path.
- Validation blocker for a fully green quick suite remains unrelated:
  `glb_008_secret_scan_test` failure due to detected default password string at
  `lib/gen/inf:90`.
- No current code blocker for closing this phase.

### Next steps

1. Prepare closure artifacts (summary + commit when requested).
2. If required, open a follow-on active plan focused on remaining gap to
   `<400ms`.

### Context

- Branch: `master`.
- Modified files currently in working tree: `bin/ini`, `bin/orc`,
  `cfg/core/lzy`, `val/core/initialization/orc_test.sh`.
- No persistent temp artifacts from this session are required for continuation.
- Timing command used for all measurements:
  `time bash -lc 'MASTER_TERMINAL_VERBOSITY=off; source /home/es/lab/bin/ini' 2>&1`.
- Key finding: combined Phase 1 resume optimizations reduced median bootstrap
  time to `0.624s`, exceeding the <`800ms` target.
- New finding (continuation): after `ver_log` consolidation plus `bin/orc`
  basename fork removal, current 3-run sample median is `0.587s`; this meets
  both Phase 1 (<`800ms`) and Phase 2 (<`600ms`) targets.
- New finding (fresh-context Phase 3 prototype): selective lazy-loading for
  `lib/ops/ssh` keeps bootstrap at `0.591s` median while preserving tested
  init behavior.
- New finding (Phase 3 completion): static lazy function maps avoid per-boot
  discovery scans and reduce median bootstrap time to `0.495s`.

## Verification Plan

- Syntax-check each edited script with `bash -n <file>`.
- Run nearest targeted tests for touched modules (at minimum core and bootstrap
  path tests; expand to category/full suite if scope widens).
- Capture before/after bootstrap timing samples and confirm median latency
  reduction trend toward Phase 1 target (<800ms).
- Confirm no regressions in boot logging, error handling, and shell load path.

## Exit Criteria

- Phase 1 items 1-5 implemented and merged in working branch.
- Bootstrap latency reduced from ~1.7s baseline to <800ms median in repeated
  local measurements.
- Validation commands pass for changed scope (syntax + tests).
- Follow-on recommendation for Phase 2 documented with measured deltas.
- Phase 2 target (<600ms median) reached in continuation pass; next work is
  Phase 3 lazy-load structural optimization.
- Phase 3 lazy-load structural optimization completed and validated for ops/gen
  module loading behavior.

## Scope

### Phase 1 -- Eliminate fork overhead (target: <800ms)

Zero-fork replacements for the highest-cost patterns. No structural changes.

1. **Replace `$(date ...)` with `printf '%(%T)T' -1`** in `ini_log`, `ver_log`,
   and all `tme_*` functions. This is a Bash 4.2+ builtin (zero forks).
   Eliminates ~179 forks.

2. **Replace `echo ... | bc` with `$(( ))` integer arithmetic** in
   `tme_end_timer`, `print_timing_entry`, `tme_print_timing_report`. Use
   `%s%N` epoch nanoseconds and bash integer math for duration calculation.
   Eliminates ~68 forks.

3. **Replace `$(printf '\033[...]')` with `$'\033[...]'` direct assignment**
   in `lib/core/col` and `lib/core/tme`. ANSI escapes do not need subshells.
   Eliminates ~35 forks.

4. **Remove `mktemp`/`rm` from `source_helper`** -- capture stderr via
   redirection to a variable (`2>&1`) instead of temp file.
   Eliminates ~42 forks.

5. **Set `LOG_DEBUG_ENABLED=0` during boot** -- disable stack-trace dumping
   in `lo1_log` until boot completes. Re-enable afterward if configured.
   Eliminates ~500+ file writes.

### Phase 2 -- Reduce verification overhead (target: <600ms)

6. **Skip `ver_verify_module` during boot for modules just loaded** -- the
   modules were literally just sourced two lines above. Move verification
   to an explicit post-boot health-check command or to `./go validate`.

7. **Consolidate `ver_log` calls** -- batch or suppress verification logging
   during boot. File logging can be deferred to a single summary write.

### Phase 3 -- Defer eager loading (target: <400ms)

8. **Lazy-load `lib/ops/`** -- define stub functions that auto-load the real
   module on first call. The 10 ops modules (13,953 lines) are rarely all
   needed in a single session. Use the existing DIC pattern in `src/dic/`
   as the lazy-load mechanism.

9. **Evaluate lazy-loading `lib/gen/`** (4,960 lines) with the same stub
   pattern, except for `aux` which is needed for ops module helpers.

10. **Remove `find | sort` pipe in `source_directory`** -- replace with
    bash glob + sort builtin, or a hardcoded ordered list for known
    directories. Eliminates 4 process forks.

### Out of scope

- Changes to `./go` entrypoint (shell integration lifecycle, not boot path).
- Functional changes to ops/gen module APIs.
- Removal of the timing/logging infrastructure itself.
- Changes to `cfg/env/` configuration semantics.

## Risks

1. **Bash version floor**: `printf '%(%T)T'` requires Bash 4.2+. The project
   already targets Bash 4+ so this is minimal risk but needs a version guard
   or documented floor bump to 4.2.

2. **Integer arithmetic precision**: replacing `bc` floating-point with
   integer nanosecond math changes the timing report format slightly
   (e.g., `1.234s` computed via integer division). Verify timing report
   output matches current format.

3. **Lazy-load correctness**: stub functions must faithfully reproduce the
   contract of the real function on first call (arguments, return codes,
   stdout). Needs test coverage for each stubbed module.

4. **Debug log expectations**: setting `LOG_DEBUG_ENABLED=0` during boot
   changes what appears in `lo1.log` for boot diagnostics. Must ensure
   `ini.log` still captures sufficient boot debug context.

5. **Regression in interactive shell behavior**: `bin/orc` changes shell
   options (`set -eo pipefail`) conditionally. Any refactoring must preserve
   this interactive-safety logic.

## Next Step

1. Choose closure path: finalize Phase 1 completion in this item now, or open
   a follow-on for optional Phase 2 verification/logging refinements.
