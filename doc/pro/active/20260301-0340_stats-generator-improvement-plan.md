# stats generator improvement plan

## context

- `utl/doc/generators/stats` is now a standalone metrics reporter writing to `STATS.md`.
- It should complement the reference pipelines (`func`, `var`, `rdp`, `dep`, `tst`, `scp`, `err`) without duplicating their outputs.

## goals

- Provide repository health signals that are operationally useful and trendable.
- Keep output deterministic and lightweight for routine regeneration.
- Separate human summary (`STATS.md`) from machine-readable metrics (`doc/ref/stats.json`).

## current status (2026-03-01)

- current position: **phase 4 is complete**, including follow-up tuning, per-suite flaky budget controls, and profile-based default presets.
- latest implemented metric version: `3.5.0`.
- phases 1 through 4 are implemented in `utl/doc/generators/stats`.
- outputs are now:
  - human report: `STATS.md`
  - machine snapshot: `doc/ref/stats.json`
  - persistent history: `doc/ref/stats-history/<timestamp>.json`
- delivered capabilities now include:
  - phase 1: repository shape, growth deltas, hygiene checks, and quality-gate synthesis
  - phase 2: velocity/churn windows, hotspots, and trend summary from history snapshots
  - phase 3: complexity distribution/outliers and security-adjacent risk signals with deltas
  - phase 4: test-health/flaky heuristics, optional CI hard-gate extensions (`--ci-gate`, `--ci-gate-flaky`), per-suite budgets (`--flaky-suite-budget`, `STATS_FLAKY_SUITE_BUDGETS`), and profile presets (`--flaky-budget-profile`, `STATS_FLAKY_BUDGET_PROFILE`)
- latest completion checkpoint:
  - metric version: `3.5.0`
  - focused suite: `./val/core/stats_generator_test.sh` passing (`37/37`)
  - profile verification: `LAB_DIR='/home/es/lab' STATS_FLAKY_BUDGET_PROFILE='balanced' ./utl/doc/generators/stats --json --sample-tests --sample-runs=1` passing
- next open item:
  - optional expansion of profile catalog and profile-specific threshold packs (future)

## non-overlap contract

- Do not repeat full tables already generated in `doc/ref/*.md`.
- Focus on dimensions currently underrepresented:
  - growth and change velocity
  - complexity/risk distribution
  - quality/hygiene and regression signals
  - time-series trend and budget tracking

## metric set (recommended)

### 1) repository shape and growth

- Total files, directories, and total size (KB/MB).
- Per-top-level-path footprint (`bin`, `cfg`, `lib`, `src`, `val`, `utl`, `doc`).
- Delta vs previous snapshot (absolute and percent).

### 2) change velocity and churn

- Commits in last 7/30/90 days.
- File churn by path (adds/deletes) for same windows.
- Top 10 churn hotspots with owner/author counts.

### 3) complexity and maintainability risk

- Function length distribution (p50/p90/max lines).
- Long-function count over thresholds (e.g., 80/120/150 lines).
- Nesting/outlier approximations where feasible in bash scripts.

### 4) test health (beyond mapping)

- Last test run status summary and total duration (if available).
- Test runtime trend from snapshots.
- Flaky candidate list (same suite re-run variance, optional).

### 5) hygiene and compliance signals

- `bash -n` pass/fail counts on targeted scripts.
- Optional shellcheck finding counts (if shellcheck installed).
- Executable bit anomalies for scripts expected to be executable.

### 6) security-adjacent static signals

- Potential secret-pattern hits (high-signal regex set, excluding docs).
- Risky shell usage counts (`eval`, unsafe unquoted expansions heuristics).
- New risky findings since last snapshot.

### 7) duplication indicators

- Duplicate function names across modules.
- Near-duplicate block count heuristic for long copied segments.

## output design

### human output: `STATS.md`

- concise summary with sections:
  - overview
  - trend highlights
  - top risks
  - quality gates status (`ok`, `warn`, `fail`)
- keep to compact tables and short bullet highlights.

### machine output: `doc/ref/stats.json`

- stable schema for CI/automation consumption.
- include timestamp, git ref, and metric version.
- store previous snapshots in `doc/ref/stats-history/<timestamp>.json`.

## thresholds and budgets

- Define per-metric budgets and status levels:
  - `ok`: within expected bounds
  - `warn`: drift detected, attention needed
  - `fail`: regression threshold exceeded
- Start with soft warnings, then enable hard CI gating for severe regressions only.

## rollout plan

### phase 1 (quick wins)

- Repo shape + growth deltas.
- Syntax/hygiene checks (`bash -n`, executable bit checks).
- Baseline `STATS.md` + `doc/ref/stats.json` generation.

### phase 2

- Git velocity/churn windows and hotspots.
- Trend history snapshots and diff summaries.

### phase 3

- Complexity distribution and outlier reporting.
- Security-adjacent static signals and delta detection.

### phase 4

- Optional flaky-test heuristics.
- CI budget enforcement with explicit fail criteria.

## implementation notes

- Keep `stats` explicit and opt-in in orchestrator (`./utl/doc/run_all_doc.sh stats`).
- Prefer deterministic ordering to reduce diff noise.
- Ensure fallbacks when optional tools are missing (e.g., shellcheck).
- Keep runtime bounded; heavy analyses should be cacheable or optional flags.

## success criteria

- `STATS.md` provides clear health insight in under 1 minute of reading.
- `doc/ref/stats.json` is stable enough for CI automation and trend dashboards.
- Regressions are visible early without duplicating existing ref generator outputs.

## continuation (phase 3 kickoff)

### scope for next implementation pass

- implement complexity distribution and outlier detection in `utl/doc/generators/stats`.
- implement security-adjacent static signals with deterministic, low-noise heuristics.
- keep runtime bounded so `./utl/doc/run_all_doc.sh stats` remains practical for routine local use.

### explicit non-goals for this pass

- no flaky-test rerun heuristic yet (reserved for phase 4).
- no hard CI failure policy changes yet; only emit quality-gate signals.
- no overlap with generated reference content already covered by `func`, `dep`, `tst`, or `err` outputs.

### phase 3 work breakdown

1. complexity metrics collection
   - collect function-length distribution (p50, p90, max).
   - count threshold breaches for `>80`, `>120`, and `>150` lines.
   - emit top 10 longest functions with module path for triage.
2. risk-pattern scanning
   - scan extensionless bash modules plus `.sh` scripts in `val/` and `utl/`.
   - count occurrences of risky constructs: `eval`, backticks, and broad `chmod 777` patterns.
   - add high-signal secret pattern checks (token/password/private key) excluding `doc/`.
3. delta and trend integration
   - compare new risk counts against previous `doc/ref/stats.json` snapshot.
   - expose `new_findings` and `resolved_findings` counts for phase 3 signals.
   - append phase 3 fields into history snapshots without breaking older reads.
4. report rendering updates
   - add concise phase 3 blocks to `STATS.md` under `Top Risks` and `Quality Gates Status`.
   - add stable JSON keys under new top-level sections: `complexity` and `risk_signals`.
   - keep deterministic ordering for all arrays/tables.

### proposed json schema extension (metric_version 3.0.0)

- `complexity`:
  - `function_length`: `p50_lines`, `p90_lines`, `max_lines`
  - `threshold_counts`: `gt_80`, `gt_120`, `gt_150`
  - `top_longest`: array of `{ function, file, lines }`
- `risk_signals`:
  - `counts`: `eval`, `backticks`, `chmod_777`, `secret_patterns`
  - `delta_vs_previous`: same keys with signed integer deltas
  - `new_findings`: integer
  - `resolved_findings`: integer

### quality gate extension (phase 3)

- add `complexity` gate:
  - `ok`: `gt_150 == 0`
  - `warn`: `gt_150 in [1, 3]`
  - `fail`: `gt_150 > 3`
- add `risk_signals` gate:
  - `ok`: no new secret-pattern findings and `eval` delta <= 0
  - `warn`: non-secret risky deltas increase
  - `fail`: any new secret-pattern finding
- keep existing synthesis model, but include new gates in overall status.

### test and verification plan

1. syntax checks
   - `bash -n utl/doc/generators/stats`
   - `bash -n val/core/stats_generator_test.sh`
2. focused tests
   - extend `val/core/stats_generator_test.sh` to assert phase 3 markdown/json sections.
   - run `./val/core/stats_generator_test.sh`.
3. category confidence
   - run `./val/run_all_tests.sh core` if test updates span core helpers.

### execution order

1. add collectors (complexity + risk signals) with isolated helpers.
2. integrate serialization and markdown sections.
3. update tests for schema + rendering.
4. run validation sequence and capture results in this plan.

### completion checkpoint template

- implementation status: `not started | in progress | complete`
- metric version after change: `<value>`
- commands run:
  - `<command>` -> `pass|fail`
- follow-up items for phase 4:
  - flaky-test heuristic design
  - optional CI hard gate wiring

### completion checkpoint (2026-03-01)

- implementation status: `complete`
- metric version after change: `3.0.0`
- commands run:
  - `bash -n utl/doc/generators/stats` -> `pass`
  - `bash -n val/core/stats_generator_test.sh` -> `pass`
  - `./val/core/stats_generator_test.sh` -> `pass` (20/20)
- follow-up items for phase 4:
  - flaky-test heuristic design
  - optional CI hard gate wiring

## phase 4 follow-up execution (2026-03-01)

### delivered now

- tightened secret-pattern heuristic to reduce false positives:
  - high-signal direct matches retained (`PRIVATE KEY`, `AKIA...`)
  - sensitive-assignment detection now skips env/indirect references (`$VAR`, `${...}`, `$(...)`, backticks)
  - placeholder-like values are filtered (`example`, `dummy`, `changeme`, etc.)
- optional CI hard gate wiring implemented via `--ci-gate`:
  - hard-fail criteria: syntax gate fail, or risk-signals gate fail
  - command exits `2` when hard criteria fail
  - outputs are still generated before gate enforcement in `--update` mode

### flaky-test heuristic design (captured for next implementation)

- add optional `test_health` block to `doc/ref/stats.json` with:
  - `last_run`: status, duration_seconds, timestamp
  - `history_trend`: p50/p90 duration for recent snapshots
  - `flaky_candidates`: suites with status oscillation or duration variance spikes
- acquisition strategy:
  - consume persisted validation logs when available
  - do not run full validation by default inside `stats`
  - expose opt-in mode for active flaky sampling

### verification (follow-up pass)

- `bash -n utl/doc/generators/stats`
- `bash -n val/core/stats_generator_test.sh`
- `./val/core/stats_generator_test.sh`

### completion checkpoint (phase 4 follow-up)

- implementation status: `complete`
- metric version after change: `3.1.0`
- commands run:
  - `bash -n utl/doc/generators/stats` -> `pass`
  - `bash -n val/core/stats_generator_test.sh` -> `pass`
  - `./val/core/stats_generator_test.sh` -> `pass` (21/21)
  - `LAB_DIR='/home/es/lab' ./utl/doc/generators/stats --update --ci-gate` -> `pass`
- follow-up items still open:
  - flaky-test heuristic implementation (design captured)

## phase 4 execution (flaky-test heuristic implementation) (2026-03-01)

### delivered now

- implemented `test_health` metrics collection in `utl/doc/generators/stats`:
  - `last_run`: suite, status, duration_seconds, timestamp
  - `history_trend`: points, p50_duration_seconds, p90_duration_seconds
  - `flaky_candidates`: status oscillation and duration variance heuristics
- wired optional active flaky sampling:
  - `--sample-tests` enables opt-in suite sampling
  - `--sample-runs=N` controls repetitions per suite (default `3`)
  - default sampled suite is `val/core/agents_md_test.sh` (overridable via `STATS_TEST_SAMPLE_SUITES`)
- updated `STATS.md` rendering with a new `## Test Health` section.
- extended validation assertions in `val/core/stats_generator_test.sh` for the new JSON/markdown blocks and CLI help option.

### verification (implementation pass)

- `bash -n utl/doc/generators/stats`
- `bash -n val/core/stats_generator_test.sh`
- `./val/core/stats_generator_test.sh`
- `LAB_DIR='/home/es/lab' ./utl/doc/generators/stats --json --sample-tests --sample-runs=1`

### completion checkpoint (phase 4 implementation)

- implementation status: `complete`
- metric version after change: `3.2.0`
- commands run:
  - `bash -n utl/doc/generators/stats` -> `pass`
  - `bash -n val/core/stats_generator_test.sh` -> `pass`
  - `./val/core/stats_generator_test.sh` -> `pass` (25/25)
  - `LAB_DIR='/home/es/lab' ./utl/doc/generators/stats --json --sample-tests --sample-runs=1` -> `pass`
- follow-up items still open:
  - optional CI hard gate extension for flaky-test severity thresholds (future)

## phase 4 execution (flaky tuning + ci hard gate extension) (2026-03-01)

### delivered now

- tuned flaky-candidate thresholds to reduce noise and improve signal quality:
  - minimum samples increased to `4`
  - duration variance now requires both `>=4s` spread and `>=2.5x` max/min ratio
  - deterministic policy constants added for future budget tuning
- extended quality-gate synthesis with a new `test_health` gate:
  - `fail`: status oscillation candidates meet threshold or total flaky candidates exceed fail budget
  - `warn`: duration-variance candidates exceed warning threshold
  - `ok`: no threshold breach
- implemented optional CI hard gate enforcement for flaky severity:
  - new CLI option `--ci-gate-flaky` (implies `--ci-gate`)
  - hard-fail now includes `test_health=fail` when this option is used
- enriched machine output schema (`metric_version 3.3.0`) under `test_health`:
  - `flaky_summary`
  - `flaky_policy`
  - existing `flaky_candidates` retained
- updated human output with flaky-candidate summary and test-health gate line.
- expanded `val/core/stats_generator_test.sh` assertions for the new CLI option and schema keys.

### verification (tuning pass)

- `bash -n utl/doc/generators/stats`
- `bash -n val/core/stats_generator_test.sh`
- `./val/core/stats_generator_test.sh`
- `LAB_DIR='/home/es/lab' ./utl/doc/generators/stats --update --ci-gate-flaky`

### completion checkpoint (phase 4 tuning + ci gate)

- implementation status: `complete`
- metric version after change: `3.3.0`
- commands run:
  - `bash -n utl/doc/generators/stats` -> `pass`
  - `bash -n val/core/stats_generator_test.sh` -> `pass`
  - `./val/core/stats_generator_test.sh` -> `pass` (28/28)
  - `LAB_DIR='/home/es/lab' ./utl/doc/generators/stats --update --ci-gate-flaky` -> `pass`
- follow-up items still open:
  - optional per-suite flaky budgets configurable via CLI/env (future)

## phase 4 execution (per-suite flaky budgets via cli/env) (2026-03-01)

### delivered now

- implemented per-suite flaky budget controls in `utl/doc/generators/stats`:
  - new CLI option: `--flaky-suite-budget=SUITE:OSC:VAR` (repeatable)
  - new env option: `STATS_FLAKY_SUITE_BUDGETS` (comma-separated entries using same `SUITE:OSC:VAR` format)
  - budgets are applied to flaky gate synthesis using over-budget counters (instead of raw candidate totals)
- extended machine output schema (`metric_version 3.4.0`) under `test_health`:
  - `flaky_summary` now includes over-budget counters
  - `flaky_policy` now includes `suite_budgets_configured`
  - new `suite_budgets` array emitted with configured per-suite budgets
- updated human output (`STATS.md`) test-health and gate signal lines to show over-budget totals.
- expanded `val/core/stats_generator_test.sh` coverage for:
  - new CLI help option
  - invalid per-suite budget argument handling
  - new JSON keys (`suite_budgets`, `over_budget_total`)

### verification (budget pass)

- `bash -n utl/doc/generators/stats`
- `bash -n val/core/stats_generator_test.sh`
- `./val/core/stats_generator_test.sh`
- `LAB_DIR='/home/es/lab' STATS_FLAKY_SUITE_BUDGETS='val/core/agents_md_test.sh:1:1' ./utl/doc/generators/stats --json --sample-tests --sample-runs=1`

### completion checkpoint (phase 4 budgets)

- implementation status: `complete`
- metric version after change: `3.4.0`
- commands run:
  - `bash -n utl/doc/generators/stats` -> `pass`
  - `bash -n val/core/stats_generator_test.sh` -> `pass`
  - `./val/core/stats_generator_test.sh` -> `pass` (32/32)
  - `LAB_DIR='/home/es/lab' STATS_FLAKY_SUITE_BUDGETS='val/core/agents_md_test.sh:1:1' ./utl/doc/generators/stats --json --sample-tests --sample-runs=1` -> `pass`
- follow-up items still open:
  - optional per-suite default budget presets by profile (future)

## phase 4 execution (profile-based default suite budgets) (2026-03-01)

### delivered now

- implemented default per-suite flaky budget presets by profile in `utl/doc/generators/stats`:
  - new CLI option: `--flaky-budget-profile=PROFILE`
  - new env option: `STATS_FLAKY_BUDGET_PROFILE`
  - supported profiles: `none`, `strict`, `balanced`, `relaxed`
- profile application is default-oriented and deterministic:
  - profile budgets are applied as defaults only (do not overwrite explicit per-suite budget entries)
  - explicit entries from `--flaky-suite-budget` and `STATS_FLAKY_SUITE_BUDGETS` still take precedence
- extended outputs under test-health policy:
  - `STATS.md` now shows a `Budget profile` row in the `## Test Health` section
  - `doc/ref/stats.json` now includes `test_health.flaky_policy.budget_profile`
- expanded focused validation coverage in `val/core/stats_generator_test.sh` for:
  - new CLI help option
  - invalid profile handling
  - env-driven profile application
  - explicit per-suite override behavior over profile defaults

### verification (profile preset pass)

- `bash -n utl/doc/generators/stats`
- `bash -n val/core/stats_generator_test.sh`
- `./val/core/stats_generator_test.sh`
- `LAB_DIR='/home/es/lab' STATS_FLAKY_BUDGET_PROFILE='balanced' ./utl/doc/generators/stats --json --sample-tests --sample-runs=1`

### completion checkpoint (phase 4 profile presets)

- implementation status: `complete`
- metric version after change: `3.5.0`
- commands run:
  - `bash -n utl/doc/generators/stats` -> `pass`
  - `bash -n val/core/stats_generator_test.sh` -> `pass`
  - `./val/core/stats_generator_test.sh` -> `pass` (37/37)
  - `LAB_DIR='/home/es/lab' STATS_FLAKY_BUDGET_PROFILE='balanced' ./utl/doc/generators/stats --json --sample-tests --sample-runs=1` -> `pass`
- follow-up items still open:
  - optional expansion of profile catalog and profile-specific threshold packs
