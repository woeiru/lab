# Logging Architectural Restructure

- Status: inbox
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-03
- Links: lib/core/lo1, lib/core/err, lib/core/tme, lib/core/ver, lib/gen/aux, lib/core/col, bin/ini, cfg/core/ric, doc/arc/07-logging-and-error-handling.md, doc/pro/inbox/20260303-0336_logging-system-renewal-plan.md, doc/pro/inbox/20260303-2245_logging-performance-renewal-plan.md

## Goal

Consolidate five independent logging subsystems (`ini_log`, `ver_log`,
`lo1_log`, `err_process`, `aux_log`) into a coherent two-layer architecture
with a single shared log writer, a unified verbosity model, and consistent
file logging hygiene. This is the second of three logging renewal projects:
the performance renewal made logging fast; this project makes it simple.

The bootstrapper architectural restructure
(`doc/pro/completed/20260302-0345_bootstrap-architectural-restructure-plan`)
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

**Design required:** Yes. A Design Decision Record is needed for the
unified log writer interface and the verbosity model simplification. Phase 1
is design-only (no code changes).

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

### Phase 1 -- Design (no code changes) (target: approved DDR)

1. Produce a Design Decision Record (DDR) for the shared log writer:
   - Interface specification: `_log_write <level> <message> <file> [component]`
   - Constraints: must work at bootstrap time (before `aux` is loaded),
     must handle ANSI stripping, must use Bash builtins for timestamp
   - Alternatives considered: (a) single function, (b) two functions
     (bootstrap writer + runtime writer), (c) keep five separate writers
   - Chosen approach with rationale

2. Produce a DDR for the unified verbosity model:
   - Level specification: `silent < error < normal < verbose < debug`
   - Mapping table from legacy variables to new levels
   - Backward compatibility strategy (legacy vars as aliases)
   - Interaction with `LAB_BOOTSTRAP_VERBOSITY`

3. Document the test impact inventory: which existing tests exercise
   logging behavior and what needs to change.

4. Document the call-site inventory: all locations that call each of the
   five logging functions, grouped by subsystem.

### Phase 2 -- Shared writer and test fixes (target: single writer, green tests)

1. Implement `_log_write` as an internal function in `lib/core/lo1`
   (or a new `lib/core/log` if cleaner). It must:
   - Accept level, message, target file, optional component
   - Format timestamp via `printf '%(%Y-%m-%d %H:%M:%S)T' -1`
   - Strip ANSI codes for file output (using `${var//\033\[*([0-9;])m/}`)
   - Append to target file with consistent format
   - Route terminal output to stderr only
   - Check verbosity level before terminal emission

2. Rewrite `lo1_test.sh` to test actual `lo1` API:
   - `lo1_log` with correct calling convention
   - `lo1_setlog on/off` state management
   - `lo1_init_logger` / `lo1_cleanup_logger` lifecycle
   - `lo1_log_message` with component/level
   - Verify file output does not contain ANSI codes

3. Fix `err_process` parameter swap in `command_not_found_handle`
   (`lib/core/err:397-410`).

4. Remove unreliable aliases from `lo1`. Replace with thin function
   wrappers if needed.

5. Verify: `bash -n` all changed files. Run `val/core/modules/lo1_test.sh`,
   `val/core/modules/err_test.sh`. Run `./val/run_all_tests.sh core`.

### Phase 3 -- Verbosity unification (target: single LAB_LOG_LEVEL controls all output)

1. Define `LAB_LOG_LEVEL` in `cfg/core/ric` with default `normal`.

2. Create verbosity check function `_log_level_permits <required_level>`
   that compares against `LAB_LOG_LEVEL`:
   - `silent`: nothing to terminal
   - `error`: only errors
   - `normal`: errors + warnings + info
   - `verbose`: all of above + verbose/progress messages
   - `debug`: everything including debug traces

3. Wire `lo1_log` terminal output through `_log_level_permits`.

4. Wire `aux_log` terminal output through `_log_level_permits`. Fix the
   master verbosity bypass.

5. Wire `lo1_log_message` terminal output through `_log_level_permits`.

6. Wire `ver_log` terminal output through `_log_level_permits`.

7. Wire `ini_log` terminal output through `_log_level_permits` (respecting
   `LAB_BOOTSTRAP_VERBOSITY` interaction: bootstrap verbosity takes
   precedence during boot, `LAB_LOG_LEVEL` takes over post-boot).

8. Add backward compatibility mappings in `cfg/core/ric`:
   - `MASTER_TERMINAL_VERBOSITY=off` → `LAB_LOG_LEVEL=silent`
   - Individual `*_TERMINAL_VERBOSITY` vars map to per-subsystem overrides
   - Document the mapping table

9. Verify: `./val/run_all_tests.sh` full suite.

### Phase 4 -- File hygiene and rotation (target: clean logs, bounded growth)

1. Route all subsystems through `_log_write` for file output:
   - `lo1_log` → `_log_write` for `lo1.log`
   - `err_process` → `_log_write` for `err.log`
   - `ver_log` → `_log_write` for `ver.log`
   - `ini_log` → `_log_write` for `ini.log`
   - `aux_log` → `_log_write` for `aux.log` (human format)

2. Standardize all file timestamps to `YYYY-MM-DD HH:MM:SS`.

3. Fix terminal routing: all terminal log output goes to stderr.
   Remove stdout routing from `lo1_log` and `err_process`.

4. Add size-based rotation in `_log_write`: when file exceeds
   `LAB_LOG_MAX_SIZE` (default 10MB), move to `.1` and truncate.
   Only keep one rotation (`.1`). Lightweight check: stat file size
   every N writes (not every write).

5. Verify: file output contains no ANSI codes (`grep -P '\033\[' .log/*.log`
   returns empty). Timestamps are consistent across all log files.

6. Verify: `./val/run_all_tests.sh` full suite.
7. Verify: `./val/core/log_contract_test.sh` passes.

### Phase 5 -- Documentation and closure (target: updated docs, green suite)

1. Update `doc/arc/07-logging-and-error-handling.md` to reflect:
   - New two-layer architecture (shared writer + context front-ends)
   - Unified verbosity model (`LAB_LOG_LEVEL`)
   - File logging hygiene guarantees
   - Rotation behavior

2. Regenerate reference docs: `./utl/doc/run_all_doc.sh`.

3. Update `cfg/log/README.md` with new verbosity model documentation.

4. Run full test suite: `./val/run_all_tests.sh`.
5. Run workflow checker: `bash doc/pro/check-workflow.sh`.

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

Depends on: `20260303-2245_logging-performance-renewal-plan`. Execute
the performance renewal first to establish optimized primitives, then
triage this plan for design and implementation. Phase 1 (design) can
begin as soon as the performance renewal is complete.
