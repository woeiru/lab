# README Style Guide

This guide standardizes README files in this repository.

## Required Sections
Each README should include these sections (or equivalent wording):
- `Purpose`
- `Quick Start`
- `Structure`
- `Common Tasks`
- `Troubleshooting`
- `Related Docs`

## Section Intent
- `Purpose`: Explain what the directory/component is for and who should use it.
- `Quick Start`: Show the fastest path to success with runnable commands.
- `Structure`: Summarize key files/folders and responsibilities.
- `Common Tasks`: List the most frequent workflows.
- `Troubleshooting`: Document common failure modes and first checks.
- `Related Docs`: Link to nearby references and higher-level docs.

## Formatting Rules
- Keep README files concise; move deep technical references into `doc/`.
- Prefer actionable commands over long prose.
- Keep headings at `##` depth for top-level sections.
- Use relative links for repository-local documentation.

## Recommended Length
- Typical README target: 80-200 lines.
- If content exceeds this, split detailed material into linked docs.

## Baseline Navigation Links
Include both links in `Related Docs`:
- `Repository Root` (`README.md` at repository root)
- `Documentation Hub` (`doc/README.md`)

## Maintenance Checklist
- Verify commands still execute as documented.
- Verify relative links resolve correctly.
- Remove stale status/date claims when not actively maintained.
- Keep examples aligned with current CLI and scripts.
