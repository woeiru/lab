# Bootstrapper Performance Renewal

- Status: active
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-01 (checkpoint verification + Phase 2 item 7 pass)
- Links: bin/ini, bin/orc, lib/core/col, lib/core/err, lib/core/lo1, lib/core/tme, lib/core/ver, cfg/core/ric, cfg/core/rdc, cfg/core/mdc, doc/arc/01-bootstrap-and-orchestration.md

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

1. Begin Phase 3 by preparing a minimal lazy-load strategy for `lib/ops/`
   (stub wrappers + first-load source path) that preserves current contracts.
2. Prototype the lazy-load path for a small subset of ops functions first, then
   validate parity (arguments, return codes, output) against eager-load behavior.
3. Measure bootstrap again and decide whether to expand lazy-loading to all
   `lib/ops/` modules in this item or split into a follow-on active plan.

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

### In-flight

- Current active code edits in this pass: `lib/core/ver`, `bin/orc`.
- Running quick validation produced generated working-tree deltas outside this
  plan scope: `STATS.md`, `doc/ref/stats/actual.md`, and
  `doc/ref/stats/20260301T210850Z.json`.
- Phase 1 and Phase 2 objectives are achieved in continuation samples
  (latest median `0.587s`).

### Blockers

- No functional/code blockers for the active optimization path.
- Validation blocker for a fully green quick suite remains unrelated:
  `glb_008_secret_scan_test` failure due to detected default password string at
  `lib/gen/inf:90`.
- No current code blocker for proceeding into Phase 3 planning/prototyping.

### Next steps

1. Isolate this plan's intended deltas from quick-suite generated stats artifacts
   before preparing a commit.
2. Draft/implement first Phase 3 lazy-load prototype for `lib/ops/`.
3. Re-run focused validations and timing after prototype integration.
4. Decide whether to continue Phase 3 expansion in this item or split follow-on.

### Context

- Branch: `master`.
- Modified files currently in working tree: `bin/orc`, `lib/core/ver`, plus generated
  stats outputs from quick-suite execution (`STATS.md`,
  `doc/ref/stats/actual.md`, `doc/ref/stats/20260301T210850Z.json`).
- No persistent temp artifacts from this session are required for continuation.
- Timing command used for all measurements:
  `time bash -lc 'MASTER_TERMINAL_VERBOSITY=off; source /home/es/lab/bin/ini' 2>&1`.
- Key finding: combined Phase 1 resume optimizations reduced median bootstrap
  time to `0.624s`, exceeding the <`800ms` target.
- New finding (continuation): after `ver_log` consolidation plus `bin/orc`
  basename fork removal, current 3-run sample median is `0.587s`; this meets
  both Phase 1 (<`800ms`) and Phase 2 (<`600ms`) targets.

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
