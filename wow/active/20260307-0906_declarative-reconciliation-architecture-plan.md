# Declarative Reconciliation Architecture Plan

- Status: active
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 10:45
- Links: wow/task/active-capture, wow/task/RULES.md, wow/inbox/20260307-0941_workflow-completed-folder-chronology-checker-issue.md, doc/arc/00-architecture-overview.md, src/README.md, utl/README.md

## Retroactive Capture

- Origin: The work started as a quick architecture check on the difference between `utl/` and `src/` boundaries.
- Escalation reason: The discussion exposed a broader coupling issue where `utl/pla` is carrying both sandbox planning concerns and declarative-runtime concerns that affect `src/set` and runtime architecture.
- Design classification:
  - Are there meaningful alternatives for how to solve this? Yes (`cfg/desired` vs `cfg/dcl`, `src/rec` vs `src/rco`, keep vs rename `src/set`).
  - Will other code or users depend on the shape of the output? Yes (execution flow, documentation, onboarding, and future module boundaries).
  - Design: required
- Work so far: Agreed directional architecture is `cfg/dcl` as single declarative source of truth, `src/rec` as reconciliation/compile layer, and `src/run` as execution runbooks; agreed that `utl/pla` should remain sandbox-only and non-authoritative.

## Triage Decision

- Why now: Boundary decisions are now blocking clean decomposition of planning, declarative modeling, and runtime execution surfaces.
- Are there meaningful alternatives for how to solve this? Yes.
- Will other code or users depend on the shape of the output? Yes.
- Design: required

## Phase 1 Design Deliverable

### Global invariants

1. `cfg/dcl/` is the only authored desired-state source.
2. `cfg/env/` remains environment context (observed/runtime parameters), not desired intent.
3. `src/rec/` is the only bridge that translates desired intent into executable plans.
4. `src/run/` executes plan artifacts and does not define desired values inline.
5. `utl/pla/` remains sandbox-only and cannot become runtime-authoritative.

### `cfg/dcl/` contract

1. Purpose: declare desired infrastructure state in a stable, reviewable model.
2. Layout mirrors existing environment layering ergonomics:
   - `cfg/dcl/<site>`: base desired state.
   - `cfg/dcl/<site>-<stage>`: environment overlay (for example `dev`, `stg`, `prd`).
   - `cfg/dcl/<site>-<node>`: node override.
3. Content rules:
   - Declarative data only (no imperative shell actions).
   - Stable key contracts documented under `doc/ref/` and validated by tests.
   - Host-prefixed conventions are allowed when needed for multi-node targeting.
4. Ownership rule: changes to intended behavior must land in `cfg/dcl/` first, then flow through `src/rec/`.

### `src/rec/` contract

1. Purpose: reconcile desired state (`cfg/dcl/`) with environment/runtime context (`cfg/env/`) and compile executable plans.
2. Inputs:
   - Desired model from `cfg/dcl/`.
   - Contextual data from `cfg/env/` and invocation parameters.
3. Outputs:
   - A deterministic plan artifact consumed by `src/run/`.
   - Validation/report artifacts describing unresolved keys, conflicts, or unsafe operations.
4. Error semantics:
   - Validation failures stop before execution artifact handoff.
   - Plan output includes explicit target metadata so `src/run/` cannot execute ambiguously.
5. Boundary rule: direct execution of `lib/ops/*` from `src/rec/` is not allowed.

### `src/run/` contract

1. Purpose: execute reconciled plans through runbooks and sectioned workflows.
2. Inputs: only plan artifacts from `src/rec/` plus explicit runtime flags.
3. Rules:
   - No desired-state literals embedded in runbook logic.
   - Existing section semantics (for example `a_xall`) stay available during migration.
   - Interactive/headless execution remains supported.
4. Boundary rule: if a required plan artifact is missing or invalid, fail before any operation call.

### Compatibility and migration strategy

1. Keep current operator entrypoints callable while introducing `src/rec/` and `src/run/`.
2. Add compatibility wrappers so `src/set/*` delegates to `src/run/*` during transition.
3. Keep `src/dic` available as a compatibility interface while progressively routing plan resolution into `src/rec/`.
4. Mark legacy surfaces as deprecated only after parity tests pass and docs are updated.

### Naming decisions locked in this phase

1. Desired state root: `cfg/dcl/`.
2. Reconciliation layer: `src/rec/`.
3. Execution runbooks layer: `src/run/`.
4. Legacy naming retained only as temporary compatibility aliases.

## Progress Checkpoint

### Done

- Finalized migration scaffolding and contracts across `cfg/dcl`, `src/rec`, `src/run`, and compatibility bridges in `src/set/*` + `src/dic/run`.
- Implemented schema-aware reconciliation validation in `src/rec/ops` for sections, modes, preconditions, order, dependencies, policy gates, and enforcement-stage metadata.
- Implemented plan-aware execution controls in `src/run/dispatch` including section gating, dependency/order/policy checks, and stage resolution (`CLI -> env -> plan target -> plan default -> compat`).
- Fixed a runtime correctness issue in `src/dic/run` so dispatch failures now propagate non-zero exit codes correctly.
- Set initial declarative rollout policy in `cfg/dcl/site1` (`h1/c1/c2/c3=compat`, `t1/t2=guarded`) and aligned docs in `cfg/dcl/README.md`, `src/run/README.md`, `src/dic/README.md`, `src/README.md`, and `doc/man/04-deployments.md`.
- Expanded `val/src/rec_run_contract_test.sh` to cover compile artifact contracts, invalid schema cases, stage precedence, guarded defaults, and bridge pass-through behavior.
- Validation summary this session: `bash val/src/rec_run_contract_test.sh` passed, `bash val/src/dic/dic_set_menu_contract_test.sh` passed, `bash wow/check-workflow.sh` passed.

### In-flight

- Reconcile-first execution is still opt-in; legacy-compatible invocation remains default across `src/set/*` and `src/dic/ops`.
- `src/dic/ops` still resolves injected values from `cfg/env/site1`; declarative-first data flow is not yet the primary injection path.
- Policy gate approvals are provided via runtime flags/env vars; automatic evidence capture and gate attestation are not implemented.
- Rollout policy is currently defined only in `cfg/dcl/site1`; environment-specific promotion policy has not been split into staged overlays.

### Blockers

- No technical blockers for scaffolding continuation.
- No active workflow checker blocker at this checkpoint; chronology policy follow-up remains tracked in `wow/inbox/20260307-0941_workflow-completed-folder-chronology-checker-issue.md`.

### Next steps

1. Decide cutover criteria for switching reconcile-first flow from opt-in to default.
2. Encode promotion criteria for `guarded -> strict` into `cfg/dcl/SCHEMA.md` and `src/rec/ops` validation (required policy gates, required dependency context).
3. Implement automated gate-evidence loading for dispatch in `src/run/dispatch` (non-interactive source + validation contract) and pass-through in `src/dic/run`.
4. Add/extend contract coverage in `val/src/rec_run_contract_test.sh` for automated gate-evidence success/failure paths and strict-stage promotion invariants.
5. Update rollout guidance docs in `doc/man/04-deployments.md`, `src/run/README.md`, and `cfg/dcl/README.md` with strict promotion checklist and operational examples.
6. Keep checker-regression remediation as a separate track via `wow/inbox/20260307-0941_workflow-completed-folder-chronology-checker-issue.md`.

### Context

- Branch: `master`.
- Worktree is dirty with unrelated user changes; do not revert outside touched migration files.
- Phase status: Phase 1 complete, Phase 2 complete, Phase 3 in progress, Phase 4 in progress.
- Latest checks in this context: `bash val/src/rec_run_contract_test.sh` passed, `bash val/src/dic/dic_set_menu_contract_test.sh` passed, `bash wow/check-workflow.sh` passed.
- Workflow checker status: `bash wow/check-workflow.sh` passed.

## Execution Plan

1. Phase 3 (Migration) [in progress]: Make reconcile-first execution primary by default across `src/set/*`, `src/dic/run`, and `src/dic/ops`; completion criterion: legacy-compatible path is explicit opt-out and runtime behavior is plan-first by default.
2. Phase 4 (Validation and docs) [in progress]: Finalize promotion policy (`guarded -> strict`), gate-evidence automation, and end-to-end contract coverage; completion criterion: strict rollout rules are codified in schema + runtime checks and documented for operators.

## Exit Criteria

1. `cfg/dcl` is the only authoritative declarative-state source.
2. `src/rec` is the sole reconciliation/compile bridge into executable artifacts.
3. `src/run` executes plans without embedding desired-state definitions.
4. `utl/pla` is explicitly sandbox/planning-only and non-authoritative for runtime execution.
5. Legacy `src/dic`/`src/set` behavior is either migrated or covered by documented compatibility/deprecation guidance.
