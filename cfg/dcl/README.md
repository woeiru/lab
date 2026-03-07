# Declarative Intent Configuration (`cfg/dcl`)

`cfg/dcl/` is the authoritative source of desired infrastructure intent.

## Boundary

- This directory defines desired state only.
- Do not place imperative execution logic here.
- Runtime context remains under `cfg/env/`.
- Reconciliation from desired intent to executable plans belongs to `src/rec/`.

## Intended layout

- `cfg/dcl/<site>`: base desired state.
- `cfg/dcl/<site>-<stage>`: environment overlay.
- `cfg/dcl/<site>-<node>`: node override.

## Status

- Phase: scaffolding.
- Schema draft is documented in `cfg/dcl/SCHEMA.md`.
- Validation hooks are implemented in `src/rec/ops validate`.
- Initial rollout policy in `cfg/dcl/site1` keeps `h1`/`c*` at `compat` and
  sets `t1`/`t2` to `guarded` via `DCL_TARGET_ENFORCEMENT_STAGE`.

## Strict promotion checklist (`guarded -> strict`)

- Keep target order metadata in `DCL_TARGET_ORDER` so strict execution remains
  deterministic.
- Keep non-empty dependency context in `DCL_TARGET_DEPENDS_ON` for each strict
  target.
- Keep non-empty policy gates in `DCL_TARGET_POLICY_GATES` for each strict
  target.
- Validate with `src/rec/ops validate` before compiling run artifacts.
