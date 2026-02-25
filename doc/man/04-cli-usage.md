# 04 - CLI Usage and the DIC

The framework's CLI is fundamentally different from typical Bash scripts. Instead of writing custom shell scripts with `getopts` blocks and explicit argument handling, the system relies on a Dependency Injection Container (DIC) located at `src/dic/ops` (available via the `ops` command).

## The Dual Interface

The framework provides two primary ways to interact with its modules (`lib/ops/`):

1. **Direct Bash Functions (Pure Mode):** You call the raw function directly in your shell (e.g., `gpu_ptd`).
2. **The DIC CLI (`ops` command):** You use the DIC to resolve parameters automatically based on the current configuration environment.

### Direct Execution

All functions in `lib/ops/` are pure, stateless Bash functions. They expect arguments to be passed exactly as their signature defines.

```bash
# Explicitly providing all arguments
gpu_ptd "0000:01:00.0" "vfio-pci" "h1" "gpu1"
```

This is tedious for daily operations, and you must manually retrieve the values from your configuration.

### The DIC (`ops`) Execution

The `ops` command is the intelligent interface to these functions. It analyzes the signature of the underlying Bash function, scans the `cfg/env/` configuration for matching variables (respecting hostname prefixes), and automatically injects the resolved values into the function call.

```bash
# Using the DIC to execute gpu_ptd
ops gpu ptd -j
```

## DIC Execution Modes

The DIC operates in three distinct modes:

### 1. Hybrid Mode (Default)

If you just run `ops gpu ptd`, the DIC expects you to provide some arguments, but will try to supplement missing ones if possible.

### 2. Injection Mode (`-j`)

This is the most powerful and commonly used mode. When you append `-j`, the DIC performs full parameter resolution from the environment.

* **Hostname Resolution:** The DIC automatically looks for variables prefixed with the current hostname (e.g., `h1_NODE_PCI0`).
* **Global Resolution:** It then falls back to global variables (e.g., `NODE_PCI0`).
* **Array Auto-Conversion:** If a configuration value is a Bash array, the DIC auto-converts it to a space-separated string (or whatever format the function expects).

### 3. Explicit Mode (`-x`)

Some functions in `lib/ops/` are designed to handle their own parameter sourcing (often multi-step interactive workflows). When you append `-x`, the DIC acts as a strict pass-through, bypassing injection entirely.

## Understanding What Will Happen

If you are ever unsure what parameters the DIC will inject into a function, run the command without arguments (or with `--help`).

```bash
ops pve vpt
```

The DIC acts as a dry-run helper and prints an intelligent **Usage Preview**. It displays exactly which parameters will be auto-injected from the configuration (e.g., `<pci0_id:01:00.0>`) and which ones require manual CLI input.

## The Output

All commands executed via the DIC or directly are fully integrated into the framework's logging infrastructure (`lib/core/lo1` and `lib/gen/aux`).

* Return codes are standardized: `0` (Success), `1` (Usage error), `2` (Runtime failure), `127` (Command missing).
* Detailed traces are written to the logs. If `OPS_DEBUG=1` is set, you will see verbose resolution tracing from the DIC.

Continue to [05 - Deployments and Runbooks](05-deployments.md) to understand how to string these commands together into multi-step orchestrations.
