# lib Global Specification
# Type: Global baseline
# Scope: All functions under `lib/core`, `lib/gen`, and `lib/ops`
# Companion specs: `lib/core/.spec`, `lib/gen/.spec`, `lib/ops/.spec`
# Last Updated: 2026-02-28

## 1. Hierarchy, scope, and precedence

This repository uses hierarchical `.spec` files.

Precedence (highest to lowest):
1. `lib/<module>/.spec`
2. `lib/.spec`

Scope contract:
- `lib/.spec` applies to all functions in `lib/core`, `lib/gen`, and `lib/ops`.
- Module specs apply only to their own module.

Conflict contract:
- Module specs MAY tighten or specialize module behavior.
- Module specs MUST NOT weaken global safety or quality rules from this file.

## 2. Normative language

- `MUST`/`MUST NOT`: mandatory requirement.
- `SHOULD`/`SHOULD NOT`: strong recommendation unless justified.
- `MAY`: optional behavior.

## 3. Global mandatory rules

### GLB-001 Function naming
- Public functions MUST use module-prefixed snake_case names: `[module]_[name]`.
- Internal helpers SHOULD use `_`-prefixed names.

### GLB-002 Variable hygiene
- Function-local variables MUST use `local` unless global scope is intentional.
- Variable expansion MUST be quoted unless deliberate word splitting is required.

### GLB-003 Help handling
- Functions that support help MUST handle `--help` and `-h` first and return `0`.

### GLB-004 Invalid usage contract
- Invalid invocation MUST return `1` and display usage guidance.

### GLB-005 Technical documentation contract
- Functions participating in `aux_use`/`aux_tec` help extraction MUST keep:
  - a 3-line usage comment block above the function name, and
  - a technical details block inside the function with at least:
    - `Technical Description:`
    - `Dependencies:`
    - `Arguments:`

### GLB-006 Input validation
- User-facing inputs MUST be validated before side effects.
- Validation strategy MAY vary by module capability (see module specs).

### GLB-007 Return code semantics
- Functions MUST follow canonical return meanings:
  - `0`: success
  - `1`: parameter/usage/user error
  - `2`: system/dependency/runtime failure
  - `127`: required command not found

### GLB-008 Dependency checks
- Functions that require external commands, files, permissions, or network access MUST check prerequisites before execution.

### GLB-009 Error quality
- Failure paths MUST return explicit status codes and actionable error messages.

### GLB-010 Security baseline
- Secrets and credentials MUST NOT be hardcoded.
- Sensitive operations SHOULD follow secure temp-file and permissions practices.

### GLB-011 Safe destructive file updates
- Destructive file changes MUST use safe update patterns (for example: backup, temporary file, atomic replace) when feasible.

### GLB-012 Module capability boundaries
- `lib/core` MUST remain bootstrap-safe and MUST NOT assume `aux_*` unless explicitly sourced.
- `lib/gen` and `lib/ops` SHOULD use `aux_*` where applicable.

### GLB-013 Enforceability
- Each `MUST` rule in this file MUST map to:
  - an implemented compliance check in `val/`, or
  - a documented temporary waiver with owner and removal date.

## 4. Global recommendations

- Functions SHOULD stay cohesive and reasonably small.
- Complex behavior SHOULD be split into focused helpers.
- Logging SHOULD include enough context for troubleshooting.

## 5. Exclusions from this file

To avoid scope bleed, this file MUST NOT contain:
- module-specific execution contracts (for example DIC-only patterns),
- module rollout order or migration timelines,
- environment profile playbooks,
- long examples that duplicate module specs.

Those details belong in module specs and `doc/pro` planning documents.
