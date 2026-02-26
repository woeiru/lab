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