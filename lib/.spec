# Global Library Standards and Best Practices
# Type: Core Specification & Guidelines
# Scope: All functions across the `lib/` directory (`core`, `gen`, `ops`)
#
# This document merges strict technical specifications (MUST) with best 
# practices (SHOULD) for writing robust Bash functions in this repository.

## 1. Function Naming Convention
To ensure clarity and prevent naming collisions:
- **Public Functions** MUST use a three-letter module prefix: `[module]_[name]` (e.g., `ana_laf`, `aux_val`).
- **Internal Helpers** MUST be prefixed with an underscore and the module name: `_[module]_[name]` (e.g., `_ana_helper`).
- **Case** MUST be `snake_case` for all function names and local variables.

## 2. Documentation and Comment Blocks (Required by `ana`)
The `lib/gen/ana` module dynamically parses files to generate documentation and JSON definitions. 
Functions MUST include properly formatted comment blocks.

### The `aux_use` Header (Exactly 3 lines above the function)
```bash
# 1. Full description of what the function does
# 2. shortname or mnemonic
# 3. <required_param> [optional_param] or -x
function_name() {
```

### The `aux_tec` Block (Immediately inside the function)
```bash
    # Technical Description:
    #   Step-by-step explanation of behavior.
    # Dependencies:
    #   - Required external commands (e.g., jq, curl)
    # Arguments:
    #   $1: param_name - Explanation of parameter.
```

## 3. Parameter Validation & Return Codes
No function can run without proper parameter validation. 
- **Help Flags:** Functions MUST handle `--help` or `-h` as the first check, calling `aux_tec` and returning `0`.
- **Validation:** Functions MUST validate argument counts and types using `aux_val`. On failure, call `aux_use` and return `1`.
- **Exit Codes:** MUST follow standard conventions:
  - `0`: Success
  - `1`: Parameter validation failure or user error
  - `2`: System, execution, or dependency error
  - `127`: Required command missing (checked via `aux_chk`)

## 4. Auxiliary Integration (`aux_*`)
To ensure cross-module consistency, functions SHOULD leverage the `lib/gen/aux` framework:
- **`aux_val`**: MUST be used for input validation (e.g., `aux_val "$1" "not_empty"`).
- **`aux_chk`**: MUST be used to verify dependencies (e.g., `aux_chk "command" "jq"`).
- **`aux_ask`**: SHOULD be used for interactive user prompts.
- **`aux_cmd`**: SHOULD be used for safe external command execution.

## 5. Code Quality & Safety (Best Practices)
- **Size Limits:** Functions SHOULD NOT exceed 150 lines. Break complex logic into `_helper` functions.
- **Variable Scope:** ALL variables MUST be declared as `local` to prevent global namespace pollution.
- **Safe File Operations:** When modifying existing system files, functions SHOULD create backups first (e.g., `cp "$file" "$file.bak"`).
- **Atomic Operations:** Functions SHOULD adhere to the single-responsibility principle. Do one thing and do it well.
- **Graceful Degradation:** Provide clear, actionable error messages before returning `2`.
