# Bootstrap Visual Output Redesign

- Status: inbox
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-03
- Links: bin/ini, bin/orc, lib/core/tme, lib/core/lo1, lib/core/err, lib/core/col

## Goal

Redesign the bootstrap terminal output (`bin/ini` + `bin/orc` sourcing chain)
to be professional, minimalistic, and state-of-the-art looking. Replace the
current verbose, multi-line tree output with a compact, efficient display that
communicates initialization status without visual clutter.

## Context

The current bootstrap produces dense terminal output across five visual layers:

1. **Startup separator** (`bin/ini:129`): `─────────────── ` plain line.
2. **`ini_log` messages** (`bin/ini:317`): `└─ message [HH:MM:SS]` per step.
3. **`lo1_log` messages** (`lib/core/lo1:262-297`): depth-colored indented
   tree lines emitted by `bin/orc` during component loading.
4. **`err_print_report`** (`lib/core/err:210-302`): ` ━ RC Error Report`
   block with categorized errors/warnings.
5. **`tme_print_timing_report`** (`lib/core/tme:516-566`): ` ━ RC Timing
   Report` with recursive tree of component durations, percentages, and
   status icons.
6. **Completion line** (`bin/ini:731-733`):
   ` ━ Initialization completed in Xms`.

Three separate color palettes coexist (TME rainbow, COL_DEPTH viridis,
COL semantic), creating visual inconsistency. The timing report uses its
own ANSI-16 palette while lo1/aux use 256-color from `lib/core/col`.

Verbosity is gated by `MASTER_TERMINAL_VERBOSITY`, `INI_LOG_TERMINAL_VERBOSITY`,
`LO1_LOG_TERMINAL_VERBOSITY`, `TME_TERMINAL_VERBOSITY`, and
`ERR_TERMINAL_VERBOSITY` -- five independent switches.

## Scope

### In scope

- Redesign `ini_log` terminal output format in `bin/ini`.
- Redesign or suppress `lo1_log` terminal output during bootstrap phase
  (gate on `LAB_BOOTSTRAP_MODE`).
- Redesign `tme_print_timing_report` and `print_timing_entry` display format
  in `lib/core/tme`.
- Redesign `err_print_report` display format in `lib/core/err`.
- Unify color usage: use `lib/core/col` semantic palette consistently,
  remove TME's private rainbow palette.
- Design a compact single-pass progress indicator (e.g., inline status dots
  or a single summary line) instead of per-module log lines.
- Preserve all file-based logging unchanged (only terminal stderr output
  changes).
- Ensure the redesign works with existing verbosity toggle variables.

### Out of scope

- `aux_log` operational logging format (post-bootstrap, different audience).
- Changes to `lo1_log` behavior outside of bootstrap context.
- Functional changes to initialization logic, error handling, or timer
  internals.
- New dependencies or external tools.
- Changes to `cfg/` configuration files or environment variable names.

### Design direction

The target aesthetic is compact, single-section output similar to modern CLI
tools (e.g., `pnpm install`, `cargo build`, `starship` prompt). Key traits:

- **One header line**: system name + version/profile, dim metadata.
- **Progress**: minimal inline indicators (spinner, dots, or checkmarks) --
  not a tree per module.
- **Summary block**: 2-3 lines max -- component count, timing, errors if any.
- **Color**: use `COL_DIM`/`COL_METADATA` for chrome, `COL_SUCCESS`/
  `COL_ERROR` for status, `COL_INFO` for emphasis. No rainbow.
- **Width**: fit in 80 columns. No trailing whitespace.
- **Failure mode**: on error, expand to show the failing component and
  message; suppress the rest.

Example rough sketch (not final):

```
 lab  interactive  5 modules  3 components
 ✓ core  ✓ ops  ✓ gen  ✓ cfg  ✓ aux          142ms
```

Or on failure:

```
 lab  interactive
 ✓ core  ✓ ops  ✗ gen  sec: permission denied
```

## Risks

- **Regression in diagnostics**: suppressing per-module log lines during
  bootstrap could make debugging harder. Mitigation: keep full detail in
  file logs (`ini.log`, `lo1` log file); add a `--verbose` / env-var mode
  that restores detailed terminal output.
- **Color palette migration**: removing TME's private colors requires
  updating `print_timing_entry` and `tme_print_timing_report`. Must ensure
  `lib/core/col` is loaded before `lib/core/tme` in the sourcing chain
  (currently it is: col loads first in `load_modules`).
- **Verbosity switch proliferation**: five independent terminal verbosity
  toggles may conflict with a unified compact mode. May need a single
  `LAB_BOOTSTRAP_VERBOSITY=compact|verbose|silent` variable that overrides
  the per-module switches during bootstrap.
- **Interactive vs deployment profile**: both profiles share display code;
  deployment may want even less output. Must test both paths.
- **Test coverage**: `val/core/` and `val/lib/` tests may assert on specific
  output patterns. Verify and update affected test expectations.

## Next Step

Prototype the compact output format in `bin/ini` behind a feature flag
(`LAB_BOOTSTRAP_OUTPUT=compact`), starting with the header line and
completion summary. Leave existing output as the default until the new
format is validated.
