# Auto-Commit Investigation Checklist

## Context

- Mystery commit: `fa618ed6`
- Timestamp: `2026-02-23 10:54:23 +0100`
- Message: `chore: automated sync 2026-02-23`
- Suspected source: `sys_gio` in `lib/ops/sys`
- User statement: sync was not triggered manually

## Completed So Far

- [x] Confirmed commit details and changed file (`lib/ops/dev`)
- [x] Verified fallback auto-message in `lib/ops/sys` (`sys_gio`)
- [x] Searched direct `sys_gio` callers in `lib/`, `bin/`, `go`, `val/`, `src/` (no hits)
- [x] Checked user crontab (`crontab -l`) (empty)
- [x] Checked shell profile files for direct `sys_gio` mention (no hits)

## Open Investigation Checklist

### High Priority

- [x] Inspect `lib/ops/sys` for internal call paths that can invoke `sys_gio` indirectly
- [x] Read `bin/ini` end-to-end and trace every sourced file and hook path
- [x] Read `go` end-to-end, especially `init`, `on`, `setup`, and validate/test wrappers
- [x] Read `bin/orc` for lifecycle hooks, post-actions, and sync-like behavior
- [x] Inspect `.git/hooks/` for commit/push automation scripts

### Runtime Trigger Sources

- [x] Search for `trap` hooks (`EXIT`, `ERR`, signals) across repo and shell configs
- [x] Inspect `PROMPT_COMMAND` setup in shell configs and initialization chain
- [x] Inspect alias/function wrappers that may map to `sys_gio` or git sync routines
- [x] Inspect tmux hooks (`~/.tmux.conf`) for shell-exit or session-close actions
- [x] Inspect systemd user timers/services (`~/.config/systemd/user/`)
- [x] Inspect OpenCode config (`~/.config/opencode/`) for post-task hooks/scripts

### Evidence Collection

- [x] Check shell history around 10:54 for direct or indirect trigger commands
- [x] Search for generic auto-sync patterns (`auto_sync`, `auto_commit`, `git commit`, `git push`) in `lib/` and `bin/`
- [x] Build a trigger timeline: shell/session events before commit timestamp
- [x] Identify exact trigger mechanism (root cause) and classify scope (repo-local vs global environment)
- [x] Propose and implement guardrails to prevent unwanted auto-commits

## Deliverables

- [x] Root-cause write-up: what triggered `sys_gio`, when, and through which chain
- [x] Minimal remediation patch (or config fix)
- [x] Verification steps proving the trigger no longer fires unexpectedly

## Recommended Location Policy For Planning Files

Use this rule of thumb:

- `doc/pro/` -> active plans and near-future project execution checklists
- `doc/issue/` -> bug/incident tracking and issue narratives
- `arc/` -> archive/reference material only (historical fixes, retired plans, snapshots)

Current recommendation for this repository:

- Keep active project plans in `doc/pro/`
- Move plans from `arc/pro/` to `doc/pro/` when you start actively working them
- Optionally keep stubs in `arc/pro/` that link to the active location, if you want backward compatibility
