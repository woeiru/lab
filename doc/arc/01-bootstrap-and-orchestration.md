# 01 - Bootstrap and Orchestration Architecture (Current State)

This document describes how shell integration, bootstrap, and component orchestration currently work in the Lab Environment Management System.

## 1. `./go` Entrypoint (Shell Integration)

`./go` is the user-facing CLI entrypoint for shell integration lifecycle management. It does not bootstrap modules itself; it writes and removes managed blocks in a shell startup file, then `bin/ini` performs runtime loading when sourced.

### `init` / `setup` behavior
When a user runs `./go init` (or `./go setup`), the script:
1. Validates shell compatibility (Bash 4+ or Zsh 5+).
2. Resolves target user and home directory.
3. Chooses shell config file in this order:
   - first existing `~/.zshrc`
   - else existing `~/.bashrc`
   - else default `~/.bashrc` (created if needed)
4. Builds `INJECT_CONTENT` for auto-load: `. <lab_root>/bin/ini`.
5. Saves resolved settings to `.tmp/go_settings`.
6. Injects a persistent helper block (`lab`, `lab-on`, `lab-off`) under helper markers.

`lab` is the current-shell activation path (`source <lab_root>/bin/ini`).

### Runtime command semantics
- `./go on`: loads `.tmp/go_settings`, then injects the auto-load managed block.
- `./go off`: loads `.tmp/go_settings`, then removes only the auto-load managed block.
- `./go purge`: loads `.tmp/go_settings`, removes auto-load block (if present), then removes helper block.
- `./go status`: checks `~/.lab_initialized`, checks `.tmp/go_settings`, and reports whether shell integration appears active.

## 2. Initialization Controller (`bin/ini`)

`bin/ini` is the bootstrap controller sourced into the current shell. It uses a re-source guard (`_INI_LOADED`) and returns early on repeat loads in the same shell.

### End-to-end sequence

```mermaid
sequenceDiagram
    autonumber
    participant U as User Shell
    participant G as ./go
    participant RC as ~/.bashrc or ~/.zshrc
    participant I as bin/ini
    participant O as bin/orc
    participant C as cfg/core/*
    participant L as lib/core/* + lib/*

    U->>G: ./go init
    G->>RC: Inject helper block (lab/lab-on/lab-off)
    G->>G: Save .tmp/go_settings
    Note over G,RC: Auto-load block is controlled later by ./go on/off

    U->>G: ./go on
    G->>RC: Inject auto-load block (. <lab_root>/bin/ini)

    U->>RC: Start new shell
    RC->>I: source bin/ini
    I->>I: guard: [[ -n _INI_LOADED ]] && return 0
    I->>C: source cfg/core/ric
    I->>C: source cfg/core/rdc
    I->>C: source cfg/core/mdc
    I->>L: source lib/core/ver
    I->>I: main_ini()
    I->>I: init_logging_system()
    I->>I: verify_core_modules_loaded()
    I->>I: init_module_system()
    I->>L: load_modules(): col -> err -> lo1 -> tme
    I->>I: init_timer_system()
    I->>I: source_component_orchestrator()
    I->>O: source bin/orc
    I->>I: init_runtime_system_with_timing()
    I->>I: init_runtime_system()
    I->>I: process_runtime_config()
    I->>I: init_registered_functions()
    I->>I: cache_module_verification()
    I->>I: process_function_registration()
    I->>I: register_single_function()
    I->>I: setup_components_with_finalization()
    I->>O: setup_components()
    O->>O: execute_component(source_cfg_ecc)
    O->>O: execute_component(source_cfg_ali)
    O->>O: execute_component(source_lib_ops)
    O->>O: execute_component(source_lib_gen)
    O->>O: execute_component(source_cfg_env)
    O->>O: execute_component(source_src_aux)
    O-->>I: return from setup_components()
    I->>I: finalize RC_SOURCED (set 1 if missing)
    I->>U: export RC_SOURCED=1 on success

    alt initialization fails
        I->>I: setup_minimal_environment
        I->>U: minimal PATH and PS1 fallback
    end
```

### Conceptual flow (quick view)

```mermaid
flowchart LR
    A[./go init once] --> B[helper block injected]
    B --> C[./go on optional]
    C --> D[new shell starts]
    D --> E[source bin/ini]
    E --> F[load core cfg + core libs]
    F --> G[source bin/orc]
    G --> H[load cfg/ali + lib/ops + lib/gen + cfg/env + optional source_src_aux]
    H --> I[RC_SOURCED=1]
    E --> J[failure path]
    J --> K[minimal PATH + PS1]
```

### Maintenance rule

If bootstrap call order, function names, or component order change in `go`, `bin/ini`, or `bin/orc`, update this document in the same PR.

### Bootstrap sequence (actual call order)
1. Captures start timestamp (`_INI_START_NS`).
2. Sources core config files:
   - `cfg/core/ric`
   - `cfg/core/rdc`
   - `cfg/core/mdc`
3. Sources verification module: `lib/core/ver`.
4. Runs `main_ini`, which performs:
   - `init_module_system` (essential checks, directory validation, core module loading)
   - timer system initialization (`tme_init_timer`, `tme_start_timer` when available)
   - `source_component_orchestrator` (sources `bin/orc`)
   - `init_runtime_system_with_timing` (runtime config processing + registered function loading)
   - `setup_components_with_finalization` (calls orchestrator `setup_components`, finalizes `RC_SOURCED`)

### Core module loading in `init_module_system`
Modules are loaded in this fixed order:
1. `lib/core/col`
2. `lib/core/err`
3. `lib/core/lo1`
4. `lib/core/tme`

### Failure behavior
If initialization fails, `bin/ini` runs `setup_minimal_environment`:
- appends a base fallback segment to `PATH`
- sets a minimal prompt (`PS1="(minimal)[\u@\h \W]\$ "`)
- ensures `${BASE_DIR}/.log` and `${BASE_DIR}/.tmp` exist

### Runtime/performance toggles
- `PERFORMANCE_MODE=1` during the early critical section of `main_ini`.
- `PERFORMANCE_MODE=0` before component setup.
- Timing report is force-enabled at the end when timing functions are available.

## 3. Component Orchestrator (`bin/orc`)

`bin/orc` defines `setup_components` and component source helpers. It is sourced by `bin/ini` and does not auto-execute component setup on load.

### Shell behavior and trap handling
- In non-interactive contexts it enables `set -eo pipefail`; in interactive contexts it keeps `pipefail` only.
- It installs `trap cleanup EXIT INT TERM`.
- `cleanup` removes `TEMP_ERROR_FILE` if present.

### Execution wrapper
`execute_component` provides:
- function existence checks
- timer start/end wrapping
- error routing (`err_handler`)
- required vs optional behavior

Note: in the current `components` array, every component is configured as optional (`COMPONENT_OPTIONAL`).

### Component execution order in `setup_components`
1. `source_cfg_ecc` (`cfg/core/ecc`)
2. `source_cfg_ali` (`cfg/ali/*`)
3. `source_lib_ops` (`lib/ops/*`, filtered to skip doc/hidden files)
4. `source_lib_gen` (`lib/gen/*`, then optional password-init hook)
5. `source_cfg_env` (site required; env/node overrides optional)
6. `source_src_aux` (`SRC_AUX_DIR`, default `${LAB_DIR}/src/aux`, optional)

On success, `RC_SOURCED=1` is exported.

## 4. Managed Shell Blocks

`./go` writes two distinct managed blocks to the selected shell config file:

```bash
# helper block (persistent unless purge)
lab()     { source "<lab_root>/bin/ini"; }
lab-on()  { "<lab_root>/go" on; }
lab-off() { "<lab_root>/go" off; }

# auto-load block (toggled by on/off)
. <lab_root>/bin/ini
```

`off` removes the auto-load block only; `purge` removes both blocks.

## 5. State and Side Effects Relevant to Refactoring

- `main_ini` is exported with `export -f main_ini`, and many bootstrap symbols remain in the interactive shell after sourcing.
- Orchestrator and bootstrap flows are tightly coupled to globals seeded by `cfg/core/ric`.
- `bin/orc` changes shell error behavior depending on interactivity, which can affect callers that source it inside larger scripts.
- `TEMP_ERROR_FILE` is a transient global variable used for cleanup, not a stable exported runtime contract.
