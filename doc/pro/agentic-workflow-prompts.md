# Agentic Workflow Prompt Templates

Use these templates to ask an LLM agent to maintain `doc/pro` workflow state consistently.

## Core rules to include in prompts

- Work only inside `doc/pro/` unless explicitly told otherwise.
- Keep filename timestamp prefixes stable after creation.
- Update `- Updated:` on content changes.
- Move items by folder state (`inbox` -> `queue` -> `active` -> `completed` or `dismissed`).
- Keep completed items under `completed/<topic>/`.
- Run `bash doc/pro/check-workflow.sh` before finishing.

## 1) Capture a new idea in inbox

```text
<IDEA>
Create a new workflow item in doc/pro/inbox for this idea.

Requirements:
- Filename format: yyyymmdd-hhmm_<topic>-plan.md
- Include header fields: Status, Owner, Started, Updated, Links
- Set Status: inbox
- Add sections: Goal, Context, Scope, Risks, Next Step
- Do not move any existing files
- Run: bash doc/pro/check-workflow.sh
- Return: created file path + 3-bullet summary
```

## 2) Triage inbox -> queue

```text
Review all files in doc/pro/inbox and pick the highest-value next item.

Then:
- Move exactly one chosen item from inbox to queue
- Keep its filename prefix unchanged
- Update the document header Updated date
- Add a short "## Triage Decision" section with why it was selected now
- Run: bash doc/pro/check-workflow.sh
- Return: moved file path, reason, and top 2 deferred items
```

## 3) Direct move inbox -> queue (known item)

```text
<INBOX_FILE_PATH>
Move this specific workflow item from inbox to queue.

Requirements:
- Move exactly this file to doc/pro/queue
- Keep filename prefix unchanged
- Update `- Updated:` in the header
- Add a short `## Triage Decision` note (why now)
- Do not modify any other workflow items
- Run: bash doc/pro/check-workflow.sh

Return:
- New file path
- What changed (max 3 bullets)
- Validation result
```

## 4) Start execution queue -> active

```text
<QUEUE_FILE_PATH>
Take this queued item and start execution.

Requirements:
- Move it to doc/pro/active
- Keep filename prefix unchanged
- Set Status: active
- Update Updated date
- Add sections: Execution Plan (today), Verification Plan, Exit Criteria
- If a waiver is needed, add/update doc/pro/active/waivers/*_waiver-register.md
- Run: bash doc/pro/check-workflow.sh
- Return: active path + next 3 execution steps
```

## 5) Close active -> completed

```text
<ACTIVE_FILE_PATH>
Finalize this active item into completed state.

Requirements:
- Move file into doc/pro/completed/<topic>/
- Keep filename prefix unchanged
- Set Status: completed
- Update Updated date
- Add final sections:
  - What changed
  - What was verified (tests/checks with commands)
  - What remains (if anything)
- If related review/result docs exist, move them into the same topic folder
- Run: bash doc/pro/check-workflow.sh
- Return: completed folder path + verification evidence summary
```

## 6) Close active/queue/inbox -> dismissed

```text
<FILE_PATH>
Move this workflow item to dismissed with clear rationale.

Requirements:
- Move to doc/pro/dismissed
- Keep filename prefix unchanged
- Set Status: dismissed
- Update Updated date
- Ensure filename pattern ends with -plan.md
- Add section: ## Dismissal Reason (1-3 concise bullets)
- Run: bash doc/pro/check-workflow.sh
- Return: dismissed file path + rationale
```

## 7) Weekly maintenance sweep

```text
Perform a weekly doc/pro hygiene pass.

Tasks:
1) List all active items and flag stale ones (Updated older than 7 days)
2) Suggest one move for each stale item: keep active, complete, or dismiss
3) Check queue ordering and suggest top 3 execution candidates
4) Ensure completed items are in completed/<topic>/
5) Run: bash doc/pro/check-workflow.sh

Return format:
- Active summary
- Stale recommendations
- Queue top 3
- Any structural fixes applied
```

## 8) Combined "do it all" orchestrator prompt

```text
You are my workflow operator for doc/pro.

Objective:
- Keep the board clean
- Advance one meaningful item toward delivery
- Preserve naming and structure rules

Do this in order:
1) Validate current state with bash doc/pro/check-workflow.sh
2) Triage inbox and move one item to queue if needed
3) Move one queued item to active if active WIP is reasonable (see README for limits)
4) If any active item already meets exit criteria, move it to completed/<topic>/
5) Update Updated headers on touched docs
6) Re-run bash doc/pro/check-workflow.sh

Constraints:
- Keep timestamp filename prefixes stable
- Do not edit files outside doc/pro
- Make minimal, auditable changes

Return:
- Exact files moved/edited
- Why each move was made
- Suggested next action for me
```

## 9) Fast-track inbox -> active (triage + start in one step)

```text
<INBOX_FILE_PATH>
Fast-track this inbox item directly into active execution.

Requirements:
- Move file to doc/pro/active (single-step promotion, skip queue)
- Keep filename prefix unchanged
- Set Status: active
- Update Updated date
- Add section: ## Triage Decision (why this item, why skip queue)
- Add sections: Execution Plan (today), Verification Plan, Exit Criteria
- If 3+ items are already in active, stop and report instead of moving
- If a waiver is needed, add/update doc/pro/active/waivers/*_waiver-register.md
- Do not modify any other workflow items
- Run: bash doc/pro/check-workflow.sh
- Return: active path + triage rationale + next 3 execution steps

Use only when the item is clearly highest priority and ready to execute now.
```

## 10) Move to experiments (spike/prototype)

```text
<FILE_PATH>
Move this item to experiments for prototyping.

The source file may be in queue/ or active/.

Requirements:
- Move file to doc/pro/experiments
- Keep filename prefix unchanged
- Set Status: experiment
- Update Updated date
- Add section: ## Experiment Goal (what question this spike answers)
- Add section: ## Success Criteria (how to judge if the prototype is promising)
- Add section: ## Time Box (maximum effort before deciding)
- Do not modify any other workflow items
- Run: bash doc/pro/check-workflow.sh
- Return: experiments path + goal summary + time box
```

## 11) Resolve experiment -> queue or dismissed

```text
<EXPERIMENT_FILE_PATH>
Resolve this experiment based on its outcome.

Requirements:
- Evaluate the experiment against its Success Criteria
- If promising: move to doc/pro/queue, set Status: queue
- If not worth pursuing: move to doc/pro/dismissed, set Status: dismissed,
  add ## Dismissal Reason section
- Keep filename prefix unchanged
- Update Updated date
- Add section: ## Experiment Outcome (what was learned, evidence)
- Do not modify any other workflow items
- Run: bash doc/pro/check-workflow.sh
- Return: destination path + outcome summary + what was learned
```

## 12) Checkpoint active item (save progress for context handoff)

Use before closing a context window or switching to a different task.
The LLM captures everything the next context needs to continue.

```text
<ACTIVE_FILE_PATH>
Checkpoint progress on this active item before I close this context.

Requirements:
- Read the active plan and update it with current progress
- Update Updated date
- Add or replace section: ## Progress Checkpoint
  Include these subsections:
  - Done: what was completed this session (files changed, decisions made)
  - In-flight: anything partially done or uncommitted
  - Blockers: problems encountered, unresolved questions
  - Next steps: ordered list of what to do next (be specific, include file paths)
  - Context: any non-obvious state the next session needs (branch name,
    temp files, test status, relevant findings)
- Update the Execution Plan to reflect remaining work only
- If tests were run, record pass/fail summary
- Do not move the file to another folder
- Do not modify any other workflow items
- Run: bash doc/pro/check-workflow.sh
- Return: updated file path + 5-bullet handoff summary
```

## 13) Resume active item (pick up in new context)

Use at the start of a new context window to continue work on an active item.
The LLM reads the plan, orients itself, and continues execution.

```text
<ACTIVE_FILE_PATH>
Resume work on this active item in a fresh context.

Requirements:
- Read the full active plan, especially Progress Checkpoint and Execution Plan
- Read files referenced in the Next Steps and In-flight sections
- Verify any in-flight state described in the checkpoint still holds
  (check git status, file contents, test results)
- If the checkpoint mentions blockers, address those first
- Present a short status briefing before doing any work:
  - Where we left off
  - What I will do now (first 3 steps)
  - Any checkpoint state that looks stale or conflicting
- Wait for my confirmation before executing, unless I say "just go"
- As you work, update the active plan:
  - Move completed Next Steps into Done
  - Add new findings to Context
  - Keep Execution Plan current
- Run: bash doc/pro/check-workflow.sh when done
- Return: what was accomplished + updated next steps
```

## Optional add-on line for stricter runs

```text
Strict mode: do not infer missing details; if required data is absent, stop and report exactly what field/value is missing.
```
