# DIC Debug Verbosity Coupling Follow-up Plan

- Status: inbox
- Owner: es
- Started: 2026-03-05
- Updated: 2026-03-05 02:38
- Links: val/src/dic/dic_basic_test.sh, val/src/dic/dic_integration_test.sh, val/src/dic/dic_phase1_completion_test.sh, src/dic/ops, lib/gen/aux, lib/core/log, cfg/core/ric, doc/pro/completed/20260305-0235_logging-architectural-restructure/20260303-2246_logging-architectural-restructure-plan.md, doc/pro/completed/20260305-0235_logging-visual-output-redesign/20260303-2247_logging-visual-output-redesign-plan.md

## Goal

Stabilize DIC validation by removing coupling between DIC test pass/fail outcomes
and logging verbosity configuration, so DIC correctness is validated regardless
of terminal log level defaults.

## Context

1. DIC tests in `val/src/dic/*` currently assert on debug-string presence such as
   `Executing`, `Extracted parameters`, and `Using sanitized hostname`.
2. After the logging architectural/visual projects, debug emission is correctly
   gated by `_log_level_permits` and `LAB_LOG_LEVEL` (`normal` by default).
3. At default verbosity, DIC tests can report false negatives even when command
   execution and parameter injection behavior are correct.
4. Reproduced behavior:
   - `./val/run_all_tests.sh dic` fails selected DIC tests at default settings.
   - `LAB_LOG_LEVEL_AUX=debug ./val/run_all_tests.sh dic` passes all DIC tests.

## Scope

1. Update DIC test assertions to validate functional outcomes and structured
   behavior contracts without depending on debug-terminal visibility.
2. Where debug text checks remain necessary, set explicit per-test logging
   preconditions (for example `LAB_LOG_LEVEL_AUX=debug`) inside the test scope.
3. Audit DIC test scripts for counter/reporting consistency (`TESTS_TOTAL`,
   `TESTS_PASSED`, and displayed pass-rate math) to avoid misleading summaries.
4. Document expected debug-gating behavior in DIC test notes/README context.

## Risks

1. Over-relaxing assertions could hide real DIC regressions if behavioral checks
   are replaced with weak output checks.
2. Test-local verbosity overrides can mask global configuration drift if not
   clearly scoped and documented.
3. Mixed legacy and modern DIC test expectations may create temporary confusion
   until all scripts align on the same pass criteria.

## Next Step

Triage this inbox follow-up into `doc/pro/queue/` with a focused execution plan
that updates DIC tests first, then re-validates with both default and explicit
debug verbosity settings.
