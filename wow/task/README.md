# wow/task

Executable prompt templates for LLM agents operating the `doc/pro` workflow board.

## Usage

Give the task filepath first (short instruction), then the project filepath
(large context). This order matters -- the LLM uses the short instruction as
a lens to selectively attend to the larger document that follows, producing
better task adherence than the reverse.

```
wow/task/active-start
wow/active/20260301-1400_gpu-thermal-monitoring-plan.md
```

For tasks that take free-form input instead of a file (like inbox-capture),
put the idea/problem statement after the task path:

```
wow/task/inbox-capture
Add GPU thermal monitoring to the sys module
```

Use `Strict mode.` when you want capture-only behavior with no extra analysis.

Append `Strict mode.` to halt on ambiguity instead of inferring.

## Parallel orchestration mode

For large initiatives, use one program plan plus multiple child workstream
plans in separate contexts.

- This mode is explicit and manual. Nothing in `wow/` auto-fanouts or
  auto-splits by size.
- Trigger point: after an item is in `active/` and shaped as a
  `*-program-plan.md` parent.
- `inbox/` and `queue/` stay single-item planning states; they do not create
  child workstreams automatically.

- Program coordinator context: runs orchestration tasks and owns parent state.
- Worker contexts: run child plans and only modify assigned touch-sets.
- Use this task sequence:
  1. `active-fanout` (create/refresh child plans from parent)
  2. `active-assign` (bind child plans to owners/contexts/branches/worktrees)
  3. workers execute with `active-start` / `active-checkpoint` / `active-resume`
  4. `active-sync` (roll up child status into parent)
  5. `active-converge` (integration wave review + release next wave)

### Prompt ordering principle

**Short task first, big file second.** When composing a prompt with both a
task instruction and a large project document, always place the concise
instruction before the larger body of content. The model processes tokens
sequentially and uses early tokens to prime attention over later ones. Giving
the task first lets the model know what to extract before it encounters the
bulk material, rather than forcing it to re-weight retroactively.

## Follow-up routing policy

- Default route for follow-up items from close/converge tasks is `inbox/`.
- Direct `queue/` routing is allowed only when the follow-up is mandatory,
  scope is already clear, and priority is already locked.
- When routing directly to `queue/`, record
  `Routing: queue (mandatory follow-up)` and a one-line rationale in the
  parent closeout/convergence section.

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
| `active-fanout`             | Split active program into child workstreams  |
| `active-assign`             | Assign workstreams to contexts/worktrees     |
| `active-sync`               | Sync child checkpoints into program plan     |
| `active-converge`           | Converge a wave and release next wave        |
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
