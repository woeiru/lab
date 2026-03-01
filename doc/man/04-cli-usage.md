# 04 - CLI Usage and the DIC

The framework's CLI is fundamentally different from typical Bash scripts. Instead of writing custom shell scripts with `getopts` blocks and explicit argument handling, the system relies on a Dependency Injection Container (DIC) located at `src/dic/ops` (available via the `ops` command).

## Dual Interface

The framework provides two primary ways to interact with its modules (`lib/ops/`):

1. **Direct Bash Functions (Direct Mode):** You call the raw function directly in your shell (e.g., `gpu_ptd`).
2. **The DIC CLI (`ops` command):** You use the DIC to resolve parameters automatically based on the current configuration environment.

### Direct Execution

Operational functions in `lib/ops/` expose parameter-driven Bash interfaces. They expect arguments to be passed exactly as their signature defines.

```bash
# Explicit call style (current signature)
# Usage: gpu_ptd [-d driver] [gpu_id] [hostname] [config_file] [pci0_id] [pci1_id]
gpu_ptd -d lookup "01:00.0" "h1" "/path/to/config" "0000:01:00.0" "0000:01:00.1"
```

This is tedious for daily operations, and you must manually retrieve the values from your configuration.

### DIC (`ops`) Execution

The `ops` command is the primary interface to these functions. It analyzes the target function signature, scans `cfg/env/` for matching variables (including hostname-prefixed keys), and injects resolved values into the function call.

```bash
# Using the DIC to execute gpu_ptd
ops gpu ptd -j
```

## DIC Execution Modes

The DIC operates in three distinct modes:

### 1. Hybrid Mode (Default)

If you run `ops gpu ptd` without mode flags, the DIC accepts explicit arguments and supplements missing values when they can be resolved safely.

### 2. Injection Mode (`-j`)

This is the most powerful and commonly used mode. When you append `-j`, the DIC performs full parameter resolution from the environment.

Resolution order is strict:
1. **User Arguments:** Explicit CLI arguments always win.
2. **Hostname Resolution:** The DIC then checks hostname-prefixed variables (e.g., `h1_NODE_PCI0`).
3. **Global Resolution:** It falls back to global variables (e.g., `NODE_PCI0`).
4. **Function Defaults:** Finally it uses defaults defined in the target function when available.

- **Array Auto-Conversion:** If a configuration value is a Bash array, the DIC auto-converts it to a caller-compatible format.

### 3. Explicit Mode (`-x`)

Some functions in `lib/ops/` are designed as action-style execution paths and require explicit execute flags (often `-x` in the function contract itself). When you append `-x` to the DIC call, it acts as a strict pass-through, bypassing standard injection logic.

## Usage Preview

If you are unsure what the DIC will inject, run the command without arguments (or with `--help`).

```bash
ops pve vpt
```

The DIC acts as a dry-run helper and prints an intelligent **Usage Preview**. It displays exactly which parameters will be auto-injected from the configuration (e.g., `<pci0_id:01:00.0>`) and which ones require manual CLI input.

## Output and Return Codes

All commands executed via the DIC or directly are fully integrated into the framework's logging infrastructure (`lib/core/lo1` and `lib/gen/aux`).

- Return codes are standardized: `0` (Success), `1` (Usage error), `2` (Runtime failure), `127` (Command missing).
- Detailed traces are written to the logs. If `OPS_DEBUG=1` is set, you will see verbose resolution tracing from the DIC.

Continue to [05 - Deployments and Runbooks](05-deployments.md) to understand how to string these commands together into multi-step orchestrations.
