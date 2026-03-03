# Active Work Index

This directory stores only in-progress work.

## Current state

- Active items live here.
- `waivers/` stores temporary policy waivers for active work.

## Filename rule (required)

- Every non-README file in `doc/pro/active/` must use `yyyymmdd-hhmm_filename`.
- The prefix is the file's last git touch timestamp.
- Rename the file when it is updated so the prefix stays current.

## Pause checkpoint (2026-02-28)

- `GLB-008` finding is tracked via temporary waiver `WVR-2026-001`.
- Plan moved to `doc/pro/completed/*_spec-hierarchy-and-enforcement-plan.md`.
- Next planned action: strict/report default wiring, then rerun baselines.

## How to use this folder

1. **Planned work**: move a file from `doc/pro/queue/` to this directory when
   work starts (normal path via `active-move` task).
2. **Emergent work**: if a quick fix grew beyond a single-session scope and was
   never tracked, capture it directly here via the `active-capture` task.
   The capture document includes inline triage (design classification) and
   a progress checkpoint so downstream tasks (resume, split, close) work
   normally.
3. Keep implementation notes and reviews here while the item is open.
4. Move the full topic set to `doc/pro/completed/<topic>/` once accepted.
