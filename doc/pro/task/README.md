# doc/pro/task

Executable prompt templates for LLM agents operating the `doc/pro` workflow board.

## Usage

Give the task filepath first (short instruction), then the project filepath
(large context). This order matters -- the LLM uses the short instruction as
a lens to selectively attend to the larger document that follows, producing
better task adherence than the reverse.

```
doc/pro/task/active-start
doc/pro/active/20260301-1400_gpu-thermal-monitoring-plan.md
```

For tasks that take free-form input instead of a file (like inbox-capture),
put the idea after the task path:

```
doc/pro/task/inbox-capture
Add GPU thermal monitoring to the sys module
```

Append `Strict mode.` to halt on ambiguity instead of inferring.

### Prompt ordering principle

**Short task first, big file second.** When composing a prompt with both a
task instruction and a large project document, always place the concise
instruction before the larger body of content. The model processes tokens
sequentially and uses early tokens to prime attention over later ones. Giving
the task first lets the model know what to extract before it encounters the
bulk material, rather than forcing it to re-weight retroactively.

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
