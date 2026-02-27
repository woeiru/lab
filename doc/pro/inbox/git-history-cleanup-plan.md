# AI-Assisted Git History Cleanup Plan

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-02-27
- Links: none

## Goal
- Reduce approximately 3000 commits to a smaller set of semantically meaningful commits (target ~1000, flexible).
- Preserve final repository state and keep full original history available.

## Strategy
- Keep existing history untouched in a backup branch/tag.
- Build a cluster proposal first (no rewriting yet).
- Review and adjust cluster plan.
- Rebuild history on a new branch.
- Validate tree equality and run tests before adopting.

## Phase 0: Safety and Scope (30-60 min)
- Create backup refs: `legacy/main` and a backup tag.
- Define rewrite scope (full history or a bounded window).
- Write a short rewrite contract: what can change vs what must remain identical.

Estimated effort: up to 0.5 day.

## Phase 1: Data Extraction (2-4 hours)
- Export commit metadata:
  - hash
  - timestamp
  - author
  - message
  - files touched
  - diff stat
- Build features per commit:
  - file overlap
  - message similarity
  - temporal distance
  - module/path affinity
- Output artifacts: `json/csv` dataset.

Estimated effort: 0.5 day.

## Phase 2: Semantic Clustering (4-8 hours)
- Use AI agents to form dynamic commit clusters.
- Heuristics:
  - high file/symbol overlap => same cluster candidate
  - tiny follow-up commits (typos/format/noise) attach to nearest semantic parent
  - outliers remain single-commit clusters
- Output artifacts:
  - `cluster_plan.md`
  - `cluster_map.json` (old commit hash -> cluster id)

Estimated effort: 0.5-1 day.

## Phase 3: Human Review (3-6 hours)
- Review largest clusters first.
- Inspect mixed-signal clusters (touch many unrelated paths).
- Adjust and approve cluster plan v2.

Estimated effort: 0.5 day.

## Phase 4: Rebuild Clean History (6-12 hours)
- Create `clean-main` branch.
- Replay cluster-by-cluster.
- Draft improved commit messages (why-focused) with AI assistance.
- Resolve entangled commit conflicts as needed.

Estimated effort: 1-1.5 days.

## Phase 5: Validation and Acceptance (2-5 hours)
- Verify final tree equality between `legacy/main` HEAD and `clean-main` HEAD.
- Run full test suite.
- Audit a random sample of rewritten commits.
- Produce go/no-go report.

Estimated effort: 0.5 day.

## Total Time Estimate
- Fast path: 2.5-3 days.
- Realistic path: 4-5 days.
- Worst case: 6-7 days.

## Parallel Agent Setup
1. Extractor agent
   - Builds feature dataset only.
2. Clustering agent
   - Proposes semantic grouping.
3. Message agent
   - Drafts concise why-focused messages per cluster.
4. Validation agent
   - Defines and runs equivalence/test checks.

Coordinator role merges outputs and resolves disagreements.

## Milestones
- M1 (Day 1): backups + dataset + first cluster proposal.
- M2 (Day 2): reviewed and approved cluster map.
- M3 (Day 3-4): `clean-main` rebuilt.
- M4 (Day 4-5): validation complete and adoption decision.

## Risk Controls
- Keep `legacy/main` long-term.
- Do not delete old refs until final validation is complete.
- Replay in batches by era/module to reduce conflict load.
- If quality is low, limit rewrite scope (for example: last 18 months).

## Practical Recommendation
- Run a pilot first on the last 300-500 commits to tune heuristics and estimate real effort.
- If pilot quality is good, scale to full history.
