# Bootstrap Visual Output Redesign

- Status: active
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

## Triage Decision

- **Why now**: Bootstrap output is the first user-visible impression on every
  shell session. The current display has accumulated three competing color
  palettes and five independent verbosity switches, producing cluttered,
  inconsistent output. Cleaning this up improves daily ergonomics for every
  user.
- **Design: required**
  1. Meaningful alternatives exist: single summary line vs inline progress
     dots vs checkmark grid; unified verbosity variable vs layered overrides;
     multiple valid compact layout options.
  2. Other code depends on output shape: tests under `val/core/` and
     `val/lib/` assert on specific output patterns and will need updating.
- Justification: both the format design and the downstream test/code
  dependencies require deliberate design decisions before implementation.

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

## Execution Plan

### Phase 1: Design (design phase -- no implementation)

Deliverable: a design document section (appended here or in a linked file)
that specifies:

1. **Output format specification** -- exact line-by-line layout for the compact
   bootstrap output in both success and failure cases, with character-level
   detail (fields, separators, alignment, truncation rules).
2. **Color mapping** -- which `lib/core/col` semantic tokens replace each
   current color usage in `tme`, `err`, `lo1`, and `ini_log` terminal output.
3. **Verbosity model** -- how `LAB_BOOTSTRAP_VERBOSITY` (or equivalent)
   interacts with the five existing per-module switches; whether switches are
   preserved, aliased, or deprecated.
4. **Feature flag** -- confirm `LAB_BOOTSTRAP_OUTPUT=compact` as the gating
   mechanism; define default value and override behavior.
5. **Test impact inventory** -- list every test file and assertion that depends
   on current output format, with the planned change per assertion.
6. **Constraints and trade-offs** -- document rejected alternatives and
   rationale.

Completion criterion: the design document is reviewed and captures all six
items above with enough precision to implement without further design
decisions.

### Phase 2: Implement compact output in `bin/ini`

Replace `ini_log` terminal format and the startup separator / completion line
with the new compact layout behind the `LAB_BOOTSTRAP_OUTPUT=compact` flag.
File logging remains unchanged.

Completion criterion: `bin/ini` produces the designed compact output when the
feature flag is set, and existing output is unchanged when the flag is unset.

### Phase 3: Migrate `tme_print_timing_report` and `err_print_report`

Update `lib/core/tme` and `lib/core/err` terminal display functions to use
`lib/core/col` semantic colors and the compact summary format defined in the
design. Remove TME's private rainbow palette.

Completion criterion: timing and error reports render in the new compact
format using only `lib/core/col` tokens when the feature flag is set.

### Phase 4: Suppress `lo1_log` during bootstrap

Gate `lo1_log` terminal output on `LAB_BOOTSTRAP_MODE` so per-module tree
lines are suppressed in compact mode. File logging unchanged.

Completion criterion: bootstrap in compact mode produces no `lo1_log` tree
output on the terminal; verbose mode still shows it.

### Phase 5: Update tests and remove feature flag

Update all affected test assertions identified in Phase 1. Make compact mode
the default. Preserve a verbose fallback via `LAB_BOOTSTRAP_VERBOSITY=verbose`.

Completion criterion: `./val/run_all_tests.sh` passes with compact mode as
the default.

## Verification Plan

- After each phase, run `bash -n` on every modified file.
- After Phase 2: run `./val/core/config/cfg_test.sh` and any `val/` tests
  that exercise `bin/ini` output.
- After Phase 3: run `./val/lib/run_all_tests.sh --core` for `tme` and `err`
  coverage.
- After Phase 4: run `./val/run_all_tests.sh core` and `./val/run_all_tests.sh lib`.
- After Phase 5: run `./val/run_all_tests.sh` (full suite).
- Manual spot-check: source `bin/ini` in a fresh shell with
  `LAB_BOOTSTRAP_OUTPUT=compact` and visually confirm output matches the
  design spec from Phase 1.

## Exit Criteria

- Compact bootstrap output is the default for interactive shells.
- All terminal output during bootstrap uses only `lib/core/col` semantic
  palette (no TME rainbow, no raw ANSI codes).
- A single verbosity variable (`LAB_BOOTSTRAP_VERBOSITY`) controls bootstrap
  terminal detail level with at least `compact`, `verbose`, and `silent` modes.
- File-based logging is completely unchanged.
- `./val/run_all_tests.sh` passes with zero failures.
