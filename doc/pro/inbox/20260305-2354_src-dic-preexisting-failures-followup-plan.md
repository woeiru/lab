# Source DIC Pre-existing Failures Follow-up Plan

- Status: inbox
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-05 23:57:36
- Links: val/src/dic/dic_framework_test.sh, val/src/dic/dic_integration_test.sh, val/src/dic/dic_phase1_completion_test.sh, val/run_all_tests.sh, doc/pro/completed/20260305-2356_src-set-bootstrapper-logging-alignment/20260305-2249_src-set-bootstrapper-logging-alignment-plan.md

## Goal

Resolve known pre-existing `src` DIC test failures so category-level validation
is green at default project settings.

## Context

1. During `src/set` bootstrapper/logging alignment verification, `./val/run_all_tests.sh src` reported failures in `dic_framework_test`, `dic_integration_test`, and `dic_phase1_completion_test`.
2. These failures predate and are outside the scoped implementation changes for
   the `src/set` alignment item.
3. The alignment contract test added for `src/set` passed, so follow-up should
   focus on existing DIC suite assumptions and regressions.

## Scope

1. Reproduce failing DIC tests in isolation and capture root-cause categories.
2. Distinguish true runtime regressions from brittle assertion or logging-level
   coupling issues.
3. Implement fixes and update tests/docs as needed.
4. Re-run `./val/run_all_tests.sh src` to confirm the category passes.

## Risks

1. DIC failures may involve shared bootstrap/logging behavior with wide blast
   radius.
2. Test-only fixes could mask real runtime defects if not paired with behavior
   validation.

## Next Step

Move this follow-up to `doc/pro/queue/` for triage and prioritization.
