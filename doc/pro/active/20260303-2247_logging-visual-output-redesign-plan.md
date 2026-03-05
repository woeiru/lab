# Logging Visual Output Redesign

- Status: active
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-05 02:12
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

### [IN PROGRESS 2026-03-05] Phase 4 -- Closeout and archive (target: completed-close with documented known-failure scope)

1. Record closure note that the remaining full-suite failures are known,
   unrelated DIC failures (`dic_framework_test`, `dic_integration_test`,
   `dic_phase1_completion_test`) tracked outside this visual-output item.
2. Verify workflow metadata one final time: `bash doc/pro/check-workflow.sh`.
3. Execute `doc/pro/task/completed-close` for this active item, preserving
   links to DIC follow-up tracking in the completion notes.

## Phase 1 Design Deliverable

Date: 2026-03-05
Design classification: required

### Visual contract

#### Level indicator contract

| Level | Glyph | Semantic color | Notes |
|-------|-------|----------------|-------|
| debug | `·` | `dim` | low-importance trace events |
| info | `›` | `info` | default operational events |
| success | `✓` | `success` | completion/positive transitions |
| warn | `!` | `warn` | recoverable risk or drift |
| error | `✗` | `error` | failed operation |
| critical | `✗` | `critical` | fatal/stop-the-line failure |

#### Line layout contract

1. Compact normal levels (`info`, `success`, `warn`, `error`, `critical`):
   `<glyph> <message>`
2. Compact debug:
   `<glyph> [<component>] <message>`
3. Verbose normal levels:
   `[HH:MM:SS] <glyph> <indented_message>`
4. Verbose debug:
   `[HH:MM:SS] <glyph> [<component>] <indented_message>`

#### Report header contract (`tme` and `err`)

Shared section framing (ASCII-safe):
- Header line: `== <TITLE> ==`
- Section line: `-- <SECTION> --`
- Footer line: `== end <TITLE> ==`

The title and section labels use semantic color only on terminal output.
File output remains plain text and unchanged.

### Interfaces

1. `_log_format_terminal <subsystem> <level> <message> [component] [depth]`
   - Produces one terminal-ready line that respects `LAB_LOG_FORMAT`.
   - Returns `0` on success, `1` on parameter error, `2` on render/runtime error.
2. `_log_level_glyph <level> <out_var>`
   - Resolves canonical glyph for the provided level.
3. `_log_level_semantic <level> <out_var>`
   - Resolves semantic color name for glyph/message coloring.
4. `_log_report_header <report_type> <title> <section>`
   - Emits standardized report framing for `tme` and `err` renderers.

Chosen location: `lib/core/log` so `lo1`, `aux`, and `ver` can share one
bootstrap-safe formatter alongside `_log_write` and `_log_level_permits`.

### Constraints

1. Must remain bootstrap-safe: no dependency on `lib/gen/aux` helpers.
2. Must preserve `LAB_LOG_FORMAT=verbose` as legacy-compatible fallback.
3. Must not alter file log schema, field order, or color-stripping behavior.
4. Must route all color selection through `col_get_semantic`.
5. Must keep terminal routing consistent with current stderr-first policy.

### Trade-offs

1. Reusing `✗` for both `error` and `critical` optimizes recognizability;
   severity differentiation is carried by semantic color (`error` vs `critical`).
2. Compact mode removes tree glyphs for density; verbose mode retains tree
   indentation for debugging depth analysis.
3. ASCII report framing maximizes terminal portability but is less decorative
   than box-drawing styles.
4. Coloring only glyphs (and warn/error messages) reduces visual noise while
   keeping high-severity events prominent.

### Chosen approach

Implement a shared terminal formatter in `lib/core/log` and route all runtime
human-readable rendering through it:

1. `lo1_log` uses compact or verbose template based on `LAB_LOG_FORMAT`.
2. `aux_log` human mode replaces `aux_get_log_color` lookups with
   `col_get_semantic` via shared formatter helpers.
3. `ver_log` adopts the same glyph/color/layout contract as other subsystems.
4. `tme_print_timing_report` and `err_print_report` use one report header style.
5. `LAB_LOG_FORMAT` defaults to `verbose` during transition, then flips to
   `compact` in Phase 4 after validation.

### `col_get_semantic` extension decision

1. Add `dim` alias that maps to existing metadata/dim-style rendering.
2. Keep existing semantic names for `business`, `security`, `audit`, and `perf`
   unchanged (already supported in `lib/core/col`).
3. Do not remove or remap any existing semantic tokens.

### Rejected alternatives

1. Emoji level indicators (`:warning:`, `:x:`): rejected for width variance,
   inconsistent font support, and noisy visual style.
2. Full-line severity coloring for all levels: rejected due to eye fatigue and
   poor scanability in dense logs.
3. Keep subsystem-specific formatting rules: rejected because drift and
   inconsistency would continue.
4. Introduce progress bars/spinners in runtime logs: rejected as scope creep
   outside report/log-line redesign.

## Progress Checkpoint

### Done

1. Updated runtime default to compact in `cfg/core/ric` (`LAB_LOG_FORMAT=compact`).
2. Updated visual/runtime architecture docs in
   `doc/arc/07-logging-and-error-handling.md` and
   `cfg/log/README.md`.
3. Regenerated reference docs via `./utl/doc/run_all_doc.sh`
   (`doc/ref/functions.md`, `doc/ref/variables.md`,
   `doc/ref/module-dependencies.md`, `doc/ref/error-handling.md`,
   `doc/ref/test-coverage.md`, `doc/ref/scope-integrity.md`,
   `doc/ref/reverse-dependecies.md`).
4. Ran full validation `./val/run_all_tests.sh`:
   44 passed, 3 failed (`dic_framework_test`, `dic_integration_test`,
   `dic_phase1_completion_test`).
5. Ran workflow metadata check successfully:
   `bash doc/pro/check-workflow.sh`.

### In-flight

1. Active-checkpoint updated; commit is pending.
2. Item remains in `doc/pro/active/` until `completed-close` is executed.

### Blockers

1. No hard blockers in visual-output scope.
2. Full-suite-green criterion remains blocked by known unrelated DIC tests.

### Next steps

1. Add explicit known-failure note and DIC follow-up link in this file:
   `doc/pro/active/20260303-2247_logging-visual-output-redesign-plan.md`.
2. Run `bash doc/pro/check-workflow.sh`.
3. Run `doc/pro/task/completed-close` on
   `doc/pro/active/20260303-2247_logging-visual-output-redesign-plan.md`.

### Context

1. Runtime rendering is now centralized in `lib/core/log` helpers and consumed
   by `lo1`, `ver`, and `aux` human-mode rendering.
2. Report framing for `tme` and `err` is standardized and exercised by module
   tests.
3. Full-suite failures remain limited to known DIC tests; no new failures were
   introduced in core/lib/integration coverage relevant to this plan.
4. Full-suite and doc-generation runs update `STATS.md` and
   `doc/ref/stats/*` as normal side effects.

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

Close this item via `doc/pro/task/completed-close` with a documented note that
the remaining DIC failures are known out-of-scope follow-up work.
