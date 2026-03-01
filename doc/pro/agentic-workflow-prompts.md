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
Create a new workflow item in doc/pro/inbox for this idea:
<IDEA>

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

## 3) Start execution queue -> active

```text
Take this queued item and start execution:
<QUEUE_FILE_PATH>

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

## 4) Close active -> completed

```text
Finalize this active item into completed state:
<ACTIVE_FILE_PATH>

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

## 5) Close active/queue/inbox -> dismissed

```text
Move this workflow item to dismissed with clear rationale:
<FILE_PATH>

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

## 6) Weekly maintenance sweep

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

## 7) Combined "do it all" orchestrator prompt

```text
You are my workflow operator for doc/pro.

Objective:
- Keep the board clean
- Advance one meaningful item toward delivery
- Preserve naming and structure rules

Do this in order:
1) Validate current state with bash doc/pro/check-workflow.sh
2) Triage inbox and move one item to queue if needed
3) Move one queued item to active if active WIP < 3
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

## Optional add-on line for stricter runs

```text
Strict mode: do not infer missing details; if required data is absent, stop and report exactly what field/value is missing.
```
