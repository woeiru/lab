# Generic Utilities Module Standards
# Type: Module-specific specialization
# Scope: Functions under `lib/gen/`
#
# This specification extends `lib/.spec` and applies only to `lib/gen/`.

## 1. Inheritance and scope
- Inherits all mandatory baseline rules from `lib/.spec`.
- Applies only to `lib/gen/*` functions.
- Does not apply to `lib/core/*` or `lib/ops/*`.

## 2. gen-specific constraints
- `lib/gen` utilities should integrate with `aux_*` helpers where applicable.
- Analysis and helper modules should remain safe to run in read-only/test contexts.
- Function help contracts (`aux_use`/`aux_tec`) follow the baseline format in `lib/.spec`.

## 3. Conflict handling
- If this file defines a stricter rule than `lib/.spec`, follow this file for `lib/gen/`.
- If this file is silent on a topic, `lib/.spec` remains authoritative.

## 4. Lazy-map synchronization for gen modules

- GEN-001: Adding, removing, or renaming a public function in `lib/gen/<module>`
  MUST include an update to `ORC_LAZY_GEN_FUNCTIONS["<module>"]` in
  `cfg/core/lzy` in the same change.
- GEN-002: Fallback function discovery in `bin/orc` is a runtime safety net and
  MUST NOT replace map maintenance for known gen modules.
- GEN-003: Gen lazy-map/function parity MUST be enforced by automated checks in
  `val/`, or explicitly tracked under a temporary waiver with owner and
  removal date.
