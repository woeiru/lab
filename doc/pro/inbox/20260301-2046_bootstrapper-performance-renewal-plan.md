# Bootstrapper Performance Renewal

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-01
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

1. Implement Phase 1 (items 1-5) on a feature branch.
2. Measure before/after with `time source bin/ini` (MASTER_TERMINAL_VERBOSITY=off
   for clean measurement).
3. Run `./val/run_all_tests.sh` to verify no regressions.
4. If Phase 1 achieves <800ms, move this item to `active/` and proceed to
   Phase 2.
