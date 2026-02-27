# Core Module Standards
# Type: Module-specific specialization
# Scope: Functions under `lib/core/`
#
# This specification extends `lib/.spec` and applies only to `lib/core/`.

## 1. Inheritance and scope
- Inherits all mandatory baseline rules from `lib/.spec`.
- Applies only to `lib/core/*` functions.
- Does not apply to `lib/gen/*` or `lib/ops/*`.

## 2. Core-specific constraints
- Bootstrap-safe design is mandatory.
- Do not assume `aux_*` helpers are available unless explicitly sourced.
- Keep dependencies minimal and early-load safe for the init chain.

## 3. Conflict handling
- If this file defines a stricter rule than `lib/.spec`, follow this file for `lib/core/`.
- If this file is silent on a topic, `lib/.spec` remains authoritative.
