# bin/ini Performance Optimization Plan

Consolidated plan for optimizing the shell bootstrapper.
Supersedes `ini-performance-plan-orginal.md` and `ini-performance-plan-with-compromise.md`.

## Design Constraints

1. **Visual output is preserved exactly.** Every tree line, color, icon, banner,
   timing report entry, and error report the user sees today remains identical.
2. **Real safety guards are preserved exactly.** The four `source ... || exit 1`
   guards at `bin/ini:185-203` and the per-module return-code checks in
   `load_modules()` are not touched.
3. **No new dependencies.** Bash 5.0+ is already the runtime (verified via
   `$EPOCHREALTIME` availability on `w1`). No external tools are added.

## What This Plan Does NOT Do

It does not trade safety for speed. The verification system being removed is
not safety -- it is redundant re-checking of invariants that are already
guaranteed by prior steps. See the "Redundancy Evidence" section for proof.

---

## Profiling Baseline

Measured on `w1`, Bash 5.x, 5-run median:

| Metric            | Value          |
|-------------------|----------------|
| Wall time         | ~1.54s         |
| External forks    | 630            |
| Files sourced     | 32 (29 unique) |
| Lines parsed      | ~16,571 (ops+gen alone) |

### Fork breakdown

| Command       | Count | Est. cost | Purpose                        |
|---------------|------:|----------:|--------------------------------|
| `date`        | 337   | 253ms     | Timestamps everywhere          |
| `cat`         | 85    | 64ms      | Reading lo1_state, tme_state   |
| `dirname`     | 54    | 41ms      | Path resolution in loggers     |
| `bc`          | 41    | 31ms      | Timer arithmetic               |
| `mkdir`       | 30    | 23ms      | Directory creation             |
| `basename`    | 25    | 19ms      | Module name extraction         |
| `mktemp`+`rm` | 44   | 33ms      | source_helper temp error files |
| `find`+`sort` | 6     | 5ms       | Directory listing in orc       |
| Other         | 8     | 6ms       | hostname, chmod, grep, touch   |
| **Total**     |**630**|**~475ms** | ~31% of wall time              |

### Phase breakdown (from tme.log)

```
Phase                            Duration  % of Total
------------------------------------------------------
Pre-timer setup (ini->modules)      227ms     15%
SOURCE_COMP_ORCHESTRATOR              8ms      1%
INIT_RUNTIME_SYSTEM                 275ms     18%
  +-- BATCH_FUNCTION_REGISTRATION   184ms       (hotspot)
CFG_ECC                              73ms      5%
CFG_ALI                              91ms      6%
LIB_OPS                            356ms     23%  <-- biggest
  +-- orchestration overhead        108ms
LIB_UTL (lib/gen)                   238ms     15%
  +-- orchestration overhead         75ms
CFG_ENV                             126ms      8%
SRC_AUX                              64ms      4%
FINALIZE + timing report             72ms      5%
------------------------------------------------------
TOTAL                             ~1,540ms
```

---

## Redundancy Evidence

This section documents why removing the verification system during bootstrap
is not a safety trade. These are facts from the code, not opinions.

### 1. Variables are verified 30+ times for no reason

`cfg/core/ric` is sourced at `bin/ini:185` with `|| exit 1`. It unconditionally
sets `LOG_DIR`, `TMP_DIR`, `ERROR_LOG`, `BASE_DIR`, `LOG_FILE`, etc. These are
constants assigned with `=`. They cannot partially fail.

Despite this, `ver_verify_var` (which runs `declare -p`) checks these same
variables approximately 30 times during init:

- 3x in `ver_essential_check` (BASE_DIR, LOG_DIR, TMP_DIR)
- 9x per module in `ver_verify_module` (3 MODULE_VARS entries x 3 modules = 9)
- 8+ more times during `init_registered_functions` which re-calls
  `ver_verify_module` for modules that were just loaded

Each `ver_verify_var` call triggers `ver_log`, which forks `date` and
runs `mkdir -p` on the log directory.

### 2. The same paths are verified 21+ times

`LOG_DIR` is checked by `ver_verify_path` at least 6 times:

1. `init_logging_system` -> `ensure_dir_cached "$LOG_DIR"`
2. `ver_essential_check` -> `ver_verify_path "$LOG_DIR" "dir" "true"`
3. `ver_verify_module "err"` -> iterates MODULE_PATHS, finds LOG_DIR
4. `ver_verify_module "lo1"` -> same
5. `ver_verify_module "tme"` -> same
6. Function registration re-triggers `ver_verify_module` for all three again

### 3. The function registration phase is pure waste (184ms)

`init_registered_functions` (`bin/ini:540-660`) processes 6 functions by:

1. Calling `ver_verify_function_dependencies` -> calls `ver_verify_module` AGAIN
   for modules that are already loaded and verified
2. Calling `ver_verify_function` -> runs `grep` on the source file to confirm
   the function definition exists (the function is already in memory)
3. Calling `source "$module_path"` -> RE-SOURCES modules that `load_modules()`
   already sourced, re-triggering every module's top-level `ver_verify_module`
   guard and re-executing init code

This phase takes 184ms and does nothing that `type "$func" &>/dev/null`
(a <1ms builtin check) would not accomplish.

### 4. LOG_DEBUG_ENABLED=1 is a bug, not a feature

`lib/core/lo1:38` sets `LOG_DEBUG_ENABLED=1` by default. This causes every
`lo1_log` call to also run `lo1_dump_stack_trace`, which walks the entire
FUNCNAME array and writes multiple lines to the log file. With 30-50 log
calls and average stack depth of 5-8, this generates hundreds of extra file
writes. This is a development debugging setting that was left on.

### 5. The demo code with rm -rf is a latent hazard

`err_dangerous_operation()` in `lib/core/err:190-195` contains
`rm -rf some_important_directory/`. This is example/template code that is
never called but should not exist in production. Removing it is a safety
improvement.

### What IS the real safety net (preserved by this plan)

```bash
# bin/ini:185-203 -- these four guards catch real failures
source "${BASE_DIR}/cfg/core/ric" || { echo "Failed ric" >&2; exit 1; }
source "${BASE_DIR}/cfg/core/rdc" || { echo "Failed rdc" >&2; exit 1; }
source "${BASE_DIR}/cfg/core/mdc" || { echo "Failed mdc" >&2; exit 1; }
source "${BASE_DIR}/lib/core/ver" || { echo "Failed ver" >&2; exit 1; }

# bin/ini:458-465 -- module load return-code checks
if source "$module"; then
    ...
else
    ini_log "ERROR: Failed to source module: $module_name"
fi
```

If `ric` fails to source, init aborts. If a module fails to source, it is
logged. These are the only guards that matter because they catch the only
failure mode that exists: a file being missing or having a syntax error.

---

## Workstreams

### Phase 1: Independent workstreams (run in parallel)

All workstreams in Phase 1 have no file-level conflicts and can be
implemented simultaneously by separate agents.

---

#### WS-1: Replace External Commands with Builtins

**Files:** `bin/ini`, `lib/core/col`, `lib/core/tme`, `lib/core/lo1`,
`lib/core/err`, `lib/core/ver`, `bin/orc`
**Estimated savings:** 400-480ms
**Effort:** Medium
**Visual impact:** None

##### WS-1.1 Replace all `date` calls with printf builtins / $EPOCHREALTIME

337 `date` forks -> 0.

| File | Calls | Current | Replacement |
|------|------:|---------|-------------|
| `bin/ini` (ini_log) | ~66 | `date '+%H:%M:%S'` | `printf -v ts '%(%H:%M:%S)T' -1` |
| `bin/ini` lines 69, 736 | 2 | `date +%s%N` | `$EPOCHREALTIME` string math |
| `lib/core/tme` | ~83 | `date +%s.%N` | `$EPOCHREALTIME` |
| `lib/core/tme` | ~41 | `date -d @...` (report) | `printf '%(%T)T' "$epoch"` |
| `lib/core/lo1` | ~115 | `date +%s` | `printf -v t '%(%s)T' -1` |
| `lib/core/err` | ~6 | various `date` formats | `printf -v` equivalents |
| `lib/core/ver` | ~26 | `date` in ver_log | `printf -v` equivalents |

##### WS-1.2 Replace all `bc` with bash arithmetic

41 `echo ... | bc` -> 0:

```bash
# Current (3 forks: echo + pipe + bc):
duration=$(echo "$end - $start" | bc)

# Replacement (0 forks, using $EPOCHREALTIME strings):
local e_int="${end%.*}" e_frac="${end#*.}"
local s_int="${start%.*}" s_frac="${start#*.}"
e_frac="${e_frac}000000"; e_frac="${e_frac:0:6}"
s_frac="${s_frac}000000"; s_frac="${s_frac:0:6}"
local diff_us=$(( (e_int*1000000 + 10#$e_frac) - (s_int*1000000 + 10#$s_frac) ))
duration="$((diff_us / 1000000)).$( printf '%06d' $((diff_us % 1000000)) )"
```

##### WS-1.3 Replace `basename`/`dirname` with parameter expansion

25 `basename` + 54 `dirname` -> 0:

```bash
# basename: $(basename "$path") -> ${path##*/}
# dirname:  $(dirname "$path")  -> ${path%/*}
```

Sites: `bin/ini:441,453,169`, `bin/orc:122,233,402`, `lib/core/ver:297,46`.

##### WS-1.4 Replace `$(printf '\033[...]')` with ANSI-C quoting

35 subshell forks in `col` and `tme` -> 0:

```bash
# Current (subshell fork):
readonly COL_RED=$(printf '\033[0;31m')

# Replacement (zero forks):
readonly COL_RED=$'\033[0;31m'
```

Also remove the 10 duplicate color constants in `tme` -- reuse `COL_*`.

##### WS-1.5 Replace `$(cat "$file")` with `$(< "$file")`

85 `cat` forks -> 0 (bash builtin file read):

```bash
# Current (1 fork):
state=$(cat "$LOG_STATE_FILE" 2>/dev/null || echo "true")

# Replacement (0 forks):
state=$(< "$LOG_STATE_FILE" 2>/dev/null) || state="true"
```

Sites: `lo1:86`, `tme:176,219` and all `tme_settme`/`tme_print_*` functions.

##### WS-1.6 Replace `$(printf ...)` with `printf -v`

```bash
# Current (subshell fork):
_INI_ELAPSED_S=$(printf '%d.%03d' ...)

# Replacement (zero forks):
printf -v _INI_ELAPSED_S '%d.%03d' ...
```

---

#### WS-2: Eliminate source_helper Overhead

**Files:** `bin/orc`
**Estimated savings:** 60-100ms
**Effort:** Low
**Visual impact:** None

##### WS-2.1 Remove mktemp/cat/rm per file

`source_helper()` (`bin/orc:120-177`) creates a temp file for every sourced
file to capture stderr. With ~20 files sourced, this is 20x `mktemp` +
20x `cat` + 40x `rm` = 80 forks doing nothing useful.

Replace with direct sourcing and a shared error log:

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

##### WS-2.2 Replace `find | sort` with bash glob

`source_directory()` and `source_lib_ops()` both run
`find ... -print0 | sort -z > tmpfile` -- 3 forks per directory, 4
directories = 12+ forks.

Replace with glob (builtin, alphabetically sorted by default):

```bash
source_directory() {
    local dir="$1" description="${2:-}" count=0 total=0

    shopt -s nullglob
    local files=("$dir"/*)
    shopt -u nullglob

    for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        local name="${file##*/}"
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

##### WS-2.3 Consolidate source_lib_ops into source_directory

`source_lib_ops()` (`bin/orc:341-422`) is a near-copy of `source_directory()`
with added exclusion patterns. Eliminate the duplication by adding an
exclusion parameter to `source_directory`.

---

#### WS-3: Remove Redundant Verification

**Files:** `bin/ini`, `lib/core/err`, `lib/core/lo1`, `lib/core/tme`,
`cfg/core/ecc`, `cfg/core/rdc`
**Estimated savings:** 220-300ms
**Effort:** Low
**Visual impact:** None
**Safety impact:** None (see "Redundancy Evidence" above)

##### WS-3.1 Skip ver_verify_module during bootstrap

Each core module runs `ver_verify_module "X" || exit 1` at source time.
Add a guard so this is skipped when sourced from `bin/ini` (where the
environment is already validated) but still runs if a module is sourced
individually by a developer:

```bash
# In lib/core/err, lib/core/lo1, lib/core/tme:
[[ "${_INI_BOOTSTRAP:-0}" == "1" ]] || ver_verify_module "err" || exit 1
```

In `bin/ini`, set the flag before `load_modules`:

```bash
_INI_BOOTSTRAP=1
load_modules
unset _INI_BOOTSTRAP
```

Verification still runs if modules are sourced outside bootstrap context.

##### WS-3.2 Replace registered-functions system with type checks

Replace the entire `init_registered_functions` flow (`bin/ini:540-660`) --
which re-verifies, re-greps, and re-sources already-loaded modules -- with
6 `type` checks:

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

This replaces BATCH_FUNCTION_REGISTRATION (184ms) with <1ms of work.

##### WS-3.3 Remove redundant rdc re-sourcing

`cfg/core/rdc` is sourced at `bin/ini:190` and again at `bin/ini:504`
inside `init_runtime_system()`. The second source is redundant.

Remove lines 491-509 in `init_runtime_system` (the `VERIFY_RDC_PATH` and
`LOAD_RDC` timer-wrapped blocks).

##### WS-3.4 Remove process_runtime_config no-op

`process_runtime_config()` (`bin/ini:534-537`) does nothing except log.
It is wrapped with full timer start/stop calls. Remove the function and
its timer wrapping from `init_runtime_system()`.

##### WS-3.5 Remove double loop in load_modules

`load_modules()` iterates the modules array twice: once for "batch
validation" (lines 439-449) and once for actual loading (lines 452-469).
The first loop only calls `check_file_cached` which is then re-called in
the second loop. Remove the first loop entirely.

##### WS-3.6 Deduplicate hostname fork

`cfg/core/ric:90` calls `$(hostname)` to set `NODE_NAME`, then
`cfg/core/ecc:34` calls `$(hostname)` again to override it. Fix:

```bash
# In cfg/core/ecc:
export NODE_NAME="${NODE_NAME:-$(hostname)}"
```

##### WS-3.7 Remove dead functions from bin/ini

Two functions are defined but never called:

- `register_function` (lines 663-695) -- `register_single_function` is
  used instead
- `verify_function_dependencies` (lines 624-636) -- the code calls
  `ver_verify_function_dependencies` from `ver` instead

Delete both (~70 lines of dead code).

##### WS-3.8 Remove demo code with rm -rf

`err_dangerous_operation()` and `err_safe_operation()` in `lib/core/err`
(lines 190-205) contain `rm -rf some_important_directory/` and `dnf update`.
These are example/template code that should not exist in production.
Delete both functions.

---

#### WS-4: Reduce Logging Overhead

**Files:** `lib/core/lo1`, `bin/ini`
**Estimated savings:** 100-200ms
**Effort:** Medium
**Visual impact:** None (all changes are to internal mechanics, not output)

##### WS-4.1 Default LOG_DEBUG_ENABLED to 0

`lib/core/lo1:38` sets `LOG_DEBUG_ENABLED=1`. This causes every `lo1_log`
call to dump a full stack trace to the log file. This is a development
debugging feature that should be opt-in:

```bash
export LOG_DEBUG_ENABLED=${LOG_DEBUG_ENABLED:-0}
```

Users who want debug logging set `LOG_DEBUG_ENABLED=1` in their environment.

##### WS-4.2 Eliminate subshell captures in lo1_log

Every `lo1_log` call triggers 4 functions captured via `$(...)`:

1. `$(lo1_get_cached_log_state)` -- reads state file
2. `$(lo1_calculate_final_depth)` -- walks call stack
3. `$(lo1_get_indent "$depth")` -- builds indent string
4. `$(lo1_get_color "$depth")` -- looks up color

Refactor to use global return variables:

```bash
# Instead of: depth=$(lo1_calculate_final_depth)
_lo1_calculate_final_depth   # sets _LO1_RESULT
local depth=$_LO1_RESULT
```

Or inline the logic directly into `lo1_log`.

##### WS-4.3 Cache log state in variable instead of file

`lo1_get_cached_log_state()` reads `$LOG_STATE_FILE` from disk on nearly
every call (85 `cat` forks during init). The state only changes when
`lo1_setlog` is explicitly called.

Use a global variable as the primary state holder:

```bash
declare -g LOG_STATE_CACHED="on"

lo1_setlog() {
    LOG_STATE_CACHED="$1"
    echo "$1" > "$LOG_STATE_FILE"  # persist for next session
}

# In lo1_log, replace $(lo1_get_cached_log_state) with:
[[ "$LOG_STATE_CACHED" != "on" ]] && return 0
```

##### WS-4.4 Cache dirname in ini_log

`ini_log` (`bin/ini:169`) runs `$(dirname "$INI_LOG_FILE")` on every call
(~40 times). The result never changes. Compute once:

```bash
_INI_LOG_DIR="${INI_LOG_FILE%/*}"

# In ini_log, replace:
#   ensure_dir_cached "$(dirname "$INI_LOG_FILE")"
# With:
#   ensure_dir_cached "$_INI_LOG_DIR"
```

##### WS-4.5 Skip depth calculation during init

`lo1_get_base_depth()` walks the FUNCNAME array on every log call. During
init most callers are unique so the cache rarely hits. During
`PERFORMANCE_MODE=1` (set by ini), use a fixed depth:

```bash
lo1_get_base_depth() {
    if [[ "${PERFORMANCE_MODE:-0}" == "1" ]]; then
        echo 1; return
    fi
    # ... existing call-stack walking logic
}
```

##### WS-4.6 Deduplicate mkdir in tme_init_timer

`tme_init_timer` calls `mkdir -p "$TMP_DIR"` at lines 88, 96, and 115
(same directory) and `mkdir -p "$log_dir"` at lines 79 and 143 (same
directory). Replace with one call per unique directory at the top:

```bash
tme_init_timer() {
    local log_dir="${LOG_DIR:-${BASE_DIR}/.log}"
    mkdir -p "$log_dir" "$TMP_DIR"
    # ... rest of init, no more mkdir calls
}
```

##### WS-4.7 Add mkdir guard in ver_log

`ver_log` (line 46) runs `mkdir -p "$(dirname "$VER_LOG_FILE")"` on every
invocation. Guard with a flag:

```bash
[[ -z "${_VER_LOG_DIR_READY:-}" ]] && {
    mkdir -p "${VER_LOG_FILE%/*}" 2>/dev/null
    _VER_LOG_DIR_READY=1
}
```

##### WS-4.8 Replace type-check repetitions with a flag

After `load_modules` loads tme, the code checks `type tme_start_timer`
at ~20 different call sites throughout `bin/ini`. Set a flag once:

```bash
_TME_AVAILABLE=0
type tme_start_timer &>/dev/null && _TME_AVAILABLE=1

# Then replace all occurrences of:
#   type tme_start_timer &>/dev/null &&
# With:
#   ((_TME_AVAILABLE)) &&
```

---

### Phase 2: Lazy Module Loading (after Phase 1 merges)

#### WS-5: Autoload Stubs for ops/gen Modules

**Files:** `bin/ini`, `bin/orc`, `cfg/core/autoload` (new),
`lib/ops/*` (preamble only), `lib/gen/*` (preamble only)
**Estimated savings:** 300-500ms
**Effort:** High
**Visual impact:** None
**Trade-off:** First call to any lazy-loaded function has a one-time
~30-50ms delay (imperceptible to a human). A fallback flag
`LAB_EAGER_LOAD=1` restores the old behavior.

##### WS-5.1 Create an autoload manifest

A file `cfg/core/autoload` listing every public function and its module:

```
gpu_ptd:lib/ops/gpu
gpu_lst:lib/ops/gpu
pve_cdo:lib/ops/pve
net_sca:lib/ops/net
...
```

Generated by a helper script (run manually after adding functions):

```bash
# bin/gen-autoload
for module in lib/ops/* lib/gen/*; do
    [[ -f "$module" ]] || continue
    name="${module##*/}"
    case "$name" in *.md|*.txt|*.spec|.*) continue ;; esac
    grep -oP '^\s*(?:function\s+)?(\w+)\s*\(\)' "$module" |
        sed "s/[[:space:]]*()//; s/function //" |
        while read -r func; do
            [[ "$func" == _* ]] && continue  # skip private
            echo "${func}:${module}"
        done
done > cfg/core/autoload
```

##### WS-5.2 Generate stub functions during bootstrap

Instead of sourcing 15 files (16,571 lines), read the manifest and
generate lightweight stubs:

```bash
load_autoload_stubs() {
    local func module
    while IFS=: read -r func module; do
        eval "${func}() { source \"\${BASE_DIR}/${module}\" && ${func} \"\$@\"; }"
    done < "${BASE_DIR}/cfg/core/autoload"
}
```

When any function is called for the first time, the real module is sourced
(overwriting the stub), then the function runs with the original arguments.

Stubs are real functions visible to `type` and `compgen -A function`,
so tab completion and `type func_name` still work.

##### WS-5.3 Eager-load fallback

```bash
if [[ "${LAB_EAGER_LOAD:-0}" == "1" ]]; then
    source_lib_ops
    source_lib_gen
else
    load_autoload_stubs
fi
```

##### WS-5.4 Fix ops module preambles

Every ops module has a preamble that forks 2 subshells:

```bash
# Current (2 forks):
DIR_FUN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILE_FUN=$(basename "$BASH_SOURCE")

# Replacement (0 forks):
DIR_FUN="${BASH_SOURCE[0]%/*}"
[[ "$DIR_FUN" == "${BASH_SOURCE[0]}" ]] && DIR_FUN="."
FILE_FUN="${BASH_SOURCE[0]##*/}"
```

Applies to all 12 modules sharing this preamble pattern.

---

### Phase 3: Deferred (implement only if Phase 1+2 savings are insufficient)

#### WS-6: Init Caching (OPTIONAL)

**Files:** `bin/ini`
**Estimated additional savings:** 200-400ms
**Effort:** Medium
**Trade-off:** Changes to `lib/ops/*`, `lib/gen/*` are not picked up until
the cache is invalidated. Requires a `lab --reload` command.
**Why deferred:** Adds a new failure mode (stale cache). Phase 1+2 should
already bring init from ~1.54s to ~0.5-0.8s, which may be sufficient.

##### WS-6.1 Fast-path init cache

After a successful init, dump all variable and function state to a cache
file. On subsequent runs, source the cache instead of re-running init:

```bash
_INI_CACHE="${BASE_DIR}/.tmp/ini_cache"

if [[ -f "$_INI_CACHE" ]] && [[ "$_INI_CACHE" -nt "$0" ]]; then
    source "$_INI_CACHE"
    return 0
fi

# ... normal init ...

# At end of successful init:
declare -p BASE_DIR LOG_DIR TMP_DIR ... > "$_INI_CACHE"
declare -f >> "$_INI_CACHE"
```

##### WS-6.2 Cache invalidation

Compare timestamps of all source files against the cache:

```bash
local newest_source
newest_source=$(stat -c %Y lib/ops/* lib/gen/* | sort -rn | head -1)
local cache_time
cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)

if (( cache_time > newest_source )); then
    source "$cache_file"
else
    source_all_modules
    declare -f > "$cache_file"
fi
```

Manual invalidation: `lab --reload` or `rm "${BASE_DIR}/.tmp/ini_cache"`.

---

## Implementation Summary

| WS | What | Savings | Effort | Phase |
|----|------|--------:|--------|-------|
| WS-1.1 | `date` -> `printf` / `$EPOCHREALTIME` | 250-350ms | Medium | 1 |
| WS-1.2 | `bc` -> bash arithmetic | 20-40ms | Medium | 1 |
| WS-1.3 | `basename`/`dirname` -> param expansion | 40-60ms | Low | 1 |
| WS-1.4 | `$(printf '\033')` -> `$'\033'` | 10-20ms | Low | 1 |
| WS-1.5 | `$(cat)` -> `$(< )` | 30-60ms | Low | 1 |
| WS-1.6 | `$(printf)` -> `printf -v` | 5-10ms | Low | 1 |
| WS-2.1 | Remove mktemp in source_helper | 50-80ms | Low | 1 |
| WS-2.2 | `find\|sort` -> glob | 10-20ms | Low | 1 |
| WS-2.3 | Consolidate source_lib_ops | ~0 | Low | 1 |
| WS-3.1 | Skip ver_verify_module during bootstrap | 60-100ms | Low | 1 |
| WS-3.2 | Replace registered-functions with `type` | 150-184ms | Low | 1 |
| WS-3.3 | Remove redundant rdc re-sourcing | 10-15ms | Trivial | 1 |
| WS-3.4 | Remove process_runtime_config no-op | 5ms | Trivial | 1 |
| WS-3.5 | Remove double loop in load_modules | 5-10ms | Trivial | 1 |
| WS-3.6 | Deduplicate hostname fork | 2-5ms | Trivial | 1 |
| WS-3.7 | Remove dead functions from bin/ini | ~0 | Trivial | 1 |
| WS-3.8 | Remove demo code with rm -rf | ~0 | Trivial | 1 |
| WS-4.1 | LOG_DEBUG_ENABLED=0 default | 50-150ms | Trivial | 1 |
| WS-4.2 | lo1_log subshell elimination | 20-60ms | Medium | 1 |
| WS-4.3 | Cache log state in variable | 30-60ms | Low | 1 |
| WS-4.4 | Cache dirname in ini_log | 15-30ms | Trivial | 1 |
| WS-4.5 | Skip depth calc in PERFORMANCE_MODE | 10-20ms | Low | 1 |
| WS-4.6 | Deduplicate mkdir in tme_init_timer | 5-10ms | Trivial | 1 |
| WS-4.7 | Add mkdir guard in ver_log | 5-15ms | Trivial | 1 |
| WS-4.8 | Replace type-check repetitions with flag | 5-15ms | Low | 1 |
| **Phase 1 total** | | **~750-1100ms** | | |
| WS-5 | Lazy module loading (autoload stubs) | 300-500ms | High | 2 |
| **Phase 1+2 total** | | **~1050-1600ms** | | |
| WS-6 | Init caching (optional) | 200-400ms | Medium | 3 |

### Projected init time

| After | Estimated wall time | Forks |
|-------|-------------------:|------:|
| Current | ~1.54s | 630 |
| Phase 1 | ~0.5-0.8s | ~40-60 |
| Phase 1+2 | ~0.3-0.5s | ~20-40 |
| Phase 1+2+3 | ~0.15-0.3s | ~10-20 |

---

## Agent Parallelization Map

```
Phase 1 (all run in parallel, no file conflicts):

  Agent A: WS-1 (Builtin replacements)
    Files: lib/core/tme, lib/core/ver, lib/core/lo1,
           lib/core/err, lib/core/col, bin/ini
    Scope: Replace date/bc/basename/dirname/printf/cat
           with builtins and parameter expansion
    Note:  In lo1, only touch timestamp generation (date calls).
           Agent D handles lo1's log flow changes.
    Note:  In tme, only touch timestamps and bc.
           Agent D handles tme's mkdir dedup.

  Agent B: WS-2 (source_helper + orc I/O)
    Files: bin/orc
    Scope: Remove mktemp/cat/rm per source, replace find|sort
           with glob, consolidate source_lib_ops

  Agent C: WS-3 (Redundancy removal)
    Files: bin/ini, lib/core/err (guard + demo code),
           lib/core/lo1 (guard only), lib/core/tme (guard only),
           cfg/core/ecc (hostname)
    Scope: Add _INI_BOOTSTRAP guard, simplify registered functions,
           remove dead code, remove rdc re-source, remove no-op

  Agent D: WS-4 (Logging overhead)
    Files: lib/core/lo1 (log flow), bin/ini (ini_log only),
           lib/core/tme (mkdir dedup), lib/core/ver (mkdir guard)
    Scope: LOG_DEBUG_ENABLED default, cache state in variables,
           eliminate subshell captures, type-check flag,
           mkdir deduplication
```

### Conflict notes

- Agents A and D both touch `lib/core/lo1` but on different concerns:
  Agent A changes `date` -> `printf` (timestamp generation).
  Agent D changes log state caching and subshell elimination (log flow).
  These touch different functions and merge cleanly.

- Agents A and D both touch `lib/core/tme`:
  Agent A changes timestamps and `bc`.
  Agent D deduplicates `mkdir` calls.
  Different functions, clean merge.

- Agent C touches `lib/core/err`, `lo1`, `tme` only to modify the
  single-line `ver_verify_module` guard at the top. No overlap with
  Agent A's timestamp changes or Agent D's flow changes.

---

## Validation Protocol

### Per-workstream (after each agent finishes)

```bash
# 1. Syntax check all modified files
bash -n bin/ini bin/orc lib/core/*

# 2. Run relevant test category
./val/run_all_tests.sh core

# 3. Functional smoke test -- should produce identical tree output
bash -c 'source bin/ini' 2>&1

# 4. Timing check
for i in {1..5}; do
    bash -c 'source bin/ini' 2>&1 | tail -1
done
```

### After Phase 1 integration

```bash
# 1. Full test suite
./val/run_all_tests.sh

# 2. Visual output comparison (diff ignoring timestamps)
bash -c 'source bin/ini' 2>&1 | sed 's/\[.*\]/[TS]/g' > /tmp/after.txt
# Compare with saved baseline

# 3. Function availability check
bash -c 'source bin/ini; type gpu_ptd; type pve_cdo; type net_sca' 2>&1

# 4. Timing comparison (5-run median)
for i in {1..5}; do
    bash -c 'source bin/ini' 2>&1 | tail -1
done
```

### After Phase 2 (lazy loading)

```bash
# All of the above, plus:

# 5. Verify lazy loading works for every ops function
bash -c '
    source bin/ini
    for func in $(compgen -A function | grep -E "^(gpu|pve|net|sys|dsk)_"); do
        type "$func" | head -1
    done
'

# 6. Verify LAB_EAGER_LOAD fallback
LAB_EAGER_LOAD=1 bash -c 'source bin/ini; type gpu_ptd' 2>&1
```
