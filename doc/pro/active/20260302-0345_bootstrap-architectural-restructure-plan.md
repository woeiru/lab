# Bootstrap Architectural Restructure

- Status: active
- Owner: es
- Started: 2026-03-03
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
6. Prototype a compiled bootstrap snapshot.

Out of scope:

1. Changes to `lib/ops/*` or `lib/gen/*` module APIs or contracts.
2. Changes to DIC argument injection semantics (`src/dic/lib/*`).
3. Functional changes to deployment manifests (`src/set/*` section logic).
4. Further fork/subprocess elimination (completed in performance renewal).
5. Changes to `./go` entrypoint shell integration lifecycle.

## Execution Plan (today)

### Phase 1 -- Design baseline and decision record

Document the final bootstrap architecture before implementation, including:

- unified module loader interface and ownership (`lab_source_module` + state map)
- exact interactive vs deployment load boundaries
- removal plan for registration/verification ceremony and dead boot-time consumers
- invariants for idempotent sourcing and source-time side effects

Completion criterion: a committed design section in this file that records interfaces, constraints, alternatives considered, and chosen approach.

### Phase 2 -- Remove dead boot-time ceremony

Implement the removals that do not depend on new architecture wiring:

- remove `mdc` from boot path and keep it only in validation/test contexts
- remove registration/verification ceremony from `bin/ini`
- remove `execute_component` wrapper and call components directly

Completion criterion: interactive bootstrap no longer executes dead ceremony paths, verified by targeted initialization tests.

### Phase 3 -- Implement unified sourcing registry

Implement and adopt one canonical module loader across `bin/orc`, `src/dic/ops`, and `src/set/.menu`.

Completion criterion: all three paths source modules only through `lab_source_module` with shared loaded-state tracking.

### Phase 4 -- Separate interactive and deployment bootstrap paths

Refactor `bin/ini` into a lean shared foundation plus explicit interactive/deployment path behavior.

Completion criterion: interactive bootstrap is linear and deployment execution works without redundant eager re-sourcing.

### Phase 5 -- Compiled bootstrap snapshot prototype

Prototype a cacheable compiled bootstrap payload and wire staleness detection.

Completion criterion: `./go compile` generates a valid cache that `bin/ini` can source when fresh.

## Dependency Order

```
Phase 1 (design baseline)
    |
    v
Phase 2 (dead code removal)
    |
    v
Phase 3 (unified registry)
    |
    v
Phase 4 (path separation)
    |
    v
Phase 5 (compiled snapshot prototype)
```

Phases execute in order. Each phase can be delivered as its own change set
after its completion criterion is met.

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

## Exit Criteria

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
| Phase 1 (design baseline) | 1-2 hours |
| Phase 2 (dead code removal) | 2-3 hours |
| Phase 3 (unified registry) | 3-5 hours |
| Phase 4 (path separation) | 4-6 hours |
| Phase 5 (compiled snapshot) | 3-5 hours |

Total: ~13-21 hours across 5 phases.

## Relationship to Performance Renewal

The completed performance renewal (`doc/pro/completed/20260301-2328_*`)
targeted boot latency through fork elimination, integer arithmetic, and lazy
loading. This plan targets architectural simplification: removing code that
should not exist, unifying paths that diverged unnecessarily, and separating
concerns that were conflated. The two efforts are complementary --
performance renewal made the existing architecture fast; this plan makes it
simple.
