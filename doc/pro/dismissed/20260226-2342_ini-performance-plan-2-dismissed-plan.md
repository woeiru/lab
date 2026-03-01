# bin/ini Performance Plan — With Compromise

Status: dismissed

## Dismissal Reason
- Superseded by later planning artifacts with clearer scope boundaries and decision criteria.
- Proposes high-risk compromises (verification and caching shortcuts) without current validation evidence.
- Overlaps heavily with adjacent plans, making parallel tracking noisy and harder to govern.

Performance optimization plan that preserves all visual/terminal output
but accepts behavioral compromises: reduced internal verification depth,
lazy module loading, less file I/O during init, and structural shortcuts
that trade safety-during-bootstrap for speed.

The "no-compromise" sibling plan covers safe-only changes (builtin
substitutions, parameter expansion, etc.). This plan goes further.

## Profiling Baseline

Measured on current system (`w1`, Bash 5.x):

| Metric              | Value         |
|---------------------|---------------|
| Wall time           | ~1.54s        |
| User CPU            | 1.1s          |
| System CPU          | 0.45s         |
| Total trace lines   | 21,426        |
| External forks      | **630**       |
| Files sourced       | 32 (29 unique)|
| Lines parsed        | ~16,571 (ops+gen alone) |

### Fork breakdown

| Command      | Count  | Est. cost | Purpose                          |
|--------------|-------:|----------:|----------------------------------|
| `date`       | 337    | 253ms     | Timestamps everywhere            |
| `cat`        | 85     | 64ms      | Reading lo1_state, tme_state     |
| `dirname`    | 54     | 41ms      | Path resolution in loggers       |
| `bc`         | 41     | 31ms      | Timer arithmetic                 |
| `mkdir`      | 30     | 23ms      | Directory creation               |
| `basename`   | 25     | 19ms      | Module name extraction           |
| `mktemp`+`rm`| 44     | 33ms      | source_helper temp error files   |
| `find`+`sort`| 6      | 5ms       | Directory listing in orc         |
| Other        | 8      | 6ms       | hostname, chmod, grep, touch     |
| **Total**    | **630**| **~475ms**| ~31% of wall time is fork cost   |

### Phase breakdown (from tme.log trace)

```
Phase                            Duration  % of Total
────────────────────────────────────────────────────────
Pre-timer setup (ini→modules)      227ms     15%
SOURCE_COMP_ORCHESTRATOR             8ms      1%
INIT_RUNTIME_SYSTEM                275ms     18%
  └─ BATCH_FUNCTION_REGISTRATION   184ms       (hotspot)
CFG_ECC                             73ms      5%
CFG_ALI                             91ms      6%
LIB_OPS                           356ms     23%  ← biggest
  └─ orchestration overhead        108ms
LIB_UTL (lib/gen)                  238ms     15%
  └─ orchestration overhead         75ms
CFG_ENV                            126ms      8%
SRC_AUX                             64ms      4%
FINALIZE + timing report            72ms      5%
────────────────────────────────────────────────────────
TOTAL                            ~1,540ms
```

---

## Compromise Principles

These are changes the no-compromise plan avoids but this plan embraces:

1. **Skip verification during bootstrap** — trust the file layout, verify
   lazily on first function use or not at all
2. **Lazy-load ops and gen modules** — don't source 16,571 lines of
   function definitions at startup; source on first call
3. **Eliminate the registered-functions system** during init — the modules
   are already loaded; a `type` check suffices
4. **Reduce internal logging during init** — keep terminal output
   identical but skip file-based debug logging, stack traces, and
   per-operation audit writes
5. **Simplify source_helper** — drop per-file error capture via mktemp;
   use return codes and a single shared error log
6. **Accept Bash 5.0+ as minimum** — enables `$EPOCHREALTIME` and
   `${EPOCHREALTIME}` for zero-fork nanosecond timestamps

The terminal tree output the user sees remains **identical**.

---

## CWS-1: Zero-Fork Builtins (Foundation)

**Files:** `bin/ini`, `lib/core/col`, `lib/core/tme`, `lib/core/lo1`,
`lib/core/err`, `lib/core/ver`, `bin/orc`
**Impact:** HIGH — eliminates ~475ms of fork overhead
**Parallel:** Yes — can start immediately, no dependencies
**Estimated savings:** 350-400ms

This workstream is identical to WS-1 in the no-compromise plan but
is listed here because everything else builds on it.

### CWS-1.1 Replace all `date` calls with printf builtins / $EPOCHREALTIME

337 `date` forks → 0. Details in `ini-performance-plan-no-compromise.md`
WS-1.1. The key sites:

| File | Calls | Current | Replacement |
|------|------:|---------|-------------|
| `bin/ini` (ini_log) | ~66 | `date '+%H:%M:%S'` | `printf -v ts '%(%H:%M:%S)T' -1` |
| `lib/core/tme` | ~83 | `date +%s.%N` | `$EPOCHREALTIME` (Bash 5+) |
| `lib/core/lo1` | ~115 | `date +%s` | `printf -v t '%(%s)T' -1` |
| `lib/core/tme` | ~41 | `date -d @...` (report) | `printf '%(%T)T' "$epoch"` |
| `lib/core/err` | ~6 | various `date` formats | `printf -v` equivalents |
| `lib/core/ver` | ~26 | `date` in ver_log | `printf -v` equivalents |

### CWS-1.2 Replace all `bc` with bash arithmetic

41 `echo ... | bc` → 0. Use `$EPOCHREALTIME` string math:

```bash
# Current (3 forks: echo + pipe + bc):
duration=$(echo "$end - $start" | bc)

# Replacement (0 forks):
local e_int="${end%.*}" e_frac="${end#*.}"
local s_int="${start%.*}" s_frac="${start#*.}"
# Pad fractions to 6 digits, do integer subtraction
e_frac="${e_frac}000000"; e_frac="${e_frac:0:6}"
s_frac="${s_frac}000000"; s_frac="${s_frac:0:6}"
local diff_us=$(( (e_int*1000000 + 10#$e_frac) - (s_int*1000000 + 10#$s_frac) ))
duration="$((diff_us / 1000000)).$( printf '%06d' $((diff_us % 1000000)) )"
```

### CWS-1.3 Replace all `basename`/`dirname` with parameter expansion

25 `basename` + 54 `dirname` → 0:

```bash
# basename: $(basename "$path") → ${path##*/}
# dirname:  $(dirname "$path")  → ${path%/*}
```

Sites: `bin/ini:441,453`, `bin/orc:122,233,402`, `lib/core/ver:297`,
`bin/ini:169` (ini_log dirname, called ~40x).

### CWS-1.4 Replace `$(printf '\033[...]')` with ANSI-C quoting

25 forks in `col` + 10 in `tme` = 35 subshell forks → 0:

```bash
# Current (1 subshell fork each):
readonly COL_RED=$(printf '\033[0;31m')

# Replacement (zero forks):
readonly COL_RED=$'\033[0;31m'
```

Also removes the 10 duplicate color constants in `tme` — reuse `COL_*`.

### CWS-1.5 Replace `$(cat "$file")` with `$(<"$file")`

85 `cat` forks → 0 (bash builtin file read):

```bash
# Current (1 fork):
state=$(cat "$LOG_STATE_FILE" 2>/dev/null || echo "true")

# Replacement (0 forks):
state=$(<"$LOG_STATE_FILE" 2>/dev/null) || state="true"
```

Sites: `lo1:86`, `tme:176,219` and all `tme_settme`/`tme_print_*`
functions (~10 sites total).

### CWS-1.6 Use `printf -v` instead of `$(printf ...)`

```bash
# Current (subshell fork):
_INI_ELAPSED_S=$(printf '%d.%03d' ...)

# Replacement (zero forks):
printf -v _INI_ELAPSED_S '%d.%03d' ...
```

---

## CWS-2: Eliminate source_helper Overhead

**Files:** `bin/orc`
**Impact:** HIGH — removes ~80 forks and simplifies the hot path
**Parallel:** Yes — only touches `bin/orc`
**Estimated savings:** 50-80ms

### CWS-2.1 Remove mktemp/cat/rm per file

`source_helper()` (`bin/orc:120-177`) creates a temp file for every
single file it sources to capture stderr. With ~20 files sourced through
the orchestrator, this is 20× `mktemp` + 20× `cat` + 40× `rm` = **80
forks doing nothing useful**.

**Compromise:** Accept that source errors go to a shared log file
instead of being captured per-file:

```bash
source_helper() {
    local file="$1" description="${2:-}"
    local name="${file##*/}"

    [[ -f "$file" && -r "$file" ]] || { lo1_log "lvl" "Cannot source: $name"; return 1; }

    tme_start_timer "source_${description:-$name}"
    if source "$file" 2>>"${LOG_DIR}/source_errors.log"; then
        lo1_log "lvl" "Successfully sourced: $name"
        tme_end_timer "source_${description:-$name}" "success"
        return 0
    else
        lo1_log "lvl" "Error sourcing: $name (see source_errors.log)"
        tme_end_timer "source_${description:-$name}" "error"
        return 1
    fi
}
```

### CWS-2.2 Replace `find | sort` with bash glob

`source_directory()` and `source_lib_ops()` both run
`find ... -print0 | sort -z > tmpfile` then read it — 3 forks per
directory call (find, sort, mktemp), 4 directories = **12+ forks**.

**Replacement:**

```bash
source_directory() {
    local dir="$1" description="${2:-}" count=0 total=0

    shopt -s nullglob
    local files=("$dir"/*)
    shopt -u nullglob

    for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        local name="${file##*/}"
        # Skip non-source files
        case "$name" in
            *.md|*.txt|*.spec|*.readme|*.doc|README*|.*) continue ;;
        esac
        ((total++))
        if source_helper "$file" "$name"; then
            ((count++))
        fi
    done

    lo1_log "lvl" "Successfully sourced $count/$total files from $dir"
}
```

Glob expansion is alphabetically sorted by default — same as `sort`.
Zero forks for the listing step.

### CWS-2.3 Consolidate source_lib_ops into source_directory

`source_lib_ops()` (`bin/orc:341-422`) is a near-copy of
`source_directory()` with added exclusion patterns. The 80 lines of
duplication can be eliminated by adding an exclusion-pattern parameter
to `source_directory`:

```bash
source_directory "$LIB_OPS_DIR" "operational" \
    "*.md|*.txt|*.spec|*.readme|*.doc|README*|.*"
```

---

## CWS-3: Lazy Module Loading (Biggest Structural Compromise)

**Files:** `bin/orc`, `bin/ini`, `lib/ops/*`, `lib/gen/*`
**Impact:** VERY HIGH — avoids parsing 16,571 lines at startup
**Parallel:** Partially — design first, then implement
**Estimated savings:** 300-500ms

### The Problem

During LIB_OPS (356ms, 23% of total) and LIB_UTL (238ms, 15%), the
bootstrapper sources 15 files totaling 16,571 lines. These files are
almost entirely function definitions — no source-time work. The bash
parser must tokenize and store every function body even though most
functions are never called in any given session.

### CWS-3.1 Autoload stubs for ops modules

Instead of sourcing each ops module eagerly, define a thin stub function
for each public function that sources the real module on first call:

```bash
# Generated stub for lib/ops/gpu functions:
gpu_ptd() { source "$LIB_DIR/ops/gpu" && gpu_ptd "$@"; }
gpu_lst() { source "$LIB_DIR/ops/gpu" && gpu_lst "$@"; }
# ... etc
```

When `gpu_ptd` is called for the first time, the real module is sourced
(overwriting the stub with the real function), then the function is
called with the original arguments.

**Implementation approach:**

1. Create a manifest file `cfg/core/autoload` listing every public
   function and its module:

   ```
   gpu_ptd:lib/ops/gpu
   gpu_lst:lib/ops/gpu
   pve_cdo:lib/ops/pve
   net_sca:lib/ops/net
   ...
   ```

2. During bootstrap, instead of sourcing 15 files, read the manifest
   and generate stub functions:

   ```bash
   load_autoload_stubs() {
       local func module
       while IFS=: read -r func module; do
           eval "${func}() { source \"\${BASE_DIR}/${module}\" && ${func} \"\$@\"; }"
       done < "${BASE_DIR}/cfg/core/autoload"
   }
   ```

3. The stub generation loop is pure builtins (read + eval) — no forks,
   and processes a few hundred lines instead of 16,571.

**Compromise:** First invocation of any function in a module incurs a
one-time ~30-50ms load delay. Subsequent calls are at full speed.

**Tab completion:** Stubs are real functions visible to `type` and
`compgen -A function`, so completion and `type func_name` still work.

### CWS-3.2 Generate the autoload manifest

A helper script to regenerate the manifest from actual module files:

```bash
# bin/gen-autoload (run manually after adding functions)
for module in lib/ops/* lib/gen/*; do
    [[ -f "$module" ]] || continue
    name="${module##*/}"
    case "$name" in *.md|*.txt|*.spec|.*) continue ;; esac
    grep -oP '^\s*(?:function\s+)?(\w+)\s*\(\)' "$module" |
        sed "s/[[:space:]]*()//; s/function //; s/^/${name}:${module}/" |
        grep -v '^_'  # skip private functions
done > cfg/core/autoload
```

### CWS-3.3 Keep eager loading as a fallback

For debugging or when lazy loading causes issues:

```bash
if [[ "${LAB_EAGER_LOAD:-0}" == "1" ]]; then
    source_lib_ops   # original eager path
    source_lib_gen
else
    load_autoload_stubs
fi
```

### CWS-3.4 Handle the preamble problem

Every ops module has a 9-line preamble that sets `DIR_FUN`, `FILE_FUN`,
`BASE_FUN`, etc. plus 4 `eval` calls. This preamble runs at source-time
and is needed by some functions within the module.

**Fix:** Move the preamble into a function and call it at source-time.
When the autoload stub triggers a source, the preamble runs naturally.
No change needed in the modules themselves.

However, the preamble also uses `cd+dirname+basename` (2 subshell forks
per module). Replace with parameter expansion:

```bash
# Current (2 forks):
DIR_FUN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_FUN=$(basename "$BASH_SOURCE")

# Replacement (0 forks):
DIR_FUN="${BASH_SOURCE[0]%/*}"
[[ "$DIR_FUN" == "${BASH_SOURCE[0]}" ]] && DIR_FUN="."
FILE_FUN="${BASH_SOURCE[0]##*/}"
```

This applies to all 12 modules sharing the preamble pattern.

---

## CWS-4: Gut the Verification System During Init

**Files:** `bin/ini`, `lib/core/ver`, `lib/core/err`, `lib/core/lo1`,
`lib/core/tme`
**Impact:** HIGH — ver_verify_module is called 3× at source-time
costing ~15-20 verification operations each with logging
**Parallel:** Yes — only touches ver and module source-time guards
**Estimated savings:** 80-150ms

### CWS-4.1 Skip ver_verify_module during bootstrap

Each core module (`err:28`, `lo1:31`, `tme:34`) runs
`ver_verify_module "xxx" || exit 1` as its first source-time statement.
`ver_verify_module` iterates MODULE_VARS, MODULE_PATHS, and
MODULE_COMMANDS arrays, calling `ver_verify_var`, `ver_verify_path`,
and `command -v` for each match. For 3 modules this is 15-20 individual
checks with `ver_log` calls (each forking `date` + `dirname`).

**Compromise:** Trust the layout during bootstrap. Add a guard:

```bash
# In lib/core/err, lib/core/lo1, lib/core/tme:
[[ "${LAB_SKIP_VERIFY:-0}" == "1" ]] || ver_verify_module "err" || exit 1
```

In `bin/ini`, set the flag before loading modules:

```bash
LAB_SKIP_VERIFY=1
load_modules  # sources col, err, lo1, tme without verification
unset LAB_SKIP_VERIFY
```

Verification still runs if modules are sourced outside the bootstrap
context (e.g., individually by a developer).

### CWS-4.2 Eliminate registered-functions verification

The entire `init_registered_functions` flow (`bin/ini:540-660`) processes
6 functions by: caching module verification → calling
`ver_verify_function_dependencies` → calling `register_single_function`
(which `grep`s the source file then re-sources the module).

The modules (`err`, `lo1`, `tme`) are **already sourced** by
`load_modules()`. Re-sourcing and grepping them is pure waste.

**Compromise:** Replace the entire subsystem with 6 `type` checks:

```bash
init_registered_functions() {
    ini_log "Verifying registered functions"
    local success=0
    for func in "${REGISTERED_FUNCTIONS[@]}"; do
        if type "$func" &>/dev/null; then
            ((success++))
            ini_log "Verified function: $func"
        else
            ini_log "WARNING: Function $func not available"
        fi
    done
    ini_log "Verified $success/${#REGISTERED_FUNCTIONS[@]} registered functions"
}
```

This replaces BATCH_FUNCTION_REGISTRATION (184ms) with ~6 `type` checks
(< 1ms).

### CWS-4.3 Remove redundant rdc sourcing

`cfg/core/rdc` is sourced at `bin/ini:190` (top-level) and again at
`bin/ini:504` (inside `init_runtime_system`). The second source plus
its preceding `ver_verify_path` check is redundant.

**Fix:** Delete lines 493-504 in `init_runtime_system` or guard with:

```bash
[[ -n "${REGISTERED_FUNCTIONS[*]:-}" ]] || source "$rde_path"
```

### CWS-4.4 Remove redundant hostname fork

`cfg/core/ric:90` calls `$(hostname)` to set `NODE_NAME`, then
`cfg/core/ecc:34` calls `$(hostname)` again to override it.

**Fix:** In `ecc`, use the value already set by `ric`:

```bash
# In cfg/core/ecc, replace:
export NODE_NAME="$(hostname)"
# With:
export NODE_NAME="${NODE_NAME:-$(hostname)}"
```

---

## CWS-5: Reduce Logging Overhead During Init

**Files:** `lib/core/lo1`, `bin/ini`
**Impact:** HIGH — lo1_log is called 30-50+ times, each call has
4 subshell captures + potential `date`/`cat` forks
**Parallel:** Yes — only touches lo1 and ini's ini_log
**Estimated savings:** 100-200ms

### CWS-5.1 Disable debug logging by default

`lib/core/lo1:38` sets `LOG_DEBUG_ENABLED=1`. This causes every
`lo1_log` call to also trigger `lo1_debug_log` → `lo1_dump_stack_trace`
which walks the entire FUNCNAME array and writes multiple lines per call.

With 30-50 `lo1_log` calls and average stack depth 5-8, this generates
hundreds of extra file writes during init.

**Compromise:** Default to off. Users opt in via environment:

```bash
export LOG_DEBUG_ENABLED=${LOG_DEBUG_ENABLED:-0}
```

### CWS-5.2 Eliminate subshell captures in lo1_log

Every `lo1_log` call triggers 4 functions captured via `$(...)`:

1. `$(lo1_get_cached_log_state)` — reads state file
2. `$(lo1_calculate_final_depth)` — walks call stack
3. `$(lo1_get_indent "$depth")` — builds indent string
4. `$(lo1_get_color "$depth")` — looks up color

Each `$(...)` has overhead. Refactor to use global return variables:

```bash
# Instead of: depth=$(lo1_calculate_final_depth)
# Functions write to a well-known variable:
_lo1_calculate_final_depth   # sets _LO1_RESULT
local depth=$_LO1_RESULT
```

Or, more invasively, inline the logic into `lo1_log` itself since
the helper functions are trivial.

### CWS-5.3 Cache dirname in ini_log

`ini_log` (`bin/ini:169`) runs `$(dirname "$INI_LOG_FILE")` on every
call (~40 times). The result never changes.

**Fix:** Compute once and store:

```bash
# At ini_log definition time:
_INI_LOG_DIR="${INI_LOG_FILE%/*}"

# In ini_log, replace:
#   ensure_dir_cached "$(dirname "$INI_LOG_FILE")"
# With:
#   ensure_dir_cached "$_INI_LOG_DIR"
```

### CWS-5.4 Cache log state in variable, not file

`lo1_get_cached_log_state()` reads `$LOG_STATE_FILE` from disk on
nearly every call (85 `cat` forks during init). The state only changes
when `lo1_setlog` is called.

**Fix:** Use a global variable as the primary state holder. Write to
file only for persistence:

```bash
declare -g LOG_STATE_CACHED="on"

lo1_setlog() {
    LOG_STATE_CACHED="$1"
    echo "$1" > "$LOG_STATE_FILE"  # persist for next session
}

# In lo1_log, replace $(lo1_get_cached_log_state) with:
[[ "$LOG_STATE_CACHED" != "on" ]] && return 0
```

This eliminates all 85 `cat` forks.

### CWS-5.5 Skip depth calculation during init

`lo1_get_base_depth()` walks the FUNCNAME array on every log call.
During init most callers are unique so the cache rarely hits.

**Compromise:** During init (when `PERFORMANCE_MODE=1`), use a fixed
depth instead of calculating:

```bash
lo1_get_base_depth() {
    if [[ "${PERFORMANCE_MODE:-0}" == "1" ]]; then
        echo 1; return
    fi
    # ... existing call-stack walking logic
}
```

---

## CWS-6: Eliminate Dead Code and Redundant Work

**Files:** `bin/ini`, `lib/core/tme`
**Impact:** LOW-MEDIUM — housekeeping that removes noise
**Parallel:** Yes — trivial changes, no dependencies
**Estimated savings:** 10-30ms

### CWS-6.1 Remove dead functions from bin/ini

Two functions are defined but never called:

- `register_function` (lines 663-695) — `register_single_function` is
  used instead
- `verify_function_dependencies` (lines 624-636) — the code calls
  `ver_verify_function_dependencies` from the `ver` module instead

**Fix:** Delete both functions (~70 lines of dead code).

### CWS-6.2 Merge two module loops in load_modules

`load_modules()` iterates the modules array twice:
- Loop 1 (lines 439-449): "batch validate" — calls `check_file_cached`
- Loop 2 (lines 452-469): load — calls `check_file_cached` again + source

The first loop provides zero benefit since the second loop immediately
follows and re-checks everything.

**Fix:** Delete loop 1 entirely.

### CWS-6.3 Deduplicate mkdir in tme_init_timer

`tme_init_timer` calls `mkdir -p "$TMP_DIR"` at lines 88, 96, and 115
(3 times, same directory). Also `mkdir -p "$log_dir"` at lines 79 and
143.

**Fix:** One `mkdir -p` call per unique directory, at the top:

```bash
tme_init_timer() {
    local log_dir="${LOG_DIR:-${BASE_DIR}/.log}"
    mkdir -p "$log_dir" "$TMP_DIR"
    # ... rest of init, no more mkdir calls
}
```

### CWS-6.4 Remove process_runtime_config no-op

`process_runtime_config()` (`bin/ini:534-537`) does nothing except log.
It is wrapped with full timer start/stop calls, adding overhead for
zero functionality.

**Fix:** Remove the function, its timer wrapping, and its call from
`init_runtime_system()`.

### CWS-6.5 Remove dangerous example functions from err

`err_dangerous_operation()` and `err_safe_operation()` (lines 190-205)
contain live destructive commands (`rm -rf some_important_directory/`,
`dnf update`). These are example/demo code that should not exist in
production.

**Fix:** Delete both functions.

---

## CWS-7: Structural Init Redesign (Most Aggressive)

**Files:** `bin/ini`, `bin/orc`
**Impact:** VERY HIGH — rearchitects the init flow
**Parallel:** No — depends on CWS-1 through CWS-5 being done first
**Estimated savings:** 200-400ms additional (on top of other CWS savings)

### CWS-7.1 Fast-path init mode

Create a cached init state that skips all verification and logging
on subsequent runs in the same environment:

```bash
_INI_CACHE="${BASE_DIR}/.tmp/ini_cache"

if [[ -f "$_INI_CACHE" ]] && [[ "$_INI_CACHE" -nt "$0" ]]; then
    # Cache is newer than ini itself — fast path
    source "$_INI_CACHE"
    return 0
fi

# ... normal init ...

# At end of successful init, write cache:
declare -p BASE_DIR LOG_DIR TMP_DIR ... > "$_INI_CACHE"
declare -pf > "${_INI_CACHE}.funcs"  # all function definitions
```

**Compromise:** Changes to lib/ops/*, lib/gen/*, etc. won't be picked
up until the cache is invalidated. Add a `lab --reload` command:

```bash
lab_reload() { rm -f "${BASE_DIR}/.tmp/ini_cache"*; source bin/ini; }
```

### CWS-7.2 Parallel module sourcing (advanced)

Source independent modules in background subshells and collect results.
This is complex because `source` must run in the current shell to
define functions. However, we can **parse-check** files in parallel
and source sequentially:

```bash
# Pre-warm filesystem cache in parallel
for f in lib/ops/*; do cat "$f" > /dev/null & done
wait
# Then source sequentially (files are now in page cache)
for f in lib/ops/*; do source "$f"; done
```

This helps primarily on cold filesystem (first boot), less on warm
cache. Marginal benefit but zero risk.

### CWS-7.3 Compiled function cache (most aggressive)

Use `declare -f` to dump all loaded functions to a single cache file
after first successful init:

```bash
# After all modules are loaded:
declare -f > "${BASE_DIR}/.tmp/function_cache.sh"
```

On subsequent inits, source this single file instead of 15+ individual
files. One file open + one parse pass instead of 15.

**Invalidation:** Compare timestamps:

```bash
local newest_source
newest_source=$(stat -c %Y lib/ops/* lib/gen/* | sort -rn | head -1)
local cache_time
cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)

if (( cache_time > newest_source )); then
    source "$cache_file"  # fast path
else
    # slow path: source all modules, regenerate cache
    source_all_modules
    declare -f > "$cache_file"
fi
```

**Compromise:** Adds `stat` forks for cache validation. Net positive
only if cache hits are common (they should be — modules change rarely).

---

## Projected Savings Summary

### Conservative (CWS-1 through CWS-6 only)

| Workstream | Savings | Effort |
|-----------|--------:|--------|
| CWS-1: Zero-fork builtins | 350-400ms | Medium |
| CWS-2: source_helper elimination | 50-80ms | Low |
| CWS-3: Lazy module loading | 300-500ms | High |
| CWS-4: Skip verification | 80-150ms | Low |
| CWS-5: Logging overhead | 100-200ms | Medium |
| CWS-6: Dead code removal | 10-30ms | Trivial |
| **Total (conservative)** | **~700-1000ms** | |
| **Projected init time** | **~500-800ms** | |

### Aggressive (add CWS-7)

| Workstream | Additional | Effort |
|-----------|----------:|--------|
| CWS-7.1: Fast-path cache | 200-400ms | Medium |
| CWS-7.3: Compiled function cache | 100-200ms | Medium |
| **Total with CWS-7** | **~1000-1400ms** | |
| **Projected init time** | **~150-400ms** | |

---

## Subagent Parallelization Map

```
┌─────────────────────────────────────────────────────────────────┐
│ Phase 1: Independent workstreams (run all in parallel)          │
│                                                                 │
│  Agent A: CWS-1 (Zero-Fork Builtins)                          │
│    Files: lib/core/tme, lib/core/ver, lib/core/lo1,            │
│           lib/core/err, lib/core/col, bin/ini                  │
│    Scope: Replace date/bc/basename/dirname/printf subshells    │
│           with builtins and parameter expansion                │
│    Test:  ./val/core/config/cfg_test.sh                        │
│                                                                 │
│  Agent B: CWS-2 (source_helper + orc I/O)                     │
│    Files: bin/orc                                              │
│    Scope: Remove mktemp/cat/rm per source, replace find|sort   │
│           with glob, consolidate source_lib_ops                │
│    Test:  bash -c 'source bin/ini' (functional check)          │
│                                                                 │
│  Agent C: CWS-4 + CWS-6 (Verification skip + dead code)       │
│    Files: bin/ini, lib/core/err, lib/core/lo1, lib/core/tme,   │
│           cfg/core/ecc, cfg/core/rdc                           │
│    Scope: Add LAB_SKIP_VERIFY guard, simplify registered       │
│           functions, remove dead code, deduplicate hostname,   │
│           remove redundant rdc source, remove no-op function   │
│    Test:  ./val/run_all_tests.sh core                          │
│                                                                 │
│  Agent D: CWS-5 (Logging overhead)                             │
│    Files: lib/core/lo1, bin/ini (ini_log only)                 │
│    Scope: LOG_DEBUG_ENABLED=0 default, cache dirname/state     │
│           in variables, eliminate subshell captures in lo1_log, │
│           skip depth calc in PERFORMANCE_MODE                  │
│    Test:  ./val/core/config/cfg_test.sh                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                    (merge + integration test)
                    ./val/run_all_tests.sh
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Phase 2: Depends on Phase 1 completion                         │
│                                                                 │
│  Agent E: CWS-3 (Lazy module loading)                          │
│    Files: bin/ini, bin/orc, cfg/core/autoload (new),           │
│           lib/ops/* (preamble fix only), lib/gen/* (preamble)  │
│    Scope: Create autoload manifest, generate stub functions,   │
│           fix preamble to use parameter expansion,             │
│           add LAB_EAGER_LOAD fallback                          │
│    Pre:   Phase 1 merged (so stubs source optimized modules)   │
│    Test:  ./val/run_all_tests.sh (full suite)                  │
│           + manual: call each ops function, verify it loads    │
│                                                                 │
│  Agent F: CWS-7 (Structural redesign) [optional]              │
│    Files: bin/ini                                              │
│    Scope: Implement fast-path init cache, compiled function    │
│           cache, cache invalidation, lab --reload              │
│    Pre:   Phase 1 + Phase 2 Agent E merged                     │
│    Test:  ./val/run_all_tests.sh + timing comparison           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Conflict Matrix

|       | CWS-1 | CWS-2 | CWS-3 | CWS-4+6 | CWS-5 | CWS-7 |
|-------|-------|-------|-------|---------|-------|-------|
| CWS-1 | —     | none  | P2    | none    | none  | P2    |
| CWS-2 | none  | —     | P2    | none    | none  | P2    |
| CWS-3 | P2    | P2    | —     | P2      | P2    | seq   |
| CWS-4+6| none | none  | P2    | —       | none  | P2    |
| CWS-5 | none  | none  | P2    | none    | —     | P2    |
| CWS-7 | P2    | P2    | seq   | P2      | P2    | —     |

- `none` = no file overlap, safe to parallelize
- `P2` = Phase 2 dependency (run after Phase 1 merges)
- `seq` = must run sequentially (CWS-7 after CWS-3)

CWS-1 and CWS-5 both touch `lib/core/lo1` but on different concerns:
- Agent A changes `date` → `printf` calls (timestamp generation)
- Agent D changes log state caching and subshell elimination (log flow)

These touch different functions within `lo1` and can be merged cleanly.

---

## Validation Protocol

### Per-workstream (after each agent finishes)

```bash
# 1. Syntax check all modified files
bash -n bin/ini bin/orc lib/core/*

# 2. Run relevant test category
./val/run_all_tests.sh core

# 3. Functional smoke test
bash -c 'source bin/ini' 2>&1  # should produce identical tree output

# 4. Timing check
for i in {1..5}; do
    bash -c 'source bin/ini' 2>&1 | tail -1
done
```

### After full integration

```bash
# 1. Full test suite
./val/run_all_tests.sh

# 2. Visual output comparison
# Capture before and after, diff ignoring timestamps:
bash -c 'source bin/ini' 2>&1 | sed 's/\[.*\]/[TS]/g' > /tmp/after.txt
# Compare with saved baseline

# 3. Function availability check
bash -c 'source bin/ini; type gpu_ptd; type pve_cdo; type net_sca' 2>&1

# 4. Timing comparison (5-run median)
for i in {1..5}; do
    bash -c 'source bin/ini' 2>&1 | tail -1
done
```

### Target metrics

| Metric | Current | After Phase 1 | After Phase 2 |
|--------|--------:|-------------:|-------------:|
| Wall time | 1.54s | ~0.6-0.8s | ~0.3-0.5s |
| Forks | 630 | ~50-80 | ~20-40 |
| Files parsed | 32 | 32 | ~10 (stubs) |
| Lines parsed | 16,571+ | 16,571+ | ~500 (stubs) |
