# Runbooks Layer (`src/run`)

`src/run/` is the execution boundary for applying reconciled plans.

## Contract

- Consumes plan artifacts produced by `src/rec/`.
- Provides runbook-style execution entrypoints.
- Must not embed desired-state definitions.

## Scaffolding status

- Initial compatibility dispatcher is `src/run/dispatch`.
- `dispatch` supports optional `--plan <artifact>` preflight validation.
- When `--plan` is provided with `-x`, `dispatch` validates requested sections
  against plan metadata before invoking legacy runbooks.
- Optional runtime enforcement flags are available when `--plan` is present:
  `--enforce-deps`, `--enforce-order`, and `--enforce-policy-gates`.
- Stage defaults are available via `--enforcement-stage <stage>` or
  `LAB_RUN_ENFORCEMENT_STAGE` with values `compat`, `guarded`, `strict`.
  - `compat`: no strict enforcement defaults.
  - `guarded`: dependency + order enforcement defaults.
  - `strict`: dependency + order + policy-gate enforcement defaults.
- If neither CLI nor env stage is set, `dispatch` resolves stage from plan
  metadata (`target_*_enforcement_stage`, then `enforcement_stage_default`,
  then `compat`).
- Current rollout in `cfg/dcl/site1` keeps `h1`/`c1`/`c2`/`c3` at `compat` and
  sets `t1`/`t2` to `guarded` as initial adoption targets.
- Dependency and policy checks accept runtime context via repeatable flags:
  `--completed-target <target>` and `--allow-gate <gate>`.
- Environment equivalents are supported for automation contexts:
  `LAB_RUN_COMPLETED_TARGETS`, `LAB_RUN_ALLOWED_POLICY_GATES`.
- Policy gate approvals can be auto-loaded from evidence artifacts using
  `--gate-evidence <path>` or `LAB_RUN_GATE_EVIDENCE_FILE`.
- `src/run/gate-evidence` can generate CI/orchestration-safe
  `gate-evidence-v0` artifacts from explicit `--allow-gate` values or
  `LAB_RUN_ALLOWED_POLICY_GATES`, with optional `--plan` policy-gate checks.
- Gate evidence contract is key-value text with:
  - `format=gate-evidence-v0`
  - `target=<dispatch-target>`
  - approved gates via `approved_gates="g1 g2"` or repeatable
    `approved_gate=<gate>` keys.
- Invalid gate evidence (missing keys, target mismatch, bad gate tokens) fails
  before runbook execution.
- Strict stage keeps dependency/order checks active; targets with declared
  dependencies still require completion context (`--completed-target` or
  `LAB_RUN_COMPLETED_TARGETS`).
- Legacy runbooks can opt into the reconcile bridge by setting
  `LAB_USE_DIC_RUN_BRIDGE=1`.
- Legacy `src/set/*` still remains the active execution surface during
  migration.
