# Reconciliation Layer (`src/rec`)

`src/rec/` is the compile/reconcile boundary between declarative intent and
execution runbooks.

## Contract

- Inputs: `cfg/dcl/` desired intent + contextual data from `cfg/env/`.
- Outputs: deterministic plan artifacts for `src/run/`.
- Rule: this layer does not execute infrastructure operations directly.

## Scaffolding status

- Initial entrypoint is `src/rec/ops` with `validate` and `compile` commands.
- `compile` currently emits a `rec-plan-v0` scaffold artifact with target metadata.
- `validate` enforces the draft declarative schema described in `cfg/dcl/SCHEMA.md`.
- Artifact metadata now includes per-target sections, execution mode, and
  optional preconditions.
- Schema and artifacts now include optional per-target order, dependency, and
  policy-gate metadata.
- Plans also emit enforcement-stage metadata (`enforcement_stage_default` and
  `target_*_enforcement_stage`) for `src/run/dispatch` stage resolution.
- Artifact schema, richer validation reporting, and strict compatibility checks
  are pending.
