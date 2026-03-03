# Bootstrap Visual Output Redesign

- Status: completed
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-03 (phase 5 complete; blocker resolved; moved to completed)
- Links: bin/ini, bin/orc, lib/core/tme, lib/core/lo1, lib/core/err, lib/core/col, lib/gen/inf, val/core/glb_008_secret_scan_test.sh

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

Status: complete (design deliverable captured below).

### Phase 1 Deliverable (2026-03-03): Compact Bootstrap Output Spec

#### 1) Output format specification (exact terminal layout)

Scope: terminal output only (stderr), bootstrap context only
(`LAB_BOOTSTRAP_MODE=1`), compact mode only
(`LAB_BOOTSTRAP_OUTPUT=compact`). File logging remains unchanged.

Success case (compact mode):

```
lab · <profile> · bootstrap
<spinner> <component statuses on one mutable line>
✓ <ok>/<total> components · <elapsed> · clean
```

Failure case (compact mode):

```
lab · <profile> · bootstrap
✗ <failed_component> · <failure_message>
  logs: <ini_log_path> <err_log_path> <tme_log_path>
```

Character and alignment rules:

1. Header line is single-line chrome with ` · ` separators. No trailing spaces.
2. Progress is single-pass and inline:
   - TTY: one mutable line using carriage return (`\r`) and spinner frames
     `|`, `/`, `-`, `\\`.
   - Non-TTY: no spinner animation; emit one finalized progress/status line.
3. Component token format is fixed-width: `<symbol><name>` where symbol is:
   - pending `·`
   - success `✓`
   - failed `✗`
4. Status token ordering follows actual bootstrap execution order from
   `setup_components` component list.
5. Width cap is 80 columns:
   - truncate only rightmost fields first (metadata, then message tail)
   - truncation marker is ASCII `...`
   - never wrap.
6. Failure message normalization:
   - collapse internal newlines/tabs to spaces
   - trim leading/trailing whitespace
   - truncate to remaining width after component label and separators.
7. Compact success summary uses exactly one final status line; detailed trees are
   suppressed in compact mode.
8. Verbose mode (`LAB_BOOTSTRAP_VERBOSITY=verbose`) preserves detailed
   multi-line bootstrap output behavior (per-module lines).

#### 2) Color mapping (unified on `lib/core/col` semantics)

Color policy in compact mode:

- Header chrome/separators/spinner: `COL_DIM` and `COL_METADATA`
- Success symbols (`✓`) and success totals: `COL_SUCCESS`
- Warning markers/counts: `COL_WARN`
- Failure symbols (`✗`) and failure summary: `COL_ERROR`
- Timing and secondary metadata (`<elapsed>`, profile metadata, log paths):
  `COL_METADATA`
- Emphasis labels (component names in compact status line): `COL_INFO`
- Reset token everywhere: `COL_RESET`

Legacy-to-new mapping decisions:

1. `bin/ini` startup separator (`────────`) is removed in compact mode.
2. `ini_log` per-step `└─ message [time]` terminal lines are replaced by
   compact header/progress/summary lines.
3. `lo1_log` depth/viridis tree terminal lines are suppressed during compact
   bootstrap (file logging unchanged).
4. `tme_print_timing_report` compact terminal output uses semantic colors only;
   remove `TME_*` private ANSI palette usage from terminal-render path.
5. `err_print_report` compact terminal output uses semantic colors only;
   keep detailed category output for verbose mode.

#### 3) Verbosity model (new variable + compatibility)

New controller variable:

- `LAB_BOOTSTRAP_VERBOSITY=compact|verbose|silent`

Effective mode precedence (bootstrap terminal output):

1. `MASTER_TERMINAL_VERBOSITY=off` -> force `silent`
2. Else if `LAB_BOOTSTRAP_VERBOSITY` is set and valid -> use it
3. Else compatibility mapping from legacy toggles:
   - all of `INI_LOG_TERMINAL_VERBOSITY`, `LO1_LOG_TERMINAL_VERBOSITY`,
     `TME_TERMINAL_VERBOSITY`, `ERR_TERMINAL_VERBOSITY` are `on` -> `verbose`
   - all four are `off` -> `silent`
   - mixed state -> `compact`

Compatibility policy:

- Existing variables remain accepted and exported.
- During compact bootstrap output, legacy toggles are interpreted via the
  mapping above rather than independently shaping each line family.
- Outside bootstrap mode, existing module verbosity behavior remains unchanged.

#### 4) Feature flag contract

Gating variable:

- `LAB_BOOTSTRAP_OUTPUT=legacy|compact`

Behavior:

1. Phase 2-4 implementation default: `legacy` (opt-in compact for rollout).
2. Phase 5 default flips to `compact`.
3. Invalid value falls back to `legacy` and records a warning in `ini.log`
   (no extra terminal noise in compact/silent paths).
4. `LAB_BOOTSTRAP_OUTPUT` controls format selection; verbosity remains governed
   by effective bootstrap verbosity mode above.

#### 5) Test impact inventory (current repo scan)

Output-shape-dependent assertions found:

1. `val/core/modules/tme_test.sh:199`-`val/core/modules/tme_test.sh:201`
   - Current assertion checks `tme_print_timing_report` output contains
     `REPORT_TEST`.
   - Dependency type: content-dependent (not strict formatting).
   - Planned change: keep `REPORT_TEST` visible in verbose report output; if
     compact mode alters report detail, update assertion to validate semantic
     report data instead of line shape.

Behavior-only, non-format assertions touching logging/timing entrypoints:

1. `val/core/initialization/ini_test.sh:124`-`val/core/initialization/ini_test.sh:130`
   (`lo1_log` call success only)
2. `val/integration/complete_workflow_test.sh:211`-`val/integration/complete_workflow_test.sh:213`
   (`lo1_log` + `err_process` success path only)

No strict assertions were found for:

- exact `ini_log` line shape
- `lo1_log` tree glyph formatting
- `err_print_report` header text shape
- initialization completion line formatting.

#### 6) Constraints, trade-offs, rejected alternatives

Constraints:

1. No behavior change to bootstrap logic, only terminal presentation.
2. File logging in `.log/*` must remain unchanged.
3. 80-column cap, no wrapped output blocks.
4. No new dependency/tool introduction.

Trade-offs and rejected options:

1. Rejected: single final line only (no progress). Too little live feedback.
2. Rejected: keep five independent terminal switches in compact mode. Too
   fragmented for a coherent UX.
3. Rejected: preserve TME rainbow/depth palettes. Conflicts with unified
   semantic color policy.
4. Rejected: globally changing `lo1_log` behavior outside bootstrap. Out of
   scope and risks non-bootstrap regressions.

### Phase 1 findings (2026-03-03)

1. Current bootstrap output has three distinct visual systems active at once
   (`ini_log`, `lo1_log`, `tme`/`err` reports), which makes compact mode design
   easiest if all terminal rendering is routed through one bootstrap display
   contract.
2. Existing tests are weakly coupled to formatting; most risk is limited to
   `tme_print_timing_report` content assertions rather than strict snapshots.
3. A compatibility mapping layer is sufficient to preserve old verbosity env
   variables while still introducing one effective bootstrap verbosity control.

## Execution Plan (current)

- [COMPLETE] Phase 1: Design
- [COMPLETE] Phase 2: Compact output implementation in `bin/ini`
- [COMPLETE] Phase 3: Compact `tme`/`err` terminal rendering with semantic colors
- [COMPLETE] Phase 4: Compact bootstrap `lo1_log` terminal suppression
- [COMPLETE] Phase 5: Final verification and closure with compact default

## Progress Checkpoint

### Done

1. Implemented compact bootstrap rendering in `bin/ini` with compact default,
   legacy verbose fallback, and silent mode stream suppression.
2. Implemented compact report rendering in `lib/core/tme` and `lib/core/err`
   using semantic color tokens from `lib/core/col`; removed compact-path use of
   private TME rainbow colors.
3. Implemented bootstrap-only `lo1` terminal suppression in `lib/core/lo1` when
   `LAB_BOOTSTRAP_MODE=1` and effective output mode is compact.
4. Added initialization regression coverage in
   `val/core/initialization/ini_test.sh` for compact default, verbose fallback,
   and silent stream behavior.
5. Tests run this session:
    - Pass: `bash -n bin/ini lib/core/tme lib/core/err lib/core/lo1 val/core/initialization/ini_test.sh`
    - Pass: `./val/core/initialization/ini_test.sh`
    - Pass: `./val/core/modules/tme_test.sh`
    - Pass: `./val/core/modules/err_test.sh`
    - Pass: `./val/core/modules/lo1_test.sh`
    - Pass: `./val/run_all_tests.sh lib`
    - Pass: `bash -n lib/gen/inf`
    - Pass: `./val/core/glb_008_secret_scan_test.sh`
    - Pass: `./val/run_all_tests.sh` (47/47 passed)
6. Resolved GLB-008 blocker by replacing hardcoded default
   `CT_DEFAULT_PASSWORD="password"` in `lib/gen/inf` with env-backed
   `CT_DEFAULT_PASSWORD="${LAB_CT_DEFAULT_PASSWORD:-}"`.

### In-flight

1. None. Phase 5 closure is complete.

### Blockers

1. None. Previous GLB-008 blocker at `lib/gen/inf:90` is resolved.

### Next steps

1. Completed: resolved `glb_008_secret_scan_test` failure by removing hardcoded
   password literal from `lib/gen/inf`.
2. Completed: re-ran `./val/run_all_tests.sh` with zero failures.
3. Completed: marked Phase 5 complete and prepared completion handoff.
4. Completed: moved this plan into `doc/pro/completed/<topic>/`.

### Context

1. Branch: `master`.
2. Closure updates in this session:
   - `lib/gen/inf`
   - `doc/pro/completed/20260303-0220_bootstrap-visual-output-redesign-plan/20260303-0220_bootstrap-visual-output-redesign-plan.md`
   - `doc/pro/active/waivers/20260228-0105_waiver-register.md`
3. Full suite status: `./val/run_all_tests.sh` pass (47 passed, 0 failed).
4. Workflow checker status: `bash doc/pro/check-workflow.sh` pass.

### Phase 2: Implement compact output in `bin/ini`

Replace `ini_log` terminal format and the startup separator / completion line
with the new compact layout behind the `LAB_BOOTSTRAP_OUTPUT=compact` flag.
File logging remains unchanged.

Completion criterion: `bin/ini` produces the designed compact output when the
feature flag is set, and existing output is unchanged when the flag is unset.

Status: complete.

Phase 2 implementation notes:

1. Added compact/legacy output mode routing in `bin/ini` with
   `LAB_BOOTSTRAP_OUTPUT=compact|legacy`, legacy fallback on invalid values,
   and file-only warning logging for invalid values.
2. Reworked `ini_log` terminal behavior to dual-path rendering:
   - legacy path keeps current `└─ message [HH:MM:SS]` format
   - compact path renders single-section header/progress/success/failure output.
3. Replaced startup separator and final completion line behavior to be
   mode-aware:
   - separator + legacy completion line only in `legacy`
   - compact summary line in `compact`.
4. Added compact progress helpers in `bin/ini` (header printing, spinner
   cycling, truncation, line finalization, success/failure summaries) while
   preserving file logging unchanged.

Phase 2 verification evidence:

- Pass: `bash -n bin/ini`
- Pass: `./val/core/config/cfg_test.sh`
- Pass: `./val/core/initialization/ini_test.sh`
- Manual spot-check (compact):
  `MASTER_TERMINAL_VERBOSITY=on INI_LOG_TERMINAL_VERBOSITY=on LO1_LOG_TERMINAL_VERBOSITY=off ERR_TERMINAL_VERBOSITY=off TME_TERMINAL_VERBOSITY=off LAB_BOOTSTRAP_OUTPUT=compact source bin/ini`
- Manual spot-check (legacy unchanged):
  `MASTER_TERMINAL_VERBOSITY=on INI_LOG_TERMINAL_VERBOSITY=on LO1_LOG_TERMINAL_VERBOSITY=off ERR_TERMINAL_VERBOSITY=off TME_TERMINAL_VERBOSITY=off LAB_BOOTSTRAP_OUTPUT=legacy source bin/ini`

### Phase 2 findings (2026-03-03)

1. Compact mode can be introduced in `bin/ini` without changing initialization
   logic by treating rendering as a terminal-only concern and leaving file logs
   on the existing path.
2. Legacy output compatibility is easiest to preserve with explicit dual-path
   rendering at the call site (`ini_log`) rather than attempting post-process
   translation of legacy lines.

### Phase 3: Migrate `tme_print_timing_report` and `err_print_report`

Update `lib/core/tme` and `lib/core/err` terminal display functions to use
`lib/core/col` semantic colors and the compact summary format defined in the
design. Remove TME's private rainbow palette.

Completion criterion: timing and error reports render in the new compact
format using only `lib/core/col` tokens when the feature flag is set.

Status: complete.

Phase 3 implementation notes:

1. Added compact-mode rendering paths in `lib/core/tme` and `lib/core/err`
   gated by `LAB_BOOTSTRAP_OUTPUT=compact`.
2. `tme_print_timing_report` now emits compact summary lines (total time,
   component counts, slowest component metadata) in compact mode, and keeps
   legacy report tree in legacy mode.
3. `err_print_report` now emits compact summary lines (error/warning counts +
   log path) in compact mode, and keeps full detailed report in legacy mode.
4. Legacy timing tree color selection now prefers `lib/core/col` depth/semantic
   tokens when available, with fallback compatibility retained for direct module
   sourcing contexts.
5. `bin/ini` compact-mode finalization now suppresses `tme_settme` status noise
   while still forcing report state on.

Phase 3 verification evidence:

- Pass: `bash -n bin/ini lib/core/tme lib/core/err`
- Pass: `./val/core/modules/tme_test.sh`
- Pass: `./val/core/modules/err_test.sh`
- Pass: `./val/core/initialization/ini_test.sh`
- Informational: `./val/lib/run_all_tests.sh --core` does not currently execute
  these suites (runner points to non-existent `val/lib/core/*_test.sh` paths);
  direct module tests above were used as effective coverage.
- Manual compact-mode check:
  `MASTER_TERMINAL_VERBOSITY=on INI_LOG_TERMINAL_VERBOSITY=on LO1_LOG_TERMINAL_VERBOSITY=off ERR_TERMINAL_VERBOSITY=on TME_TERMINAL_VERBOSITY=on TME_REPORT_TERMINAL_OUTPUT=on LAB_BOOTSTRAP_OUTPUT=compact source bin/ini`

### Phase 3 findings (2026-03-03)

1. Compact summary rendering in `tme` required ERR-trap-safe arithmetic
   increments (`+= 1`) because post-increment (`var++`) can return status `1`
   on first increment and trigger bootstrap error traps.
2. Timing component keys may include spaces, so associative-array access in
   compact rendering must use quoted keys (`arr["$key"]`) to avoid trap-driven
   failures during report generation.

### Phase 4: Suppress `lo1_log` during bootstrap

Gate `lo1_log` terminal output on `LAB_BOOTSTRAP_MODE` so per-module tree
lines are suppressed in compact mode. File logging unchanged.

Completion criterion: bootstrap in compact mode produces no `lo1_log` tree
output on the terminal; verbose mode still shows it.

Status: complete.

Phase 4 implementation notes:

1. `lib/core/lo1` terminal emission paths (`lo1_log`, `lo1_setlog`) now
   suppress bootstrap terminal tree output when both
   `LAB_BOOTSTRAP_MODE=1` and `LAB_BOOTSTRAP_OUTPUT=compact`.
2. `bin/ini` now keeps `LAB_BOOTSTRAP_MODE=1` active through component setup so
   lo1 bootstrap suppression applies to orchestrator-driven module logs.
3. File logging behavior in `lo1.log` remains unchanged.

Phase 4 verification evidence:

- Pass: `bash -n bin/ini lib/core/lo1`
- Manual compact-mode check (lo1 enabled):
  `MASTER_TERMINAL_VERBOSITY=on INI_LOG_TERMINAL_VERBOSITY=on LO1_LOG_TERMINAL_VERBOSITY=on ERR_TERMINAL_VERBOSITY=off TME_TERMINAL_VERBOSITY=off LAB_BOOTSTRAP_OUTPUT=compact source bin/ini`
  (no lo1 tree lines on terminal)
- Manual verbose-mode check:
  `MASTER_TERMINAL_VERBOSITY=on INI_LOG_TERMINAL_VERBOSITY=on LO1_LOG_TERMINAL_VERBOSITY=on ERR_TERMINAL_VERBOSITY=off TME_TERMINAL_VERBOSITY=off LAB_BOOTSTRAP_OUTPUT=legacy source bin/ini`
  (lo1 tree lines present)
- Category suites:
  - `./val/run_all_tests.sh lib` -> pass
  - `./val/run_all_tests.sh core` -> fail due pre-existing
    `glb_008_secret_scan_test` (unrelated to this change set)

### Phase 4 findings (2026-03-03)

1. Bootstrap-tree suppression in `lo1` depends on `LAB_BOOTSTRAP_MODE` lifecycle;
   clearing the flag too early in `bin/ini` prevents suppression from affecting
   orchestrator component logs.


### Phase 5: Update tests and remove feature flag

Update all affected test assertions identified in Phase 1. Make compact mode
the default. Preserve a verbose fallback via `LAB_BOOTSTRAP_VERBOSITY=verbose`.

Completion criterion: `./val/run_all_tests.sh` passes with compact mode as
the default.

Status: complete.

Phase 5 implementation notes:

1. Compact mode is now the default bootstrap presentation path in `bin/ini`
   (legacy retained as compatibility behavior for explicit verbose mode).
2. Added `LAB_BOOTSTRAP_VERBOSITY=compact|verbose|silent` handling in `bin/ini`
   and wired mode-specific terminal stream overrides.
3. `verbose` mode now forces legacy output; `silent` disables bootstrap terminal
   streams; `compact` keeps compact output as default.
4. `bin/ini` now exports effective bootstrap mode variables so downstream
   modules (`lo1`, `tme`, `err`) evaluate a consistent compact/legacy context.
5. Extended `val/core/initialization/ini_test.sh` with new coverage for:
   - default compact mode
   - verbose fallback to legacy
   - silent-mode terminal suppression.

Phase 5 verification evidence:

- Pass: `bash -n bin/ini val/core/initialization/ini_test.sh`
- Pass: `./val/core/initialization/ini_test.sh`
- Pass: `./val/core/modules/tme_test.sh`
- Pass: `./val/core/modules/err_test.sh`
- Pass: `./val/core/modules/lo1_test.sh`
- Pass: `./val/run_all_tests.sh lib`
- Pass: `bash -n lib/gen/inf`
- Pass: `./val/core/glb_008_secret_scan_test.sh`
- Full-suite result: `./val/run_all_tests.sh` -> pass (47 passed, 0 failed)

### Phase 5 findings (2026-03-03)

1. End-to-end bootstrap verbosity control can be layered in `bin/ini` without
   changing module APIs by exporting effective bootstrap mode variables and
   applying stream overrides before initialization logging begins.
2. Closing this topic required resolving GLB-008 in `lib/gen/inf`; after that
   change, strict secret scan and full-suite validation both passed.

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

## What changed

1. Completed all planned phases for bootstrap visual output redesign and
   finalized compact mode as default with verbose/silent compatibility.
2. Resolved closure blocker by replacing hardcoded
   `CT_DEFAULT_PASSWORD="password"` with env-backed
   `CT_DEFAULT_PASSWORD="${LAB_CT_DEFAULT_PASSWORD:-}"` in `lib/gen/inf`.
3. Updated waiver register entry `WVR-2026-001` to `resolved` after strict
   secret-scan passed with zero matches.
4. Updated this plan with final verification evidence and completion status.

## What was verified

1. `bash -n lib/gen/inf` -> pass.
2. `./val/core/glb_008_secret_scan_test.sh` -> pass (`Potential secret matches: 0`).
3. `./val/run_all_tests.sh` -> pass (`Total Tests: 47`, `Failed: 0`, `Passed: 47`).

## What remains

1. No mandatory follow-up items for this topic.
