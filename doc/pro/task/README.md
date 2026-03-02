# doc/pro/task

Executable prompt templates for LLM agents operating the `doc/pro` workflow board.

## Usage

Point your agent at the task file and provide context:

```
Read and execute doc/pro/task/inbox-capture

I want to add GPU thermal monitoring to the sys module
```

Append `Strict mode.` to halt on ambiguity instead of inferring.

## Naming conventions

| Pattern              | Meaning                          | Examples                          |
|----------------------|----------------------------------|-----------------------------------|
| `UPPERCASE.md`       | Shared config, not a task        | `RULES.md`                        |
| `folder-action`      | Workflow task; prefix = destination folder | `active-move`, `queue-triage`  |
| `singleword`         | Cross-cutting operation, no target folder  | `status`, `maintenance`        |

## Tasks

| File                        | Action                                      |
|-----------------------------|---------------------------------------------|
| `inbox-capture`             | New idea into inbox                          |
| `queue-triage`              | Pick highest-value inbox item, move to queue |
| `queue-move`                | Move a specific inbox item to queue          |
| `active-move`               | Move queue item to active, add plan          |
| `active-start`              | Begin executing an active item               |
| `active-split`              | Split active item into smaller pieces        |
| `active-checkpoint`         | Checkpoint progress before closing context   |
| `active-resume`             | Resume active item in a new context          |
| `active-reopen`             | Reopen a completed item into active          |
| `completed-close`           | Finalize active item into completed          |
| `dismissed-close`           | Dismiss any item with rationale              |
| `experiments-move`          | Move item to experiments for prototyping     |
| `experiments-resolve`       | Resolve experiment to queue or dismissed     |
| `status`                    | Review board state (read-only)               |
| `maintenance`               | Weekly maintenance sweep                     |
| `RULES.md`                  | Shared rules (referenced by all tasks)       |
