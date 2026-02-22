# AGENTS.md

Agent operating guide for this repository.

This repo is a Bash-based infrastructure automation system (no compiled app build step).
Primary entrypoints are `./go`, `bin/ini`, and scripts under `val/`.

## 1) Build, Lint, and Test Commands

### Project root
- Run all commands from repository root: `/home/es/lab`.

### Build / bootstrap
- There is no traditional compile/build pipeline (no `Makefile`, `package.json`, `go.mod`, `pyproject.toml`, or `Cargo.toml`).
- Setup shell integration (interactive):
  - `./go init` (also accepts `./go setup`)
- Enable or disable integration after init:
  - `./go on`
  - `./go off`
- Check setup status:
  - `./go status`

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
- Note: it checks init state first (`~/.lab_initialized`), so in clean CI-like contexts prefer direct `val/` scripts.

### Focused library suite runner
- Run grouped library suites:
  - `./val/lib/run_all_tests.sh`
  - `./val/lib/run_all_tests.sh --core`
  - `./val/lib/run_all_tests.sh --ops --gen`
  - `./val/lib/run_all_tests.sh --integration`
  - `./val/lib/run_all_tests.sh --help`

## 2) Code Style and Implementation Guidelines

These rules come from repository docs and actual code patterns, especially:
- `lib/ops/.spec`
- `lib/ops/.guide`
- `lib/ops/README.md`
- `val/helpers/test_framework.sh`
- `go`, `bin/orc`, and existing module files

### Language and shell baseline
- Use Bash (`#!/bin/bash`).
- Target Bash 4+ compatibility.
- Prefer strict mode in non-interactive scripts:
  - `set -euo pipefail` (or project-appropriate variant where interactive safety is required).

### File and module organization
- Keep functionality in existing structure:
  - `lib/core/` foundational modules
  - `lib/ops/` operational modules
  - `lib/gen/` general utilities
  - `src/dic/` dependency-injection wrappers/interfaces
  - `val/` tests
- Avoid introducing new top-level patterns unless they match current architecture.

### Imports / sourcing conventions
- Source dependencies near the top of scripts.
- Use robust relative sourcing based on `BASH_SOURCE[0]`:
  - Test scripts use the one-liner form:
    - `source "$(dirname "${BASH_SOURCE[0]}")/../path/to/file"`
  - Ops modules typically use a two-step form:
    - `DIR_FUN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"`
    - `source "${DIR_FUN}/../gen/aux"`
- For operational logging and helper integration in ops modules, source `lib/gen/aux` as needed (some modules source it explicitly; others rely on it being pre-loaded via the initialization chain).

### Function naming
- In `lib/ops`, public functions should follow module prefix convention:
  - `[module]_[name]` (example: `pve_cdo`, `gpu_ptd`).
- Internal helpers should use leading underscore where appropriate:
  - `_module_helper`.
- Use `snake_case` consistently for functions and locals.

### Parameters and validation
- Validate parameters for all user-facing functions.
- Standard help handling first:
  - `--help` or `-h` should return success (`0`) and show technical usage.
- On invalid parameters, show usage and return `1`.
- For action functions that otherwise take no args, follow `-x` execution flag convention in ops standards.

### Return codes and error semantics
- Follow consistent return codes:
  - `0` success
  - `1` parameter/usage error
  - `2` system/dependency/runtime failure
  - `127` required command missing
- Prefer explicit `return` values over implicit status in multi-step functions.

### Error handling patterns
- Fail fast on invalid inputs/dependencies.
- Check dependencies before use (commands/files/permissions).
- Use structured error reporting helpers where applicable (`aux_err`, `err_process`, etc.).
- Keep destructive operations guarded and auditable.

### Logging expectations
- For `lib/ops`, prefer structured logging via aux helpers:
  - `aux_info`, `aux_warn`, `aux_err`, `aux_dbg`, `aux_audit`, `aux_business`.
- Include context as key-value pairs when possible:
  - `"component=gpu,operation=passthrough,status=failed"`
- Use plain `echo/printf` for function return data or deliberate formatted UI output.

### Variables and constants
- Use `local` inside functions.
- Use `readonly` for constants that should not change.
- Uppercase for environment/global constants (`LAB_ROOT`, `LOG_DIR`), lowercase snake_case for locals.
- Quote variable expansions unless intentional word splitting is required.

### Formatting and readability
- Follow existing style: descriptive section headers and grouped helper functions.
- Prefer short, cohesive functions; split complex logic into helpers.
- Keep indentation and spacing consistent with surrounding file style.
- Add comments for non-obvious logic, not for trivial statements.

### Types and data handling (Bash-specific)
- Use arrays for structured multi-value data.
- Use `declare -A` for associative maps where needed.
- Validate expected types/formats (numeric, path, non-empty, etc.) before use.

### Security and safety
- Never hardcode secrets; follow existing security utilities in `lib/gen/sec`.
- Respect secure file permissions for sensitive material.
- Prefer safe temp-file patterns (`mktemp`) and cleanup traps where appropriate.

### Testing expectations for changes
- For small targeted edits, run the nearest relevant single test script.
- For module-level changes, run at least the relevant category in `val/run_all_tests.sh`.
- For broad or cross-module changes, run full suite:
  - `./val/run_all_tests.sh`

### Documentation expectations
- Keep usage/help text in sync with function signatures.
- If behavior changes, update relevant docs in `doc/` and module READMEs when applicable.

## 3) Cursor and Copilot Rules

Checked for repository-level agent rule files:
- `.cursorrules`
- `.cursor/rules/`
- `.github/copilot-instructions.md`

Result: none found in this repository at time of writing.

If these files are added later, treat them as higher-priority guidance and merge them into this document.
