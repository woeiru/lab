# doc/pro/task

Executable prompt templates for LLM agents operating the `doc/pro` workflow board.

## Usage

Point your agent at the task file and provide context:

```
Read and execute doc/pro/task/inbox-capture.md

I want to add GPU thermal monitoring to the sys module
```

Append `Strict mode.` to halt on ambiguity instead of inferring.

## Naming conventions

| Pattern              | Meaning                          | Examples                          |
|----------------------|----------------------------------|-----------------------------------|
| `UPPERCASE.md`       | Shared config, not a task        | `RULES.md`                        |
| `folder-action.md`   | Workflow task; prefix = destination folder | `active-start.md`, `queue-triage.md` |
| `singleword.md`      | Cross-cutting operation, no target folder  | `status.md`, `maintenance.md`    |

## Tasks

| File                        | Action                                      |
|-----------------------------|---------------------------------------------|
| `inbox-capture.md`          | New idea into inbox                          |
| `queue-triage.md`           | Pick highest-value inbox item, move to queue |
| `queue-move.md`             | Move a specific inbox item to queue          |
| `active-start.md`           | Start execution: queue to active             |
| `active-split.md`           | Split active item into smaller pieces        |
| `active-checkpoint.md`      | Checkpoint progress before closing context   |
| `active-resume.md`          | Resume active item in a new context          |
| `active-reopen.md`          | Reopen a completed item into active          |
| `completed-close.md`        | Finalize active item into completed          |
| `dismissed-close.md`        | Dismiss any item with rationale              |
| `experiments-move.md`       | Move item to experiments for prototyping     |
| `experiments-resolve.md`    | Resolve experiment to queue or dismissed     |
| `status.md`                 | Review board state (read-only)               |
| `maintenance.md`            | Weekly maintenance sweep                     |
| `RULES.md`                  | Shared rules (referenced by all tasks)       |
