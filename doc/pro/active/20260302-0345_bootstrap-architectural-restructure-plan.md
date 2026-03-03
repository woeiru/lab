# Bootstrap Architectural Restructure

- Status: active
- Owner: es
- Started: 2026-03-03
- Updated: 2026-03-03 (phase 5 prototype implemented; validation refreshed)
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

## Session Findings (2026-03-03)

1. The canonical module loader must be owned by shared bootstrap foundations,
   not by an execution-specific path (`bin/orc`, DIC, or deployment menu), so
   all three callers can share one loaded-state registry.
2. Idempotent sourcing is a hard invariant: module source-time side effects
   must run exactly once per process, and all additional calls must short-circuit
   as cache hits.
3. The registration/verification ceremony in `bin/ini` can be removed without
   replacing it in bootstrap; module/function integrity checks should move to
   explicit validation/test contexts.
4. Interactive and deployment bootstrap need an explicit split after a small
   shared foundation, replacing behavior switches (`PERFORMANCE_MODE`,
   `LAB_BOOTSTRAP_MODE`) with explicit control flow.
5. `bin/ini` no longer needs a runtime-registration phase for bootstrap;
   removing the runtime ceremony path is safe when core module loading remains
   unchanged.
6. `cfg/core/mdc` can be removed from bootstrap sourcing without impacting
   initialization tests.
7. `setup_components` can call component functions directly while preserving
   timing and error reporting behavior, making `execute_component` unnecessary.
8. A shared `lab_source_module` entrypoint can be adopted incrementally in
   `bin/orc`, `src/dic/ops`, and `src/set/.menu` while preserving compatibility
   fallbacks for direct script execution contexts.

## Execution Plan (current)

- [DONE] Phase 5 -- Compiled bootstrap snapshot prototype

### Phase 5 -- Compiled bootstrap snapshot prototype

Prototype a cacheable compiled bootstrap payload and wire staleness detection.

Completion criterion: `./go compile` generates a valid cache that `bin/ini` can source when fresh.

Status: complete (optional phase delivered).

## Progress Checkpoint

### Done

1. Completed Phase 4 path split with explicit bootstrap profiles.
   - `bin/ini`: added `resolve_bootstrap_profile`, profile-aware
     `setup_components_with_finalization`, and exported
     `main_ini_interactive` / `main_ini_deployment`.
   - `bin/orc`: added shared `_orc_execute_component_set` and
     `setup_deployment_components`, with `setup_components` retained for
     interactive loading.
2. Added deployment-profile regression coverage.
   - `val/core/initialization/ini_test.sh`: deployment profile skips alias bootstrap.
   - `val/core/initialization/orc_test.sh`: deployment profile routes through
     deployment component set and avoids interactive-only symbols.
3. Verified deployment-facing consumers still deduplicate shared loader usage
   when booted with `LAB_BOOTSTRAP_PROFILE=deployment` and then sourcing
   `src/dic/ops` + `src/set/.menu`.
4. Updated architecture docs for the new profile-based flow:
   - `doc/arc/00-architecture-overview.md`
   - `doc/arc/01-bootstrap-and-orchestration.md`
   - `doc/arc/02-core-and-gen.md`
   - `doc/arc/03-operational-modules.md`
   - `doc/arc/07-logging-and-error-handling.md`
5. Validation results (this session):
    - Pass: `bash -n bin/ini bin/orc val/core/initialization/ini_test.sh val/core/initialization/orc_test.sh`
    - Pass: `./val/core/initialization/ini_test.sh`
    - Pass: `./val/core/initialization/orc_test.sh`
    - Pass: `./val/src/dic_framework_test.sh`
    - Pass: `bash doc/pro/check-workflow.sh`
6. Implemented compiled bootstrap cache prototype (Phase 5).
   - `./go compile` now generates:
     - `.tmp/bootstrap/ini_core.cache` (single sourceable payload with core module bodies)
     - `.tmp/bootstrap/ini_core.meta` (versioned staleness signatures for cache and source files)
   - `bin/ini` now attempts compiled cache load for core modules when cache is fresh,
     and falls back to direct module sourcing on stale/missing/invalid cache.
7. Added regression coverage for cache behavior.
   - `val/core/initialization/ini_test.sh`:
     - fresh cache path is consumed (`INI_COMPILED_BOOTSTRAP_CACHE_USED=1`)
     - stale cache metadata forces fallback (`INI_COMPILED_BOOTSTRAP_CACHE_USED=0`)
8. Validation results (phase 5 additions):
   - Pass: `bash -n go bin/ini val/core/initialization/ini_test.sh`
   - Pass: `./val/core/initialization/ini_test.sh`
   - Pass: `./val/core/initialization/orc_test.sh`
   - Pass: `./val/src/dic_framework_test.sh`
   - Pass: `./go compile`

### In-flight

1. No partial phase implementation remains.
2. No active blocker or incomplete coding task in this phase.

### Blockers

1. No hard implementation blocker.

### Next steps

1. Optionally run broader suites (`./val/run_all_tests.sh core` or full suite)
   before merge/commit.
2. Prepare a commit that includes phase 5 implementation and plan checkpoint.

### Context

1. Branch: `master` (`master...origin/master`).
2. Resume-state check found prior checkpoint context stale: working tree was clean
   at resume start (no pending phase 4 commit remained).
3. Current working tree changes for phase 5:
    - `go`
    - `bin/ini`
    - `val/core/initialization/ini_test.sh`
    - `doc/pro/active/20260302-0345_bootstrap-architectural-restructure-plan.md`
4. Current cache artifacts are generated under `.tmp/bootstrap/` by `./go compile`
   and are not tracked in git.
5. Workflow checker pass after this update: `bash doc/pro/check-workflow.sh`.

## Phase 1 Design Decision Record

Date: 2026-03-03
Design classification: required

### Constraints and invariants

1. `lab_source_module` is the only canonical module source entrypoint used by
   `bin/orc`, `src/dic/ops`, and `src/set/.menu`.
2. Loaded-state is process-local and centralized in one registry map
   (`LAB_MODULE_SOURCE_STATE`) keyed by logical module id.
3. Sourcing is idempotent: if a module is already loaded, `lab_source_module`
   returns success without re-sourcing.
4. Source-time side effects (for example core maps and constants) run once per
   process and are not relied on for re-execution behavior.
5. Bootstrap validation checks move out of hot-path initialization and into
   explicit validation/test flows.

### Unified loader interface

`lab_source_module <module_id> <module_path> [context]`

- `module_id`: stable logical id (`core:err`, `ops:gpu`, `gen:aux`, etc.).
- `module_path`: absolute path to source.
- `context`: optional caller label (`ini`, `orc`, `dic`, `menu`) for logging.
- Returns:
  - `0` module already loaded or sourced successfully.
  - `1` invalid parameters.
  - `2` source/runtime failure.
  - `127` missing/unreadable module path.
- Side effects:
  - updates `LAB_MODULE_SOURCE_STATE["$module_id"]=1` on success.
  - emits structured logs once per miss/hit event.

The registry implementation is shared bootstrap foundation code loaded before
any of the three callers. Callers no longer invoke raw `source` for module
files.

### Interactive vs deployment boundaries

Shared foundation (always loaded):

1. Path constants from `cfg/core/ric`.
2. Core modules required for logging/error/timing.
3. Unified loader registry and helper functions.
4. Environment resolution primitives (without alias/prompt setup).

Interactive path only:

1. Alias loading (`cfg/ali/*`).
2. Shell UX concerns (prompt/interactive convenience).
3. Optional lazy stub registration for ops/gen modules.

Deployment path only:

1. `src/set/.menu` section execution helpers.
2. DIC invocation path (`src/dic/ops`) and on-demand module loading.
3. Environment overlay application needed for deployment scripts.

### Dead-ceremony removal design

1. Remove `init_registered_functions`, `cache_module_verification`,
   `process_function_registration`, and related boot-time calls from `bin/ini`.
2. Remove boot-time `mdc` sourcing and `init_module_requirements` execution.
3. Keep `cfg/core/rdc` and `cfg/core/mdc` available only for validation/test
   tooling until all non-boot consumers are removed.
4. Replace `execute_component` wrapper usage with direct ordered component calls
   in `setup_components`.

### Alternatives considered

1. Keep loader state in `bin/orc` only and have DIC/menu source `bin/orc`.
   Rejected: couples non-orchestrator paths to orchestrator implementation and
   keeps ambiguous ownership.
2. Keep per-path source maps and add synchronization glue.
   Rejected: preserves duplication and creates race/ordering complexity.
3. Create a shared bootstrap foundation loader used by all paths.
   Chosen: single ownership, explicit contract, and direct support for exit
   criteria requiring one canonical loader.

### Chosen approach

Implement a shared foundation loader contract centered on
`lab_source_module`, adopt it first in `bin/orc`, then migrate
`src/dic/ops` and `src/set/.menu` to the same interface, and remove direct
module `source` calls from those paths. Phase 2 removals proceed before
registry adoption where independent, then Phase 3 wiring unifies all callers.

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
