# Declarative Reconciliation Architecture Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 15:45
- Links: wow/task/active-capture, wow/task/RULES.md, wow/active/20260307-0941_workflow-completed-folder-chronology-checker-issue.md, doc/arc/00-architecture-overview.md, src/README.md, utl/README.md

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

- Implemented strict promotion invariants in `src/rec/ops` so effective `strict` targets require `DCL_TARGET_ORDER`, non-empty `DCL_TARGET_DEPENDS_ON`, and non-empty `DCL_TARGET_POLICY_GATES` metadata.
- Implemented non-interactive gate-evidence loading in `src/run/dispatch` via `--gate-evidence` and `LAB_RUN_GATE_EVIDENCE_FILE` with contract validation (`format=gate-evidence-v0`, target match, valid gate tokens, non-empty approvals).
- Added gate-evidence passthrough handling in `src/dic/run` so bridge invocations can forward evidence artifacts to dispatch.
- Expanded contract coverage in `val/src/rec_run_contract_test.sh` for gate-evidence success/failure paths and strict-promotion invariants.
- Added `src/run/gate-evidence` producer entrypoint to generate `gate-evidence-v0` artifacts from explicit approvals (`--allow-gate`) or `LAB_RUN_ALLOWED_POLICY_GATES`, with optional `--plan` validation of required policy gates.
- Extended `val/src/rec_run_contract_test.sh` with producer-path coverage (artifact generation, missing-gate rejection, and strict dispatch consumption of produced artifacts).
- Documented producer usage and strict-run evidence flow in `src/run/README.md`, `src/dic/README.md`, and `doc/man/04-deployments.md`.
- Updated rollout/docs references in `cfg/dcl/SCHEMA.md`, `cfg/dcl/README.md`, `src/run/README.md`, `src/dic/README.md`, and `doc/man/04-deployments.md`.
- Validation summary this session: `bash -n src/run/gate-evidence val/src/rec_run_contract_test.sh` passed; `bash val/src/rec_run_contract_test.sh` passed; `bash val/src/dic/dic_set_menu_contract_test.sh` passed; `bash wow/check-workflow.sh` passed.

### In-flight

- Reconcile-first execution is still not default end-to-end; `src/dic/ops` remains direct-mode by default and `src/set/*` still allows non-plan dispatch paths.
- `src/dic/ops` continues to source injected values from `cfg/env/site1`; declarative-first injection data flow is not yet primary.
- Gate evidence consumption and producer generation are implemented, but attestation persistence/retention is still manual/out-of-band.
- Rollout policy is still concentrated in `cfg/dcl/site1`; staged overlays for environment promotion are not yet implemented.
- All work remains uncommitted in a dirty worktree with unrelated user changes.

### Blockers

- No technical blockers for continuation.
- Open design dependency: choose canonical evidence producer + artifact retention location to complete strict-run automation and auditability.
- Workflow chronology follow-up remains separate and active at `wow/active/20260307-0941_workflow-completed-folder-chronology-checker-issue.md`.

### Next steps

1. Implement attestation persistence and retention conventions for gate approvals and document audit retrieval in `doc/man/04-deployments.md`.
2. Move `src/dic/ops` toward declarative-first defaults and reduce direct `cfg/env/site1` sourcing behavior.
3. Split rollout policy into staged overlays under `cfg/dcl/` and update `cfg/dcl/SCHEMA.md` + `cfg/dcl/README.md` with environment promotion examples.
4. Re-run `bash val/src/rec_run_contract_test.sh`, `bash val/src/dic/dic_set_menu_contract_test.sh`, and `bash wow/check-workflow.sh`, then record outcomes in this plan.

### Context

- Branch: `master`.
- Worktree is dirty with unrelated user changes; do not revert outside touched migration files.
- Key files touched this session: `src/run/gate-evidence`, `val/src/rec_run_contract_test.sh`, `src/run/README.md`, `src/dic/README.md`, `doc/man/04-deployments.md`.
- Gate evidence contract currently accepted by dispatch: `format=gate-evidence-v0`, `target=<dispatch-target>`, approvals via `approved_gates="..."` or `approved_gate[_N]=...`.
- Phase status: Phase 1 complete, Phase 2 complete, Phase 3 in progress, Phase 4 in progress.
- Latest checks in this context: `bash -n src/run/gate-evidence val/src/rec_run_contract_test.sh` passed; `bash val/src/rec_run_contract_test.sh` passed; `bash val/src/dic/dic_set_menu_contract_test.sh` passed; `bash wow/check-workflow.sh` passed.
- Workflow checker status: `bash wow/check-workflow.sh` passed.

## Execution Plan

1. Phase 3 (Migration) [in progress]: Make reconcile-first execution primary by default across `src/set/*`, `src/dic/run`, and `src/dic/ops`; completion criterion: legacy-compatible path is explicit opt-out and runtime behavior is plan-first by default.
2. Phase 4 (Validation and docs) [in progress]: Implement strict-run evidence production + attestation retention and staged rollout overlays; completion criterion: strict runs use an end-to-end automated evidence flow with documented operator audit guidance and test coverage.

## Exit Criteria

1. `cfg/dcl` is the only authoritative declarative-state source.
2. `src/rec` is the sole reconciliation/compile bridge into executable artifacts.
3. `src/run` executes plans without embedding desired-state definitions.
4. `utl/pla` is explicitly sandbox/planning-only and non-authoritative for runtime execution.
5. Legacy `src/dic`/`src/set` behavior is either migrated or covered by documented compatibility/deprecation guidance.

## What changed

1. Closed this architecture plan into completed state and moved it from `wow/active/` to `wow/completed/20260307-1545_declarative-reconciliation-architecture/` while keeping its original file timestamp prefix.
2. Preserved the full design/implementation history and added explicit closeout sections for final changes, verification evidence, and remaining follow-ups.
3. Captured each remaining follow-up as a new inbox item per default routing policy:
   - `wow/inbox/20260307-1545_gate-evidence-attestation-retention-followup.md`
   - `wow/inbox/20260307-1546_dic-ops-declarative-first-defaults-followup.md`
   - `wow/inbox/20260307-1547_dcl-staged-rollout-overlays-followup.md`

## What was verified

1. Prior implementation/test evidence already recorded in this plan remained valid at closeout:
   - `bash -n src/run/gate-evidence val/src/rec_run_contract_test.sh` (passed)
   - `bash val/src/rec_run_contract_test.sh` (passed)
   - `bash val/src/dic/dic_set_menu_contract_test.sh` (passed)
2. Workflow integrity check for this closeout run:
   - `bash wow/check-workflow.sh` (passed)

## What remains

1. Attestation persistence and retention conventions for strict-run gate approvals still need implementation and operator audit retrieval guidance.
   Follow-up: `wow/inbox/20260307-1545_gate-evidence-attestation-retention-followup.md`
2. `src/dic/ops` still needs declarative-first defaults with reduced direct `cfg/env/site1` sourcing behavior.
   Follow-up: `wow/inbox/20260307-1546_dic-ops-declarative-first-defaults-followup.md`
3. Rollout policy overlays under `cfg/dcl/` still need staged environment promotion support and accompanying schema/docs examples.
   Follow-up: `wow/inbox/20260307-1547_dcl-staged-rollout-overlays-followup.md`
