# Project Workflow (`doc/pro`)

This folder is your lightweight project board.

Use it to move work through clear states:

`inbox` -> `active` -> `completed` (or `dismissed`)

## Folder meanings

- `inbox/`: ideas, plans, and tasks you might do later
- `active/`: work currently in progress
- `completed/`: finished work with final outcome documented
- `dismissed/`: ideas you decided not to do (with a short reason)
- `experiments/`: alternative approaches/prototypes

## Recommended flow (best practice)

1. Capture in `inbox/`
   - Add new ideas quickly.
   - Keep one file per idea/plan.

2. Start work -> move to `active/`
   - Move the file from `inbox/` to `active/` when you commit to doing it.
   - If helpful, prefix with sequence number (`0-`, `1-`, `2-`) to show execution order.

3. Execute and review in `active/`
   - Yes: review notes can stay in `active/` while work is still open.
   - Keep review files tied to the same topic slug (example: `ana-...-review.md`).

4. Finish -> move to `completed/`
   - When implementation + review are accepted, move related files to `completed/`.
   - Add a short final section: what changed, what was verified, what remains.

5. Reject -> move to `dismissed/`
   - If you decide not to continue, move the file to `dismissed/`.
   - Add one or two lines explaining why (obsolete, too risky, low value, duplicate, etc.).

## Important rule for your question

If something is in `active/`, it is not done yet.

- Review notes in `active/` are normal while work is ongoing.
- Once the result is acceptable, move both the plan and review notes to `completed/`.

## Keep `completed/` organized

Use one of these simple options:

- Option A (flat): keep current style and use strong filenames
  - Example: `ana-module-expansion-final.md`
- Option B (recommended): one subfolder per finished item
  - Example: `completed/ana-module-expansion/plan.md`, `review.md`, `result.md`

Option B is easier when one topic has multiple documents.

## Minimal document template

Use this header at the top of each work file:

```md
# <Title>

- Status: inbox | active | completed | dismissed
- Owner: <name>
- Started: YYYY-MM-DD
- Updated: YYYY-MM-DD
- Links: related files/PRs/tests
```

## WIP limit (recommended)

To avoid overload as a solo developer:

- Keep at most 1-3 items in `active/`.
- Finish or dismiss before starting many new ones.

## Validation helpers

- Checklist: `doc/pro/workflow-checklist.md`
- Checker script: `bash doc/pro/check-workflow.sh`

---

This workflow is already good. The main improvement is simple: treat `active/` as "currently open," and move all related docs to `completed/` only when the work is truly done.
