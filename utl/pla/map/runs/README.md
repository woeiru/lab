# Runs (`utl/pla/map/runs`)

Create one subdirectory per mapping run:

- `yyyymmdd-hhmm_<state-or-snapshot>/`

Required files per run:

1. `input-manifest.json`
2. `llm-proposal.json`
3. `reviewer-notes.md`
4. `approved-mapping.json`

Keep run folders immutable after review close; create a new run for changes.
