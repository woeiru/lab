# Workflow Checklist

Use this quick checklist before ending a doc/pro update session.

- File names follow folder naming rules (`inbox`, `dismissed`).
- Workflow item markdown files in `inbox/`, `queue/`, `active/`, `completed/`,
  `dismissed/`, and `experiments/` use `yyyymmdd-hhmm_filename`.
- Root meta/support files under `doc/pro/` do not need timestamp prefixes.
- Every workflow doc has header fields: `Status`, `Owner`, `Started`, `Updated`, `Links`.
- Dismissed docs include `## Dismissal Reason`.
- `active/` contains only in-progress items.
- `active/waivers/*_waiver-register.md` entries include owner, expiry date, and removal criteria.
- Completed topics live under `completed/<topic>/`.

Run the checker:

```bash
bash doc/pro/check-workflow.sh
```
