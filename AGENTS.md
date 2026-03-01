# AGENTS.md

Agent operating guide for this repository.

This repo is a Bash-based infrastructure automation system (no compiled app build step).
Primary entrypoints are `./go`, `bin/ini`, and scripts under `val/`.

---

## 1) Repository Overview

### What this system is
A Bash-native, modular infrastructure automation framework that injects library
functions into the user's interactive shell. It manages real infrastructure:
virtual machines, GPUs, networking, storage, and system services.

### Directory architecture

| Directory   | Purpose              | Key contents                                                  |
|-------------|----------------------|---------------------------------------------------------------|
| `bin/`      | Orchestration        | `ini` (bootstrap), `orc` (component loader)                   |
| `cfg/`      | Configuration        | `env/` (environments), `core/` (constants), `ali/`, `log/`    |
| `lib/core/` | Primitives           | `err`, `lo1`, `tme`, `ver`, `col` (no file extensions)        |
| `lib/gen/`  | Utilities            | `aux` (helpers/logging), `sec` (security), `env`, `inf`, `ana`|
| `lib/ops/`  | Operations           | `gpu`, `pve`, `net`, `sys`, `ssh`, `srv`, etc. (no extensions)|
| `src/dic/`  | Dependency injection | Resolves config to function arguments                         |
| `src/set/`  | Deployment manifests | Hostname-mapped task scripts                                  |
| `val/`      | Testing              | BDD-style test framework, `helpers/test_framework.sh`         |
| `doc/`      | Documentation        | `arc/` (architecture), `man/` (manual), `ref/` (reference)    |

### File extension convention (important)
Most files under `lib/` and `bin/` have **no file extension** -- they are
sourced Bash scripts without `.sh` suffixes. Test files under `val/` **do** use
`.sh` extensions. The `go` script at the repo root also has no extension.

This means glob patterns like `**/*.sh` will miss most library code. When
searching the codebase, account for extensionless files.

### Sourcing chain
The loading order is: `./go` -> `bin/ini` -> `bin/orc` -> `lib/core/*` ->
`lib/gen/*` -> `lib/ops/*`. Functions from earlier stages are available in
later ones. Before assuming a function or variable is available, trace where
in this chain the current file sits.

---

## 2) Build, Lint, and Test Commands

### Project root
- Run all commands from repository root: `/home/es/lab`.

### Build / bootstrap
- There is no traditional compile/build pipeline (no `Makefile`, `package.json`,
  `go.mod`, `pyproject.toml`, or `Cargo.toml`).
- Setup shell integration (interactive):
  - `./go init` (also accepts `./go setup`)
- After init, three shell functions are available in every shell:
  - `lab`      -- activate in current shell only (sources `bin/ini`, no bashrc change)
  - `lab-on`   -- enable auto-load in all new shells (same as `./go on`)
  - `lab-off`  -- disable auto-load in all new shells (same as `./go off`)
- Check setup status:
  - `./go status`
- Remove helper functions from bashrc:
  - `./go purge`

### Lint / static checks
- No dedicated centralized linter command is defined.
- Practical lint-equivalent checks used in this repo:
  - Bash syntax checks:
    - `find . -type f \( -name '*.sh' -o -name 'go' \) -print0 | xargs -0 -r bash -n`
  - Config syntax check via test suite:
    - `./val/core/config/cfg_test.sh`
  - Standards/compliance-oriented checks for ops modules:
    - `./val/lib/ops/std_compliance_test.sh`

### Test commands (primary)
- Main test runner (all categories):
  - `./val/run_all_tests.sh`
- Category-only runs:
  - `./val/run_all_tests.sh core`
  - `./val/run_all_tests.sh lib`
  - `./val/run_all_tests.sh integration`
  - `./val/run_all_tests.sh src`
  - `./val/run_all_tests.sh dic`
  - `./val/run_all_tests.sh legacy`
- Helpful options:
  - `./val/run_all_tests.sh --list`
  - `./val/run_all_tests.sh --quick`
  - `./val/run_all_tests.sh --verbose`
  - `./val/run_all_tests.sh --help`

### Running a single test (important)
- Preferred method: execute the individual test script directly.
- Examples:
  - `./val/core/config/cfg_test.sh`
  - `./val/lib/ops/sys_test.sh`
  - `./val/src/dic/dic_integration_test.sh`
- If script is not executable, run with Bash:
  - `bash val/core/config/cfg_test.sh`

### Alternate validation entrypoint
- `./go validate` (or `./go test`) forwards to validation scripts.
- Note: it checks init state first (`~/.lab_initialized`), so in clean
  CI-like contexts prefer direct `val/` scripts.

### Focused library suite runner
- Run grouped library suites:
  - `./val/lib/run_all_tests.sh`
  - `./val/lib/run_all_tests.sh --core`
  - `./val/lib/run_all_tests.sh --ops --gen`
  - `./val/lib/run_all_tests.sh --integration`
  - `./val/lib/run_all_tests.sh --help`

### Change verification checklist
After any code change, follow this sequence (stop at the appropriate level):

1. **Syntax-check** edited files: `bash -n <file>`
2. **Single test** -- run the nearest relevant test script directly.
3. **Category tests** -- if the change touches multiple files in a module:
   `./val/run_all_tests.sh <category>`
4. **Full suite** -- for cross-module or structural changes:
   `./val/run_all_tests.sh`

---

## 3) Code Style and Implementation Guidelines

These rules come from repository docs and actual code patterns, especially:
- `lib/.spec` -- canonical merged baseline + quality standards across `lib/`
- `lib/ops/.spec` -- mandatory ops and DIC-specific technical standards
- `lib/ops/README.md`
- `val/helpers/test_framework.sh`
- `go`, `bin/orc`, and existing module files

### Language and shell baseline
- Use Bash (`#!/bin/bash`).
- Target Bash 4+ compatibility.
- Prefer strict mode in non-interactive scripts:
  - `set -euo pipefail` (or project-appropriate variant where interactive
    safety is required).

### File and module organization
- Keep functionality in existing structure:
  - `lib/core/` foundational modules
  - `lib/ops/` operational modules
  - `lib/gen/` general utilities
  - `src/dic/` dependency-injection wrappers/interfaces
  - `val/` tests
- Avoid introducing new top-level patterns unless they match current
  architecture.

### Imports / sourcing conventions
- Source dependencies near the top of scripts.
- Use robust relative sourcing based on `BASH_SOURCE[0]`:
  - Test scripts use the one-liner form:
    - `source "$(dirname "${BASH_SOURCE[0]}")/../path/to/file"`
  - Ops modules typically use a two-step form:
    - `DIR_FUN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"`
    - `source "${DIR_FUN}/../gen/aux"`
- For operational logging and helper integration in ops modules, source
  `lib/gen/aux` as needed (some modules source it explicitly; others rely on
  it being pre-loaded via the initialization chain).

### Function naming
- In `lib/ops`, public functions follow a three-letter module prefix
  convention:
  - `[module]_[name]` (example: `pve_cdo`, `gpu_ptd`).
- Internal helpers use a leading underscore:
  - `_module_helper`.
- Use `snake_case` consistently for functions and locals.

### Parameters and validation
- Validate parameters for all user-facing functions.
- Standard help handling first:
  - `--help` or `-h` should return success (`0`) and show technical usage.
- On invalid parameters, show usage and return `1`.
- **No function without parameters**: for action functions that traditionally
  take no args, follow the `-x` execution flag convention defined in
  `lib/ops/.spec`.
- Use `aux_val` for input validation, `aux_use` for usage display, `aux_tec`
  for detailed help.

### Return codes and error semantics
- Follow consistent return codes:
  - `0` success
  - `1` parameter/usage error
  - `2` system/dependency/runtime failure
  - `127` required command missing
- Prefer explicit `return` values over implicit status in multi-step functions.

### Error handling patterns
- Fail fast on invalid inputs/dependencies.
- Check dependencies before use with `aux_chk` (commands/files/permissions).
- Use structured error reporting helpers (`aux_err`, `err_process`, etc.).
- Keep destructive operations guarded and auditable.

### Logging expectations
- For `lib/ops`, use structured logging via aux helpers (never raw
  `echo`/`printf` for operational messages):
  - `aux_info`, `aux_warn`, `aux_err`, `aux_dbg`, `aux_audit`, `aux_business`.
- Include context as key-value pairs:
  - `"component=gpu,operation=passthrough,status=failed"`
- Use plain `echo`/`printf` only for:
  - Function return values (data piped to callers).
  - Deliberate formatted UI display output.
  - File content generation.

### Variables and constants
- Use `local` inside functions.
- Use `readonly` for constants that should not change.
- Uppercase for environment/global constants (`LAB_ROOT`, `LOG_DIR`),
  lowercase `snake_case` for locals.
- Quote variable expansions unless intentional word splitting is required.

### Formatting and readability
- Follow existing style: descriptive section headers and grouped helper
  functions.
- Prefer short, cohesive functions; split complex logic into helpers.
- Maximum ~150 lines per function (per spec guidance).
- Keep indentation and spacing consistent with surrounding file style.
- Add comments for non-obvious logic, not for trivial statements.

### Types and data handling (Bash-specific)
- Use arrays for structured multi-value data.
- Use `declare -A` for associative maps where needed.
- Validate expected types/formats (numeric, path, non-empty, etc.) before use.

### Security and safety
- Never hardcode secrets; follow existing security utilities in `lib/gen/sec`.
- Respect secure file permissions for sensitive material.
- Prefer safe temp-file patterns (`mktemp`) and cleanup traps where
  appropriate.
- Create backups before modifying system files (see spec safe file
  operations pattern).

### Testing expectations for changes
- For small targeted edits, run the nearest relevant single test script.
- For module-level changes, run at least the relevant category in
  `val/run_all_tests.sh`.
- For broad or cross-module changes, run full suite:
  - `./val/run_all_tests.sh`

### Documentation expectations
- Keep usage/help text in sync with function signatures.
- If behavior changes, update relevant docs in `doc/` and module READMEs
  when applicable.
- Keep `aux_use` comment blocks (3 lines above function name) and `aux_tec`
  technical detail blocks accurate.

---

## 4) Agent Workflow Strategy

### Use subagents for exploration and parallel work

**Explore agents** -- use for codebase navigation:
- Finding files, searching code, answering structural questions.
- Essential because most `lib/` files have no extensions -- naive glob patterns
  miss them.
- Prefer `explore` over manual grep/glob for open-ended questions like "where
  is X handled?" or "what modules depend on Y?".

**General agents** -- use for parallel multi-step work:
- Fixing multiple test failures simultaneously.
- Updating multiple modules in parallel.
- Researching several doc files at once.

**When to use subagents vs direct tools:**

| Situation                                        | Approach                                |
|--------------------------------------------------|-----------------------------------------|
| Open-ended search ("where is X?")                | `explore` subagent                      |
| Codebase structure questions                     | `explore` subagent                      |
| Known file path to read/edit                     | Direct Read/Edit/Glob tool              |
| Multiple independent changes                    | `general` subagents in parallel         |
| Single targeted edit                             | Direct Edit tool                        |
| Understanding architecture or cross-module flow  | `explore` subagent with `doc/arc/` hint |

### Understand before modifying

1. **Before editing any `lib/ops/` module**: read `lib/.spec` (canonical global
   baseline + quality standards) and `lib/ops/.spec` (ops/DIC-specific
   standards). These define how every function must be structured.
2. **Before cross-module changes**: read `doc/arc/00-architecture-overview.md`
   for the system paradigm and execution flow.
3. **Before writing a new module**: read `doc/man/05-writing-modules.md`.
4. **Before modifying sourcing or bootstrap**: understand the chain
   `./go` -> `bin/ini` -> `bin/orc` -> `lib/core/` -> `lib/gen/` -> `lib/ops/`.
5. **Before editing tests**: read `val/helpers/test_framework.sh` for available
   assertions and the `val/README.md` for structure conventions.

### Key reference documents

| Document                           | When to consult                           |
|------------------------------------|-------------------------------------------|
| `lib/.spec`                        | Canonical merged standards for all `lib/` |
| `lib/ops/.spec`                    | Ops and DIC-specific contracts             |
| `doc/arc/00-architecture-overview.md` | System-wide understanding              |
| `doc/arc/04-dependency-injection.md`  | DIC / config resolution work           |
| `doc/arc/07-logging-and-error-handling.md` | Logging or error handling changes |
| `doc/man/05-writing-modules.md`    | Creating new modules                      |
| `doc/ref/functions.md`             | Function reference lookup                 |
| `doc/ref/variables.md`             | Variable/constant reference               |
| `doc/ref/module-dependencies.md`   | Direct imports + host command checks      |
| `doc/ref/test-coverage.md`         | Test traceability mapping                 |
| `doc/ref/error-handling.md`        | Return/exit/log handling map              |
| `val/README.md`                    | Test structure and framework usage        |

### Generated reference docs contract (`doc/ref/`)

- Canonical generated reference context lives in `doc/ref/`.
- `doc/pro/` is planning workflow state, not executable/reference source data.
- Treat `doc/ref/*.md` as high-signal navigation context for symbol lookup,
  dependency tracing, and test/error mapping before deep file reads.
- If a generated reference conflicts with code, treat source code as the source
  of truth and regenerate references.
- Regenerate reference docs after structural changes (new/renamed functions,
  signature changes, dependency changes, variable map changes):
  - `./utl/doc/run_all_doc.sh`

---

## 5) Safety Rules

This is infrastructure automation code that manages real systems. Agents must
respect these safety boundaries.

### Safe to run (no side effects)
- Test scripts: anything under `val/`
- Syntax checks: `bash -n <file>`
- Status checks: `./go status`
- Read-only exploration: `grep`, `cat`, file reads

### NEVER run directly
- Operational functions from `lib/ops/` -- they modify VMs, GPUs, networking,
  storage, and system services on real hosts.
- Deployment manifests from `src/set/` -- they execute infrastructure changes.
- `./go init` or `./go on` -- they modify the user's shell configuration.

### General safety principles
- Do not execute functions you do not fully understand.
- Do not modify files under `cfg/env/` without explicit instruction -- these
  are live environment configurations.
- Never hardcode credentials or secrets.
- When in doubt, ask the user before running anything that could affect system
  state.

---

## 6) Git and Commit Conventions

### Commit messages
- Keep messages short and descriptive.
- Use lowercase, no trailing period.
- Prefix with scope when relevant: `docs:`, `fix:`, `val:`, `lib/ops:`, etc.
- Examples from this repo's history:
  - `fix tme numeric formatting for locale-safe timing output`
  - `docs: adjustments`
  - `doc/man rewrite`

### Commit discipline
- Do not commit unless explicitly asked by the user.
- Do not commit files that contain secrets (`.env`, credentials, keys).
- Do not amend or force-push without explicit instruction.
- Run at minimum `bash -n` on changed files before committing.

---

## 7) Cursor and Copilot Rules

This repository currently uses `AGENTS.md` as the canonical local agent guide.

No additional repository-level rule files were found at time of writing.

If tool-specific rule files are added later (for example Cursor, Copilot, or
OpenCode-specific paths), treat them as higher-priority guidance and merge
them into this document.

---

## 8) Common Pitfalls

Mistakes agents frequently make in this repo:

1. **Searching only for `*.sh` files** -- misses all of `lib/` and `bin/`.
   Use extensionless patterns or `explore` subagents.
2. **Assuming functions are globally available** -- a function is only usable
   if the current file is loaded after its source in the initialization chain.
3. **Using `echo` for operational messages in `lib/ops/`** -- must use
   structured `aux_*` logging instead.
4. **Creating functions without parameters** -- every function requires at
   least one parameter (use `-x` flag pattern for action-only functions).
5. **Running ops functions to "test" them** -- they modify real infrastructure.
   Use the test suite under `val/` instead.
6. **Ignoring `.spec` requirements** -- `aux_use`, `aux_tec`, `aux_val`,
   parameter validation, and return codes are mandatory, not optional.
7. **Editing `AGENTS.md` without running its test** -- always verify with
   `./val/core/agents_md_test.sh` after changes.
8. **Using `doc/pro/ref` as canonical reference path** -- canonical generated
   reference docs are under `doc/ref/`; `doc/pro/` is for planning documents.
