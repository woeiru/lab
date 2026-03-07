You are operating the wow/ workflow board.

File rules:
- Keep filename timestamp prefixes (yyyymmdd-hhmm_) stable after creation.
- Update the "- Updated:" header field on every content change.
- Set the "- Status:" header field to match the destination folder.
- Valid statuses: inbox, queue, active, experiment, completed, dismissed.
- Every workflow doc must have these header fields:
  Status, Owner, Started, Updated, Links.

Artifact contract rules (active-artifacts task):
- `active-artifacts` reads optional `## Artifact Contract` from the parent
  active plan.
- Default contract when missing:
  - `Profile: general`
  - `Artifacts: evidence,result`
- Supported artifact names: `evidence`, `result`, `decision-log`, `checklist`.
- Unsupported artifact names are skipped and reported.
- Artifact docs created in `wow/active/` are workflow docs; include required
  header fields and exactly one `## Triage Decision` section with one
  canonical design token (`Design: required` or `Design: not needed`).

Parallel orchestration rules (for large initiatives):
- A parent program item uses suffix `-program-plan.md`.
- Program items should include sections:
  `## Program Scope`, `## Global Invariants`, `## Workstreams`,
  `## Integration Cadence`.
- Child workstream items must include `## Orchestration Metadata` with keys:
  `Program`, `Workstream-ID`, `Depends-On`, `Touch-Set`, `Merge-Gate`,
  `Branch`, `Worktree`.
- `Merge-Gate` allowed values: `minimal`, `module`, `integration`.
- `Depends-On` references `Workstream-ID` values from sibling children under
  the same `Program`.
- Keep dependency declarations acyclic.

Folder-specific naming:
- inbox/: filename must end with -plan.md, -issue.md, -review.md, or -followup.md
- dismissed/: filename must end with -plan.md; must include ## Dismissal Reason
- completed/: files must be in completed/<topic-folder>/<file>.md (one subfolder deep)
- completed/: valid topic-folder formats are:
  - standard close: yyyymmdd-hhmm_<topic>
  - bundle close: yyyymmdd-hhmm-bundle-<module-slug>
- completed/: folder timestamp is the close time and must be >= every file timestamp prefix inside that folder
- completed/: bundle folders must keep one stable folder per module-slug (do not create multiple `*-bundle-<module-slug>` folders)
- completed/: topic folders must not be empty

Follow-up routing policy:
- Default route for follow-up items from close/converge actions is inbox/.
- Direct queue routing is allowed only when all are true:
  1) follow-up is mandatory,
  2) scope is clear enough to execute,
  3) priority is already locked.
- When direct queue routing is used, add this line in the parent closeout
  section plus a one-line reason: `Routing: queue (mandatory follow-up)`.

Documentation gate policy:
- Active plan items should include `## Documentation Impact` with exactly one token:
  `Docs: required`, `Docs: none`, or `Docs: deferred`.
- Completed closeout must include exactly one docs outcome token in
  `## What was verified`: `Docs: updated`, `Docs: none`, or `Docs: deferred`.
- `Docs: deferred` is allowed only with a blocker reason and a linked follow-up
  item path.
- For structural/public surface changes (new/renamed functions, signature
  changes, dependency changes, variable map changes), regenerate reference docs
  with `./utl/ref/run_all_doc.sh` and record the result.

Reference pointers:
- Primary operating guide: AGENTS.md.
- Workflow semantics and checker behavior: wow/README.md.
- Canonical architecture context: doc/arc/.
- Canonical generated references: doc/ref/.
- If touching lib modules, consult lib/.spec and lib/ops/.spec.
- wow/ is workflow/planning state, not executable source of truth.
- If docs conflict on behavior, follow source code.

Validation:
- Run: bash wow/check-workflow.sh before finishing.
- If the checker fails, fix every reported issue before returning.
  Common fixes: rename for timestamp prefix, add missing header fields,
  move completed files into topic subfolder, replace legacy completed/<topic>/ placeholders,
  rename completed topic folder timestamp to match latest Updated close time or latest content-update commit time,
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
