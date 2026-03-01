# 01 - Bootstrap and Orchestration Architecture (Current State)

This document provides an in-depth analysis of the current bootstrapping sequence and orchestration mechanisms that load the Lab Environment Management System into a user's interactive shell session.

## 1. The `./go` Entrypoint (Shell Integration)

The `./go` script is the primary CLI entrypoint responsible for managing shell integration. It does not load the lab environment into its own process; rather, it manages the injection of helpers into the user's `.bashrc` or `.zshrc`.

### Shell Injection Mechanics
When a user runs `./go init` (or `setup`), the script:
1. Validates shell compatibility (Bash 4+, Zsh 5+).
2. Identifies the target user and shell config file (defaulting to `~/.bashrc`).
3. Saves settings state to `.tmp/go_settings`.
4. Injects a permanent block of helper functions (`lab`, `lab-on`, `lab-off`) wrapped in `# === BEGIN MANAGED BLOCK: Lab Helper Functions [source: lab] ===`.
5. `lab` acts as the trigger to source `bin/ini` into the *current* shell session.

### Commands
- `./go on` / `./go off`: Dynamically adds/removes the auto-load source command (`. /path/to/bin/ini`) from the shell config file.
- `./go status`: Reads `.tmp/go_settings` and `~/.lab_initialized` to report current state.
- `./go purge`: Completely strips all managed blocks from the shell profile.

## 2. The Initialization Controller (`bin/ini`)

When `lab` is invoked (or the shell auto-loads), `bin/ini` takes over. It acts as the primary bootstrap controller, heavily optimized with caching (e.g., `file_existence_cache`, `dir_creation_cache`) and a performance mode to ensure sub-second load times.

### Phase 1: Foundation and Early Configs
1. **Timing Check:** Captures `_INI_START_NS` immediately.
2. **Core Config Sourcing:** Sources `cfg/core/ric` (Runtime Initialization Constants), `cfg/core/rdc` (Runtime Dependencies), and `cfg/core/mdc` (Module Dependencies).
3. **Verification Loader:** Sources `lib/core/ver` to expose critical path/module validation functions.

### Phase 2: Core Module System (`init_module_system`)
1. Executes `ver_essential_check` to ensure the environment is sane.
2. Validates essential directories (`lib/`, `cfg/`).
3. Discovers and securely loads foundational modules strictly in this order:
   - `lib/core/col` (Colors)
   - `lib/core/err` (Error handling)
   - `lib/core/lo1` (Logging)
   - `lib/core/tme` (Timing)

### Phase 3: Runtime System & Dependency Injection (`init_runtime_system`)
1. **Timer Activation:** Initializes the performance tracking framework.
2. **Dynamic Registration:** Evaluates `REGISTERED_FUNCTIONS` (loaded from `rdc`/`mdc`). 
3. **Dependency Resolution:** For every registered function, it checks `FUNCTION_DEPENDENCIES` and dynamically sources the required component path using cached module checks to accelerate loading.

### Phase 4: Orchestration Delegation
Sources `bin/orc` and triggers `setup_components_with_finalization`. If the load fails at any critical step, `bin/ini` falls back to `setup_minimal_environment`, restoring a safe standard `PATH` and basic `PS1`.

## 3. The Component Orchestrator (`bin/orc`)

The orchestrator manages the bulk loading of operational and utility modules. It implements a strict `execute_component` wrapper that handles timers, errors, and distinguishes between required vs. optional components.

### Sourcing Execution Order
The orchestrator processes directories and files in a very specific, hardcoded sequence:
1. **`source_cfg_ecc`**: Loads Environment Controller Configuration (`cfg/core/ecc`).
2. **`source_cfg_ali`**: Loads Alias Configuration files (`cfg/ali/*`).
3. **`source_lib_ops`**: Loads Operational Functions (`lib/ops/*`). *Note: Excludes `.md`, `.txt`, `.spec` and hidden files via strict filtering.*
4. **`source_lib_gen`**: Loads General Utility Functions (`lib/gen/*`), and optionally triggers `init_password_management_auto`.
5. **`source_cfg_env`**: Applies environmental hierarchy:
   - `SITE_CONFIG_FILE` (Required)
   - `ENV_OVERRIDE_FILE` (Optional)
   - `NODE_OVERRIDE_FILE` (Optional)
6. **`source_src_aux`**: Loads Auxiliary Framework files (`src/aux/*`).

Upon successful completion, it exports `RC_SOURCED=1`.

## 4. State Changes & Shell Injections

**Injected into `.bashrc` / `.zshrc`:**
```bash
# Helper Functions (Permanent)
lab()     { source "/home/es/lab/bin/ini"; }
lab-on()  { "/home/es/lab/go" on; }
lab-off() { "/home/es/lab/go" off; }

# Auto-load (Toggled via lab-on/lab-off)
. /home/es/lab/bin/ini
```

**Exported Environment Variables (post-initialization):**
- `RC_SOURCED`: Set to `1` when orchestration completes successfully.
- `PERFORMANCE_MODE`: Briefly exported as `1` during `main_ini` and toggled to `0` before component setup.
- `TEMP_ERROR_FILE`: Temporarily exported and cleaned up via shell `trap` during orchestrator execution.

## 5. Known Constraints & Vulnerabilities (Analysis for Refactoring)
- **State Leakage:** `bin/ini` exports functions (e.g., `main_ini`) into the global user shell.
- **Tight Coupling:** The orchestrator relies on variables heavily pre-defined in `ric` and expects strict directory structures without much dynamic fallback.
- **Error Trapping:** `bin/orc` manipulates `set -e` based on interactivity (`if [[ ! -t 0 || "${-}" != *i* ]]`), which can cause unintended side-effects if sourced deeply inside another automated script.
