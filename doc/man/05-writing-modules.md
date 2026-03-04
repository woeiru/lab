# 05 - Writing Modules

This guide covers how to add or modify operational modules in `lib/ops/` while
keeping compatibility with DIC, tests, and repository standards.

## 1. Where Module Code Lives

- Operational modules: `lib/ops/*` (extensionless Bash files).
- General utilities: `lib/gen/*`.
- Core primitives: `lib/core/*`.
- Tests for ops modules: `val/lib/ops/*_test.sh`.

Important: most source files in `lib/` and `bin/` have no `.sh` extension.

## 2. Required Standards

Read these first before editing module contracts:
- `lib/.spec` (canonical standards for all `lib/` modules)
- `lib/ops/.spec` (ops/DIC-specific requirements)

Key enforced contracts:
- user-facing functions validate input,
- help flags (`-h`/`--help`) return `0`,
- usage errors return `1`, runtime/system failures return `2`, missing commands return `127`,
- action-style functions use explicit execute flags (typically `-x`) instead of zero-argument execution,
- for lazy-loaded `lib/ops/*` and `lib/gen/*`, public function changes also update `cfg/core/lzy` (`ORC_LAZY_OPS_FUNCTIONS` or `ORC_LAZY_GEN_FUNCTIONS`) in the same patch.

## 3. Function Design Rules

### Naming

- Public function format: `<module>_<action>` (for example `gpu_ptd`, `pve_cdo`).
- Internal helpers: `_<module>_<helper>`.
- Use `snake_case` for locals; reserve uppercase for constants/global env values.

### Parameters and validation

- Parse `-h`/`--help` first.
- Validate user-facing inputs with `aux_val` and related checks.
- Check external command dependencies early with `aux_chk`.
- Return explicit codes for each failure class.

### Logging and errors

- In `lib/ops/*`, use structured logging helpers (`aux_info`, `aux_warn`, `aux_err`, `aux_dbg`, `aux_audit`, `aux_business`).
- Avoid raw `echo` for operational status/error output.
- Include context metadata when useful (for example `component=gpu,operation=passthrough`).

## 4. Self-Documentation Pattern (`aux_use` / `aux_tec`)

Keep function help extractable by maintaining comment blocks:
- three comment lines above the function for usage (`aux_use`),
- technical block inside function body for detailed docs (`aux_tec`).

Example skeleton:

```bash
# does something useful
# short operation label
# Usage: net_fas [-x] <service>
net_fas() {
    # Technical Description:
    #   Explain behavior, dependencies, and side effects.

    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        aux_tec
        return 0
    fi

    local execute_flag="${1:-}"
    local service="${2:-}"

    if [[ "$execute_flag" != "-x" ]]; then
        aux_use
        return 1
    fi

    if ! aux_val "$service" "not_empty"; then
        aux_err "service is required"
        return 1
    fi

    if ! aux_chk "command" "firewall-cmd"; then
        aux_err "firewall-cmd command not found"
        return 127
    fi

    aux_info "running firewall action" "component=net,operation=fas,service=$service"
    # operation logic
    return 0
}
```

## 5. Testing Requirements

Every new module/function needs tests.

Recommended test workflow:

```bash
bash -n lib/ops/<module>
./val/lib/ops/<module>_test.sh
./val/core/initialization/orc_test.sh
./val/run_all_tests.sh lib
```

Run full suite for cross-module changes:

```bash
./val/run_all_tests.sh
```

## 6. Common Pitfalls

- Searching only for `*.sh` and missing extensionless module files.
- Returning implicit status from multi-step functions.
- Missing `-x` action gating on destructive flows.
- Using plain `echo` instead of `aux_*` logging in ops modules.
- Adding module functions without corresponding tests.
- Adding/removing public functions without updating `cfg/core/lzy` lazy maps.

## 7. Related Docs

- Next: [06 - Security and Logging](06-security-and-logging.md)
- Architecture context: [doc/arc/03-operational-modules.md](../arc/03-operational-modules.md)
- Reference maps: [doc/ref/functions.md](../ref/functions.md)
