# Operations and DIC Specification
# Type: Module-specific specialization
# Scope: Functions under `lib/ops/`
# Extends: `lib/.spec`
# Last Updated: 2026-02-28

## 1. Inheritance and precedence

For files in `lib/ops/`, precedence is:
1. `lib/ops/.spec`
2. `lib/.spec`

If this file is silent on a topic, `lib/.spec` remains authoritative.

## 2. DIC contract (stateless and predictable)

The Dependency Injection Container (`src/dic/`) maps environment values to function arguments.

- OPS-001: Functions MUST be stateless with respect to environment mapping.
  - Do not hardcode environment variables in operational logic when values are expected as inputs.
- OPS-002: Positional arguments MUST be assigned to well-named local variables immediately.
  - Example: `local vm_id="$1"`, `local node_pci="$2"`.
- OPS-003: Parameter names and local variable intent SHOULD stay stable to avoid DIC mapping drift.

## 3. Explicit execution pattern (`-x`)

Infrastructure actions can be destructive and must be explicit.

- OPS-004: Action functions that would otherwise run without parameters MUST require `-x`.
- OPS-005: Invalid execute-flag usage MUST return `1` and show usage.
- OPS-006: Help flags (`--help`/`-h`) MUST return `0` and not execute actions.

Reference validation pattern:

```bash
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    aux_tec
    return 0
fi

if [ $# -ne 1 ] || [ "$1" != "-x" ]; then
    aux_use
    return 1
fi
```

## 4. Structured logging contract

`lib/ops` is orchestration-facing and must emit structured operational logs.

- OPS-007: User-facing operational messages MUST use `aux_info`, `aux_warn`, `aux_err`, or `aux_dbg`.
- OPS-008: Raw `echo`/`printf` MUST NOT be used for operational status/error messages.
- OPS-009: `echo`/`printf` MAY be used for:
  - function data returns for pipelines,
  - deliberate file content generation,
  - intentional formatted UI output.
- OPS-010: Log context MUST use key-value format (for example `"component=gpu,operation=detach"`).
- OPS-011: Log context SHOULD include at least `component` and `operation` where applicable.

## 5. Validation and dependency checks in ops

- OPS-012: Parameters MUST be validated before side effects.
- OPS-013: External dependencies MUST be checked before use.
- OPS-014: Missing required commands MUST return `127`.
- OPS-015: Runtime operation failures MUST return `2`.

Recommended helper usage in `lib/ops`:
- `aux_val` for input validation
- `aux_chk` for command/file/permission prechecks
- `aux_cmd` for safer command execution wrappers

## 6. Safety and recovery expectations

- OPS-016: Functions MUST verify system preconditions before mutating state.
  - Example: check VM or service state before changing it.
- OPS-017: Functions SHOULD validate candidate configuration before apply when supported.
  - Example: dry-run or lint-style check commands.
- OPS-018: Multi-step state changes SHOULD prefer reversible sequences or safe degraded outcomes over partial corruption.
- OPS-019: Destructive operations SHOULD produce auditable logs (`aux_audit` where relevant).

## 7. Documentation contract for ops functions

- OPS-020: Functions MUST keep the help/documentation extraction format used by `aux_use` and `aux_tec`.
- OPS-021: Technical blocks MUST document:
  - required dependencies,
  - argument meanings and expected formats,
  - operational side effects when relevant.

## 8. Non-goals of this file

This file does not define:
- project workflow state management (`doc/pro/*`),
- validation rollout schedules,
- non-ops module standards.

## 9. Generated reference sync for ops changes

- OPS-022: Changes to `lib/ops/*` that modify function signatures, dependency
  imports, host command requirements, return/error behavior, or test mappings
  MUST be followed by regenerating `doc/ref/` artifacts.
- OPS-023: Generated reference docs are maintained in `doc/ref/`; `doc/pro/`
  content MUST NOT be used as canonical ops reference data.

## 10. Lazy-map synchronization for ops modules

- OPS-024: Adding, removing, or renaming a public function in `lib/ops/<module>`
  MUST include an update to `ORC_LAZY_OPS_FUNCTIONS["<module>"]` in
  `cfg/core/lzy` in the same change.
- OPS-025: Fallback function discovery in `bin/orc` is a runtime safety net and
  MUST NOT replace map maintenance for known ops modules.
- OPS-026: Ops lazy-map/function parity MUST be enforced by automated checks in
  `val/`, or explicitly tracked under a temporary waiver with owner and
  removal date.
