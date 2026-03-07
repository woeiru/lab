# Alias Generator Dissolve Into lib/ops/usr Plan

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06 01:58:17
- Links: utl/ali, lib/ops/usr, cfg/ali/sta, cfg/ali/dyn, cfg/core/lzy, bin/orc, val/lib/ops/usr_test.sh, doc/ref/functions.md, doc/ref/module-dependencies.md

## Goal

Move alias-dynamic-generation behavior from `utl/ali` into `lib/ops/usr` as a
first-class `ops usr ...` capability while preserving current generated output
(`cfg/ali/dyn`) and shell-user workflow.

## Context

1. The alias generator currently lives in `utl/ali` and writes dynamic aliases
   to `cfg/ali/dyn` via `CFG_ALI_DIR`.
2. Alias loading in bootstrap is directory-based (`bin/orc` sources `cfg/ali/*`),
   so generator logic should remain executable-on-demand rather than implicitly
   sourced at shell init.
3. `cfg/ali/sta` currently defines `alias ali='$UTL_DIR/cfg-ali'`, which is now
   stale after path changes and should be replaced with a stable entrypoint.
4. If the capability becomes a public ops function, lazy-load metadata in
   `cfg/core/lzy` must remain in sync with `lib/ops/usr` exports.
5. `bin/orc` sources all files under `cfg/ali/` during bootstrap, so generator
   logic must stay out of `cfg/ali/*` and remain on-demand execution.
6. `src/dic/ops` already provides lazy-safe module invocation, so routing the
   command through `ops usr ali -x` avoids direct bootstrap sourcing risks.
7. Existing static alias wiring can point directly to the DIC entrypoint path
   (`$SRC_DIC_OPS usr ali -x`) to avoid alias-on-alias dependency.
8. `usr_ali` is now implemented in `lib/ops/usr` and generates `cfg/ali/dyn`
   with parity sections for README, directory, env, ops, and set aliases.
9. `cfg/ali/sta` now maps `ali` to `$SRC_DIC_OPS usr ali -x` so interactive
   usage routes through DIC/lazy loading.
10. `utl/ali` was removed immediately per user directive; alias generation now
    runs only through `ops usr ali -x` (or `ali`).
11. Verification passed for syntax checks, `val/lib/ops/usr_test.sh` (11/11),
    direct DIC invocation, and doc reference regeneration.

## Scope

1. Define a public user-ops function contract in `lib/ops/usr` (for example
   `usr_ali`) using existing module conventions (`--help`/`-h`, validation,
   return-code discipline, `-x` execution gating if required by policy).
2. Port generator logic from `utl/ali` into `lib/ops/usr` with behavior parity:
   README aliases, directory aliases, env aliases, ops aliases, and set aliases.
3. Replace stale convenience alias wiring in `cfg/ali/sta` so `ali` resolves to
   the new `usr`-module entrypoint (prefer a lazy-load-safe call path).
4. Update `cfg/core/lzy` if a new public `usr_*` function is added.
5. Decide deprecation strategy for `utl/ali` (remove immediately or keep a
   temporary compatibility shim that forwards to the new function).
6. Add/adjust tests around the new behavior (at minimum syntax + targeted `usr`
   module tests; ideally include focused checks for dynamic alias file generation).
7. Regenerate reference docs if exported function surface or dependencies change
   (`doc/ref/*` parity expectations).

## Triage Decision

- Why now: the alias entrypoint is currently split between moved paths and stale
  wiring, and delaying migration increases user confusion and compatibility risk.
- Meaningful alternatives for solving this: yes.
- Other code or users depending on output shape: yes.
- Design: required.
- Justification: command surface, lazy-loading behavior, and generated alias
  contracts affect both shell workflows and downstream docs/tests, so the
  integration design must be explicit before implementation.

## Execution Plan

### Phase 1 -- Finalize Design Contract

- [x] Lock the canonical command surface and argument contract for the new
  `usr` entrypoint (including help and execution gating behavior).
- [x] Document compatibility policy for legacy invocation paths and define the
  deprecation timeline for `utl/ali`.
- [x] Record interfaces, constraints, trade-offs, and chosen approach for
  migration inside this active item before any code changes.

Completion criterion: this document contains a finalized design decision record
covering interfaces, constraints, trade-offs, and the chosen migration approach.

## Phase 1 Design Decision Record

Date: 2026-03-06
Design classification: required

1. Command surface and execution contract:
   - Public function: `usr_ali` in `lib/ops/usr`.
   - Invocation path: `ops usr ali -x` (interactive shortcut: `ali`).
   - Help contract: `ops usr ali --help` and `ops usr ali -h` return `0`.
   - Execution gate: `-x` required; invalid invocation returns `1` with usage.
2. Runtime interface and side effects:
   - Inputs: explicit execute flag only (`-x`), no positional payload.
   - Required environment: `LAB_DIR`, `CFG_ALI_DIR`, `CFG_ENV_DIR`,
     `LIB_OPS_DIR`, `SRC_SET_DIR` (resolved via `cfg/core/ric` fallback).
   - Output artifact: regenerates `cfg/ali/dyn` deterministically.
   - Logging: operational status via `aux_info`/`aux_err`.
3. Compatibility policy and deprecation timeline:
   - `cfg/ali/sta` is rewired to the new ops entrypoint in this change.
   - `utl/ali` is removed in this change; no compatibility shim is retained.
   - Direct callers must use `ops usr ali -x` or the `ali` shortcut.
4. Constraints and non-negotiables:
   - Generator logic must not be moved into `cfg/ali/*` because those files are
     sourced on shell bootstrap.
   - Public function addition requires lazy-map sync in `cfg/core/lzy`.
   - Alias categories must preserve parity with current `cfg/ali/dyn` behavior
     (README, directory, env, ops, and set aliases).
5. Alternatives considered and trade-offs:
   - Immediate deletion of `utl/ali`: cleaner end state, but higher short-term
     break risk for direct-path users.
   - Keep full generator in `utl/ali`: no migration risk, but contradicts target
     architecture and keeps stale entrypoint drift.
6. Chosen approach:
   - Implement generator behavior in `lib/ops/usr` as `usr_ali` now, rewire
     `ali` alias to DIC entrypoint, and keep only a thin deprecated shim in
     `utl/ali` during transition.

### Phase 2 -- Implement Migration in Runtime Paths

- [x] Add the chosen public function to `lib/ops/usr` and port alias-generation
  behavior from `utl/ali` with parity for `cfg/ali/dyn` output categories.
- [x] Update `cfg/ali/sta` so `ali` points to the new stable entrypoint.
- [x] Sync lazy-load exports in `cfg/core/lzy` and apply the chosen
  compatibility handling for `utl/ali`.

Completion criterion: all scoped migration edits exist in working tree with no
unresolved compatibility TODO markers.

### Phase 3 -- Verify Behavior and Reference Parity

- [x] Run syntax checks on changed shell files and execute targeted `usr` tests.
- [x] Validate generated alias behavior and entrypoint compatibility in a
  controlled shell session.
- [x] Regenerate/update reference artifacts if exported function surface or
  dependency maps changed.

Completion criterion: targeted validation commands and parity checks pass with
no unresolved failures.

## Verification Plan

1. Run `bash -n` for each changed script file (`lib/ops/usr`, `cfg/ali/sta`,
   `cfg/core/lzy`, and any compatibility shim touched during migration).
2. Run `bash val/lib/ops/usr_test.sh` as the nearest module test baseline.
3. Re-source alias config in a clean shell context and confirm `ali` invokes the
   new path while `cfg/ali/dyn` remains sourceable.
4. If public symbols/dependencies changed, run `./utl/doc/run_all_doc.sh` and
   verify updated `doc/ref` outputs are consistent.
5. Run `bash wow/check-workflow.sh` before closing or moving this item.

## Exit Criteria

1. Alias generation is invoked through the selected `lib/ops/usr` command
   surface and no longer depends on `utl/ali` as the primary path.
2. `cfg/ali/sta` exposes a working `ali` shortcut mapped to the new entrypoint.
3. `cfg/ali/dyn` generation behavior matches current expected alias categories
   without regressions.
4. Required lazy-map, test, and reference updates are complete and validated.

## Risks

1. Running generator logic through ops may fail in contexts where required env
   paths are not initialized, causing confusing user-facing failures.
2. Alias-entrypoint changes in `cfg/ali/sta` can break existing muscle-memory
   commands if compatibility handling is incomplete.
3. Writing `cfg/ali/dyn` from a new path can introduce regressions in content
   ordering/naming that affect downstream sourced aliases.
4. Partial migration without lazy-map/test/doc updates can create drift between
   runtime behavior and project references.

## What Changed

1. Added dynamic alias generation to `lib/ops/usr` via `usr_ali` plus internal
   helpers for README, directory, env, ops, and set alias sections.
2. Rewired shortcut alias to DIC path in `cfg/ali/sta` (`alias ali='$SRC_DIC_OPS usr ali -x'`).
3. Updated lazy-load export map in `cfg/core/lzy` to include `usr_ali`.
4. Removed utility-script paths (`utl/ali` and legacy `utl/cfg/ali`) so alias
   generation is no longer hosted under `utl/`.
5. Added targeted test coverage in `val/lib/ops/usr_test.sh` and regenerated
   `doc/ref/*` artifacts after public-function/dependency changes.

## What Was Verified

1. `bash -n lib/ops/usr && bash -n cfg/ali/sta && bash -n cfg/core/lzy && bash -n val/lib/ops/usr_test.sh` -> pass.
2. `bash val/lib/ops/usr_test.sh` -> pass (`11` passed, `0` failed).
3. `source cfg/core/ric && "$SRC_DIC_OPS" usr ali -x` -> pass; `cfg/ali/dyn` regenerated successfully.
4. `./utl/doc/run_all_doc.sh` -> pass (`7/7` generators successful).
5. `bash wow/check-workflow.sh` -> pass.

## What Remains

No follow-up items are required for this scope.
