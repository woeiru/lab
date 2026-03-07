# UTL Doc Legacy Reference Cleanup Follow-up

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07 11:04
- Links: wow/completed/20260307-0930_utl-ref-rename-plan/20260307-0928_utl-ref-rename-plan.md, doc/ref/stats/actual.md, wow/

## Goal

- Decide whether historical workflow/state artifacts should preserve old `utl/doc` paths or be normalized to `utl/ref` for consistency.

## Scope

- Inventory remaining `utl/doc` references in historical-only surfaces (`wow/`, archived stats snapshots, and past generated docs).
- Classify each reference as immutable history vs safe-to-normalize metadata.
- Propose a policy for future migrations so path renames do not leave ambiguous historical traces.

## Triage Decision

- Why now: this follow-up is mandatory to close the recent `utl/doc` -> `utl/ref` rename cleanly and prevent inconsistent guidance across workflow and reference docs.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes - preserve historical references verbatim vs normalize selected metadata surfaces.
  2. Will other code or users depend on the shape of the output? Yes - migration tooling, workflow checks, and contributors rely on one consistent policy.
- Design: required
- Justification: this work sets policy across multiple surfaces with viable alternatives and downstream dependencies, so design work is required.

## Design Record

- Interfaces:
  - Input surfaces: `wow/{active,queue,completed,dismissed}`, `doc/ref/stats/*.json`, `doc/ref/stats/actual.md`, and `STATS.md`.
  - Classification labels: `immutable history` and `safe-to-normalize metadata`.
  - Decision outputs: `preserved` or `normalized` per inventory entry.
- Constraints:
  - Preserve timestamped workflow archives in `wow/completed/` and `wow/dismissed/` as historical records.
  - Preserve fidelity of timestamped stats snapshots under `doc/ref/stats/*.json`.
  - Keep operational surfaces (`bin/`, `lib/`, `src/`, `cfg/`, `val/`) free of legacy `utl/doc` references.
- Trade-offs:
  - Preserving historical records keeps provenance accurate but leaves mixed path vocabulary.
  - Normalizing legacy text improves consistency but can rewrite historical evidence and add churn.
- Chosen approach:
  - Treat archived workflow docs and timestamped stats snapshots as immutable history and preserve them verbatim.
  - Treat rolling generated summaries (`doc/ref/stats/actual.md`, `STATS.md`) as safe-to-normalize metadata, but only via generator-level policy changes (not manual back-edits).
  - Use explicit follow-up routing only when generator-level normalization is selected as mandatory work.

## Inventory and Classification

| Surface | Files with `utl/doc` | Match count | Classification | Action state | Notes |
|---|---:|---:|---|---|---|
| `wow/active` | 1 | 6 | safe-to-normalize metadata | preserved | Current active item intentionally references legacy token for migration policy context. |
| `wow/queue` | 0 | 0 | n/a | n/a | No legacy references found. |
| `wow/completed` | 16 | 194 | immutable history | preserved | Archived plans/closeouts recording historical command surfaces. |
| `wow/dismissed` | 1 | 17 | immutable history | preserved | Archived dismissed record using historical command paths. |
| `doc/ref/stats/*.json` | 30 | 30 | immutable history | preserved | Timestamped archived snapshots contain historical hotspot paths. |
| `doc/ref/stats/actual.md` | 1 | 1 | safe-to-normalize metadata | preserved | Rolling generated output currently reflects historical churn window path text. |
| `STATS.md` | 1 | 1 | safe-to-normalize metadata | preserved | Rolling generated summary reflects the same historical churn signal. |

## Migration Policy

- Hard-cut operational migration rule: during path renames, all live execution surfaces must switch to the new path in one migration wave.
- Historical preservation rule: do not back-edit archived workflow records or timestamped stats snapshots solely for naming consistency.
- Generated-summary normalization rule: if path normalization is required in rolling summaries, implement it in generator logic and regenerate outputs; do not hand-edit generated artifacts.
- Closeout traceability rule: any intentional historical-path preservation must be stated explicitly in the migration closeout's "What remains" section.

## Policy Application Decision

- Final action states are now fully resolved with no undecided entries: all discovered references are marked `preserved` in this cycle.
- Reason: every current occurrence sits either in immutable history or in rolling generated output where normalization is optional and should only happen via a dedicated generator-level change.

## Handoff Outcome

- Handoff state: `no-follow-up`
- Rationale: no mandatory normalization work is required to maintain correctness or operational safety after the `utl/ref` cutover.

## Execution Plan

- Implementation and normalization steps begin only after Phase 1 is complete.
- Phase 1 - Design baseline [complete]:
  - Document policy interfaces, constraints, trade-offs, and chosen approach for handling historical `utl/doc` references.
  - Completion criterion: a `## Design Record` section exists in this item with interfaces, constraints, trade-offs, and chosen approach.
- Phase 2 - Inventory and classification [complete]:
  - Inventory remaining `utl/doc` references in `wow/`, archived stats snapshots, and generated docs, then classify each as immutable history or safe-to-normalize metadata.
  - Completion criterion: an inventory table exists and every discovered reference has exactly one classification.
- Phase 3 - Policy application decisions [complete]:
  - Resolve each classified reference into a final action state aligned with Phase 1 policy.
  - Completion criterion: every inventory entry is marked `preserved` or `normalized`, with no undecided entries.
- Phase 4 - Handoff capture [complete]:
  - Record the post-analysis handoff outcome for any remaining normalization work.
  - Completion criterion: this item includes exactly one handoff state, either `no-follow-up` or a linked queue follow-up item.

## Verification Plan

- Run `git grep -n "utl/doc" -- wow doc/ref/stats STATS.md` to confirm the final inventory and action states match observed references.
- Run `git grep -n "utl/doc" -- bin lib src cfg val` and require no matches.
- Run `bash wow/check-workflow.sh` to ensure workflow metadata and triage requirements remain valid.
- Verify all newly added links resolve to existing files.

## Exit Criteria

1. Documented policy for historical path references.
2. Agreed handling for stats snapshots and workflow archives.
3. Handoff outcome recorded as either `no-follow-up` or one linked queue follow-up item.

## What changed

- Moved this workflow item from `wow/active/` to `wow/completed/20260307-1104_utl-doc-legacy-reference-cleanup-followup/`.
- Added a design record with explicit interfaces, constraints, trade-offs, and chosen approach for legacy-path handling.
- Built and resolved a full inventory/classification table across `wow/*`, `doc/ref/stats/*.json`, `doc/ref/stats/actual.md`, and `STATS.md`, then locked policy and handoff to `no-follow-up`.

## What was verified

- `git grep -n "utl/doc" -- wow doc/ref/stats STATS.md` -> matches found only in planned/historical or generated-summary surfaces captured by this inventory.
- `git grep -n "utl/doc" -- bin lib src cfg val` -> no matches.
- `bash wow/check-workflow.sh` -> pass.

## What remains

- No mandatory follow-up identified.
- Optional future enhancement only: if display-level naming consistency is desired in rolling summaries, implement it in `utl/ref/generators/stats` and regenerate outputs.
