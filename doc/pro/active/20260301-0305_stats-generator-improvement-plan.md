# stats generator improvement plan

## context

- `utl/doc/generators/stats` is now a standalone metrics reporter writing to `STATS.md`.
- It should complement the reference pipelines (`func`, `var`, `rdp`, `dep`, `tst`, `scp`, `err`) without duplicating their outputs.

## goals

- Provide repository health signals that are operationally useful and trendable.
- Keep output deterministic and lightweight for routine regeneration.
- Separate human summary (`STATS.md`) from machine-readable metrics (`doc/ref/stats.json`).

## current status (2026-03-01)

- phases 1 and 2 are implemented in `utl/doc/generators/stats`.
- outputs are now:
  - human report: `STATS.md`
  - machine snapshot: `doc/ref/stats.json`
  - persistent history: `doc/ref/stats-history/<timestamp>.json`
- phase 1 delivered:
  - repository shape totals and top-level footprint (`bin`, `cfg`, `lib`, `src`, `val`, `utl`, `doc`)
  - deltas vs previous snapshot (absolute and percent)
  - hygiene checks (`bash -n` and executable-bit anomalies)
  - quality gates synthesis (`ok`/`warn`/`fail`)
- phase 2 delivered:
  - commit velocity windows (7/30/90 days)
  - churn by path for the same windows
  - top churn hotspots (90d) with author counts
  - trend summary from history snapshots (up to last 10 points)
- validation status:
  - `bash -n utl/doc/generators/stats` passing
  - `bash -n val/core/stats_generator_test.sh` passing
  - `./val/core/stats_generator_test.sh` passing (15/15)
- phase 3 and phase 4 are intentionally not started yet.

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
