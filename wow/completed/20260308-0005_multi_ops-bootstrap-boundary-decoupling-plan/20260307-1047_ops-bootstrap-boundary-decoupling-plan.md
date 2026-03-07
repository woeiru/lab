# Ops Bootstrap Boundary Decoupling Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-08 00:05
- Links: wow/completed/20260307-1047_lib-architecture-review/20260307-0921_lib-architecture-review-result.md, doc/ref/module-dependencies.md, doc/arc/00-architecture-overview.md, bin/ini, bin/orc

## Goal

Reduce cross-layer coupling between ops modules and bootstrap/orchestration
surfaces by introducing clearer boundary adapters.

## Context

1. The architecture review identified dependency-direction pressure around
   runtime and bootstrap boundaries.
2. Cross-layer imports increase fragility and make phased refactors harder.
3. Decoupling requires a design pass to avoid breaking initialization and lazy
   load expectations.
4. `bin/ini` owns bootstrap profile resolution and exports bootstrap toggles
   (`LAB_OPS_LAZY_LOAD`, `LAB_GEN_LAZY_LOAD`) before delegating component setup.
5. `bin/orc` owns component loading order per profile (`interactive` loads
   aliases + ops/gen; `deployment` loads env + src aux only).
6. `src/dic/ops` currently hard-couples execution to bootstrap globals
   (`LIB_OPS_DIR`) and emits direct guidance to run `source bin/ini` when
   missing.
7. `src/dic/ops` also attempts to source `cfg/env/site1` during load, which
   binds DIC behavior to a specific environment baseline.
8. Existing architecture docs already define DIC and bootstrap as separate
   runtime surfaces, so adapter-first decoupling can align implementation to
   documented boundaries.

## Scope

1. Identify boundary violations and classify by migration complexity.
2. Propose adapter/interface pattern for decoupled access paths.
3. Define migration sequence with compatibility checkpoints.
4. Update architecture docs and validation coverage for new boundaries.

## Risks

1. Boundary changes can break startup semantics if load-order assumptions are missed.
2. Over-abstraction can increase indirection and debugging friction.
3. Incomplete migration can leave dual-path confusion in docs and runtime behavior.

## Next Step

Start Phase 1 design baseline and publish a concrete boundary-decoupling design
artifact before any implementation changes.

## Triage Decision

- Why now: The architecture review already surfaced concrete bootstrap-boundary pressure, so queuing this now keeps refactor sequencing aligned before more ops/bootstrap changes stack up.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: This work defines boundary adapters and migration sequencing that affect module contracts, load behavior, and downstream documentation expectations.

## Documentation Impact

- Docs: required
- Target docs (initial): `doc/arc/00-architecture-overview.md`,
  `doc/arc/04-dependency-injection.md`, `doc/ref/module-dependencies.md`,
  `doc/ref/functions.md`, `doc/ref/test-coverage.md`

## Execution Plan

1. [done] Phase 1 - Boundary decoupling design baseline.
   Completion criterion: A design artifact is added to this item documenting
   interfaces, constraints, trade-offs, and the chosen migration approach.
2. [done] Phase 2 - Adapter and boundary implementation.
   Completion criterion: Target bootstrap/ops boundary adapters are implemented
   with no public contract drift across touched entrypoints.
3. [done] Phase 3 - Validation and convergence evidence.
   Completion criterion: Required syntax/tests/docs verification outputs are
   recorded in this item and all declared checks pass.

## Verification Plan

1. Run `bash -n` on every edited Bash source file in the touch-set.
2. Run nearest module/category tests for touched bootstrap and boundary modules,
   including the relevant `val/` suites for changed files.
3. Verify documentation targets in this item are updated before closeout.
4. If structural/public surfaces change, run `./utl/ref/run_all_doc.sh` and
   record the command result in the workflow evidence.
5. Run `bash wow/check-workflow.sh` after workflow-document updates.

## Exit Criteria

1. Boundary adapter contract is documented and accepted in this active item.
2. Implementation preserves initialization/lazy-load behavior and public
   interfaces across touched surfaces.
3. Validation evidence and documentation updates are captured with passing
   results and no open blockers.

## Phase 1 Design Deliverable

## Interfaces (Boundary Contract)

1. Bootstrap boundary (`bin/ini` -> `bin/orc`):
   `bin/ini` may select profile and invoke orchestrator entrypoints, but must
   not contain direct ops-module dispatch logic.
2. Orchestrator boundary (`bin/orc` -> loaders):
   `bin/orc` may load component sets and register lazy stubs, but module
   sourcing behavior should be exposed through loader helpers, not copied by
   downstream callers.
3. DIC runtime boundary (`src/dic/ops` -> lib modules):
   DIC should consume a runtime-path adapter for ops/env resolution instead of
   embedding fixed bootstrap assumptions (for example direct `cfg/env/site1`
   sourcing).
4. Environment boundary (`cfg/env/*`):
   environment selection should remain a policy input, while DIC performs
   optional sourcing through adapter-provided paths.

## Constraints

1. Preserve existing `ops MODULE FUNCTION ...` command semantics and return
   behavior.
2. Preserve bootstrap profile behavior and lazy-load toggle contracts.
3. Avoid module-level behavior changes in `lib/ops/*` during boundary
   extraction.
4. Keep migration backward-compatible for environments that still rely on
   `source bin/ini` setup flow.

## Trade-offs

1. Fast inline edits in `src/dic/ops` are lower effort but keep long-term
   coupling hidden.
2. Adapter extraction adds one indirection layer but creates explicit contracts
   and testable boundaries.
3. Full bootstrap redesign would reduce technical debt further but exceeds the
   scope/risk profile for this wave.

## Chosen Approach

1. Introduce a runtime boundary adapter for DIC path/environment resolution.
2. Replace DIC direct assumptions (`cfg/env/site1`, strict bootstrap wording)
   with adapter-mediated resolution + compatibility fallbacks.
3. Keep `bin/ini` and `bin/orc` execution order unchanged in this wave; scope
   implementation to coupling seams and interface contracts.
4. Verify no public command-surface drift, then update architecture/reference
   docs in the same workflow item.

## Progress Log

1. Completed Phase 1 design baseline in this item with explicit interfaces,
   constraints, trade-offs, and chosen migration approach.
2. Started Phase 2 by locking initial implementation touch-set:
   `src/dic/ops`, `src/dic/lib/*` (if adapter helper is added), and targeted
   docs (`doc/arc/00-architecture-overview.md`,
   `doc/arc/04-dependency-injection.md`, `doc/ref/module-dependencies.md`).
3. Next implementation action is to extract and wire adapter-backed DIC runtime
   resolution while preserving existing command behavior.
4. Implemented runtime boundary adapter file `src/dic/lib/runtime` and wired
   `src/dic/ops` to consume adapter-backed lab root, ops/gen path, and
   environment config candidate resolution.
5. Replaced direct `LIB_OPS_DIR` and `cfg/env/site1` assumptions in DIC
   execution paths with runtime adapter lookups plus compatibility fallback
   behavior.
6. Updated architecture docs to describe the runtime adapter boundary:
   `doc/arc/00-architecture-overview.md`,
   `doc/arc/04-dependency-injection.md`.
7. Regenerated reference documentation after structural boundary changes via
   `./utl/ref/run_all_doc.sh`.
8. Completed workflow-plan validation gate with `bash wow/check-workflow.sh`
   after evidence updates.
9. Validated standalone DIC runtime fallback behavior without bootstrap
   exports: `env -i HOME="$HOME" PATH="$PATH" bash -lc '"/home/es/lab/src/dic/ops" --list'`
   returned exit code `0` and listed ops modules.

## Verification Evidence

1. Syntax checks:
   - `bash -n src/dic/ops` -> pass
   - `bash -n src/dic/lib/runtime` -> pass
2. Nearest DIC regression suites:
   - `bash val/src/dic/dic_phase1_completion_test.sh` -> pass (8/8)
   - `bash val/src/dic/dic_basic_test.sh` -> pass (9/9)
3. Structural/reference doc regeneration:
   - `./utl/ref/run_all_doc.sh` -> pass (7/7 generators)
4. Workflow checker:
   - `bash wow/check-workflow.sh` -> pass
5. Standalone fallback sanity check:
   - `env -i HOME="$HOME" PATH="$PATH" bash -lc '"/home/es/lab/src/dic/ops" --list'` -> pass (exit `0`)

## What changed

1. Added runtime boundary adapter `src/dic/lib/runtime` for lab root, ops/gen
   directory, and environment candidate resolution.
2. Rewired `src/dic/ops` to consume adapter-mediated runtime paths and env
   sourcing, replacing fixed `cfg/env/site1` and direct bootstrap assumptions.
3. Updated architecture docs for the new DIC runtime boundary behavior:
   `doc/arc/00-architecture-overview.md`,
   `doc/arc/04-dependency-injection.md`.
4. Regenerated canonical reference documentation after structural dependency
   updates in DIC runtime surfaces.

## What was verified

1. `bash -n src/dic/ops` -> pass
2. `bash -n src/dic/lib/runtime` -> pass
3. `bash val/src/dic/dic_phase1_completion_test.sh` -> pass (8/8)
4. `bash val/src/dic/dic_basic_test.sh` -> pass (9/9)
5. `./utl/ref/run_all_doc.sh` -> pass (7/7 generators)
6. `env -i HOME="$HOME" PATH="$PATH" bash -lc '"/home/es/lab/src/dic/ops" --list'`
   -> pass (exit `0`)
7. `bash wow/check-workflow.sh` -> pass
8. Docs: updated (`doc/arc/00-architecture-overview.md`,
   `doc/arc/04-dependency-injection.md`, `doc/ref/functions.md`,
   `doc/ref/module-dependencies.md`, `doc/ref/test-coverage.md`,
   `doc/ref/error-handling.md`, `doc/ref/reverse-dependecies.md`,
   `doc/ref/scope-integrity.md`, `doc/ref/variables.md`)

## What remains

1. No mandatory follow-up items identified for this closeout.
