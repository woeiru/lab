# Function Library Review -- Active Strategy

- Status: dismissed
- Owner: es
- Started: n/a
- Updated: 2026-03-04
- Links: none

Strategic plan for systematic review and improvement of all library functions
across lib/core/, lib/gen/, and lib/ops/.

## Dismissal Reason

- Plan is stale relative to current priorities and workflow state.
- Scope is too broad and no longer actionable as a single planning item.

## Guiding Principle

Do not change a running system -- unless you can prove nothing breaks.
Tests are that proof. Every improvement must be preceded by tests that lock
in current behavior before any refactoring begins.

## Current State Assessment

### Coverage by numbers

| Layer       | Files | With Tests | Without Tests | Coverage |
|-------------|-------|------------|---------------|----------|
| lib/core/   | 5     | 4          | 1 (col)       | 80%      |
| lib/gen/    | 5     | 4          | 1 (ana)       | 80%      |
| lib/ops/    | 10    | 10         | 0             | 100%     |
| **Total**   | **20**| **18**     | **2**         | **90%**  |

### Coverage by depth

File coverage is misleading. Most existing tests are shallow:

- They verify functions exist (declare -f) and files can be sourced.
- They do not call functions with known inputs and assert outputs.
- They do not test parameter validation, error paths, or return codes.
- Several test files (sys, net, srv, sto) contain patterns that always pass
  regardless of module correctness.

Effective behavioral test coverage is estimated at under 15%.

### What works well

- val/helpers/test_framework.sh is solid and requires no changes.
- val/lib/ops/std_compliance_test.sh (708 lines) provides genuine structural
  compliance scanning across all ops modules.
- val/lib/ops/pve_compliance_test.sh is the best model for per-function
  parameter validation testing -- it calls real functions with bad inputs and
  checks return codes.
- Test isolation via subshells and temporary environments is well implemented.

### Concrete gaps

- lib/core/col -- zero tests.
- lib/gen/ana -- zero tests.
- lib/ops/pve -- compliance tests only, no pve_test.sh (largest ops module,
  15 public functions).
- Most ops test files test generic system commands rather than actual module
  functions.
- No behavioral correctness tests for the majority of ~102 public functions.

## Strategy: Test-Then-Improve Per Module

### Why not improve first

Ops functions modify real infrastructure. Refactoring without behavioral tests
means regressions are invisible. Current tests will pass no matter what changes
because they only check that function names exist.

### Why not test everything first

Writing deep tests for all ~102 functions before touching any code means weeks
of work testing implementations that are about to change. Context switching
between bulk test writing and bulk refactoring loses module-level understanding.

### The cycle

For each module, execute this sequence before moving to the next:

```
1. Run std_compliance_test.sh          -- identify .spec gaps
2. Write parameter validation tests    -- every function, bad inputs, return codes
3. Write behavioral tests             -- known inputs, expected outputs, mocked deps
4. Improve the module                 -- refactor toward merged .spec compliance
5. Run tests, fix, iterate            -- until green
6. Run category suite                 -- confirm no cross-module breakage
```

Do not skip step 2-3 for any module. Do not batch multiple modules in step 4.

## Test Priority Per Function

When writing tests for a function, cover these areas in this order:

| Priority | What to test                      | Rationale                          |
|----------|-----------------------------------|------------------------------------|
| 1        | --help returns 0                  | Mandatory per .spec, trivial       |
| 2        | Missing/bad params return 1       | Mandatory per .spec, catches drift |
| 3        | Missing dependencies return 2/127 | Safety net for runtime failures    |
| 4        | Correct output on valid input     | Actual behavioral correctness      |
| 5        | Edge cases and boundary values    | Robustness                         |

Priority 1-3 can be written without understanding function internals.
Priority 4-5 require reading and understanding the implementation.

## Module Processing Order

### Phase 1 -- Foundations

These modules underpin everything. Breakage here cascades everywhere.

```
1. lib/core/col    -- no test, small file, easy first win
2. lib/gen/ana     -- no test, used by aux and ops modules
3. lib/core/err    -- has tests, review and deepen
4. lib/core/lo1    -- has tests, review and deepen
5. lib/core/tme    -- has tests, review and deepen
6. lib/core/ver    -- has tests, review and deepen
7. lib/gen/aux     -- foundation of all ops logging and validation
8. lib/gen/env     -- environment resolution
9. lib/gen/inf     -- infrastructure definitions
10. lib/gen/sec    -- security utilities
```

### Phase 2 -- High-impact operations

Per ops priority guidance: GPU, PVE, and STO have the highest operational impact.

```
11. lib/ops/gpu    -- 7 public functions, already best-tested ops module
12. lib/ops/pve    -- 15 public functions, missing pve_test.sh entirely
13. lib/ops/sto    -- 17 public functions, largest ops module
```

### Phase 3 -- Infrastructure operations

```
14. lib/ops/net    -- 6 public functions
15. lib/ops/srv    -- 8 public functions
16. lib/ops/ssh    -- 14 public functions
```

### Phase 4 -- System and user operations

```
17. lib/ops/sys    -- 10 public functions
18. lib/ops/usr    -- 14 public functions
19. lib/ops/pbs    -- 6 public functions
20. lib/ops/dev    -- 5 public functions
```

## Test Writing Guidelines

### Use the existing framework

All tests must source val/helpers/test_framework.sh and follow the
run_test_suite / test_header / test_footer pattern. No ad-hoc test scripts.

### Follow pve_compliance_test.sh as the model

That test file is the closest to proper unit testing in the codebase. It calls
real functions with bad inputs and asserts return codes. Use it as a template.

### Mock infrastructure calls

Ops functions touch real systems. Tests must never execute against live
infrastructure. Strategies:

- Test parameter validation paths (these return before any system call).
- Test --help paths (these return before any system call).
- For behavioral tests, mock external commands using function overrides
  in test subshells.
- Use create_test_env for filesystem-dependent tests.

### Name and place test files consistently

```
lib/core/col   -->  val/core/modules/col_test.sh
lib/gen/ana    -->  val/lib/gen/ana_test.sh
lib/ops/pve    -->  val/lib/ops/pve_test.sh   (new, alongside existing compliance)
```

### What a complete function test looks like

```bash
test_xyz_help() {
    test_header "xyz --help"
    local output
    output=$(xyz_cmd --help 2>&1)
    local rc=$?
    assert_equals "0" "$rc" "help returns 0"
    assert_contains "$output" "Usage" "help shows usage"
    test_footer
}

test_xyz_missing_params() {
    test_header "xyz missing params"
    xyz_cmd 2>/dev/null
    local rc=$?
    assert_equals "1" "$rc" "missing params returns 1"
    test_footer
}

test_xyz_invalid_params() {
    test_header "xyz invalid params"
    xyz_cmd "not-a-number" 2>/dev/null
    local rc=$?
    assert_equals "1" "$rc" "invalid param type returns 1"
    test_footer
}

test_xyz_behavior() {
    test_header "xyz correct behavior"
    local output
    output=$(xyz_cmd "valid_input" 2>/dev/null)
    local rc=$?
    assert_equals "0" "$rc" "valid input returns 0"
    assert_contains "$output" "expected" "output contains expected value"
    test_footer
}
```

## Improvement Guidelines

Once tests are in place for a module, improvements follow `lib/.spec` and `lib/ops/.spec`:
- Use `lib/.spec` for canonical global and quality standards.
- Use `lib/ops/.spec` for ops and DIC-specific contracts.

### .spec compliance (mandatory, do first)

- aux_use comment blocks (3 lines above function).
- aux_tec technical detail block inside function.
- aux_val for parameter validation.
- aux_chk for dependency checks.
- Structured logging via aux_info, aux_warn, aux_err (no raw echo).
- Return codes: 0 success, 1 param error, 2 system error, 127 missing command.
- --help / -h handled first in every function.
- No function without parameters (-x flag pattern for action functions).

### Quality guidance (aspirational, do after .spec compliance)

- Single responsibility per function.
- Maximum 150 lines per function, split into _helpers.
- Stateless design, no hardcoded paths.
- Safe file operations with backups and mktemp.
- Input sanitization.
- Graceful degradation with actionable error messages.

## Verification Sequence

After completing each module:

```
1. bash -n lib/ops/<module>                          -- syntax check
2. ./val/lib/ops/<module>_test.sh                    -- unit tests
3. ./val/lib/ops/<module>_std_compliance_test.sh     -- if exists
4. ./val/run_all_tests.sh <category>                 -- category suite
5. ./val/run_all_tests.sh                            -- full suite (after phase completion)
```

Run step 5 after completing each phase, not after every module.

## Completion Criteria

A module is considered reviewed and complete when:

- All public functions have tests for priorities 1-4 (help, params, deps, behavior).
- All tests pass.
- std_compliance_test.sh reports no .spec violations for the module.
- bash -n passes.
- No raw echo/printf used for operational messages.
- All functions have aux_use, aux_tec, and aux_val.

## Risk Mitigation

- Never run ops functions outside the test harness during review.
- Never modify cfg/env/ files as part of this effort.
- Commit after each completed module (tests + improvements together).
- If a function's behavior is unclear, ask before changing it.
- If tests reveal that a function is broken in production, document the bug
  but do not fix it as part of this review unless explicitly approved.

---

# Bootstrapper Rewrite Plan — bin/ini

Status: active
Scope: bin/ini, bin/orc, lib/core/tme (timer I/O), val/ coverage
Preserves: terminal boot output, timing report, fallback environment

---

## 0. Philosophy: Boot Output Is Not Redundant

The startup output and the test suite serve fundamentally different roles.

Tests (val/) verify correctness in isolation — they run offline, against
a snapshot of the code. The boot output is a POST (Power-On Self-Test) —
it confirms the actual runtime environment is healthy RIGHT NOW, on THIS
machine, with THESE file permissions, THESE dependencies installed.

Think of it this way:
- val/ answers: "does the code work?"
- boot output answers: "is this machine ready?"

A test suite cannot tell you that /home/es/lab/.log lost write permissions
since yesterday, or that `bc` was removed by a package update. The boot
output catches that the moment you open a shell. The visual scroll IS the
value — one glance and you know the system is whole.

What needs to change is not the presence of output but its efficiency.
The current bootstrapper pays a real performance tax to produce that output
(forks for timestamps, file I/O per timer event, redundant sourcing). The
goal is to keep the POST experience while cutting the waste underneath.

---

## 1. Diagnosed Inefficiencies

### 1.1 Fork overhead in ini_log (bin/ini:158)

Every `ini_log` call runs `date '+%H:%M:%S'` in a subshell. During
bootstrap there are ~30 log calls. That is 30 forks before the system
is even loaded.

    Fix: Use `printf '%(%H:%M:%S)T' -1` (bash 4.2+ built-in, zero forks).

### 1.2 Redundant `type` checks for timer functions (bin/ini, throughout)

The pattern `type tme_start_timer &>/dev/null && tme_start_timer ...`
appears 15+ times. Each `type` invocation is cheap individually but the
pattern clutters the code and the repeated guard implies uncertainty about
whether tme is loaded. After `load_modules` succeeds, this should be a
settled question.

    Fix: After load_modules, set a flag `_TME_AVAILABLE=1`. Replace all
    scattered `type` checks with `((_TME_AVAILABLE)) && tme_start_timer`.
    Better yet, define a no-op wrapper early and replace it with the real
    function after tme loads — zero conditional overhead at call sites.

### 1.3 Double-sourcing of rdc (bin/ini:190 + bin/ini:504)

`cfg/core/rdc` is sourced unconditionally at top level (line 190-193),
then sourced again inside `init_runtime_system` (line 504). The second
source is unnecessary — rdc has no re-source guard and re-declares
the same arrays.

    Fix: Remove the second source. rdc is already loaded.

### 1.4 Timer file I/O storm (lib/core/tme)

Every `tme_start_timer` / `tme_end_timer` cycle:
- Reads LOG_STATE_FILE (to save current state)
- Writes LOG_STATE_FILE to "false" (to suppress lo1 during timing)
- Writes TME_LOG_FILE (the timing event)
- Reads LOG_STATE_FILE (to check saved state)
- Writes LOG_STATE_FILE (to restore saved state)

That is 4-5 file I/O operations per timer event. With ~20 timer events
during bootstrap, that is 80-100 file reads/writes just for timing.

    Fix: Replace the log-suppression mechanism. Instead of manipulating
    LOG_STATE_FILE on disk, use an in-memory flag:
    `_TME_SUPPRESS_LOG=1` checked by lo1_log before writing. This
    eliminates all the save/restore file I/O.

### 1.5 mktemp per source_helper call (bin/orc:150)

`source_helper` creates a temporary file via `mktemp` to capture stderr
from every sourced file. That is a fork + file create + file read + file
delete per component. With ~15 components sourced through orc, that is
60 unnecessary operations.

    Fix: Use a single persistent temp file created once in
    setup_components, reused across all source_helper calls, cleaned up
    at the end. Or capture stderr to a variable directly:
    `error_output=$(source "$file" 2>&1 1>/dev/null)` — though this
    changes fd routing. The single-tempfile approach is safer.

### 1.6 find+sort per source_directory call (bin/orc:223)

Each `source_directory` call forks `find | sort` and writes results to
a mktemp file. For lib/ops alone this means 3+ forks.

    Fix: Replace with a bash glob + readarray pattern:
    ```
    local files=()
    for f in "$dir"/$pattern; do
        [[ -f "$f" ]] && files+=("$f")
    done
    IFS=$'\n' files=($(sort <<<"${files[*]}")); unset IFS
    ```
    Zero forks, same result.

### 1.7 Dead and hollow code in bin/ini

- `process_runtime_config` (line 534-537): empty function, logs and
  returns 0. Either give it a purpose or remove it.
- `register_function` (line 663-695): never called anywhere. Dead code.
- `verify_function_dependencies` (line 624-636): defined but never
  called — `ver_verify_function_dependencies` (from lib/core/ver) is
  what line 613 actually invokes. The local one shadows it and is dead.
- `init_flow.log` write (line 473): debug artifact, not part of the
  logging system. Remove or route through ini_log.

    Fix: Remove dead functions. Either implement process_runtime_config
    or inline its call site.

### 1.8 Dual-loop module loading (bin/ini:437-469)

`load_modules` iterates the module array twice: once for "batch
validation" (file existence check), then again for actual sourcing.
The first loop does nothing useful — the second loop checks existence
again before sourcing.

    Fix: Single pass. Check and source in one iteration.

### 1.9 Fragile dynamic scoping for caches (bin/ini:553-597)

`init_registered_functions` declares `module_cache` and
`module_paths_cache` as local associative arrays, then expects child
functions `cache_module_verification` and `process_function_registration`
to read and write them via bash dynamic scoping. This works but is
invisible and fragile.

    Fix: Either make them global (with cleanup) or pass data through
    function arguments / return values. If kept as dynamic scope, add
    a comment block documenting the contract.

---

## 2. Structural Rewrite

### 2.1 New bin/ini architecture

The current ini has grown organically. Functions are interspersed with
orchestration logic and helper definitions. The rewrite should separate
these cleanly.

Proposed structure:

```
bin/ini
├── Guard: _INI_LOADED check + wall-clock capture
├── Constants: readonly declarations
├── Section 1: Minimal helpers (ini_log, ensure_dir, no-op timer stubs)
├── Section 2: Pre-module loading (source ric, rdc, mdc, ver)
├── Section 3: Core module loading (col, err, lo1, tme — single pass)
├── Section 4: Post-load setup (replace stubs with real timers, start main timer)
├── Section 5: Orchestrator delegation (source orc, call setup_components)
├── Section 6: Finalization (RC_SOURCED, timing report, total duration)
└── Section 7: Fallback (setup_minimal_environment, only on failure)
```

Key change: the no-op stub pattern. Before tme is loaded, define:

```bash
tme_start_timer() { :; }
tme_end_timer()   { :; }
```

After tme loads successfully, these get overwritten by the real
functions. This eliminates every `type tme_start_timer &>/dev/null`
guard in the entire file.

### 2.2 Collapse the function registration machinery

The current flow for registered functions:

```
init_registered_functions
  → cache_module_verification    (iterates REGISTERED_FUNCTIONS)
  → process_function_registration (iterates REGISTERED_FUNCTIONS again)
    → ver_verify_function_dependencies
    → register_single_function
      → ver_verify_function
      → source module (which was already sourced by load_modules)
```

This re-sources modules that were already loaded in `load_modules`.
The entire registration machinery was designed for a world where modules
are loaded on demand. But bin/ini already sources all core modules
unconditionally. The registration system verifies that functions exist
in files that are already sourced — it adds verification cost without
loading anything new.

    Options:
    a) Keep registration as a verification-only pass (no re-sourcing).
       This preserves the POST value: "these 6 functions are confirmed
       available." Just remove the `source` call in register_single_function
       since the module is already loaded.
    b) Remove registration entirely and replace with a simple post-load
       check: `type err_process &>/dev/null || ini_log "WARN: ..."` for
       each critical function.
    c) Move registration into val/ as a test. This is the "tests handle
       correctness, boot handles runtime" split in action.

    Recommendation: option (a) for now. It keeps the POST output and
    removes the redundant sourcing. Option (c) is a future refinement.

### 2.3 Simplify bin/orc source_helper

Replace the mktemp-per-call pattern with a single shared error capture
file:

```bash
setup_components() {
    local _orc_error_file
    _orc_error_file=$(mktemp) || { ...; return 1; }
    trap "rm -f '$_orc_error_file'" RETURN

    # ... pass _orc_error_file to source_helper calls
}
```

source_helper then truncates and reuses this file instead of creating
a new one each time.

---

## 3. Output Improvements

### 3.1 Keep the scroll, tighten the format

The current output uses `└─ message [HH:MM:SS]` for every ini_log line.
This is good. But some messages are noise during normal operation:

```
└─ Starting module system initialization [08:12:01]
└─ Starting directory initialization [08:12:01]
└─ Module file verified: col [08:12:01]
└─ Module file verified: err [08:12:01]
└─ Loading module: col [08:12:01]
└─ Successfully loaded module: col [08:12:01]
```

That is 6 lines for what should be 1-2 lines. The "batch validation"
messages add nothing when followed immediately by the load messages.

    Proposed output for a clean boot:

    ```
     ───────────────
    └─ core: ric rdc mdc ver [08:12:01]
    └─ modules: col err lo1 tme [08:12:01]
    └─ orchestrator: sourced [08:12:01]
    └─ components: CFG_ECC CFG_ALI LIB_OPS LIB_UTL CFG_ENV SRC_AUX [08:12:02]
    └─ registered: 6/6 functions [08:12:02]
     ━ Initialization completed in 847ms
    ```

    On failure, the failing step expands to show detail:

    ```
    └─ modules: col err [FAIL:lo1] tme [08:12:01]
    └─   lo1: LOG_STATE_FILE not writable
    ```

This gives the at-a-glance POST feel with minimal noise. The full
detail still goes to .log/ini.log for forensics.

### 3.2 Preserve the timing report

The `tme_print_timing_report` at the end is valuable and should stay.
No changes needed to its output format, only to its internal I/O
efficiency (section 1.4).

### 3.3 Verbosity levels

The current two-level system (MASTER + per-module) is good. Add one
more level for the new compact output:

- `INI_OUTPUT_MODE=compact` (default): the condensed POST format above
- `INI_OUTPUT_MODE=verbose`: current line-per-event output (for debugging)
- `INI_OUTPUT_MODE=silent`: no terminal output (for non-interactive / CI)

This is controlled alongside the existing MASTER_TERMINAL_VERBOSITY
switches — when MASTER is off, everything is off regardless of mode.

---

## 4. Bootstrapper Test Coverage Gaps

### 4.1 Current state

Only `val/core/initialization/ini_test.sh` (175 lines, 8 tests) covers
the bootstrapper directly. No test exists for bin/orc.

### 4.2 New tests needed

| Test file | What it covers |
|-----------|---------------|
| `val/core/initialization/ini_perf_test.sh` | Benchmark: ini completes under 2s (tighten from 5s) |
| `val/core/initialization/ini_output_test.sh` | Captures stderr, verifies POST format appears |
| `val/core/initialization/ini_failure_test.sh` | Remove a core module, verify fallback triggers |
| `val/core/initialization/orc_test.sh` | Test setup_components, source_helper, execute_component |
| `val/core/initialization/orc_failure_test.sh` | Required component failure halts chain |

### 4.3 Relationship between boot output and tests

The boot output and tests should validate DIFFERENT things:

| Aspect | Boot output (bin/ini) | Test suite (val/) |
|--------|----------------------|-------------------|
| File permissions | yes (runtime check) | no (varies by host) |
| Module syntax | no (source will fail) | yes (bash -n) |
| Function signatures | no | yes (unit tests) |
| Dependency availability | yes (bc, dirs, files) | partially |
| Cross-module integration | yes (real load order) | yes (mocked) |
| Performance regression | yes (wall-clock display) | yes (threshold) |

This confirms: boot output is POST, tests are QA. Both needed.

---

## 5. Bootstrapper Execution Order

### Phase 1 — Zero-risk cleanup (no behavior change)

1. Remove dead functions: `register_function`, `verify_function_dependencies`,
   `process_runtime_config` (or implement it)
2. Remove `init_flow.log` debug write
3. Remove double-sourcing of rdc
4. Replace `date '+%H:%M:%S'` with `printf '%(%H:%M:%S)T'` in ini_log
5. Document the dynamic-scope contract for module_cache
6. Run: `bash -n bin/ini && ./val/core/initialization/ini_test.sh`

### Phase 2 — Internal efficiency (same output, faster)

7. Implement no-op timer stubs, replace all `type` guards
8. Single-pass module loading (collapse dual loop)
9. Remove re-sourcing in register_single_function
10. tme: replace LOG_STATE_FILE manipulation with in-memory flag
11. orc: single shared tempfile for source_helper
12. orc: bash glob instead of find+sort in source_directory
13. Run: `./val/run_all_tests.sh core && ./val/run_all_tests.sh integration`

### Phase 3 — Output refinement

14. Implement compact POST output format
15. Add INI_OUTPUT_MODE switch (compact/verbose/silent)
16. Keep verbose mode as 1:1 equivalent of current output
17. Write new test: ini_output_test.sh
18. Run: `./val/run_all_tests.sh`

### Phase 4 — Structural rewrite

19. Reorganize bin/ini into the 7-section layout (section 2.1)
20. Simplify the function registration path (option a from section 2.2)
21. Write orc_test.sh and orc_failure_test.sh
22. Write ini_failure_test.sh and ini_perf_test.sh (2s threshold)
23. Run: `./val/run_all_tests.sh`
24. Tighten existing ini_test.sh threshold from 5000ms to 2000ms

---

## 6. What NOT to Change

- The re-source guard (`_INI_LOADED`) — essential for `lab` command
- The wall-clock timing at the end — users rely on this
- The timing report (`tme_print_timing_report`) — keep as-is
- The fallback to minimal environment — safety net stays
- The sourcing chain order (ric → mdc → rdc → ver → modules → orc)
- The verbosity master switch hierarchy
- MASTER_TERMINAL_VERBOSITY / INI_LOG_TERMINAL_VERBOSITY semantics
- The `export -f main_ini` at the end

---

## 7. Expected Outcome

Current bootstrap: ~800-1200ms typical (5000ms test threshold)
Target bootstrap: <500ms typical (2000ms test threshold)

Primary savings come from:
- Eliminating ~80-100 file I/O ops from tme (section 1.4): ~200ms
- Eliminating ~30 date forks from ini_log (section 1.1): ~100ms
- Eliminating ~15 mktemp cycles from orc (section 1.5): ~100ms
- Eliminating ~6 find/sort forks from orc (section 1.6): ~50ms
- Single-pass module loading (section 1.8): ~30ms

Terminal output: same information density, fewer lines in compact mode,
identical lines available in verbose mode. The boot-scroll experience
is preserved — you still see the system come alive, just without the
redundant chatter.
