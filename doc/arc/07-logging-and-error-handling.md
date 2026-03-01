# 07 - Logging and Error Handling Architecture (Current State)

Logging and error handling are split across core bootstrap modules and runtime utilities: `lib/core/lo1` handles hierarchical bootstrap/runtime console/file logs, `lib/core/err` captures and reports error records, `lib/core/tme` tracks timing/performance events, and `lib/gen/aux` provides structured operational logs (`info/warn/error/audit/business/debug`) used by DIC and ops modules.

## 1. Responsibilities and Boundaries

| Area | Primary files | Responsibility boundary |
| --- | --- | --- |
| Bootstrap/orchestrator logs | `lib/core/lo1`, `bin/ini`, `bin/orc` | Initialization and component-loading trace logs (`lo1.log`, `ini.log`). |
| Error capture/reporting | `lib/core/err` | Error codes/maps, error records, trap handler, error report output. |
| Timing/performance logs | `lib/core/tme` | Start/end timers, duration accounting, timing report (`tme.log`). |
| Operational structured logs | `lib/gen/aux` | Multi-format operational/debug logging (`aux.log`, `aux.json`, `aux.csv`). |
| Global verbosity controls | `cfg/core/ric` | Master and module-level terminal output toggles. |

## 2. Runtime/Load Sequence

### Actual call/load order

1. `cfg/core/ric` defines core paths and verbosity switches (`MASTER_TERMINAL_VERBOSITY`, `LO1_LOG_TERMINAL_VERBOSITY`, `ERR_TERMINAL_VERBOSITY`, `TME_TERMINAL_VERBOSITY`, and nested TME toggles).
2. `bin/ini` forces `LOG_DEBUG_ENABLED=0` at the start of bootstrap (saving the original value) and exports `LAB_BOOTSTRAP_MODE=1`. This suppresses `lo1_log` stack-trace dumps and `ver_log` non-error writes during boot, significantly reducing file I/O on the hot path. Both are restored/cleared after orchestrator sourcing completes or on failure.
3. `bin/ini` initializes log files (`INI_LOG_FILE`, `ERROR_LOG`) in `init_logging_system`.
4. `bin/ini` loads `lib/core/err`, `lib/core/lo1`, and `lib/core/tme` via `load_modules`.
5. `tme_init_timer` initializes timing state and `tme.log`; `bin/ini` wraps major phases with timer calls. `tme` uses integer nanosecond arithmetic (`$(date +%s%N)` captured once, then `$(( ))` bash arithmetic) instead of `echo ... | bc` pipe forks for duration calculation.
6. `bin/orc` uses `lo1_log` for component progress and `execute_component` routes failures to `err_handler`.
7. After `lib/gen/aux` is sourced (either eagerly or on first lazy-load call), runtime callers (for example `src/dic/ops` and `lib/ops/*` functions) can emit structured logs via `aux_log`/`aux_dbg` and wrappers (`aux_info`, `aux_warn`, `aux_err`, `aux_audit`, `aux_business`).

### End-to-end sequence

```mermaid
sequenceDiagram
    autonumber
    participant I as bin/ini
    participant E as lib/core/err
    participant L as lib/core/lo1
    participant T as lib/core/tme
    participant O as bin/orc
    participant R as Runtime caller (DIC/ops)
    participant A as lib/gen/aux

    I->>I: init_logging_system()
    I->>E: source err
    I->>L: source lo1
    I->>T: source tme
    I->>T: tme_init_timer()
    I->>O: source bin/orc

    O->>L: lo1_log("lvl", component status)
    O->>T: tme_start_timer()/tme_end_timer()

    alt component failure
        O->>E: err_handler(line, code)
        O->>E: err_print_report()
    end

    R->>A: aux_info/aux_warn/aux_err/aux_dbg (runtime paths)
    A-->>A: write aux.log/aux.json/aux.csv by format
```

### Conceptual flow (quick view)

```mermaid
flowchart LR
    A[cfg/core/ric verbosity + paths] --> B[core logging/error/timing loaded]
    B --> C[bootstrap + orchestrator tracing]
    C --> D[component success/failure records]
    D --> E[aux structured operational logs]
    E --> F[persistent log files + optional terminal output]
```

## 3. State and Side Effects

- `err` initializes global associative arrays (`ERROR_CODES`, `ERROR_*`) and writes to `ERROR_LOG`.
- `lo1` initializes/uses logger state files (`LOG_STATE_FILE`, depth cache in `TMP_DIR`) and appends to `LOG_FILE`. During bootstrap, `LOG_DEBUG_ENABLED=0` suppresses stack-trace dumps; timestamps use `printf '%(%T)T' -1` (Bash builtin) instead of `$(date ...)` forks. Direct file reads/writes replace `cat` usage on hot paths.
- `tme` initializes timer state maps/files and writes detailed entries to `TME_LOG_FILE`. Duration calculation uses integer nanosecond arithmetic (`$(( ))`) instead of `echo ... | bc` pipe forks. `LOG_STATE_FILE` toggling (previously `cat`/`echo` per timer event) has been removed from timing start/end/cleanup paths.
- `ver_log` short-circuits non-error log writes during `LAB_BOOTSTRAP_MODE=1`, skipping timestamp generation and file I/O. Uses cached `VER_LOG_DIR_READY` flag and parameter expansion instead of `dirname` subprocess calls.
- `aux_log`/`aux_dbg` choose output format by `AUX_LOG_FORMAT` and write to `LOG_DIR/aux.log|aux.json|aux.csv` when writable.
- `err_enable_trap` and orchestrator wrappers can install/trigger trap-based error handling behavior.

## 4. Failure and Fallback Behavior

- If `init_logging_system` cannot initialize required paths/files, `main_ini` fails early.
- `lo1` falls back to default logger state when state files are missing/empty and can run with reduced behavior.
- `tme_init_timer` attempts best-effort setup; missing optional state files emit warnings under verbosity gates.
- `err_handler` records command/file/line context and returns non-zero error code to caller path.
- `aux_dbg` only emits terminal debug output when both `AUX_DEBUG_ENABLED=1` and `MASTER_TERMINAL_VERBOSITY=on`; file logging remains available when `LOG_DIR` is writable.

## 5. Constraints and Refactor Notes

- Core modules are tightly coupled to path and verbosity globals from `cfg/core/ric`; changing names/defaults impacts all logging/error behavior.
- `bin/orc` component wrappers assume `err_handler`, `lo1_log`, and `tme_*` are available; load-order drift can break diagnostics.
- Verbosity is hierarchical in practice: `MASTER_TERMINAL_VERBOSITY` gates module-level terminal outputs.
- `aux` logging format changes (`human/json/csv/kv`) affect both terminal output and downstream log consumers/parsers.
- Return-code semantics are defined in specs (`lib/.spec`, `lib/ops/.spec`), but enforcement is distributed per function/module.
- Boot-phase log suppression (`LOG_DEBUG_ENABLED=0`, `ver_log` gating via `LAB_BOOTSTRAP_MODE`) means boot diagnostics in `lo1.log` and `ver.log` are reduced compared to runtime. If boot debugging is needed, set `LOG_DEBUG_ENABLED=1` or `VER_BOOTSTRAP_LOGGING=1` before sourcing `bin/ini`.

## Maintenance Note

Update this document in the same PR when verbosity contracts in `cfg/core/ric`, logging/error APIs in `lib/core/{err,lo1,tme}`, or structured logging behavior in `lib/gen/aux` changes.
