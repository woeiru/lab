Read and apply doc/pro/task/RULES.md first.

<ACTIVE_FILE_PATH>

Resume work on this active item in a fresh context.

- Read the full plan, especially ## Progress Checkpoint and Execution Plan.
- If ## Progress Checkpoint exists:
  - Read files referenced in Next Steps and In-flight sections
  - Verify in-flight state still holds (check git status, file contents, tests)
  - Address blockers first if any are listed
- If ## Progress Checkpoint is missing:
  - Read the Execution Plan and infer current state from the codebase
  - Note what could not be determined
- Present a short status briefing:
  - Where we left off (or best understanding if no checkpoint)
  - What I will do now (first 3 steps)
  - Any state that looks stale or conflicting
- Phase boundaries: if the checkpoint shows a phase is complete and the
  Execution Plan defines a next phase, proceed to it immediately.
  Do not treat phase transitions as decision points unless the plan
  explicitly marks the next phase as optional or conditional.
- Then proceed with execution immediately.
  Say "waiting for confirmation" only if I explicitly asked you to pause.
- As you work, keep the active plan updated:
  - Move completed steps into Done
  - Add findings to Context
  - Keep Execution Plan current
