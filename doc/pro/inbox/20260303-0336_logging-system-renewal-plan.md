# Logging System Renewal

- Status: inbox
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-03
- Links: lib/core/lo1, lib/core/err, lib/core/tme, lib/core/col, lib/gen/aux, lib/core/ver, bin/ini, cfg/core/ric, doc/arc/07-logging-and-error-handling.md, doc/pro/completed/20260302-0345_bootstrap-architectural-restructure-plan/20260302-0345_bootstrap-architectural-restructure-plan.md, doc/pro/completed/20260303-0220_bootstrap-visual-output-redesign-plan/20260303-0220_bootstrap-visual-output-redesign-plan.md

## Goal

Simplify and consolidate the logging system to be leaner, more efficient, and
architecturally coherent. Five independent logging subsystems (`ini_log`,
`ver_log`, `lo1_log`, `err_process`, `aux_log`) evolved organically across
bootstrap and runtime contexts, each with its own timestamp format, verbosity
gate, color system, file target, and terminal routing. The renewal should unify
these into a smaller set of well-defined logging primitives with consistent
behavior, fewer configuration knobs, and lower per-call overhead.

This is the logical next step after the bootstrap architectural restructure
(unified loader, profile separation, compiled cache) and the visual output
redesign (compact mode, semantic colors, unified verbosity). Those efforts
cleaned up the boot chain and terminal presentation; this effort targets the
underlying logging machinery they exposed as overdue for consolidation.

## Context

### Current state (five subsystems, post-redesign)

The logging system comprises five independent subsystems that share no common
internal interface:

| Subsystem | Module | Log file | Timestamp format | Verbosity gate | Terminal channel |
|-----------|--------|----------|-----------------|----------------|-----------------|
| `ini_log` | `bin/ini` | `ini.log` | `HH:MM:SS` | `MASTER_` + `INI_LOG_` | stderr |
| `ver_log` | `lib/core/ver` | `ver.log` | `YYYY-MM-DD HH:MM:SS` | `MASTER_` + `VER_LOG_` | stderr |
| `lo1_log` | `lib/core/lo1` | `lo1.log` | `HH:MM:SS` (Bash builtin) | `MASTER_` + `LO1_LOG_` + state file + bootstrap mode | stderr (normal), stdout (Report/init) |
| `err_process` | `lib/core/err` | `err.log` | `YYYY-MM-DD HH:MM:SS` | `MASTER_` + `ERR_` | stderr (ERROR), stdout (WARNING) |
| `aux_log` | `lib/gen/aux` | `aux.log/json/csv` | ISO 8601 | None (always emits) / `AUX_DEBUG_` for `aux_dbg` | stderr |

Supporting systems: `lib/core/tme` (timing, own log file + 5 sub-toggles),
`lib/core/col` (semantic color palette, shared post-visual-redesign).

### What the recent improvements changed

1. **Bootstrap architectural restructure** introduced `lab_source_module` as
   the canonical loader, separated interactive/deployment profiles, removed
   dead boot-time ceremony (`rdc`/`mdc`), and added compiled cache. Logging
   modules are now loaded through a unified path but their internal design
   was not touched.

2. **Visual output redesign** added compact bootstrap rendering in `bin/ini`,
   compact `tme`/`err` reports using `lib/core/col` semantic colors, bootstrap
   `lo1` terminal suppression, and a `LAB_BOOTSTRAP_VERBOSITY` controller.
   This cleaned up terminal presentation but did not consolidate the underlying
   logging functions, file formats, or verbosity model. It added new variables
   (`LAB_BOOTSTRAP_OUTPUT`, `LAB_BOOTSTRAP_VERBOSITY`) on top of the existing
   12+ toggles.

### Identified problems

1. **Five logging subsystems with no shared interface.** Each has its own
   format function, file writer, verbosity check, and color lookup. There is
   no single logging primitive that all paths go through.

2. **12+ verbosity variables.** `MASTER_TERMINAL_VERBOSITY`, 5 per-module
   `*_TERMINAL_VERBOSITY` toggles, 4 TME sub-toggles, `AUX_DEBUG_ENABLED`,
   `LOG_DEBUG_ENABLED`, plus the new `LAB_BOOTSTRAP_VERBOSITY` and
   `LAB_BOOTSTRAP_OUTPUT`. Predicting what appears on terminal requires
   understanding all of them.

3. **ANSI escape codes written to log files.** `lo1_log` writes color codes
   to `lo1.log`, making the file hard to grep or parse. Other subsystems
   handle this correctly.

4. **Inconsistent terminal routing.** `lo1_log` sends some messages to stdout
   and others to stderr. `err_process` sends WARNINGs to stdout and ERRORs to
   stderr. `aux_log` always emits to stderr regardless of
   `MASTER_TERMINAL_VERBOSITY`. This creates problems with output capture and
   piping.

5. **`lo1_log` calling convention.** The first argument must be the literal
   string `"lvl"` -- a vestigial API that serves no purpose. The module is 477
   lines, ~200 of which handle depth-cache management for tree indentation
   that is now suppressed in compact mode.

6. **`lo1_log` subshell overhead.** Multiple `$()` command substitutions per
   call (depth calculation, indent, color, state lookup) create fork overhead
   on every invocation.

7. **State file I/O for on/off toggle.** `lo1_log` persists its on/off state
   to a file and re-reads it (with 5-second cache TTL) on every call. This
   is unusual for an in-process logging toggle.

8. **`aux_log` ignores master verbosity.** In `human` format mode, `aux_log`
   unconditionally writes to stderr. Setting `MASTER_TERMINAL_VERBOSITY=off`
   does not silence operational log messages.

9. **`aux_log` cluster metadata overhead.** `aux_get_cluster_metadata()` is
   called on every `aux_log`/`aux_dbg` invocation, spawning `hostname` and
   `cut` subprocesses each time.

10. **Three different timestamp formats** across subsystems (`HH:MM:SS`,
    `YYYY-MM-DD HH:MM:SS`, ISO 8601).

11. **No log rotation.** `lo1.log` and `tme.log` are cleared per boot, but
    `err.log`, `aux.log`, `aux.json`, `aux.csv`, `ver.log`, and `ini.log` are
    append-only with no size management.

12. **`lo1_test.sh` is broken.** Tests functions (`log_info`, `log_warn`,
    `log_error`, `log_debug`) that do not exist in the `lo1` module. Uses
    wrong calling convention. Effectively dead test coverage.

13. **`err_process` parameter order misuse.** `command_not_found_handle`
    calls `err_process` with component and message arguments swapped relative
    to the function signature.

14. **`lo1_log_message` bypasses verbosity gates.** Its console output is only
    gated by `lo1_get_cached_log_state()`, not by `MASTER_TERMINAL_VERBOSITY`
    or `LO1_LOG_TERMINAL_VERBOSITY`, inconsistent with `lo1_log`.

## Scope

### In scope

1. **Consolidate logging primitives.** Design a smaller, unified set of
   logging functions that replace the current five independent subsystems.
   Candidate architecture: one core log writer shared by bootstrap and
   runtime paths, with format/destination selection at the writer level
   rather than per-subsystem.

2. **Simplify verbosity model.** Reduce 12+ toggles to a coherent,
   layered model. Candidate: one `LAB_LOG_VERBOSITY` variable with levels
   (`silent`, `error`, `normal`, `verbose`, `debug`) that subsumes the
   per-module binary switches.

3. **Fix file logging hygiene.** Remove ANSI codes from all log file writes.
   Standardize on one timestamp format for files (ISO 8601 or `YYYY-MM-DD
   HH:MM:SS`). Route all terminal output consistently to stderr.

4. **Reduce per-call overhead in `lo1`.** Eliminate `$()` subshell forks for
   depth/indent/color/state lookup. Replace state-file I/O with in-memory
   variable. Cache cluster metadata in `aux`.

5. **Fix `aux_log` master verbosity bypass.** Make `aux_log` terminal output
   respect `MASTER_TERMINAL_VERBOSITY`.

6. **Fix broken `lo1_test.sh`.** Rewrite tests to exercise actual `lo1`
   API functions with correct calling conventions.

7. **Fix `err_process` parameter misuse** in `command_not_found_handle`.

8. **Add basic log rotation or size cap** for append-only log files.

9. **Update architecture docs** (`doc/arc/07-logging-and-error-handling.md`)
   and reference docs (`doc/ref/`) to reflect changes.

10. **Preserve file logging contracts.** All changes target internal
    implementation and terminal presentation. Downstream log consumers
    (if any) that parse `aux.json`/`aux.csv` must not break without
    migration path.

### Out of scope

1. Changes to `lib/ops/*` or `lib/gen/*` module APIs beyond logging calls.
2. Changes to DIC argument injection semantics.
3. Changes to deployment manifest logic.
4. Changes to `./go` entrypoint or shell integration lifecycle.
5. Changes to the compiled bootstrap cache mechanism.
6. Introduction of external logging tools or dependencies.
7. Rework of `tme` timer internals (timing measurement, hierarchy tracking) --
   only `tme` terminal/file output formatting is in scope.

## Risks

1. **Downstream log consumers.** If any tooling parses `aux.json`, `aux.csv`,
   or `err.log` for monitoring/alerting, format changes could break
   integrations. Mitigation: audit all consumers before changing file formats;
   provide migration period with old format available behind a flag.

2. **`lo1_log` callers depend on current API.** `bin/orc`, `bin/ini`, and
   some test scripts call `lo1_log "lvl" "message"`. Changing the calling
   convention requires updating all call sites. Mitigation: grep all callers
   before changing; optionally keep backward-compatible shim during
   transition.

3. **Verbosity simplification may remove granularity users depend on.**
   Some users may have per-module verbosity overrides in their environment.
   Mitigation: keep legacy variable names as aliases that map to the new
   model during transition; document the mapping.

4. **Performance regression during consolidation.** Changing logging
   internals could introduce new overhead if not careful. Mitigation:
   benchmark per-call cost before and after; maintain the boot-time
   suppression optimizations from the performance renewal.

5. **Test coverage is thin.** `lo1_test.sh` is broken, and most other logging
   tests are existence checks only. Changes may introduce regressions that
   existing tests cannot catch. Mitigation: write proper tests first (or in
   parallel) before modifying implementation.

6. **Scope creep into `tme` internals.** Timer measurement and hierarchy
   tracking in `tme` are complex; touching output formatting may pull in
   changes to internal state management. Mitigation: keep `tme` internal
   data structures unchanged; only modify rendering/output paths.

## Next Step

Triage this plan: review the identified problems and scope, decide whether
to proceed as-is or adjust scope, then move to `queue/` or `active/` with
a phased execution plan. The recommended first implementation phase is fixing
the broken `lo1_test.sh` and `err_process` parameter misuse (low-risk, high
information-value), followed by a design phase for the consolidated logging
primitive.
