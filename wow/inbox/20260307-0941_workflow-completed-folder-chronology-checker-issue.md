# Workflow Completed Folder Chronology Checker Issue

- Status: inbox
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-07
- Links: wow/check-workflow.sh, wow/task/inbox-capture

## Goal

Restore `wow/check-workflow.sh` pass status by resolving completed-folder
chronology mismatches in legacy completed topics.

## Context

1. Current checker output reports chronology failures for two completed topics
   where file timestamp prefixes are newer than folder completion timestamps.
2. The failing topics are historical items under `wow/completed/`.
3. This issue is separate from active architecture migration work and should be
   fixed without coupling to runtime code changes.

## Scope

1. Confirm canonical policy for completed folder chronology checks.
2. Decide whether to fix by folder rename, file move normalization, or checker
   policy adjustment.
3. Apply minimal corrective change preserving workflow invariants.
4. Re-run checker and document outcome.

## Risks

1. Renaming completed topic folders can create noisy git history churn.
2. Weakening checker logic can allow invalid workflow states.
3. Mixed policy handling for old and new topics can reintroduce regressions.

## Next Step

Move this issue to `wow/queue/` for triage and select a single canonical fix
strategy before implementation.
