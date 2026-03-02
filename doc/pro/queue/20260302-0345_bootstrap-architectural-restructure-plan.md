# Bootstrap Architectural Restructure

- Status: queue
- Owner: es
- Started: n/a
- Updated: 2026-03-03
- Links: bin/ini, bin/orc, cfg/core/ric, cfg/core/rdc, cfg/core/mdc, cfg/core/lzy, lib/core/ver, src/set/.menu, src/dic/ops, doc/arc/00-architecture-overview.md, doc/arc/01-bootstrap-and-orchestration.md, doc/pro/completed/20260301-2328_bootstrapper-performance-renewal

## Triage Decision

- Why now: This is the architectural follow-on to a just-completed performance renewal, and deferring it keeps redundant boot paths and dead boot-time code in the critical initialization path.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: The work changes bootstrap structure and shared loading contracts across interactive, DIC, and deployment paths, so design choices materially affect downstream behavior.

## Goal

Simplify and restructure the bootstrap architecture to remove redundant
subsystems, unify module sourcing across all execution paths, and separate
interactive and deployment boot concerns. This is a structural/design
follow-on to the completed performance renewal (fork elimination, lazy
loading), which reduced boot time from 1.7s to ~0.5s without changing the
underlying architecture.

## Context

The performance renewal identified and fixed tactical bottlenecks (subprocess
forks, redundant I/O, eager parsing). The architecture underneath was left
intact. Reviewing the boot chain, config files, DIC layer, and deployment
framework reveals six structural issues that are independent of performance
and concern redundancy, dead ceremony, incoherent sourcing paths, and
unnecessary abstraction.

### Issue 1: Verification/Registration Ceremony Is Circular

`bin/ini` loads core modules via `load_modules()` (lines 497-552), then
immediately runs `init_registered_functions()` (line 597) which iterates
`REGISTERED_FUNCTIONS` from `cfg/core/rdc`. That array maps exactly 6
functions back to `lib/core/{err,lo1,tme}` -- the same files that
`load_modules()` already sourced. The sequence is:

1. `source lib/core/tme` (returns 0, tme_start_timer now exists)
2. `cache_module_verification()` checks that `lib/core/tme` exists as a file
3. `process_function_registration()` calls `ver_verify_function` on
   `tme_start_timer`
4. `register_single_function()` re-sources `lib/core/tme`

The entire subsystem -- `REGISTERED_FUNCTIONS`, `FUNCTION_DEPENDENCIES`,
`FUNCTION_MODULES`, `cache_module_verification`, `process_function_registration`,
`register_single_function`, `verify_function_dependencies` -- is ~150 lines
validating what `source` already established.

Files: `bin/ini:614-735`, `cfg/core/rdc` (all 66 lines).

### Issue 2: Three Independent Sourcing Paths Without Coordination

Three subsystems source the same module files with no shared loaded-state:

| Path | Location | Behavior |
|------|----------|----------|
| Interactive boot | `bin/orc` `source_lib_ops`/`source_lib_gen` | Lazy stubs or eager source |
| Deployment framework | `src/set/.menu` source-time init | Eagerly re-sources all `lib/ops/*` and `cfg/env/*` |
| DIC execution | `src/dic/ops` `ops_execute` | Sources target module again before calling function |

The lazy-load system built in `bin/orc` (using `ORC_LAZY_MODULE_LOADED`) is
bypassed by the deployment and DIC paths. A deployment run sources every ops
module at least twice. No path checks whether a module is already loaded
before sourcing it.

Files: `bin/orc:461-553`, `src/set/.menu` (source-time loading), `src/dic/ops`
(`ops_execute`).

### Issue 3: Interactive and Deployment Paths Share a Boot Chain They Shouldn't

`bin/ini` (824 lines) serves two fundamentally different use cases:

- **Interactive shell**: needs aliases, prompt setup, stubs. Speed critical.
- **Deployment scripts**: need DIC, ops modules, env config. Correctness critical.

Both go through the same timer system, verification dance, and component
orchestrator. This is why the codebase accumulated transient boot-phase
toggles (`PERFORMANCE_MODE`, `LAB_BOOTSTRAP_MODE`, `LOG_DEBUG_ENABLED=0`) --
flags to make one code path behave like two.

Files: `bin/ini` (all), `bin/orc:792-861`.

### Issue 4: `mdc` Is Dead Code at Boot Time

`cfg/core/mdc` defines `init_module_requirements()` which populates
`MODULE_VARS`, `MODULE_PATHS`, `MODULE_OPTS`, `MODULE_COMMANDS`. The only
consumer is `ver_verify_module`. But `ver_verify_module` is gated off during
bootstrap (`LAB_BOOTSTRAP_MODE=1`) by the performance renewal. So the boot
chain:

1. Sources `mdc` (72 lines parsed)
2. Calls `init_module_requirements` (populates 12+ associative array entries)
3. Skips the only code that reads them

At runtime, `ver_verify_module` is not called in any hot path. The `mdc`
subsystem is validation infrastructure that belongs in `./go validate` and
test scripts, not the boot chain.

Files: `cfg/core/mdc` (all 72 lines), `lib/core/ver:212-317`.

### Issue 5: `execute_component` Wrapper Is Unnecessary Abstraction

`bin/orc:376-422` wraps every component call with timer start/stop, function
existence check, required/optional branching, and success variable export.

- All 6 components are `COMPONENT_OPTIONAL`. The required/optional
  distinction is dead branching.
- Exported success variables (`CFG_ECC_SUCCESS`, `LIB_OPS_SUCCESS`, etc.)
  are never read by any downstream code.
- Timer wrapping duplicates what component functions already do internally
  (e.g., `source_cfg_ecc` calls `tme_start_timer "cfg_ecc"` at line 699).

Files: `bin/orc:376-422`, `bin/orc:818-826`.

### Issue 6: Compiled Bootstrap Snapshot (Optional Paradigm Shift)

The current boot parses ~24,000 lines across 31 files per shell open. Even
with lazy loading, the core modules, config files, stub map, and aliases are
still individually sourced. A build step that pre-compiles the boot state into
a single cached file would reduce 31 `source` calls (each with `open()`/
`read()`/`close()` syscalls) to one.

This is how `oh-my-zsh` compiled init, `zsh` `.zwc` files, and
`bash-completion` cached completions work. It would complement lazy loading
rather than replace it.

This issue is the only one that adds new infrastructure rather than removing
existing complexity. It is marked optional and phased last.

## Scope

In scope:

1. Remove the verification/registration ceremony from the boot path.
2. Create a unified module sourcing registry used by all three sourcing paths.
3. Separate interactive and deployment boot concerns.
4. Remove `mdc` from the boot chain.
5. Remove the `execute_component` wrapper.
6. Optionally prototype a compiled bootstrap snapshot.

Out of scope:

1. Changes to `lib/ops/*` or `lib/gen/*` module APIs or contracts.
2. Changes to DIC argument injection semantics (`src/dic/lib/*`).
3. Functional changes to deployment manifests (`src/set/*` section logic).
4. Further fork/subprocess elimination (completed in performance renewal).
5. Changes to `./go` entrypoint shell integration lifecycle.

## Implementation Approach

### Phase 1 -- Remove Boot-Time Dead Code

Remove subsystems that execute during boot but produce no used output.

**1a. Remove `mdc` from the boot chain.**

- Remove `source "${BASE_DIR}/cfg/core/mdc"` from `bin/ini`.
- Remove `init_module_requirements` call from `bin/ini:452`.
- Move `mdc` sourcing into `./go validate` and relevant `val/` test scripts
  that exercise `ver_verify_module`.
- Keep `mdc` file unchanged; only its load point moves.

**1b. Remove verification/registration ceremony from boot.**

- Remove `init_registered_functions()` call from `bin/ini:597`.
- Remove helper functions: `cache_module_verification`,
  `process_function_registration`, `register_single_function`,
  `verify_function_dependencies`, `register_function` (~150 lines).
- Remove timer instrumentation for `CACHE_MODULE_VERIFICATION` and
  `BATCH_FUNCTION_REGISTRATION` from `init_runtime_system`.
- Preserve `cfg/core/rdc` as-is for potential offline validation use; just
  stop sourcing it at boot time if no other boot consumer remains.
- Audit whether `rdc` has any boot consumer beyond the removed registration
  code. If none, remove `source "${BASE_DIR}/cfg/core/rdc"` from `bin/ini`.

**1c. Remove `execute_component` wrapper.**

- Replace `execute_component "$func" "$name" "$required"` calls in
  `setup_components` with direct function calls.
- Keep per-component timer instrumentation if desired, but inline it
  (two lines: `tme_start_timer` before, `tme_end_timer` after).
- Remove `execute_component` function, `COMPONENT_REQUIRED`/
  `COMPONENT_OPTIONAL` constants, and exported success variables.
- Simplify `setup_components` from component-definition-array parsing to
  a plain sequential call list.

Done when:

- `bin/ini` no longer sources `mdc` or `rdc` (if audit confirms no boot
  consumer).
- No verification/registration ceremony runs at boot.
- `setup_components` calls component functions directly.
- Boot timing is equal or faster than current baseline (~495ms median).
- All existing tests pass (`./val/run_all_tests.sh --quick`).

### Phase 2 -- Unified Module Sourcing Registry

Create a single source-of-truth for module loaded state, shared by
`bin/orc`, `src/set/.menu`, and `src/dic/ops`.

**2a. Define the registry.**

- Introduce a single associative array `_LAB_MODULE_LOADED` (or extend
  existing `ORC_LAZY_MODULE_LOADED`) as the authoritative loaded-state
  tracker.
- Define a single `lab_source_module` function that:
  1. Checks `_LAB_MODULE_LOADED[$module]`.
  2. If already loaded, returns 0 immediately.
  3. Otherwise sources the module file and marks it loaded.
  4. Handles error reporting on source failure.
- Place this function in `lib/core/` or `bin/orc` so it is available early.

**2b. Adopt the registry in `bin/orc`.**

- Replace `source_helper` calls in `source_lib_ops`/`source_lib_gen` eager
  paths with `lab_source_module`.
- Update `_orc_lazy_dispatch` to use `_LAB_MODULE_LOADED` (likely already
  close via `ORC_LAZY_MODULE_LOADED`; unify naming).

**2c. Adopt the registry in `src/dic/ops`.**

- Replace the direct `source "$lib_path"` in `ops_execute` with
  `lab_source_module`.
- This eliminates redundant re-sourcing when DIC executes a module that
  was already loaded via the interactive boot path or a previous DIC call.

**2d. Adopt the registry in `src/set/.menu`.**

- Replace the broad source-time loading loops for `lib/ops/*` and
  `cfg/env/*` with `lab_source_module` calls.
- This eliminates the double-source pattern where `.menu` eagerly loads
  everything and then DIC loads the same module again.

Done when:

- A single function (`lab_source_module`) is the only way modules are
  sourced across all three paths.
- `_LAB_MODULE_LOADED` is the single loaded-state tracker.
- Duplicate sourcing is eliminated (verifiable via debug logging or
  source-count instrumentation).
- Deployment scripts still function correctly end-to-end.
- Existing tests pass.

### Phase 3 -- Separate Interactive and Deployment Boot Paths

Restructure `bin/ini` so interactive shells and deployment scripts do not
share unnecessary boot ceremony.

**3a. Extract shared foundation.**

- Factor out the minimal shared setup that both paths need into a lean
  foundation layer (working name: `bin/ini_core` or a section within
  `bin/ini`):
  - Source `cfg/core/ric` (path constants).
  - Define `lab_source_module` registry (from Phase 2).
  - Source `lib/core/ver` (minimal verification).
  - Source `lib/core/col`, `lib/core/err`, `lib/core/lo1`, `lib/core/tme`
    (core primitives).
  - Export `LAB_DIR`, `BASE_DIR`, core paths.

**3b. Slim the interactive boot path.**

- `bin/ini` (the path sourced from `.bashrc`) uses the shared foundation
  plus:
  - `cfg/core/ecc` (env controller).
  - `cfg/ali/*` (aliases).
  - `cfg/core/lzy` lazy stub registration for ops/gen.
  - `cfg/env/site*` (site config).
- Remove timer instrumentation, `init_runtime_system`, and component
  orchestration ceremony from the interactive path.
- Target: the interactive path is a short, linear sequence with no
  wrapper abstractions.

**3c. Clarify the deployment boot path.**

- Deployment scripts (`src/set/*`) that source `src/set/.menu` and
  `src/dic/ops` use the shared foundation (already available if the
  interactive shell was bootstrapped, or explicitly sourced if running
  standalone).
- `.menu` no longer needs to eagerly source everything because
  `lab_source_module` (Phase 2) handles on-demand loading with
  deduplication.

**3d. Remove transient boot-phase toggles.**

- With the interactive path simplified, the need for `PERFORMANCE_MODE`,
  `LAB_BOOTSTRAP_MODE`, and boot-time `LOG_DEBUG_ENABLED` suppression
  should be re-evaluated.
- If the interactive path no longer runs verification or heavy logging
  during boot, these toggles become unnecessary.
- Remove each toggle only after confirming no remaining boot-path consumer.

Done when:

- Interactive boot path is a linear sequence without orchestration wrappers.
- Deployment scripts work standalone or on top of an existing interactive
  session without redundant loading.
- Boot-phase toggles are removed or reduced to the minimum necessary.
- Boot timing for interactive path is equal or faster than Phase 1 baseline.
- All existing tests pass.

### Phase 4 -- Compiled Bootstrap Snapshot (Optional)

Prototype a build step that pre-compiles the interactive boot state into a
single cached file.

**4a. Design the compilation step.**

- `./go compile` (or `./go cache`) concatenates the interactive boot
  payload (ric + core modules + lazy stubs + aliases) into a single file
  (e.g., `.cache/boot`).
- Include a staleness check: compare mtime of cached file against source
  files; regenerate if stale.
- Include a version/hash guard in the cached file header.

**4b. Use the cached file in the interactive boot path.**

- `bin/ini` checks for `.cache/boot`; if fresh, sources it and returns.
- If stale or missing, falls back to the normal interactive boot path and
  optionally regenerates the cache on success.

**4c. Integrate with `./go` lifecycle.**

- `./go init` and `./go on` trigger cache generation.
- `./go off` and `./go purge` remove the cache.
- `./go status` reports cache state.

Done when:

- `./go compile` produces a working cached boot file.
- Interactive boot from cache is measurably faster than Phase 3 baseline.
- Stale cache is detected and regenerated transparently.
- All existing tests pass.

## Dependency Order

```
Phase 1 (remove dead code)
    |
    v
Phase 2 (unified registry)
    |
    v
Phase 3 (path separation)
    |
    v
Phase 4 (compiled snapshot, optional)
```

Each phase is independently valuable and can be shipped as a separate
change set. Phase 1 is prerequisite for Phase 3 (removing ceremony first
makes the path separation cleaner). Phase 2 can technically proceed in
parallel with Phase 1 but is listed after because the unified registry
design benefits from knowing what boot-time code remains after Phase 1
cleanup.

## Risks

1. **Deployment scripts assume pre-loaded state.** `src/set/.menu` and
   `src/dic/ops` may implicitly depend on symbols loaded by the full
   `bin/ini` boot chain. Removing boot ceremony or changing load order
   could surface latent assumptions. Mitigation: trace all symbols used at
   source-time by `.menu` and DIC; ensure they are provided by the shared
   foundation or on-demand loading.

2. **Test scripts source `bin/ini` for setup.** Many `val/` scripts source
   `bin/ini` to get a working environment. Changing `bin/ini` structure
   affects test harness behavior. Mitigation: run full test suite at each
   phase boundary; fix test sourcing paths as needed.

3. **`rdc`/`mdc` removal may have hidden consumers.** Although analysis
   shows no boot-time consumers beyond the removed ceremony, other scripts
   or interactive usage might read `REGISTERED_FUNCTIONS` or `MODULE_VARS`.
   Mitigation: grep for all consumers before removing source lines; keep
   the files available for offline/test use.

4. **Unified registry changes source-time side effects.** Some modules
   execute code at source time (e.g., `lib/core/err` populates
   `ERROR_CODES`). Deduplicating sourcing means this code runs exactly
   once instead of multiple times. If any consumer depends on re-execution,
   it will break. Mitigation: audit source-time side effects in all ops/gen
   modules for idempotency.

5. **Compiled snapshot staleness.** If the cache is not invalidated
   correctly, users get stale function definitions after code updates.
   Mitigation: conservative staleness check (any source file newer than
   cache triggers rebuild); `./go compile` as explicit rebuild command.

## Verification Plan

1. Syntax-check all edited files: `bash -n <file>`.
2. Run targeted tests for bootstrap:
   - `./val/core/initialization/ini_test.sh`
   - `./val/core/initialization/orc_test.sh`
   - `./val/core/modules/ver_test.sh`
3. Run category suites for affected areas:
   - `./val/run_all_tests.sh core`
   - `./val/run_all_tests.sh lib`
   - `./val/run_all_tests.sh src`
   - `./val/run_all_tests.sh dic`
4. Run full suite at phase boundaries:
   - `./val/run_all_tests.sh`
5. Capture before/after boot timing at each phase:
   - `time bash -lc 'MASTER_TERMINAL_VERBOSITY=off; source /home/es/lab/bin/ini' 2>&1`
   - 3-run median comparison.
6. Verify deployment script end-to-end:
   - Source `bin/ini`, then run a DIC command (`ops <module> <function> --help`)
     to confirm module loading works through the unified registry.

## Acceptance Criteria

1. Boot chain no longer sources `mdc` or `rdc` (or sources `rdc` only if a
   boot consumer is confirmed).
2. No verification/registration ceremony runs during interactive boot.
3. `setup_components` calls component functions directly without wrapper.
4. A single `lab_source_module` function is the canonical module loader
   across `bin/orc`, `src/set/.menu`, and `src/dic/ops`.
5. No module is sourced more than once in any execution path.
6. Interactive boot timing is equal or better than current ~495ms baseline.
7. All tests pass at `./val/run_all_tests.sh` level.
8. Architecture docs (`doc/arc/00`, `01`, `02`, `03`, `04`, `05`) are
   updated to reflect structural changes.

## Estimated Effort

| Phase | Estimate |
|-------|----------|
| Phase 1 (dead code removal) | 2-3 hours |
| Phase 2 (unified registry) | 3-5 hours |
| Phase 3 (path separation) | 4-6 hours |
| Phase 4 (compiled snapshot) | 3-5 hours |

Total: ~12-19 hours across 4 phases, with Phase 4 optional.

## Relationship to Performance Renewal

The completed performance renewal (`doc/pro/completed/20260301-2328_*`)
targeted boot latency through fork elimination, integer arithmetic, and lazy
loading. This plan targets architectural simplification: removing code that
should not exist, unifying paths that diverged unnecessarily, and separating
concerns that were conflated. The two efforts are complementary --
performance renewal made the existing architecture fast; this plan makes it
simple.
