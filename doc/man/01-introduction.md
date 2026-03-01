# 01 - Introduction and Core Concepts

Welcome to the lab infrastructure automation framework. This system provides a robust, parameter-driven environment for infrastructure as code, entirely written in Bash. It has no compile/build pipeline, and relies on standard POSIX utilities plus module-specific host commands, with Bash 4+ features.

## Architecture Philosophy

The framework operates on a few key principles:
- **Parameter-Driven Modules:** Actions are implemented as explicit, parameterized Bash functions under `lib/ops/`. Caller-facing contracts are argument-driven, while some modules still use runtime globals for coordination and caching.
- **Dependency Injection Container (DIC):** Rather than typing out long lists of arguments to shell functions, the DIC (`src/dic/ops`) intelligently reads the environment configuration (`cfg/env/`) and injects the necessary parameters based on the current context (site, environment, and hostname).
- **No Compilation:** There is no `Makefile`, `package.json`, or compilation step. System activation occurs via sourcing helper functions directly into your active shell environment (`bin/ini` and `bin/orc`).
- **Explicit Runtime Dependencies:** Required host commands vary by module. Use `doc/ref/module-dependencies.md` as the canonical command requirement map before running operations on a target host.

## The Major Components

Understanding the directory structure is critical to using the framework:

- **`go` (CLI Entrypoint):** The main utility used for system installation, validation (`./go validate`), and status checks.
- **`bin/` (Initialization):** Contains `ini` (Initialization Controller) and `orc` (Component Orchestrator) which load modules sequentially into the shell.
- **`lib/` (Libraries):**
  - `core/`: Low-level foundational tools (colors, error handling, strict logging).
  - `gen/`: General utilities (validation, password generation, analysis).
  - `ops/`: The actual infrastructure modules you interact with (e.g., `pve`, `net`, `sys`, `gpu`).
- **`cfg/` (Configuration):** Holds environment definitions. `cfg/core/ecc` defines the active context, and `cfg/env/` holds the declarative state for your infrastructure nodes.
- **`src/` (Execution Layer):**
  - `dic/`: The Dependency Injection Container.
  - `set/`: Multi-step deployment orchestration scripts (runbooks).
- **`val/` (Validation):** The comprehensive test suite verifying the framework's integrity.

## How It Comes Together

In a traditional setup, you might run a script that pulls variables from a file. Here, the entire framework is activated in your current shell session. When you run an `ops` command, the DIC acts as a bridge:

1. You request an action (e.g., "Create a GPU passthrough").
2. The DIC reads the function signature from `lib/ops/gpu`.
3. The DIC checks the current active environment in `cfg/env/`.
4. It resolves the exact parameters needed for the node you are targeting.
5. It executes the resolved function call with full tracing and logging applied.

Continue to [02 - Installation and Initialization](02-installation.md) to set up your environment.
