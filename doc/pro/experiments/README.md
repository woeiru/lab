# Experiments Workspace

This folder tracks alternative implementation plans and their outcomes.

## Purpose

- Keep competing approaches isolated and easy to compare.
- Preserve `doc/pro/active` for the current default track.
- Document evaluation criteria, results, and final recommendation.

## Contents

- Experiment plans with timestamp-prefixed filenames.
- `*_AGENTS.md` (agent workflow rules for this folder).

## Filename rule (required)

- Every non-README file in `doc/pro/experiments/` must use `yyyymmdd-hhmm_filename`.
- The prefix is the file's last git touch timestamp.

## Suggested branch naming

- `e/<topic>-plan-1`
- `e/<topic>-plan-2`
- `e/<topic>-plan-4`

Use `a/<topic>` for the active path when needed.
