# Dev OAR/OAD Removal Native OpenCode Alignment

- Status: completed
- Owner: es
- Started: 2026-03-04
- Updated: 2026-03-04 23:04
- Links: lib/ops/dev, cfg/core/lzy, val/lib/ops/dev_test.sh, doc/ref/functions.md, doc/ref/error-handling.md, val/core/initialization/orc_test.sh

## Retroactive Capture

- Origin: This started from debugging an auth/login issue where an Antigravity account appeared after add/login and then disappeared.
- Escalation reason: Investigation showed local custom account management commands (`dev_oar`, `dev_oad`) were part of the workflow around denylist/reconcile behavior, and the user requested full removal in favor of native OpenCode account management.
- Design:
  1. Are there meaningful alternatives for how to solve this? Yes (retain and patch custom commands, disable them, or remove them entirely).
  2. Will other code or users depend on the shape of the output? Yes (public command surface, lazy-load map, tests, and docs).
  - Design: required
- Work so far:
  - Removed `dev_oar` and `dev_oad` function implementations from `lib/ops/dev`.
  - Removed `dev_oar` and `dev_oad` from `cfg/core/lzy` lazy-load map.
  - Removed related tests and test registration from `val/lib/ops/dev_test.sh`.
  - Removed stale function and error-reference entries from `doc/ref/functions.md` and `doc/ref/error-handling.md`.
  - Ran validation for syntax and test suites.

## Progress Checkpoint

- Done:
  - Runtime and lazy-load references for `dev_oar` and `dev_oad` are removed.
  - Validation passed for edited shell files and test suites.
- In-flight:
  - None.
- Blockers:
  - None.
- Next steps:
  1. Close this captured item to completed with final evidence.
  2. Run `bash wow/check-workflow.sh` and resolve any structural issues.
  3. Commit the removal and workflow updates.
- Context:
  - Branch: `master`.
  - Verification already run:
    - `bash -n lib/ops/dev cfg/core/lzy val/lib/ops/dev_test.sh`
    - `./val/lib/ops/dev_test.sh` (`52/52` pass)
    - `./val/core/initialization/orc_test.sh` (`8/8` pass)

## Execution Plan

### Phase 1 - Workflow close preparation

Capture final outcome details and align this item with completed-state requirements.

Completion criterion: this file has all required final sections and can be moved to completed.

### Phase 2 - Workflow structure validation

Run workflow validation and fix any checker-reported structural issues.

Completion criterion: `bash wow/check-workflow.sh` passes.

### Phase 3 - Finalize and commit

Commit all scoped code/test/doc/workflow changes for this removal decision.

Completion criterion: repository contains one commit documenting the removal and verification.

## Exit Criteria

- `dev_oar` and `dev_oad` are no longer available through runtime codepaths or lazy stubs.
- Validation evidence is recorded and workflow artifact is in completed state.
- A commit exists that captures both implementation and workflow documentation updates.

## What changed

- Removed `dev_oar` and `dev_oad` implementations from `lib/ops/dev`.
- Removed `dev_oar` and `dev_oad` lazy stubs from `cfg/core/lzy`.
- Removed related function-existence checks and dedicated test cases from `val/lib/ops/dev_test.sh`.
- Removed reference entries for both commands from `doc/ref/functions.md` and `doc/ref/error-handling.md`.
- Captured and closed this work item through `doc/pro` workflow state.

## What was verified

- Syntax checks passed:
  - `bash -n lib/ops/dev cfg/core/lzy val/lib/ops/dev_test.sh`
- Test suites passed:
  - `./val/lib/ops/dev_test.sh` (`52/52` pass)
  - `./val/core/initialization/orc_test.sh` (`8/8` pass)

## What remains

- No implementation follow-up required for this removal request.
- Optional operational follow-up: remove stale entries from local `~/.config/opencode/antigravity-account-denylist.txt` if no longer needed for native workflow.
