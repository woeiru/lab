# 02 - Core and General Utility Architecture (Current State)

This area covers the runtime foundation loaded before or alongside operations: `lib/core/*` provides bootstrap-safe primitives (`col`, `ver`, `err`, `lo1`, `tme`), and `lib/gen/*` provides cross-cutting utilities (`ana`, `aux`, `env`, `inf`, `sec`) consumed by ops modules, DIC helpers, and documentation tooling.

## 1. Responsibilities and Boundaries

| Layer | Primary files | Responsibility boundary |
| --- | --- | --- |
| Core primitives | `lib/core/col`, `lib/core/ver`, `lib/core/err`, `lib/core/lo1`, `lib/core/tme` | Provide color, verification, error, logging, and timing capabilities used during bootstrap and runtime. |
| General utilities | `lib/gen/ana`, `lib/gen/aux`, `lib/gen/env`, `lib/gen/inf`, `lib/gen/sec` | Provide analysis, help/validation/log wrappers, env switching helpers, infra variable builders, and password management helpers. |
| Bootstrap loader contract | `bin/ini`, `bin/orc` | Defines when core and gen modules are sourced and how failures are handled. |

## 2. Runtime/Load Sequence

### Actual call/load order

1. `bin/ini` sources `cfg/core/ric`, `cfg/core/rdc`, `cfg/core/mdc`, then `lib/core/ver`.
2. `main_ini` -> `init_module_system` -> `load_modules` sources core modules in fixed order: `lib/core/col` -> `lib/core/err` -> `lib/core/lo1` -> `lib/core/tme`.
3. `main_ini` sources `bin/orc` and calls `setup_components`.
4. `setup_components` executes `source_lib_gen` (after `source_lib_ops` in current orchestrator order).
5. When `LAB_GEN_LAZY_LOAD=1` (the default), `source_lib_gen` registers lightweight stub functions for each gen module from `cfg/core/lzy` (or via fallback file scanning) instead of eagerly sourcing them. Stubs forward to `_orc_lazy_dispatch`, which sources the real module on first call. When lazy loading is disabled, `source_directory "$LIB_GEN_DIR" "*"` sources non-hidden files in glob order (currently `ana`, `aux`, `env`, `inf`, `sec`).
6. `source_lib_gen` runs `init_password_management_if_needed` only when lazy loading is disabled; when lazy gen loading is active, password management initialization is deferred until first use.

### End-to-end sequence

```mermaid
sequenceDiagram
    autonumber
    participant I as bin/ini
    participant C as lib/core/*
    participant O as bin/orc
    participant G as lib/gen/*
    participant R as Runtime Callers

    I->>C: source lib/core/ver
    I->>I: load_modules()
    I->>C: source col
    I->>C: source err
    I->>C: source lo1
    I->>C: source tme
    I->>O: source bin/orc
    I->>O: setup_components()

    alt lazy gen loading enabled (default)
        O->>O: source_lib_gen()
        O->>O: _orc_lazy_register_module_stubs() per gen module
        Note over O: stubs forward to _orc_lazy_dispatch
        O->>O: password management init deferred
        R->>O: first call to any gen function
        O->>G: _orc_lazy_dispatch() sources real module
        G-->>R: function result (stubs replaced by real defs)
    else lazy gen loading disabled
        O->>G: source_lib_gen()
        O->>G: source_directory(LIB_GEN_DIR, "*")
        O->>O: init_password_management_if_needed()
        G-->>R: aux_*, ana_*, env_*, inf_*, sec_* available
    end

    alt gen loading fails
        O->>O: execute_component marks optional failure
        O-->>I: continue component sequence
    end
```

### Conceptual flow (quick view)

```mermaid
flowchart LR
    A[bin/ini bootstrap] --> B[load core modules]
    B --> C[source bin/orc]
    C --> D[load lib/ops]
    D --> E{lazy gen?}
    E -->|yes default| F[register gen stubs]
    E -->|no| G[eagerly source lib/gen]
    F --> H[ops/dic/tests use shared helpers on first call]
    G --> H
```

## 3. State and Side Effects

- `col` defines color constants using ANSI-C quoting (`$'\033[...]'` literals) instead of subshell `$(printf ...)` assignments. Exports color constants and helpers (`col_apply`, `col_get_semantic`) used by downstream logging layers.
- `err` initializes global error maps/arrays (`ERROR_CODES`, `ERROR_ORDER`, etc.) and defines `command_not_found_handle` in the shell session.
- `lo1` initializes logger state files (`LOG_STATE_FILE`, depth cache in `TMP_DIR`) and appends to `LOG_FILE`. During bootstrap (`LAB_BOOTSTRAP_MODE=1`), stack-trace dumps are suppressed via `LOG_DEBUG_ENABLED=0`. Hot-path timestamp generation uses `printf '%(%T)T' -1` (Bash builtin) instead of `$(date ...)` forks.
- `tme` initializes timing state (`TME_*` associative arrays) and writes to `TME_LOG_FILE`. Duration calculation uses integer nanosecond arithmetic (`$(( ))`) instead of `echo ... | bc` pipe forks. `LOG_STATE_FILE` toggling (`cat`/`echo` per timer event) has been removed from timing start/end/cleanup paths.
- `ver` gates `ver_verify_module` deep checks during `LAB_BOOTSTRAP_MODE=1` (modules were just sourced). `ver_log` suppresses non-error log writes during bootstrap, skipping timestamp generation and file I/O. Uses cached `VER_LOG_DIR_READY` to avoid repeated `dirname` subprocess calls.
- `aux` provides runtime logging and writes structured outputs (`aux.log`, `aux.json`, `aux.csv`) in `LOG_DIR` depending on `AUX_LOG_FORMAT`.
- `env` mutates `cfg/core/ecc` via `update_ecc` (`sed -i` plus timestamped backup) when switching site/env/node.
- `inf` and `sec` create/export runtime variables and files (`CT_*`, `VM_*`, password files), including permission changes (`chmod 700/600`) in password directories.

## 4. Failure and Fallback Behavior

- Core module sourcing in `bin/ini` is fail-sensitive during bootstrap; a critical failure can end in `setup_minimal_environment`.
- `load_modules` returns success if at least one module loads (`module_loaded > 0`), so partial core load is possible and must be considered.
- `source_lib_gen` failure is non-fatal in current orchestrator flow because all components are currently marked optional in `bin/orc`.
- `aux_cmd` returns `127` for missing commands and preserves command exit codes for runtime failures.
- `env_validate` reports missing base config as error but treats env/node override files as optional.
- `sec_get_password_directory` falls back across multiple locations and eventually to `$HOME/.lab_passwords`.

## 5. Constraints and Refactor Notes

- `lib/core/err`, `lib/core/lo1`, and `lib/core/tme` call `ver_verify_module` at source time (skipped during `LAB_BOOTSTRAP_MODE=1`), so `lib/core/ver` must be available first.
- Bootstrap order in `bin/ini` (`col` -> `err` -> `lo1` -> `tme`) is an implicit contract for color/log/error integration.
- When lazy gen loading is active (default), `lib/gen` modules are stub-loaded and only sourced on first call. Ops modules must not rely on gen helpers being available at source time unless explicitly sourced or loaded earlier in the chain.
- Some utility modules are stateful (for example `env` editing `cfg/core/ecc`, `inf` exporting large variable sets), so they are not pure read-only helpers.
- DIC runtime (`src/dic/ops`) additionally sources `lib/gen/ana` and `lib/gen/aux`; duplication of sourcing paths is expected and should stay idempotent. When lazy-loaded, the first DIC call to a gen function triggers the real module load transparently.

## Maintenance Note

Update this document in the same PR when any of these change: core module load order in `bin/ini`, `lib/gen` loading semantics in `bin/orc`, exported contracts in `lib/core/*` or `lib/gen/*`, or side-effect behavior (log files, state files, environment mutation, credential storage).
