# Logging Visual Output Redesign

- Status: queue
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-04 02:37
- Links: lib/core/lo1, lib/core/err, lib/core/tme, lib/core/col, lib/gen/aux, bin/ini, cfg/core/ric, doc/arc/07-logging-and-error-handling.md, doc/pro/inbox/20260303-0336_logging-system-renewal-plan.md, doc/pro/queue/20260303-2245_logging-performance-renewal-plan.md, doc/pro/queue/20260303-2246_logging-architectural-restructure-plan.md, doc/pro/completed/20260303-0220_bootstrap-visual-output-redesign-plan/20260303-0220_bootstrap-visual-output-redesign-plan.md

## Goal

Redesign the terminal visual presentation of all logging output to be
compact, consistent, and information-dense. This is the third and final
logging renewal project: the performance renewal made logging fast, the
architectural restructure made it simple, this project makes it beautiful.

The bootstrap visual output redesign
(`doc/pro/completed/20260303-0220_bootstrap-visual-output-redesign-plan`)
proved that compact, semantic-colored output dramatically improves the
user experience. That project only covered bootstrap-time output
(`bin/ini` compact mode, `tme` report, `err` report). This project
extends the same visual language to all runtime logging output: `lo1`
hierarchical logs, `aux` operational messages, `ver` diagnostics, and
the unified log level indicators introduced by the architectural
restructure.

## Context

### Current visual state (post-bootstrap redesign)

The bootstrap visual redesign established:
- Semantic color palette in `lib/core/col`: info=Blue, success=Green,
  warn=Yellow, error=DarkRed, critical=BrightRed, etc.
- Viridis depth-gradient (10 levels) for hierarchical log indentation
- Compact bootstrap spinner with header/progress/summary format
- Compact `tme` timing report with `col_get_depth_color`
- Compact `err` error report with `col_get_semantic`

What was NOT covered:
- Runtime `lo1_log` output still uses tree indentation with `└─` characters
  at arbitrary depths, producing wide, hard-to-scan output
- `aux_log` human-format output uses its own color lookup (`aux_get_log_color`)
  rather than the centralized `col_get_semantic`
- `ver_log` terminal output has no color or formatting
- No consistent level indicators across subsystems (some use text labels
  like `[ERROR]`, some use icons like `✗`, some use nothing)
- No density control: verbose output fills the screen, compact mode only
  applies to bootstrap phase

### Visual problems to solve

1. **`lo1_log` tree indentation is noisy.** At depth 5+, the `└─` tree
   characters consume 30+ columns before the message begins. During
   normal operation (not debugging), this depth information is noise.
   Users need to see the message, not the call graph.

2. **Inconsistent level indicators.** Bootstrap compact mode uses `✓`/`✗`/`!`.
   `err_print_report` uses `✓`/`✗`/`!` in compact mode. `tme_print_timing_report`
   uses `✓`/`✗`/`⏳`/`?`. `aux_log` uses text labels `[INFO]`/`[WARN]`/
   `[ERROR]`. `lo1_log` uses no level indicator at all. `ver_log` uses
   text labels `[INFO]`/`[WARN]`/`[ERROR]`.

3. **No runtime compact mode.** The `LAB_BOOTSTRAP_VERBOSITY=compact`
   setting only affects the bootstrap phase. Post-boot, output reverts to
   verbose line-by-line rendering. There is no way to get compact,
   information-dense runtime output.

4. **Color system fragmentation.** `aux_get_log_color` in `lib/gen/aux:644`
   duplicates semantic color resolution that `col_get_semantic` already
   provides. The mapping is slightly different (aux defines its own
   `business`/`security`/`audit`/`perf` colors) creating visual
   inconsistency between core and operational log output.

5. **No visual hierarchy for log levels.** All log levels render at the
   same visual weight. A debug trace looks the same as an error message
   except for the text label. Color-coding is inconsistent: some
   subsystems colorize the entire line, others colorize only the label,
   others don't colorize at all.

6. **Timing report header style.** The `tme_print_timing_report` header
   uses `═══` box-drawing characters. The `err_print_report` uses `━━━`
   in legacy mode and minimal dividers in compact mode. No shared
   section header style.

### Design language established by bootstrap visual redesign

The bootstrap redesign established these visual conventions (from
`doc/pro/completed/20260303-0220_bootstrap-visual-output-redesign-plan`):

- **Compact is default.** Dense, single-section output preferred over
  multi-line verbose output.
- **Semantic colors over structural colors.** Color communicates meaning
  (error=red, success=green), not structure (depth=gradient).
- **Status icons are single characters.** `✓` (success), `✗` (failure),
  `!` (warning), `⏳` (in-progress), `?` (unknown).
- **Feature flag for transition.** New rendering is opt-in first, then
  flipped to default, with legacy preserved as fallback.

## Triage Decision

**Why now:** After the performance renewal (project 1) makes logging fast
and the architectural restructure (project 2) makes it simple, the visual
output is the remaining UX debt. The unified verbosity model from project 2
provides the infrastructure to implement visual modes cleanly. Without
project 2's `LAB_LOG_LEVEL`, there is no coherent control point for
rendering decisions.

**Are there meaningful alternatives for how to solve this?** Yes.

**Will other code or users depend on the shape of the output?** Yes.

**Design: required**

**Justification:** The visual specification becomes a user-facing rendering
contract across logging subsystems, so option selection and output shape are
design-critical.

## Scope

### In scope

1. **Design a unified visual specification** for all logging terminal output
   covering: level indicator glyphs, color application rules, line format
   template, density modes (compact/verbose), section headers for reports.

2. **Implement consistent level indicators** across all subsystems:
   a unified glyph set and color for each log level, applied at the
   `_log_write` terminal rendering layer.

3. **Implement runtime compact mode.** Extend density control from
   bootstrap-only to full session via `LAB_LOG_LEVEL` and a new
   `LAB_LOG_FORMAT` variable (`compact`/`verbose`). In compact mode:
   single-line messages, abbreviated timestamps, minimal indentation.
   In verbose mode: full timestamps, tree indentation, debug context.

4. **Unify color application.** Replace `aux_get_log_color` with
   `col_get_semantic`. Extend `col_get_semantic` if needed to cover
   `business`/`security`/`audit`/`perf` semantic types. All color
   lookups go through `lib/core/col`.

5. **Redesign `lo1_log` runtime rendering.** Compact mode: `[HH:MM:SS]
   <glyph> <message>` (no tree indentation, depth expressed only via
   Viridis color). Verbose mode: current tree-indented format preserved
   for debugging.

6. **Standardize section headers** for `tme_print_timing_report` and
   `err_print_report`. Shared header style using `col_get_semantic`
   for consistent visual framing.

7. **Feature flag for transition.** `LAB_LOG_FORMAT=compact|verbose`
   (default: `compact` after validation phase). Legacy tree rendering
   preserved as `verbose` fallback.

8. **Update visual examples in documentation.**

### Out of scope

1. Changes to log file formats (files are never colorized post-project-2).
2. Changes to `tme` timer measurement internals.
3. Changes to `aux.json`/`aux.csv` structured output formats.
4. Changes to DIC argument injection.
5. Changes to `./go` entrypoint.
6. Introduction of TUI frameworks or ncurses dependencies.
7. Interactive log viewers or log tailing tools.

## Execution Plan

### Phase 1 -- Visual specification (no code) (target: approved spec)

1. **Level indicator glyph table.** Define the canonical glyph and color
   for each log level:

   | Level | Glyph | Color (semantic) | Example |
   |-------|-------|------------------|---------|
   | debug | `·` | `dim`/grey | `· Loading module ops/gpu` |
   | info | `›` | `info`/blue | `› Component initialized` |
   | success | `✓` | `success`/green | `✓ All modules loaded` |
   | warn | `!` | `warn`/yellow | `! Deprecated function called` |
   | error | `✗` | `error`/red | `✗ Module failed to load` |
   | critical | `✗` | `critical`/bright red | `✗ Fatal: cannot continue` |

2. **Line format template.** Define the standard log line layout for
   compact and verbose modes:
   - Compact: `<glyph> <message>`
   - Verbose: `[HH:MM:SS] <glyph> <indented_message>`
   - Debug: `[HH:MM:SS] <glyph> [component] <indented_message>`

3. **Report section header style.** Define the shared header/divider
   format for timing reports and error reports.

4. **Color application rules.** Define where color is applied:
   - Glyph: always colored by level
   - Message: colored by level for warn/error/critical only
   - Timestamp: dim/grey always
   - Component: dim/grey always
   - Tree characters (verbose mode): Viridis depth color

5. **`col_get_semantic` extension.** Document any new semantic names
   needed (`dim`, `business`, `security`, `audit`, `perf`).

6. **Rejected alternatives.** Document what was considered and why it
   was rejected (e.g., emoji indicators, full-line coloring, progress
   bars).

### Phase 2 -- Core rendering implementation (target: unified glyphs and colors)

1. Extend `col_get_semantic` in `lib/core/col` with any new semantic
   types from the spec (e.g., `dim`).

2. Create `_log_format_terminal` function (in `lib/core/lo1` or
   shared location) that applies the line format template:
   - Input: level, message, optional component, optional depth
   - Output: formatted terminal line with glyph, color, layout
   - Respects `LAB_LOG_FORMAT` (compact vs verbose)

3. Wire `lo1_log` terminal rendering through `_log_format_terminal`.
   Compact mode: flat output with glyph + message. Verbose mode:
   tree-indented output (current behavior).

4. Wire `aux_log` human-format terminal rendering through
   `_log_format_terminal`. Remove `aux_get_log_color` as a
   standalone function (keep as thin wrapper if needed for
   backward compatibility).

5. Wire `ver_log` terminal rendering through `_log_format_terminal`.

6. Verify: visual comparison screenshots of compact vs verbose
   modes. `bash -n` all changed files.

### Phase 3 -- Report styling and format control (target: consistent reports)

1. Standardize `tme_print_timing_report` header and section
   formatting to use the shared report style from the spec.

2. Standardize `err_print_report` header and section formatting.

3. Add `LAB_LOG_FORMAT` variable to `cfg/core/ric` (default: `verbose`
   initially for safety; flipped to `compact` in Phase 4).

4. Wire compact/verbose mode selection through all rendering paths.

5. Verify: `./val/run_all_tests.sh core` and visual comparison of
   reports in both modes.

### Phase 4 -- Default flip, documentation and closure (target: compact default, green suite)

1. Flip `LAB_LOG_FORMAT` default from `verbose` to `compact`.

2. Ensure `LAB_LOG_FORMAT=verbose` preserves full legacy rendering
   as a fallback.

3. Update `doc/arc/07-logging-and-error-handling.md` with visual
   specification reference.

4. Update `cfg/log/README.md` with visual format documentation.

5. Regenerate reference docs: `./utl/doc/run_all_doc.sh`.

6. Run full test suite: `./val/run_all_tests.sh`.

7. Run workflow checker: `bash doc/pro/check-workflow.sh`.

## Verification Plan

1. `bash -n` on every changed file after every phase
2. `val/core/modules/lo1_test.sh` -- rendering in both modes
3. `val/core/modules/err_test.sh` -- report formatting
4. `val/core/modules/tme_test.sh` -- report formatting
5. `val/lib/gen/aux_test.sh` -- `aux_log` rendering
6. `val/lib/core/col_test.sh` -- extended semantic types
7. `./val/run_all_tests.sh core` after each phase
8. `./val/run_all_tests.sh` full suite at project completion
9. Visual comparison: capture terminal output in compact and verbose
   modes for `lo1_log`, `aux_log`, `tme` report, `err` report
10. Visual comparison: verify glyph/color consistency across all
    subsystems
11. Manual: `LAB_LOG_FORMAT=verbose` produces legacy-equivalent output
12. Manual: `LAB_LOG_FORMAT=compact` produces the spec'd compact layout

## Exit Criteria

1. All logging subsystems use the same glyph set for level indicators.
2. All color lookups go through `col_get_semantic` (no duplicate palettes).
3. `LAB_LOG_FORMAT=compact` produces dense, single-line output for all
   log levels.
4. `LAB_LOG_FORMAT=verbose` preserves full tree-indented output as
   fallback.
5. `tme_print_timing_report` and `err_print_report` share a consistent
   section header style.
6. Compact mode is the default.
7. Documentation updated with visual specification.
8. Full test suite green.

## Risks

1. **Visual changes are subjective.** What looks "better" is a matter
   of preference. Mitigation: design phase produces a concrete spec
   that can be reviewed before implementation. Feature flag allows
   A/B comparison.

2. **Compact mode may hide useful information.** Users debugging issues
   may need the tree indentation and full timestamps. Mitigation:
   verbose mode preserved as `LAB_LOG_FORMAT=verbose`; debug level
   always includes component context regardless of format.

3. **`col_get_semantic` extension may affect existing callers.** Adding
   new semantic types should be additive (no breaking changes to existing
   types). Mitigation: only add new names, never modify existing
   color mappings.

4. **Report header changes affect test assertions.** Tests that
   match specific header characters (`═══`, `━━━`) will break.
   Mitigation: update test expectations in the same phase as the
   rendering change.

5. **`aux_get_log_color` removal may break external callers.** If any
   code outside `lib/gen/aux` calls this function directly, removing
   it will break. Mitigation: grep for all callers before removing;
   keep as thin wrapper around `col_get_semantic` if external usage
   exists.

6. **Scope creep into `tme` internals.** Changing report formatting
   may pull in changes to timer data structures. Mitigation: only
   modify rendering functions (`print_timing_entry`,
   `tme_print_timing_report`), not data collection functions.

## Next Step

Depends on: `20260303-2246_logging-architectural-restructure-plan`.
Execute the architectural restructure first to establish the unified
log writer and verbosity model. Phase 1 (visual specification) can
begin in parallel with the later phases of the architectural
restructure, since it is design-only and does not modify code.
