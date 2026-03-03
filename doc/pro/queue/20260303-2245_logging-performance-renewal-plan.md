# Logging Performance Renewal

- Status: queue
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-03
- Links: lib/core/lo1, lib/core/err, lib/core/tme, lib/gen/aux, lib/core/ver, bin/ini, cfg/core/ric, doc/arc/07-logging-and-error-handling.md, doc/pro/inbox/20260303-0336_logging-system-renewal-plan.md

## Goal

Eliminate per-call overhead in the logging subsystems by removing subshell
forks, redundant file I/O, and unnecessary subprocess spawns from hot paths.
This is the first of three logging renewal projects, following the same
performance-first methodology that reduced bootstrap time from 1.7s to 0.5s.

The bootstrapper performance renewal proved that replacing `$(...)` command
substitutions with `printf -v` output-variable patterns, caching expensive
lookups, and using Bash builtins over external commands yields compound
speedups. The same techniques apply directly to the logging system, where
`lo1_log` forks subshells on every invocation and `aux_log` spawns `hostname`
and `date` subprocesses per call.

This project targets measurable reduction in per-call logging cost without
changing any public API signatures, log file formats, or verbosity semantics.
Architecture and visual changes are explicitly deferred to the subsequent
projects.

## Triage Decision

- Why now: This is the first dependency in the three-part logging renewal sequence, so triaging now unblocks the downstream architecture and visual work while profiling context is still current.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required.
- Justification: The implementation strategy affects core logging internals used across modules and must preserve stable external logging behavior.

## Context

### Current per-call overhead (profiling baseline)

Each `lo1_log` invocation executes these command substitutions:

| Fork source | Function | File:Line | Est. cost |
|-------------|----------|-----------|-----------|
| `$(lo1_calculate_final_depth)` | Depth calculation | `lib/core/lo1:262` | ~2ms (subshell + stack walk) |
| `$(lo1_get_indent "$depth")` | Indent string | `lib/core/lo1:262` | ~1ms (subshell) |
| `$(lo1_get_color "$depth")` | Color lookup | `lib/core/lo1:262` | ~1ms (subshell) |
| `$(lo1_get_cached_log_state)` | State file read | `lib/core/lo1:262` | ~1ms (subshell + file read) |

Total: ~5ms per `lo1_log` call, multiplied across hundreds of calls during
component loading in `bin/orc`.

Each `aux_log` invocation executes:

| Fork source | Function | File:Line | Est. cost |
|-------------|----------|-----------|-----------|
| `$(hostname)` | Hostname lookup | `lib/gen/aux:896` | ~2ms (subprocess) |
| `$(echo ... \| grep -o ... \| cut ...)` | Metadata parsing | `lib/gen/aux:896` | ~3ms (pipe chain) |
| `$(date +%s)` | Epoch timestamp | `lib/gen/aux:669` | ~2ms (subprocess) |
| `$(date -Iseconds)` / `$(date +'%Y-%m-%d %H:%M:%S')` | ISO/formatted timestamp | `lib/gen/aux:669` | ~2ms (subprocess) |

Total: ~9ms per `aux_log` call in structured format modes.

Additional overhead patterns:

| Pattern | Location | Description |
|---------|----------|-------------|
| State file I/O | `lib/core/lo1:88-104` | `lo1_get_cached_log_state` reads `LOG_STATE_FILE` with 5s TTL cache, but the check itself uses `stat` via `$(...)` |
| `tme` duplicate colors | `lib/core/tme:309-366` | `print_timing_entry` defines local `TME_RED`, `TME_ORANGE`, etc. despite `col` being loaded |
| Inconsistent state format | `lib/core/lo1` vs `lib/core/tme` | `lo1` uses `"on"/"off"` state files, `tme` uses `"true"/"false"` |
| `lo1_debug_log` guard | `lib/core/lo1:54` | Checks `LOG_DEBUG_ENABLED` but still enters function body before returning |
| `lo1_log "lvl"` convention | `lib/core/lo1:262` | Every call passes literal `"lvl"` as arg 1, checked and discarded |

### What the bootstrapper performance renewal proved

The bootstrapper renewal (`doc/pro/completed/20260301-2328_bootstrapper-
performance-renewal`) demonstrated these techniques:

1. `printf '%(%T)T' -1` replaces `$(date +%H:%M:%S)` -- zero forks
2. `printf -v var ...` replaces `var=$(...)` -- zero subshells
3. `$'...'` literals replace `$(printf '...')` -- zero forks
4. Integer `$(( ))` arithmetic replaces `echo | bc` -- zero pipes
5. FD-based capture replaces temp-file stderr capture -- zero file I/O
6. Early-return guards before expensive operations -- zero wasted cycles

All of these apply directly to the logging system.

## Triage Decision

**Why now:** The logging subsystems are the highest-frequency callsite in the
runtime. Every module load, every operational function, every error path calls
through one or more logging functions. The per-call overhead compounds across
the entire session. The bootstrapper renewal already proved these optimization
patterns work; applying them to logging is low-risk, high-return.

**Design required:** No. This is tactical optimization (same APIs, same
behavior, fewer forks). No new interfaces or architectural decisions needed.

## Scope

### In scope

1. Replace `$(lo1_calculate_final_depth)`, `$(lo1_get_indent)`,
   `$(lo1_get_color)` with `printf -v` output-variable equivalents in
   `lo1_log`.
2. Replace `$(lo1_get_cached_log_state)` file-based state check with
   in-memory variable (`_LO1_LOG_ENABLED`). Remove state file I/O entirely.
3. Add early-return guard in `lo1_log` before any computation when logging
   is disabled or terminal verbosity is off.
4. Replace `$(hostname)` in `aux_get_cluster_metadata` with cached variable
   (`_AUX_CACHED_HOSTNAME`), populated once on first call.
5. Replace `$(date ...)` calls in `aux_log` and `aux_dbg` with
   `printf '%(%Y-%m-%d %H:%M:%S)T' -1` Bash builtin.
6. Cache `aux_get_cluster_metadata` result with TTL (populate once per
   session, not per call).
7. Remove duplicate color definitions in `tme` (`TME_RED`, `TME_ORANGE`,
   etc.) -- use `col_get_semantic` / `col_get_depth_color` exclusively.
8. Add early-return guard in `lo1_debug_log` at function entry (before
   entering function body) when `LOG_DEBUG_ENABLED=0`.
9. Fix `lo1_log "lvl"` vestigial parameter: remove the check and the
   requirement to pass `"lvl"` as first argument. Update all call sites.
10. Benchmark before/after with 3-run median timing samples.

### Out of scope

1. Changing log file formats or adding new log files.
2. Changing verbosity model or variable names.
3. Changing visual output (colors, indentation style, report formatting).
4. Consolidating logging subsystems (deferred to architectural restructure).
5. Adding log rotation.
6. Changing public API signatures beyond the `"lvl"` parameter removal.
7. Modifying `tme` timer measurement internals.

## Execution Plan

### Phase 1 -- lo1 subshell elimination (target: zero `$(...)` forks in lo1_log)

1. Rewrite `lo1_calculate_final_depth` to set a variable via `printf -v`
   instead of echoing. Create `_lo1_calculate_final_depth` that sets
   `_LO1_DEPTH`.
2. Rewrite `lo1_get_indent` to set `_LO1_INDENT` via `printf -v` instead
   of echoing.
3. Rewrite `lo1_get_color` to set `_LO1_COLOR` via direct array lookup
   into `COL_DEPTH` instead of subshell.
4. Replace state file I/O in `lo1_get_cached_log_state` with in-memory
   variable `_LO1_LOG_ENABLED`. Update `lo1_setlog` to set the variable
   directly. Remove `LOG_STATE_FILE` reads from hot path.
5. Rewrite `lo1_log` to use the new variable-setting functions and
   eliminate all `$(...)` command substitutions.
6. Add early-return guard: if `_LO1_LOG_ENABLED != 1` AND terminal
   verbosity is off, return immediately before any computation.
7. Verify: `bash -n lib/core/lo1`, run `val/core/modules/lo1_test.sh`
   (note: tests are currently broken -- verify syntax only, test fix is
   in scope item 9 of the architectural restructure).
8. Verify: `./val/run_all_tests.sh core` passes.

### Phase 2 -- aux overhead reduction (target: zero subprocesses per aux_log call)

1. Replace `$(hostname)` in `aux_get_cluster_metadata` with a cached
   variable `_AUX_CACHED_HOSTNAME`, set once on first call via
   `printf -v _AUX_CACHED_HOSTNAME '%s' "$(hostname)"` (one fork total,
   not per call).
2. Cache full `aux_get_cluster_metadata` output in `_AUX_CACHED_METADATA`
   with session-lifetime TTL (metadata does not change within a session).
3. Replace `$(date -Iseconds)` and `$(date +'%Y-%m-%d %H:%M:%S')` in
   `aux_log` with `printf -v _ts '%(%Y-%m-%dT%H:%M:%S)T' -1` Bash builtin.
4. Replace `$(date +%s)` epoch calls with `printf -v _epoch '%(%s)T' -1`.
5. Add early-return guard in `aux_dbg` when `MASTER_TERMINAL_VERBOSITY=off`
   AND no log file targets are configured.
6. Verify: `bash -n lib/gen/aux`, run `val/lib/gen/aux_test.sh`.
7. Verify: `./val/run_all_tests.sh lib` passes.

### Phase 3 -- lo1 API cleanup and tme dedup (target: clean calling convention, single color source)

1. Remove the `"lvl"` first-argument requirement from `lo1_log`. Change
   signature from `lo1_log "lvl" "message"` to `lo1_log "message"`.
2. Grep all call sites: `bin/orc`, `bin/ini`, `lib/core/*`, test files.
   Update every `lo1_log "lvl" "..."` to `lo1_log "..."`.
3. Add backward-compatible shim: if first arg is `"lvl"`, shift and
   continue (emit deprecation warning to debug log). Remove shim in
   a subsequent release.
4. Remove duplicate color constants from `lib/core/tme`
   (`TME_RED`, `TME_ORANGE`, `TME_GREEN`, `TME_YELLOW`, `TME_BLUE`,
   `TME_CYAN`, `TME_RESET`). Replace usages with `col_get_semantic`.
5. Add early-return guard in `lo1_debug_log` before function body
   when `LOG_DEBUG_ENABLED=0`.
6. Verify: `bash -n lib/core/lo1 lib/core/tme bin/orc bin/ini`.
7. Verify: `./val/run_all_tests.sh` full suite passes.
8. Benchmark: 3-run median timing of `lab` activation before and after
   all three phases. Record in progress checkpoint.

## Verification Plan

1. `bash -n lib/core/lo1 lib/core/tme lib/gen/aux bin/orc bin/ini`
2. `./val/core/modules/lo1_test.sh` (syntax; functional tests pending
   rewrite in architectural restructure)
3. `./val/core/modules/tme_test.sh`
4. `./val/lib/gen/aux_test.sh`
5. `./val/run_all_tests.sh core`
6. `./val/run_all_tests.sh lib`
7. `./val/run_all_tests.sh` (full suite at project completion)
8. 3-run median timing comparison: `time lab` before vs after

## Exit Criteria

1. Zero `$(...)` command substitutions in `lo1_log` hot path.
2. Zero subprocess forks per `aux_log` call (hostname, date cached).
3. `lo1_log` calling convention simplified (no more `"lvl"` first arg).
4. No duplicate color definitions in `tme`.
5. All existing tests pass (full suite).
6. Measurable per-call improvement documented with timing evidence.

## Risks

1. **`lo1_log "lvl"` removal breaks call sites.** Hundreds of call sites
   in `bin/orc` use `lo1_log "lvl" "..."`. Mitigation: grep all callers
   before changing; keep backward-compatible shim during transition that
   silently shifts the `"lvl"` argument.

2. **`printf -v` depth calculation changes indentation behavior.** The
   variable-setting pattern must produce identical output to the subshell
   pattern. Mitigation: capture before/after `lo1.log` output and diff.

3. **Cached hostname may be stale in long-running sessions.** If the
   system hostname changes during a session, `aux_log` will report the
   old name. Mitigation: acceptable for infrastructure automation where
   hostname changes require session restart anyway.

4. **In-memory log state loses persistence across subshells.** Removing
   the state file means `lo1_setlog on/off` in a subshell won't
   propagate to the parent. Mitigation: document that `lo1_setlog` now
   only affects the current shell process; this matches expected Bash
   variable scoping.

5. **`tme` color removal may affect report appearance.** The duplicate
   constants may have subtly different values from `col_get_semantic`.
   Mitigation: visual comparison of timing reports before and after.

## Next Step

Triage this plan: verify the overhead estimates with actual profiling
(count forks in a representative `lab` activation), then queue for
execution. Recommended to execute before the architectural restructure
as it establishes the optimized primitives that the restructure will
build upon.
