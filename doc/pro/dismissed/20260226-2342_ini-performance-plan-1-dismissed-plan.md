# bin/ini Performance Optimization Plan

Status: dismissed

## Dismissal Reason
- Superseded by newer planning iterations that consolidate this work into a single execution track.
- Large overlap with other ini performance plans would duplicate effort and increase merge risk.
- Several estimates and sequencing assumptions should be re-baselined before adoption.

Performance analysis and implementation plan for the shell bootstrapper.
All findings are verified against actual code. Organized into independent
workstreams that can be executed in parallel.

## Measurement Baseline

Before any work, capture a baseline:

```bash
# Run 5 times, record median
for i in {1..5}; do
  bash -c 'source bin/ini' 2>&1 | tail -1
done
```

The final line of ini output prints total elapsed time in ms or seconds.
All optimizations below should be re-measured against this baseline.

---

## WS-1: Fork/Exec Elimination

**Files:** `lib/core/tme`, `lib/core/ver`, `lib/core/lo1`, `lib/core/err`, `bin/ini`
**Impact:** HIGH -- each fork/exec costs ~2-5ms on Linux; current init forks 60-100+ times
**Parallel:** Yes, independent of other workstreams

### 1.1 Replace `date` calls with printf builtins

Bash 4.2+ supports `printf '%(%H:%M:%S)T' -1` which is a shell builtin
(zero fork cost). The codebase already uses this in some lo1 functions but
not consistently.

| File | Line(s) | Current | Replacement |
|------|---------|---------|-------------|
| `bin/ini` | 69, 736 | `date +%s%N` | `printf '%(%s)T' -1` + `$EPOCHREALTIME` (bash 5.0+) or keep one `date` call for nanoseconds |
| `bin/ini:ini_log` | 157 | `date '+%H:%M:%S'` | `printf -v timestamp '%(%H:%M:%S)T' -1` |
| `lib/core/ver:ver_log` | 37, 49 | `date '+%H:%M:%S'` and `date '+%Y-%m-%d %H:%M:%S'` (two forks per call) | `printf -v timestamp '%(%H:%M:%S)T' -1` and `printf -v full_ts '%(%Y-%m-%d %H:%M:%S)T' -1` |
| `lib/core/err:err_process` | 60 | `date '+%Y-%m-%d %H:%M:%S'` | `printf -v timestamp '%(%Y-%m-%d %H:%M:%S)T' -1` |
| `lib/core/err:err_process` | 66 | `date +%s%N` (for error_id) | `$RANDOM` or `$EPOCHREALTIME` or incrementing counter |
| `lib/core/err:err_handler` | 149 | `date '+%Y%m%d%H%M%S'` | `printf -v timestamp '%(%Y%m%d%H%M%S)T' -1` |
| `lib/core/tme:tme_start_timer` | 158 | `date +%s.%N` | See 1.2 below |
| `lib/core/tme:tme_end_timer` | 203 | `date +%s.%N` | See 1.2 below |
| `lib/core/tme:tme_init_timer` | 132 | `date +%s.%N` | See 1.2 below |
| `lib/core/lo1:lo1_get_cached_log_state` | 84 | `date +%s` | `printf -v current_time '%(%s)T' -1` |
| `lib/core/lo1:cleanup_cache` | 110 | `date +%s` | `printf -v current_time '%(%s)T' -1` |

**Note on nanosecond timestamps:** Bash 5.0+ provides `$EPOCHREALTIME`
(e.g. `1234567890.123456`) as a variable -- zero fork cost. For bash 4.x,
`date +%s.%N` must remain, but should be called minimally. Check bash
version with: `[[ ${BASH_VERSINFO[0]} -ge 5 ]]`.

### 1.2 Replace `bc` with bash arithmetic

`tme_end_timer` (line 209) pipes to `bc` for every timer stop:
```bash
TME_DURATIONS[$component]=$(echo "$timestamp - $start_time" | bc)
```

This is a fork+exec of `bc` for simple subtraction. Replace with
bash integer arithmetic on separate integer/fractional parts, or
use `$EPOCHREALTIME` and awk-free string math. Example:

```bash
# If using EPOCHREALTIME (bash 5.0+):
local start="${TME_START_TIMES[$component]}"
local end="$EPOCHREALTIME"
# Use parameter expansion to split on '.', do integer math
local s_sec="${start%.*}" s_frac="${start#*.}"
local e_sec="${end%.*}" e_frac="${end#*.}"
# Pad fractions to equal length and subtract
# ... (implementation detail)
```

Also applies to `tme_print_timing_report` (line 460) and
`print_timing_entry` (lines 259, 261) but those run once at
report time, so lower priority.

### 1.3 Replace `$(basename ...)` with parameter expansion

| File | Line(s) | Current | Replacement |
|------|---------|---------|-------------|
| `bin/ini:load_modules` | 441, 453 | `$(basename "$module")` | `${module##*/}` |
| `bin/orc:source_helper` | 122 | `$(basename "$file")` | `${file##*/}` |
| `bin/orc:source_directory` | 233 | `$(basename "$file")` | `${file##*/}` |
| `bin/orc:source_lib_ops` | 402 | `$(basename "$file")` | `${file##*/}` |
| `lib/core/ver:ver_validate_module` | 297 | `$(basename "$file")` | `${file##*/}` |

### 1.4 Replace `$(dirname ...)` with parameter expansion

| File | Line(s) | Current | Replacement |
|------|---------|---------|-------------|
| `bin/ini:ini_log` | 169 | `$(dirname "$INI_LOG_FILE")` | `${INI_LOG_FILE%/*}` |
| `lib/core/ver:ver_log` | 46 | `$(dirname "$VER_LOG_FILE")` | `${VER_LOG_FILE%/*}` |

---

## WS-2: I/O Reduction

**Files:** `lib/core/tme`, `lib/core/lo1`, `lib/core/ver`, `bin/ini`, `bin/orc`
**Impact:** HIGH -- disk I/O per-call adds latency, especially repeated reads of state files
**Parallel:** Yes, independent of other workstreams

### 2.1 Eliminate LOG_STATE_FILE read/write in tme_start_timer and tme_end_timer

`tme_start_timer` (lines 175-185) and `tme_end_timer` (lines 218-228)
both read `$LOG_STATE_FILE` with `cat`, write `"false"` to it, do their
work, then write the original value back. This is 4 file operations per
timer start/stop pair, and timers are started/stopped ~20-30 times during
init.

**Fix:** Use a global variable instead of file I/O for transient state
toggling. The file is only needed for persistence across shell sessions,
not within a single init run.

```bash
# In tme_start_timer, replace:
#   orig_log_state=$(cat "$LOG_STATE_FILE" 2>/dev/null || echo "true")
#   echo "false" > "$LOG_STATE_FILE"
#   ... work ...
#   echo "$orig_log_state" > "$LOG_STATE_FILE"
# With:
local _prev_log_cached="$LOG_STATE_CACHED"
LOG_STATE_CACHED="off"
# ... work ...
LOG_STATE_CACHED="$_prev_log_cached"
```

This eliminates ~80-120 file operations during init.

### 2.2 Eliminate `mkdir -p` in ver_log on every call

`ver_log` (line 46) runs `mkdir -p "$(dirname "$VER_LOG_FILE")"` on
every single invocation. The directory is created once during
`ver_essential_check` and never needs re-checking.

**Fix:** Add a guard variable:

```bash
[[ -z "${_VER_LOG_DIR_READY:-}" ]] && {
    mkdir -p "${VER_LOG_FILE%/*}" 2>/dev/null
    _VER_LOG_DIR_READY=1
}
```

### 2.3 Reduce log file count and writes during init

Currently 6 log files are written during init:
- `.log/ini.log` (ini_log)
- `.log/ver.log` (ver_log)
- `.log/lo1.log` (lo1_log, lo1_debug_log)
- `.log/tme.log` (tme_start_timer, tme_end_timer)
- `.log/err.log` (err_process)
- `.log/init_flow.log` (load_modules)

**Fix options (choose one):**
- **Option A:** Buffer log writes in variables during init, flush once at end
- **Option B:** Use a single init log file with prefixed lines `[INI]`, `[VER]`, etc.
- **Option C:** Keep separate files but batch writes using file descriptors opened once

Option C is the least invasive:
```bash
# Open FD once at start
exec 7>>"$INI_LOG_FILE"
# In ini_log, replace:
#   echo "..." >> "$INI_LOG_FILE"
# With:
echo "..." >&7
# Close at end
exec 7>&-
```

### 2.4 Remove mktemp in source_helper (bin/orc)

`source_helper()` (lines 149-176) creates a `mktemp` file for every
sourced file just to capture stderr. With ~15-20 files sourced via
source_helper, that is 15-20x `mktemp` + `cat` + `rm`.

**Fix:** Capture stderr to a variable instead:

```bash
local error_output
error_output=$(source "$file" 2>&1 1>/dev/null) && {
    # success path (source ran in subshell for stderr only)
}
```

However, `source` must run in the current shell to define functions.
Better approach -- redirect stderr to a variable using process substitution
or simply suppress it and check return code:

```bash
if source "$file" 2>>"$ERROR_LOG"; then
    lo1_log "lvl" "Successfully sourced: ${file##*/}"
    tme_end_timer "source_$description" "success"
    return 0
else
    lo1_log "lvl" "Error sourcing ${file##*/}, check $ERROR_LOG"
    tme_end_timer "source_$description" "error"
    return 1
fi
```

This eliminates all mktemp/cat/rm overhead and still captures errors.

### 2.5 Replace `find | sort` with glob in source_directory / source_lib_ops

`source_directory()` (lines 222-236) and `source_lib_ops()` (lines 382-406)
both run `find ... -print0 | sort -z > tempfile` then read the tempfile.
This is 3 processes (find, sort, tempfile write) + mktemp.

**Fix:** Use bash glob which is a builtin:

```bash
local files=()
shopt -s nullglob
for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    # apply exclusions for source_lib_ops
    case "${f##*/}" in
        *.md|*.txt|*.spec|*.readme|*.doc|README*|readme*|.*) continue ;;
    esac
    files+=("$f")
done
shopt -u nullglob
# files array is already sorted by glob expansion (alphabetical)
```

---

## WS-3: Redundant Work Elimination

**Files:** `bin/ini`, `cfg/core/rdc`, `cfg/core/mdc`, `lib/core/ver`
**Impact:** MEDIUM -- eliminates wasted cycles but individual items are cheaper than fork/exec
**Parallel:** Yes, independent of other workstreams

### 3.1 cfg/core/rdc sourced twice

`bin/ini` sources `cfg/core/rdc` at line 190-193 (top-level), then
`init_runtime_system()` sources it again at line 504:

```bash
local rde_path="${BASE_DIR}/cfg/core/rdc"
source "$rde_path" 2>/dev/null
```

**Fix:** Remove the second sourcing in `init_runtime_system()`. The file
defines associative arrays that are already populated from the first source.
The `ver_verify_path` check before it (line 495) can remain as a sanity
check but the `source` call is redundant.

### 3.2 Double iteration in load_modules

`load_modules()` iterates the modules array twice: once for "batch
validation" (lines 439-449) and once for actual loading (lines 452-469).
The first loop only calls `check_file_cached` which is then called again
in the second loop.

**Fix:** Remove the first loop entirely. The second loop already does
`check_file_cached` at line 458. The first loop's only purpose was to
populate the cache, but since the second loop is immediate, there is no
cache benefit -- it's pure overhead.

### 3.3 Redundant `type` checks after module loading

After `load_modules()` loads tme, the code checks `type tme_start_timer`
repeatedly:
- `init_timer_system()` lines 284, 288
- `source_with_timer()` lines 139, 141, 145, 150
- `source_component_orchestrator()` line 308
- `init_runtime_system_with_timing()` lines 325, 328, 332
- `setup_components_with_finalization()` lines 347, 356, 357
- `init_runtime_system()` 8 occurrences, lines 494-527

**Fix:** Set a flag variable once after tme is verified loaded:

```bash
_TME_AVAILABLE=0
type tme_start_timer &>/dev/null && _TME_AVAILABLE=1
```

Then replace all `type tme_start_timer &>/dev/null &&` with
`((_TME_AVAILABLE)) &&`. `type` is a builtin but still has overhead from
hash table lookup and stderr redirection.

### 3.4 init_module_requirements called multiple times

`init_module_requirements()` (defined in `cfg/core/mdc`) populates
MODULE_VARS, MODULE_PATHS, MODULE_OPTS, MODULE_COMMANDS. It is called:
1. From `init_module_system()` at `bin/ini:379`
2. Potentially again from `ver_verify_module()` at `lib/core/ver:212-213`
   if the arrays appear empty

**Fix:** Add a guard at top of `init_module_requirements`:
```bash
[[ -n "${_MODULE_REQS_LOADED:-}" ]] && return 0
_MODULE_REQS_LOADED=1
```

### 3.5 process_runtime_config is a no-op

`process_runtime_config()` (bin/ini:534-537) does nothing except log. It
is called with full timer wrapping (lines 512-518) adding overhead for
zero functionality.

**Fix:** Remove the function and its timer wrapping from
`init_runtime_system()`, or gate it behind a check:
```bash
if type process_runtime_config &>/dev/null; then
    process_runtime_config
fi
```

---

## WS-4: Logging and Debug Overhead

**Files:** `lib/core/lo1`, `bin/orc`
**Impact:** HIGH -- lo1_log is called 30-50+ times during init, each call is very expensive
**Parallel:** Yes, independent of other workstreams

### 4.1 LOG_DEBUG_ENABLED=1 by default causes massive overhead

`lib/core/lo1` line 38 sets `LOG_DEBUG_ENABLED=1`. This means every
`lo1_log` call (line 283) also triggers:
- `lo1_debug_log` -- formats and writes to LOG_FILE
- `lo1_dump_stack_trace` -- walks entire FUNCNAME array and writes
  multiple lines per call

With ~30-50 lo1_log calls during init and average stack depth of 5-8,
this generates hundreds of extra file writes.

**Fix:** Set `LOG_DEBUG_ENABLED=0` by default. Let users opt in:
```bash
export LOG_DEBUG_ENABLED=${LOG_DEBUG_ENABLED:-0}
```

### 4.2 lo1_log calls 4 subshell functions via command substitution

Every `lo1_log` invocation triggers:
1. `lo1_get_cached_log_state` -- returns via echo (subshell capture)
2. `lo1_calculate_final_depth` -> `lo1_get_base_depth` -- returns via echo
3. `lo1_get_indent` -- returns via echo
4. `lo1_get_color` -- returns via echo

Each `$(...)` creates overhead. All four could use variable indirection
instead of echo+capture:

```bash
# Instead of: local depth; depth=$(lo1_calculate_final_depth)
# Use a pattern where the function sets a variable directly:
lo1_calculate_final_depth  # sets _LO1_DEPTH
local depth=$_LO1_DEPTH
```

This is a larger refactor but eliminates 4 subshell-like overheads per
lo1_log call. With 30-50 calls, that's 120-200 subshell eliminations.

**Alternative (less invasive):** Inline the logic directly into lo1_log:

```bash
lo1_log() {
    [[ "$1" != "lvl" ]] && return 1
    local message="$2"

    # Inline cached state check (skip subshell)
    local log_enabled="$LOG_STATE_CACHED"
    if [[ -z "$log_enabled" ]]; then
        log_enabled=$(cat "$LOG_STATE_FILE" 2>/dev/null || echo "on")
        LOG_STATE_CACHED="$log_enabled"
    fi

    # Skip everything if logging is fully off
    [[ "$log_enabled" != "on" ]] && return 0

    # Inline depth/indent/color (avoid subshells)
    local depth=0  # simplified for init context
    local timestamp
    printf -v timestamp '%(%H:%M:%S)T' -1

    printf "      └─ %s %s\n" "$timestamp" "$message" >> "$LOG_FILE"

    if [[ "${MASTER_TERMINAL_VERBOSITY:-on}" == "on" && "${LO1_LOG_TERMINAL_VERBOSITY:-on}" == "on" ]]; then
        printf "      └─ %s %s\n" "$timestamp" "$message" >&2
    fi
}
```

### 4.3 lo1_get_base_depth walks entire FUNCNAME on every call

`lo1_get_base_depth()` iterates the call stack with a while loop
(lines 178-194). During init, this runs 30-50 times. The cache helps
for repeated callers but during init most callers are unique.

**Fix for init context:** During PERFORMANCE_MODE=1 (which ini sets),
skip depth calculation entirely and use a fixed depth:

```bash
lo1_get_base_depth() {
    if [[ "${PERFORMANCE_MODE:-0}" == "1" ]]; then
        echo 1
        return
    fi
    # ... existing logic
}
```

---

## WS-5: Orc Structural Optimizations

**Files:** `bin/orc`
**Impact:** MEDIUM
**Parallel:** Yes, independent of other workstreams

### 5.1 validate_required_globals iterates 9 variables with indirect expansion

`validate_required_globals()` (lines 86-117) loops through 9 required
vars and 1 optional var using `${!var:-}`. This is fine but the optional
var check calls `lo1_log` which is expensive.

**Fix:** Minor -- just remove the optional var warning during init or
gate behind PERFORMANCE_MODE.

### 5.2 execute_component type-checks function existence every time

`execute_component()` (line 276) runs `type "$func" &>/dev/null` for each
component. Since the functions are defined in this very file (orc), they
are always present.

**Fix:** Low priority, but could skip the check for known-internal functions.

### 5.3 source_cfg_ecc double-checks file existence

`source_cfg_ecc()` checks `[[ -f "${ecc_file}" ]]` at line 505, then
calls `source_helper` which checks `[[ ! -f "$file" ]]` again at
line 133, and `[[ ! -r "$file" ]]` at line 141.

Same pattern exists in `source_cfg_env()` for 3 files.

**Fix:** Trust `source_helper` to do all validation; remove the outer
existence checks. Or vice versa -- skip inner checks for known-validated
files.

---

## WS-6: Module Load Order and Architecture

**Files:** `bin/ini`, `lib/core/*`
**Impact:** MEDIUM -- structural changes for longer-term gains
**Parallel:** Partially (design must precede implementation)

### 6.1 ver_verify_module called at source-time for err, lo1, tme

Each of these modules runs `ver_verify_module "xxx" || exit 1` as their
first line:
- `lib/core/err:28`
- `lib/core/lo1:31`
- `lib/core/tme:34`

`ver_verify_module` (ver:194-290) does extensive checking: iterates
MODULE_VARS, MODULE_PATHS, MODULE_COMMANDS with pattern matching and
calls ver_verify_var, ver_verify_path, and `command -v` for each match.
For 3 modules, this is ~15-20 verification operations with logging.

**Fix options:**
- **Option A:** Skip verification during init (trust the layout), verify
  lazily on first use
- **Option B:** Replace per-module verification with a single batch
  verification pass before loading all modules:
  ```bash
  ver_verify_modules_batch "err" "lo1" "tme"
  source "${BASE_DIR}/lib/core/err"
  source "${BASE_DIR}/lib/core/lo1"
  source "${BASE_DIR}/lib/core/tme"
  ```
- **Option C:** Guard with `[[ "${SKIP_MODULE_VERIFY:-}" == "1" ]]`
  for performance-sensitive contexts

### 6.2 Registered functions system overhead for 6 functions

The entire `init_registered_functions` flow (ini:540-660) processes
only 6 functions. For each function it:
1. Caches module verification (iterating all functions to find deps)
2. Calls `ver_verify_function_dependencies` (which calls `ver_verify_module`)
3. Calls `register_single_function` (which calls `ver_verify_function`
   doing a `grep` on the source file, then re-sources it)

The modules (err, lo1, tme) are already sourced by `load_modules()`.
Re-sourcing them here is redundant.

**Fix:** Since these 6 functions are defined in modules already loaded,
just verify they exist as functions in the current shell:

```bash
init_registered_functions() {
    local success=0
    for func in "${REGISTERED_FUNCTIONS[@]}"; do
        if type "$func" &>/dev/null; then
            ((success++))
        else
            ini_log "WARNING: Registered function $func not available"
        fi
    done
    ini_log "Verified $success/${#REGISTERED_FUNCTIONS[@]} registered functions"
}
```

This replaces ~50 operations with ~6 `type` checks.

---

## Implementation Priority

Ranked by estimated time savings (high to low):

| Priority | Workstream | Estimated Savings | Effort |
|----------|-----------|-------------------|--------|
| P0 | WS-1.1: date -> printf builtins | 100-250ms | Low |
| P0 | WS-4.1: LOG_DEBUG_ENABLED=0 default | 50-150ms | Trivial |
| P0 | WS-2.1: tme state file I/O elimination | 40-100ms | Low |
| P1 | WS-2.4: Remove mktemp in source_helper | 30-80ms | Low |
| P1 | WS-1.2: bc -> bash arithmetic | 20-60ms | Medium |
| P1 | WS-2.5: find|sort -> glob | 20-50ms | Low |
| P1 | WS-6.2: Simplify registered functions | 30-80ms | Low |
| P2 | WS-4.2: lo1_log subshell elimination | 20-60ms | Medium |
| P2 | WS-3.1: Remove double rdc sourcing | 5-15ms | Trivial |
| P2 | WS-3.2: Remove double loop in load_modules | 5-10ms | Trivial |
| P2 | WS-3.3: type check flags | 5-15ms | Low |
| P2 | WS-2.2: ver_log mkdir guard | 5-15ms | Trivial |
| P3 | WS-1.3/1.4: basename/dirname param expansion | 5-15ms | Trivial |
| P3 | WS-6.1: Batch module verification | 10-30ms | Medium |
| P3 | WS-4.3: Skip depth calc in PERFORMANCE_MODE | 5-15ms | Low |
| P3 | WS-5.*: Orc minor optimizations | 5-10ms | Low |

**Conservative estimated total savings: 350-750ms**

---

## Subagent Parallelization Map

These workstreams have no code overlap and can be assigned to independent
agents working simultaneously:

```
Agent A: WS-1 (Fork/Exec Elimination)
         Files: lib/core/tme, lib/core/ver, lib/core/lo1, lib/core/err, bin/ini
         Scope: Replace date/bc/basename/dirname with builtins

Agent B: WS-2 (I/O Reduction)
         Files: lib/core/tme (state file), bin/orc (mktemp, find|sort)
         Scope: Eliminate unnecessary file operations
         Note:  WS-2.1 touches tme (shared with Agent A on WS-1.2)
                Coordinate: Agent A does timestamp changes in tme,
                Agent B does state-file changes in tme

Agent C: WS-3 + WS-6 (Redundancy + Architecture)
         Files: bin/ini, cfg/core/mdc, cfg/core/rdc
         Scope: Remove double sourcing, double loops, simplify
                registered functions system

Agent D: WS-4 (Logging Overhead)
         Files: lib/core/lo1
         Scope: Fix debug default, reduce lo1_log cost
         Note:  Touches lo1 only, no overlap with other agents

Agent E: WS-5 (Orc Minor)
         Files: bin/orc
         Scope: Minor structural optimizations
         Note:  Can be folded into Agent B if fewer agents preferred
```

### Conflict Matrix

| | WS-1 | WS-2 | WS-3 | WS-4 | WS-5 | WS-6 |
|---|---|---|---|---|---|---|
| WS-1 | - | tme (split by concern) | none | none | none | none |
| WS-2 | tme | - | none | none | orc | none |
| WS-3 | none | none | - | none | none | ini (shared) |
| WS-4 | none | none | none | - | none | none |
| WS-5 | none | orc | none | none | - | none |
| WS-6 | none | none | ini | none | none | - |

Shared file conflicts are resolvable by scope: Agent A changes timestamps
in tme, Agent B changes state-file logic in tme. Agent C handles ini flow
changes, Agent E handles orc-internal changes.

---

## Validation

After each workstream is implemented:

1. Run the relevant single test:
   ```bash
   ./val/core/config/cfg_test.sh
   ```

2. Run the full suite:
   ```bash
   ./val/run_all_tests.sh
   ```

3. Re-measure init time (compare to baseline):
   ```bash
   for i in {1..5}; do
     bash -c 'source bin/ini' 2>&1 | tail -1
   done
   ```

4. Verify all features still work:
   - Terminal output unchanged (when verbosity is on)
   - All log files populated correctly
   - Timer report prints correctly
   - All library functions available after init
   - `lab` command works in interactive shell
