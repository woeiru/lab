You are operating the doc/pro workflow board.

File rules:
- Keep filename timestamp prefixes (yyyymmdd-hhmm_) stable after creation.
- Update the "- Updated:" header field on every content change.
- Set the "- Status:" header field to match the destination folder.
- Valid statuses: inbox, queue, active, experiment, completed, dismissed.
- Every workflow doc must have these header fields:
  Status, Owner, Started, Updated, Links.

Folder-specific naming:
- inbox/: filename must end with -plan.md, -issue.md, -review.md, or -followup.md
- dismissed/: filename must end with -plan.md; must include ## Dismissal Reason
- completed/: files must be in completed/yyyymmdd-hhmm_<topic>/<file>.md (one subfolder deep)
- completed/: folder timestamp is the close time and must be >= every file timestamp prefix inside that folder
- completed/: topic folders must not be empty

Reference pointers:
- Primary operating guide: AGENTS.md.
- Workflow semantics and checker behavior: doc/pro/README.md.
- Canonical architecture context: doc/arc/.
- Canonical generated references: doc/ref/.
- If touching lib modules, consult lib/.spec and lib/ops/.spec.
- doc/pro/ is workflow/planning state, not executable source of truth.
- If docs conflict on behavior, follow source code.

Validation:
- Run: bash doc/pro/check-workflow.sh before finishing.
- If the checker fails, fix every reported issue before returning.
  Common fixes: rename for timestamp prefix, add missing header fields,
  move completed files into topic subfolder, replace legacy completed/<topic>/ placeholders,
  rename completed topic folder timestamp to match latest Updated close time,
  add ## Dismissal Reason.
- Report the checker output (pass or itemized failures) in your response.

Return format (apply to every template):
- List exact files moved or edited (with before/after paths for moves).
- Summarize what changed and why (max 5 bullets).
- Include checker result (pass/fail with details).

Strict mode (optional):
- Append "Strict mode." to any task prompt to activate.
- When active: do not infer missing details. If any required field, section,
  or file is absent, stop and report exactly what is missing before proceeding.
