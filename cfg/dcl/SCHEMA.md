# `cfg/dcl` Schema Draft (v0)

This is the initial declarative schema draft used by `src/rec/ops` during
migration scaffolding.

## Required variables per declarative file set

- `DCL_SITE_NAME` (string): site identifier.
- `DCL_PROFILE` (string): profile/overlay label.
- `DCL_TARGETS` (indexed array): ordered list of execution targets.
- `DCL_TARGET_SECTIONS` (associative array): map target -> space-delimited
  section list.
- `DCL_TARGET_MODES` (optional associative array): map target ->
  `interactive|headless|both`.
- `DCL_TARGET_PRECONDITIONS` (optional associative array): map target ->
  free-form precondition string.
- `DCL_TARGET_ORDER` (optional associative array): map target -> positive
  integer execution order.
- `DCL_TARGET_DEPENDS_ON` (optional associative array): map target ->
  space-delimited dependency targets.
- `DCL_TARGET_POLICY_GATES` (optional associative array): map target ->
  space-delimited policy gate tokens.
- `DCL_ENFORCEMENT_STAGE_DEFAULT` (optional string): default run enforcement
  stage for plan consumers (`compat|guarded|strict`).
- `DCL_TARGET_ENFORCEMENT_STAGE` (optional associative array): map target ->
  target-specific enforcement stage override (`compat|guarded|strict`).

## Validation rules (current)

1. At least one declarative file must exist in `cfg/dcl/` (excluding
   `README.md`).
2. Every declarative file must pass `bash -n` syntax validation.
3. `DCL_TARGETS` must be non-empty.
4. Every target in `DCL_TARGETS` must have a non-empty mapping in
   `DCL_TARGET_SECTIONS`.
5. Section tokens must match `^[a-zA-Z0-9_:-]+$`.
6. If `DCL_TARGET_MODES` is present, every target must map to one of
   `interactive`, `headless`, or `both`.
7. If `DCL_TARGET_ORDER` is present, every target must map to a unique positive
   integer.
8. If `DCL_TARGET_DEPENDS_ON` is present, dependency targets must exist,
   self-dependencies are invalid, and dependency cycles are rejected.
9. If `DCL_TARGET_POLICY_GATES` is present, gate tokens must match
   `^[a-zA-Z0-9._:-]+$`.
10. `DCL_ENFORCEMENT_STAGE_DEFAULT`, when present, must be one of
    `compat`, `guarded`, or `strict`.
11. If `DCL_TARGET_ENFORCEMENT_STAGE` is present, every provided target value
    must be one of `compat`, `guarded`, or `strict`.

## Notes

- This schema remains migration-oriented, but now includes first-pass ordering,
  dependency, and policy-gate metadata validation.
