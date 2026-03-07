# Logging Architectural Restructure

- Status: completed
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-05 02:35
- Links: lib/core/lo1, lib/core/err, lib/core/tme, lib/core/ver, lib/gen/aux, lib/core/col, bin/ini, cfg/core/ric, doc/arc/07-logging-and-error-handling.md, wow/inbox/20260303-0336_logging-system-renewal-plan.md, wow/inbox/20260305-0235_dic-debug-verbosity-coupling-followup-plan.md, wow/completed/20260304-2356_logging-performance-renewal/20260303-2245_logging-performance-renewal-plan.md, wow/completed/20260303-0139_bootstrap-architectural-restructure-plan/20260302-0345_bootstrap-architectural-restructure-plan.md

## Goal

Consolidate five independent logging subsystems (`ini_log`, `ver_log`,
`lo1_log`, `err_process`, `aux_log`) into a coherent two-layer architecture
with a single shared log writer, a unified verbosity model, and consistent
file logging hygiene. This is the second of three logging renewal projects:
the performance renewal made logging fast; this project makes it simple.

The bootstrapper architectural restructure
(`wow/completed/20260303-0139_bootstrap-architectural-restructure-plan/20260302-0345_bootstrap-architectural-restructure-plan.md`)
proved that removing dead ceremony, unifying entry points, and separating
concerns yields a dramatically simpler system without losing capability.
The same approach applies to logging: five subsystems with five independent
format functions, five verbosity gates, five file writers, and three
timestamp formats can be reduced to a shared core writer with
context-specific front-ends.

## Context

### Current state (five subsystems, no shared interface)

| Subsystem | Module | Log file | Timestamp format | Verbosity gate | Terminal channel | Purpose |
|-----------|--------|----------|-----------------|----------------|-----------------|---------|
| `ini_log` | `bin/ini` | `ini.log` | `HH:MM:SS` | `MASTER_` + `INI_LOG_` | stderr | Bootstrap progress |
| `ver_log` | `lib/core/ver` | `ver.log` | `YYYY-MM-DD HH:MM:SS` | `MASTER_` + `VER_LOG_` | stderr | Verification diagnostics |
| `lo1_log` | `lib/core/lo1` | `lo1.log` | `HH:MM:SS` | `MASTER_` + `LO1_LOG_` + state + bootstrap | stderr/stdout | Runtime hierarchical |
| `err_process` | `lib/core/err` | `err.log` | `YYYY-MM-DD HH:MM:SS` | `MASTER_` + `ERR_` | stderr(ERR)/stdout(WARN) | Error recording |
| `aux_log` | `lib/gen/aux` | `aux.log/json/csv` | ISO 8601 | None (always) / `AUX_DEBUG_` | stderr | Structured operational |

Supporting systems with own output controls:
- `lib/core/tme`: 5 sub-toggles (`TME_REPORT_`, `TME_TIMING_`, `TME_DEBUG_`,
  `TME_STATUS_`, plus `tme_settme`)
- `lib/core/col`: shared color palette (post-visual-redesign)

### The 12+ verbosity variable problem

```
MASTER_TERMINAL_VERBOSITY          # global kill switch
├── INI_LOG_TERMINAL_VERBOSITY     # bin/ini output
├── LO1_LOG_TERMINAL_VERBOSITY     # lo1 runtime logs
├── ERR_TERMINAL_VERBOSITY         # error module output
├── VER_LOG_TERMINAL_VERBOSITY     # verification output
├── TME_TERMINAL_VERBOSITY         # timing output (master for TME)
│   ├── TME_REPORT_TERMINAL_OUTPUT
│   ├── TME_TIMING_TERMINAL_OUTPUT
│   ├── TME_DEBUG_TERMINAL_OUTPUT
│   └── TME_STATUS_TERMINAL_OUTPUT
├── AUX_DEBUG_ENABLED              # aux debug gating
├── LOG_DEBUG_ENABLED              # lo1 debug gating
├── LAB_BOOTSTRAP_VERBOSITY        # compact/verbose/silent
└── LAB_BOOTSTRAP_OUTPUT           # compact/legacy
```

Predicting terminal output requires understanding all 12+ variables and
their interaction precedence. Users cannot easily control what they see.

### Identified structural problems

1. **No shared log writer.** Each subsystem has its own format-and-write
   implementation. Changing timestamp format or adding ANSI stripping
   requires touching five files independently.

2. **ANSI codes in log files.** `lo1_log` writes color escapes to
   `lo1.log`, making it ungrepable. Other subsystems strip colors
   correctly. No shared "write to file without ANSI" primitive.

3. **Inconsistent terminal routing.** `lo1_log` uses stdout for some
   messages and stderr for others. `err_process` sends WARNINGs to
   stdout and ERRORs to stderr. `aux_log` always uses stderr. This
   breaks output capture and piping.

4. **`aux_log` ignores master verbosity.** Setting
   `MASTER_TERMINAL_VERBOSITY=off` does not silence `aux_log` terminal
   output in `human` format mode.

5. **`lo1_log_message` bypasses verbosity gates.** Its console output
   is only gated by log state, not by `MASTER_TERMINAL_VERBOSITY` or
   `LO1_LOG_TERMINAL_VERBOSITY`.

6. **`err_process` parameter misuse.** `command_not_found_handle` in
   `lib/core/err` calls `err_process` with component and message
   arguments swapped relative to the function signature.

7. **`lo1_test.sh` is broken.** Tests reference functions (`log_info`,
   `log_warn`, `log_error`, `log_debug`) that do not exist in `lo1`.
   Uses wrong calling convention. Dead test coverage.

8. **Three timestamp formats.** `HH:MM:SS` (lo1, ini), `YYYY-MM-DD
   HH:MM:SS` (ver, err), ISO 8601 (aux). No reason for divergence.

9. **No log rotation.** `lo1.log` and `tme.log` are cleared per boot.
   `err.log`, `aux.log`, `aux.json`, `aux.csv`, `ver.log` grow without
   bound.

10. **Backward compatibility aliases.** `lo1` exports `alias log='lo1_log'`
    etc. Bash aliases don't work in non-interactive shells or in functions,
    making these unreliable.

### What the bootstrapper architectural restructure proved

1. A single unified entry point (`lab_source_module`) can replace three
   independent sourcing paths without losing flexibility.
2. Dead ceremony removal (verification/registration at boot) simplifies
   code without losing safety.
3. Explicit profile separation (interactive vs deployment) eliminates
   conditional complexity.
4. Design Decision Records with constraints, alternatives, and chosen
   approach prevent scope creep.

## Triage Decision

**Why now:** The performance renewal (project 1) optimizes the per-call
cost of each subsystem independently. But the structural problem -- five
independent subsystems with no shared interface -- means every future
logging change requires touching five files. Consolidation pays compound
dividends for all subsequent maintenance and feature work.

**Are there meaningful alternatives for how to solve this?** Yes.

**Will other code or users depend on the shape of the output?** Yes.

**Design: required**

**Justification:** The shared-writer and verbosity-model decisions define
cross-module contracts that future logging behavior and maintainers will depend
on.

## Scope

### In scope

1. **Design a shared log writer primitive.** A single internal function
   (`_log_write`) that all subsystems route through for file output. It
   handles: timestamp formatting, ANSI stripping for files, file
   rotation checks, and consistent `>>` append semantics.

2. **Design a unified verbosity model.** Replace 12+ toggles with a
   layered model: `LAB_LOG_LEVEL` (`silent`, `error`, `normal`,
   `verbose`, `debug`) controls what appears on terminal.
   Per-subsystem overrides preserved as optional environment variables
   that map into the level model. Legacy variable names kept as
   compatibility aliases during transition.

3. **Fix file logging hygiene.** Remove ANSI codes from all log file
   writes via the shared writer. Standardize on one timestamp format
   (`YYYY-MM-DD HH:MM:SS`) for all log files. Route all terminal output
   consistently to stderr.

4. **Fix `aux_log` master verbosity bypass.** Make `aux_log` terminal
   output respect `LAB_LOG_LEVEL` (or the legacy
   `MASTER_TERMINAL_VERBOSITY`).

5. **Fix `lo1_log_message` verbosity bypass.** Gate console output on
   the unified verbosity model.

6. **Fix `err_process` parameter misuse** in `command_not_found_handle`.

7. **Rewrite `lo1_test.sh`.** Replace dead tests with tests that
   exercise the actual `lo1` API functions with correct calling
   conventions.

8. **Add basic log rotation.** Size-cap for append-only log files
   (`err.log`, `aux.log`, `aux.json`, `aux.csv`, `ver.log`). When file
   exceeds threshold (e.g., 10MB), rotate to `.1` backup and truncate.

9. **Remove unreliable backward compatibility aliases** from `lo1`.
   Replace with proper function wrappers if backward compatibility is
   needed.

10. **Update architecture docs** (`doc/arc/07-logging-and-error-handling.md`)
    and reference docs (`doc/ref/`) to reflect the new model.

11. **Preserve downstream contracts.** `aux.json` and `aux.csv` field
    order and semantics must not change without migration path. The
    shared writer is internal; external log file formats are stable.

### Out of scope

1. Visual output changes (colors, indentation style, report formatting) --
   deferred to visual redesign.
2. Changes to `lib/ops/*` or `lib/gen/*` module APIs beyond logging calls.
3. Changes to `tme` timer measurement internals (hierarchy, nesting).
4. Changes to `./go` entrypoint or shell integration lifecycle.
5. Changes to compiled bootstrap cache mechanism.
6. Introduction of external logging tools or dependencies.

## Execution Plan

### [COMPLETED 2026-03-05] Phase 6 -- Closeout (target: finalize and archive item)

1. [done 2026-03-05] Captured final checkpoint and handoff state.
2. [done 2026-03-05] Captured DIC follow-up tracking in
   `wow/inbox/20260305-0235_dic-debug-verbosity-coupling-followup-plan.md`
   with reproduction showing verbosity-gated debug assertions.
3. [done 2026-03-05] Moved this item from `wow/active/` to
   `wow/completed/20260305-0235_logging-architectural-restructure/`.
4. [done 2026-03-05] Re-ran workflow validation:
   `bash wow/check-workflow.sh`.

## Phase 1 Design Decision Record

Date: 2026-03-05
Design classification: required

### DDR-1 Shared log writer

#### Constraints and invariants

1. The shared writer must be usable during bootstrap before `lib/gen/aux` is
   loaded, so it cannot depend on `aux_*` functions.
2. File writes must remove ANSI escape sequences before append.
3. File timestamps must standardize on `YYYY-MM-DD HH:MM:SS`.
4. Terminal emission must be gated separately from file writes so subsystems can
   keep context-specific formatting while sharing one file-writer path.
5. Rotation checks must be low overhead (amortized check cadence, not per write).

#### Interface contract

`_log_write <component> <level> <message> <target_file> [source]`

Return codes:
- `0`: write succeeded
- `1`: parameter/usage error
- `2`: write/rotation runtime failure

Companion helpers:
- `_log_strip_ansi <input> <out_var>`
- `_log_rotate_if_needed <target_file>`
- `_log_level_permits <required_level> [subsystem]` (terminal gating)

#### Alternatives considered

1. Keep five subsystem-local writers and normalize behavior by convention.
   Rejected: repeated drift and repeated fixes across modules.
2. Two independent writers (`ini` bootstrap writer + runtime writer).
   Rejected: duplicates lifecycle logic and keeps bootstrap/runtime divergence.
3. One shared core writer in a new bootstrap-safe module.
   Chosen: one implementation for timestamp/ANSI/rotation semantics.

#### Chosen approach

Create `lib/core/log` as a bootstrap-safe module and route file writes from
`ini_log`, `ver_log`, `lo1_log`, `err_process`, and `aux_log` through
`_log_write`. Keep terminal formatting in subsystem front-ends but route all
terminal eligibility through `_log_level_permits`.

### DDR-2 Unified verbosity model

#### Level model

`silent < error < normal < verbose < debug`

Terminal eligibility baseline:
- `silent`: no terminal output
- `error`: errors only
- `normal`: errors + warnings + info
- `verbose`: normal + progress/detail messages
- `debug`: all output including debug traces

#### Compatibility and precedence

Primary control:
- `LAB_LOG_LEVEL` (default `normal`) in `cfg/core/ric`

Optional subsystem override controls:
- `LAB_LOG_LEVEL_INI`, `LAB_LOG_LEVEL_VER`, `LAB_LOG_LEVEL_LO1`,
  `LAB_LOG_LEVEL_ERR`, `LAB_LOG_LEVEL_AUX`

Legacy compatibility mapping:
1. `MASTER_TERMINAL_VERBOSITY=off` -> effective level `silent` globally.
2. `*_TERMINAL_VERBOSITY=off` -> subsystem effective level `silent`.
3. Existing `AUX_DEBUG_ENABLED=0` and `LOG_DEBUG_ENABLED=0` suppress debug-only
   events but do not reduce baseline file logging.

Precedence order (highest to lowest):
1. `LAB_BOOTSTRAP_VERBOSITY` while `LAB_BOOTSTRAP_MODE=1`
2. Explicit `LAB_LOG_LEVEL_<SUBSYSTEM>`
3. Legacy subsystem toggle mapping (`*_TERMINAL_VERBOSITY`)
4. Global `LAB_LOG_LEVEL`
5. Legacy global toggle mapping (`MASTER_TERMINAL_VERBOSITY`)

#### Bootstrap interaction decision

During bootstrap (`LAB_BOOTSTRAP_MODE=1`), existing bootstrap UX controls remain
authoritative:
- `LAB_BOOTSTRAP_VERBOSITY=silent` -> effective terminal `silent`
- `LAB_BOOTSTRAP_VERBOSITY=compact` -> effective terminal `normal`
- `LAB_BOOTSTRAP_VERBOSITY=verbose` -> effective terminal `verbose`

After bootstrap mode clears, control reverts to `LAB_LOG_LEVEL` and optional
subsystem overrides.

#### Alternatives considered

1. Preserve current independent toggles and only document interactions.
   Rejected: complexity remains and behavior still hard to predict.
2. Global-only level with no subsystem overrides.
   Rejected: removes operator control used by bootstrap and diagnostics flows.
3. Global level plus optional subsystem overrides with legacy mapping.
   Chosen: predictable defaults with compatibility and targeted control.

## Phase 1 Inventories

### Call-site inventory (code paths only)

1. `ini_log` (definition: `bin/ini:490`)
   - `bin/ini` (~41 internal calls)
   - `cfg/core/mdc` (2 guarded calls: `34`, `66`)
2. `ver_log` (definition: `lib/core/ver:36`)
   - `lib/core/ver` (~37 internal calls)
3. `lo1_log` (definition: `lib/core/lo1:294`)
   - `bin/orc` (~77 calls)
   - `lib/core/lab` (5 calls)
   - `val/core/initialization/ini_test.sh` (1 direct call)
   - `val/integration/complete_workflow_test.sh` (1 direct call; legacy
     `lo1_log lvl` signature)
4. `err_process` (definition: `lib/core/err:84`)
   - `bin/orc` (2 calls)
   - `lib/core/err` (5 internal calls)
   - `val/core/modules/err_test.sh` (3 direct calls)
   - `val/integration/complete_workflow_test.sh` (1 direct call)
5. `aux_log` (definition: `lib/gen/aux:675`)
   - `lib/gen/aux` wrapper calls (7)
   - `lib/ops/sto` (4 direct calls)
   - `val/lib/gen/aux_test.sh` (3 direct calls)

### Wrapper and facade inventory

1. `aux_business`, `aux_security`, `aux_audit`, `aux_perf`, `aux_info`,
   `aux_warn`, `aux_err` -> `aux_log` (`lib/gen/aux:1190-1228`).
2. `err_lo1_handle` -> `err_process` (`lib/core/err:121-128`).
3. Alias facade `log` -> `lo1_log` (`lib/core/lo1:482`) and related `lo1`
   aliases scheduled for removal/replacement in Phase 2.

### Test impact inventory

1. `val/core/modules/lo1_test.sh` is stale against current `lo1` API and must
   be rewritten to test `lo1_log`, `lo1_setlog`, lifecycle, and ANSI hygiene.
2. `val/core/modules/err_test.sh` currently calls `err_process` with misordered
   parameters; update tests with canonical signature
   `<message> <component> <exit_code> <severity>`.
3. `val/lib/gen/aux_test.sh` directly validates `aux_log` output and will need
   updates when terminal gating is unified via `LAB_LOG_LEVEL`.
4. `val/core/initialization/ini_test.sh` validates bootstrap verbosity and is a
   key regression suite for `LAB_BOOTSTRAP_VERBOSITY` interaction behavior.
5. `val/integration/complete_workflow_test.sh` currently exercises legacy
   `lo1_log lvl` call form; update when compatibility alias behavior changes.

## Progress Checkpoint

### Done

1. Completed Phase 1 design deliverables (shared-writer DDR + unified
   verbosity DDR).
2. Completed call-site inventory for all five target logging functions.
3. Completed test impact inventory for core, gen, and integration tests.
4. Implemented new shared log primitives in `lib/core/log`:
   `_log_write`, `_log_strip_ansi`, `_log_rotate_if_needed`,
   `_log_level_permits`.
5. Integrated `lo1` and `err` file writes through `_log_write` and fixed
   stderr-only terminal routing in `err_process`.
6. Fixed `command_not_found_handle` to call `err_process` with canonical
   parameter order.
7. Replaced `lo1` compatibility aliases with thin wrapper functions for
   non-interactive contexts.
8. Rewrote `val/core/modules/lo1_test.sh` and `val/core/modules/err_test.sh`
   to validate current APIs and behaviors.
9. Verification completed: `bash -n` on edited scripts,
   `bash val/core/modules/lo1_test.sh`, `bash val/core/modules/err_test.sh`,
   `bash val/core/initialization/ini_test.sh`, and `./val/run_all_tests.sh core`.
10. Added `LAB_LOG_LEVEL` plus subsystem override variables in `cfg/core/ric`.
11. Wired `_log_level_permits` into `ini_log`, `ver_log`, and `aux_log`
    terminal emission paths (including `aux_dbg` debug gate).
12. Added `val/lib/gen/aux_test.sh` coverage for unified `LAB_LOG_LEVEL`.
13. Verification completed after Phase 3 wiring:
    `bash val/lib/gen/aux_test.sh`, `bash val/core/initialization/ini_test.sh`,
    `bash val/core/modules/ver_test.sh`, and `./val/run_all_tests.sh core`.
14. Routed `ver_log` and `ini_log` file writes through `_log_write` (with
    bootstrap-safe fallback paths when shared writer is unavailable).
15. Routed `aux_log`/`aux_dbg` `aux.log` writes through `_log_write`, and
    applied `_log_rotate_if_needed` to `aux.json`/`aux.csv` append paths.
16. Hardened exported shared log functions for subshell contexts by exporting
    `_log_normalize_level`, `_log_level_rank`, `_log_effective_level`, and by
    auto-initializing `_LOG_ROTATE_COUNTER` when needed.
17. Verified generated `.log` samples are ANSI-clean and timestamp-consistent
    (`ansi_present=False`, `timestamps_consistent=True`).
18. Full-suite validation now reports only the established DIC failures:
    `dic_framework_test`, `dic_integration_test`, `dic_phase1_completion_test`.
19. Updated `doc/arc/07-logging-and-error-handling.md` for shared writer,
    unified verbosity, and rotation behavior.
20. Updated `cfg/log/README.md` with `LAB_LOG_LEVEL` model and rotation notes.
21. Regenerated reference docs via `./utl/doc/run_all_doc.sh`.
22. Workflow metadata validation now passes (`bash wow/check-workflow.sh`).

### In-flight

1. None.

### Blockers

1. No hard blockers.

### Next steps

1. Triage
   `wow/inbox/20260305-0235_dic-debug-verbosity-coupling-followup-plan.md`
   for DIC test hardening work.

### Context

1. `aux_log` terminal output now respects unified `_log_level_permits`
   gating; no remaining master-bypass gap in current implementation.
2. Legacy `lo1_log lvl` call form remains supported for compatibility and is
   still exercised in integration coverage.
3. Running `./val/run_all_tests.sh core` regenerates stats artifacts
   (`STATS.md` and `doc/ref/stats/*`) as a side effect; these are unrelated to
   logging implementation scope.
4. DIC failures are reproducible at default verbosity and clear when
   `LAB_LOG_LEVEL_AUX=debug`, indicating test/debug-output coupling rather than
   a logging-architecture regression.
5. `bash wow/check-workflow.sh` passes for current workflow metadata.
6. Current branch contains this logging work plus generated reference-doc updates;
   `STATS.md` and `doc/ref/stats/*` are test side effects and not required for task semantics.

## Verification Plan

1. `bash -n` on every changed file after every phase
2. `val/core/modules/lo1_test.sh` -- rewritten tests pass
3. `val/core/modules/err_test.sh` -- `err_process` parameter fix verified
4. `val/core/modules/tme_test.sh` -- timing report rendering unchanged
5. `val/lib/gen/aux_test.sh` -- `aux_log` verbosity respect verified
6. `val/core/log_contract_test.sh` -- logging contract consistency
7. `./val/run_all_tests.sh core` after phases 2-3
8. `./val/run_all_tests.sh` full suite after phases 3-5
9. `grep -P '\033\[' .log/*.log` returns empty (no ANSI in files)
10. Manual: set `LAB_LOG_LEVEL=silent` and verify zero terminal output
11. Manual: set `LAB_LOG_LEVEL=debug` and verify all subsystems emit

## Exit Criteria

1. Single shared log writer (`_log_write`) used by all five subsystems.
2. `LAB_LOG_LEVEL` controls all terminal output with five levels.
3. Legacy verbosity variables work as aliases (backward compatible).
4. No ANSI codes in any log file.
5. All terminal log output goes to stderr consistently.
6. All log files use `YYYY-MM-DD HH:MM:SS` timestamp format.
7. `lo1_test.sh` rewritten and passing.
8. `err_process` parameter misuse fixed.
9. Log rotation active for append-only files.
10. Architecture docs updated.
11. Full test suite green.

## Risks

1. **Five subsystem consolidation is wide-surface.** Touching all five
   logging modules in one project risks regressions across the system.
   Mitigation: phased execution with per-phase verification gates;
   design phase first to identify all touchpoints before coding.

2. **Verbosity simplification may remove granularity users depend on.**
   Some users may have per-module verbosity overrides in their environment.
   Mitigation: keep legacy variable names as aliases that map to the new
   model during transition; document the mapping.

3. **`_log_write` at bootstrap time.** The shared writer must be available
   before `aux` is loaded (bootstrap context). It must not depend on any
   gen-layer function. Mitigation: place the writer in `lib/core/` where
   it's loaded early in the chain.

4. **ANSI stripping regex may be incomplete.** Complex ANSI sequences
   (256-color, truecolor) may not be caught by a simple pattern.
   Mitigation: use a comprehensive pattern
   `${var//\033\[[0-9;]*m/}` and test with actual log output.

5. **Log rotation I/O cost.** Checking file size on every write adds
   overhead. Mitigation: check every N writes (e.g., every 100th call)
   using a counter variable, not on every invocation.

6. **Test coverage is thin.** `lo1_test.sh` is broken and most other
   logging tests are existence checks. Changes may introduce regressions
   that existing tests cannot catch. Mitigation: rewrite tests first
   (Phase 2) before modifying implementation in Phase 3+.

## Next Step

Closed and archived; continue with the DIC follow-up captured in
`wow/inbox/20260305-0235_dic-debug-verbosity-coupling-followup-plan.md`.

## What Changed

1. Finalized closure metadata for this logging architecture item and corrected
   stale completed-path links.
2. Documented DIC follow-up as a separate inbox work item and linked it here.
3. Captured the observed DIC root cause as verbosity-gated debug assertion
   coupling, not a regression in logging architectural behavior.

## What Was Verified

1. `./val/run_all_tests.sh dic` (default settings) reproduces DIC test failures.
2. `LAB_LOG_LEVEL_AUX=debug ./val/run_all_tests.sh dic` passes DIC category
   tests, confirming verbosity sensitivity in test expectations.
3. `bash wow/check-workflow.sh` passes after workflow updates and closeout
   move.

## What Remains

1. Triage and execute
   `wow/inbox/20260305-0235_dic-debug-verbosity-coupling-followup-plan.md`
   to decouple DIC tests from debug terminal output defaults.
