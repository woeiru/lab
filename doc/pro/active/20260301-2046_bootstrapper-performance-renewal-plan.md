# Bootstrapper Performance Renewal

- Status: active
- Owner: es
- Started: 2026-03-01
- Updated: 2026-03-01 (promoted to active via triage)
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

1. Decide whether to complete Phase 1 target (<800ms) in this item by adding
   additional low-risk fork/file-I/O reductions in the boot path (`bin/ini`,
   `bin/orc`, `lib/core/ver`, `lib/core/lo1`, `lib/core/err`, `lib/core/tme`).
2. If Phase 1 remains open, run another before/after timing set with the same
   command (`MASTER_TERMINAL_VERBOSITY=off; source /home/es/lab/bin/ini`) and
   record median deltas in this plan.
3. If moving to Phase 2, implement and validate item 6 (`ver_verify_module`
   boot-path deferral) and item 7 (`ver_log` consolidation) with focused tests
   before broader suite runs.

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

### In-flight

- All code changes are local and uncommitted (intentionally left unstaged).
- Active item target (<800ms median) is not yet achieved; current median is
  `1.105s`.

### Blockers

- No functional/code blockers for Phase 1 items 1-5.
- Validation blocker for a fully green quick suite: unrelated
  `glb_008_secret_scan_test` failure due to detected default password string at
  `lib/gen/inf:90`.
- Scope decision pending: whether to close this item as "Phase 1 items
  implemented" vs continue until the <800ms target is met.

### Next steps

1. Confirm closure criteria for this item (implementation-complete vs
   performance-target-complete) in this plan.
2. If continuing for target, profile remaining startup hotspots and apply next
   low-risk optimizations in `bin/ini`, `bin/orc`, and `lib/core/lo1`.
3. Run focused verification after each optimization batch:
   `bash -n` on edited files plus `./val/core/initialization/ini_test.sh` and
   `./val/core/modules/tme_test.sh`.
4. Re-run timing command 3x and append median deltas in this document.
5. If Phase 2 starts, implement item 6 in `lib/core/ver` and boot call sites in
   `bin/ini`/`bin/orc`, then implement item 7 logging consolidation.

### Context

- Branch: `master`.
- Modified files currently in working tree: `bin/ini`, `bin/orc`,
  `lib/core/col`, `lib/core/tme`, `lib/core/ver`.
- No persistent temp artifacts from this session are required for continuation.
- Timing command used for all measurements:
  `time bash -lc 'MASTER_TERMINAL_VERBOSITY=off; source /home/es/lab/bin/ini' 2>&1`.
- Key finding: Phase 1 edits materially reduced bootstrap time but did not yet
  reach the plan's <800ms target.

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

1. Start Phase 1 implementation immediately and log timing baselines before the
   first commit.
