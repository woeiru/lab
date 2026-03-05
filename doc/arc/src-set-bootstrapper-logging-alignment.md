# src/set Bootstrapper and Logging Alignment Design

## 1. Objective

Define a stable execution contract for `src/set/.menu` and `src/set/*` runbooks
that aligns with the current bootstrapper (`bin/ini` + `bin/orc`) and the shared
logging architecture (`lib/core/log`, `lib/gen/aux`) while preserving intentional
interactive menu output.

## 2. Scope and Inputs

Design scope covers:

- `src/set/.menu`
- `src/set/h1`, `src/set/c1`, `src/set/c2`, `src/set/c3`, `src/set/t1`, `src/set/t2`

Primary references:

- `bin/ini`
- `bin/orc`
- `lib/core/log`
- `lib/gen/aux`
- `doc/arc/07-logging-and-error-handling.md`
- `lib/ops/.spec`

Out of scope for this design phase:

- Changes to operational behavior of `lib/ops/*` functions.
- Broad DIC redesign in `src/dic/*`.

## 3. Current-State Findings

1. `src/set/*` runbooks emit plain debug output during startup (`echo "[DEBUG] Sourcing ..."`), which bypasses structured logging controls.
2. `src/set/.menu` performs eager top-level auto-sourcing of env, ops, and local set files when `LAB_MENU_AUTO_SOURCE=1`, creating side effects at source-time instead of execution-time.
3. `src/set/*` runbooks invoke `clean_exit`, but only `err_clean_exit` is defined in core modules; this creates an interface mismatch risk.
4. `src/set/.menu` mixes two concerns in one channel:
   - intended interactive UI/menu rendering,
   - operational diagnostics and warnings.
5. Entry behavior is inconsistent across runbooks (`setup_source` called only in some files), so bootstrap/setup is not uniformly explicit.

## 4. Constraints

1. Preserve user-facing interactive menu formatting in `-i` mode.
2. Keep compatibility with existing `setup_main`, `setup_interactive_mode`, and
   `setup_executing_mode` usage in current runbooks.
3. Align non-UI operational messages with structured logging expectations using
   `aux_*` and shared level gating.
4. Respect return-code conventions:
   - `0` success
   - `1` usage/validation
   - `2` runtime/dependency failure
   - `127` missing required command/file
5. Avoid introducing bootstrap loops or hard dependencies that break when
   `bin/ini` has not been sourced yet.

## 5. Target Interface Contracts

### 5.1 Bootstrap Contract (Runbook Startup)

Each `src/set/*` runbook uses the same startup pattern:

1. Resolve `DIR_SH`, `FILE_SH`, `BASE_SH`.
2. Source `src/set/.menu`.
3. Source `src/dic/ops`.
4. Run explicit setup function from `.menu` (idempotent).
5. Dispatch through `setup_main "$@"`.

Design decision:

- Move from implicit source-time setup to explicit, idempotent setup entry.
- Keep compatibility switch for legacy auto-source behavior, but default runtime
  behavior should be explicit setup orchestration.

### 5.2 Logging Contract (UI vs Operational Logs)

Two output channels are explicitly separated:

1. Interactive UI channel (`printf` menu boxes, prompts, section listings)
   - allowed for user-facing display in `-i` flow.
2. Operational diagnostics channel
   - uses `aux_info`, `aux_warn`, `aux_err`, `aux_dbg` with key-value context.

Design decision:

- Keep menu rendering as formatted terminal UI.
- Route startup, sourcing, warning, and execution diagnostics to structured
  logging helpers.

### 5.3 Entrypoint/Exit Contract

Runbooks support:

- `-i [display] [-s section]`
- `-x <section>`
- `--help` / `-h`

Runbooks return (or exit) using consistent codes and a defined exit helper that
maps to `err_clean_exit` when available, with safe fallback behavior if the
error module is unavailable.

## 6. Alternatives and Trade-offs

### Alternative A: Minimal patch only (replace debug echoes)

Pros:

- Lowest immediate change risk.

Cons:

- Leaves startup side effects and `clean_exit` mismatch unresolved.
- Does not establish a durable contract.

### Alternative B: Full rewrite of `.menu` and runbooks now

Pros:

- Cleanest end-state quickly.

Cons:

- High breakage risk for shared `.menu` behavior.
- Hard to validate safely in one pass.

### Chosen approach: Adapter-first staged alignment

1. First align `.menu` interfaces and logging boundaries.
2. Then migrate runbooks to the standardized startup/exit contract.
3. Then lock behavior with tests and docs.

Rationale:

- Reduces blast radius while converging on the target architecture.
- Matches planned sequencing: shared `.menu` first, runbooks second.

## 7. Migration Plan (Implementation Phases)

### Phase 2 - `.menu` alignment

- Introduce explicit idempotent setup entry in `.menu`.
- Add/standardize helpers for structured diagnostic logging.
- Remove direct debug prints from `.menu` operational paths.
- Preserve interactive rendering output for `-i` UX.

### Phase 3 - runbook alignment

- Apply unified startup pattern to `h1`, `c1`, `c2`, `c3`, `t1`, `t2`.
- Replace startup debug echoes with structured diagnostics.
- Replace or shim `clean_exit` to the defined exit contract.
- Normalize argument handling and usage/error exits across runbooks.

### Phase 4 - validation and docs

- Add/update tests for:
  - mode dispatch (`-i`, `-x`, help, bad args),
  - setup behavior and return codes,
  - logging behavior under default and debug verbosity.
- Update docs to reflect finalized runtime and logging contracts.

## 8. Verification Strategy

1. Syntax check changed files with `bash -n`.
2. Run nearest relevant tests for `src/set` and logging/dispatch paths.
3. Validate no legacy startup debug echoes remain in `src/set/*`.
4. Verify intentional menu UI output still renders in interactive mode.

## 9. Decision Summary

Adopt adapter-first staged alignment with explicit startup, strict separation of
interactive UI output from structured operational logging, and standardized
entry/exit contracts across all `src/set` runbooks.
