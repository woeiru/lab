# Agentic Workflow Prompt Templates

Prompt templates for LLM agents operating the `doc/pro` workflow board.

## How to use

1. Copy the **Core rules** block below.
2. Append the template for the operation you need.
3. Replace `<PLACEHOLDERS>` with actual values.
4. Paste into your LLM context.

Templates assume the agent has filesystem access and can run shell commands.
Individual templates do not repeat core rules -- they only contain what is
unique to that operation.

---

## Core rules

Prepend this block to any template below.

```text
You are operating the doc/pro workflow board.

File rules:
- Keep filename timestamp prefixes (yyyymmdd-hhmm_) stable after creation.
- Update the "- Updated:" header field on every content change.
- Set the "- Status:" header field to match the destination folder.
- Valid statuses: inbox, queue, active, experiment, completed, dismissed.
- Every workflow doc must have these header fields:
  Status, Owner, Started, Updated, Links.

Folder-specific naming:
- inbox/: filename must end with -plan.md, -review.md, or -followup.md
- dismissed/: filename must end with -plan.md; must include ## Dismissal Reason
- completed/: files must be in completed/<topic>/<file>.md (one subfolder deep)

Validation:
- Run: bash doc/pro/check-workflow.sh before finishing.
- If the checker fails, fix every reported issue before returning.
  Common fixes: rename for timestamp prefix, add missing header fields,
  move completed files into topic subfolder, add ## Dismissal Reason.
- Report the checker output (pass or itemized failures) in your response.

Return format (apply to every template):
- List exact files moved or edited (with before/after paths for moves).
- Summarize what changed and why (max 5 bullets).
- Include checker result (pass/fail with details).
```

---

## Templates

### 1) 💡 Capture idea in inbox

```text
<IDEA>

Create a new workflow item in doc/pro/inbox for this idea.

- Filename: yyyymmdd-hhmm_<topic>-plan.md (use current time)
- Set Status: inbox
- Add sections: Goal, Context, Scope, Risks, Next Step
- Do not move any existing files
```

### 2) 📥 Triage inbox -> queue

```text
Review all files in doc/pro/inbox and pick the highest-value next item.

- Move exactly one item from inbox/ to queue/
- Set Status: queue
- Add ## Triage Decision section with:
  - Why this item was selected now (priority rationale)
  - Design classification -- answer both questions:
    1. Are there meaningful alternatives for how to solve this?
    2. Will other code or users depend on the shape of the output?
    If either answer is yes: "Design: required"
    If both answers are no: "Design: not needed"
  - One-sentence justification for the classification
- Report: moved file path, design classification, reason, and top 2 deferred
  items with rationale
```

### 3) 📌 Direct move inbox -> queue (known item)

```text
<INBOX_FILE_PATH>

Move this specific workflow item from inbox/ to queue/.

- Set Status: queue
- Add ## Triage Decision section with:
  - Why now (priority rationale)
  - Design classification -- answer both questions:
    1. Are there meaningful alternatives for how to solve this?
    2. Will other code or users depend on the shape of the output?
    If either answer is yes: "Design: required"
    If both answers are no: "Design: not needed"
  - One-sentence justification for the classification
- Report: new file path, design classification, what changed (max 3 bullets)
```

### 4) 🚀 Start execution: queue -> active

```text
<QUEUE_FILE_PATH>

Move this queued item into active execution.

- Read the ## Triage Decision section. It must contain a Design classification.
  If "Design: required" or "Design: not needed" is missing, stop and run
  triage (template 2 or 3) first.
- Set Status: active
- Add sections: Execution Plan (today), Verification Plan, Exit Criteria

Design-aware Execution Plan:
- If "Design: required":
  - Phase 1 must be the design phase. Its completion criterion is a concrete
    deliverable: documented interfaces, constraints, trade-offs, and the
    chosen approach. No implementation work begins until Phase 1 is complete.
  - Subsequent phases cover implementation, verified against the design.
- If "Design: not needed":
  - Write the Execution Plan directly with implementation phases.

General Execution Plan rules for multi-phase work:
  - Each phase must have one unambiguous completion criterion (a measurable
    target or a concrete deliverable, not both)
  - List phases as sequential steps, not conditional branches
    (write "Phase 1, then Phase 2" -- never "if closing... if continuing...")
  - Exit Criteria applies to the full item, not individual phases
- If a waiver is needed, add/update doc/pro/active/waivers/*_waiver-register.md
- Report: active path + design classification + next 3 execution steps
```

### 5) ✅ Close: active -> completed

```text
<ACTIVE_FILE_PATH>

Finalize this active item into completed state.

- Move file to doc/pro/completed/<topic>/
- Set Status: completed
- Add final sections:
  - What changed (files, configs, behavior)
  - What was verified (tests/checks run, with commands and results)
  - What remains (follow-up items, if any; capture each as a new inbox item)
- If related review/result docs exist in active/, move them to the same
  topic folder
- Report: completed folder path + verification evidence summary
```

### 6) 🗑️ Dismiss: any -> dismissed

```text
<FILE_PATH>

Move this workflow item to dismissed with clear rationale.

The source file may be in inbox/, queue/, active/, or experiments/.

- Move to doc/pro/dismissed/
- Set Status: dismissed
- Ensure filename ends with -plan.md (rename slug if needed, keep prefix)
- Add ## Dismissal Reason section (1-3 concise bullets)
- Preserve all original content below the dismissal reason
- Report: dismissed file path + rationale
```

### 7) 🧪 Move to experiments (spike/prototype)

```text
<FILE_PATH>

Move this item to experiments for prototyping.

The source file may be in inbox/, queue/, or active/.

- Move file to doc/pro/experiments/
- Set Status: experiment
- Add sections:
  - ## Experiment Goal (what question this spike answers)
  - ## Success Criteria (how to judge if the prototype is promising)
  - ## Time Box (maximum effort before deciding)
- Report: experiments path + goal summary + time box
```

### 8) 🧭 Resolve experiment -> queue or dismissed

```text
<EXPERIMENT_FILE_PATH>

Resolve this experiment based on its outcome.

- Read the ## Success Criteria section in the experiment file.
  If that section is missing, stop and ask for success criteria before
  proceeding.
- Evaluate the experiment against those criteria.
- If promising: move to doc/pro/queue/, set Status: queue
- If not worth pursuing: move to doc/pro/dismissed/, set Status: dismissed,
  add ## Dismissal Reason, ensure filename ends with -plan.md
- Add ## Experiment Outcome section (what was learned, evidence)
- Report: destination path + outcome summary + what was learned
```

### 9) 🔄 Reopen: completed -> active

```text
<COMPLETED_FILE_PATH>

Reopen this completed item for additional work.

- Move file from completed/<topic>/ to doc/pro/active/
- Set Status: active
- Preserve all existing content (plan, reviews, completion evidence)
- Add ## Reopened section explaining:
  - Why the completed work needs revisiting
  - What specific additional work is needed
  - New exit criteria for this round
- Report: active path + reopening rationale + next 3 steps
```

### 10) ✂️ Split active item

```text
<ACTIVE_FILE_PATH>

Split this active item into multiple smaller items.

- Keep the original file in active/ with narrowed scope
- Create new inbox/ items for each split-off piece:
  - Filename: yyyymmdd-hhmm_<topic>-plan.md (current time, new prefix)
  - Add ## Split From section linking back to the original active item
  - Include: Goal, Scope, Context (carried from parent)
- Update the original file:
  - Narrow the Execution Plan to only the retained scope
  - Add ## Split section listing the new inbox items and their scope
- Report: original path + new inbox paths + scope division summary
```

### 11) 🧾 Checkpoint active item (context handoff)

Use before closing a context window or switching tasks.

```text
<ACTIVE_FILE_PATH>

Checkpoint progress on this active item before I close this context.

- Update the active plan with current progress
- Add or replace ## Progress Checkpoint with these subsections:
  - Done: what was completed this session (files changed, decisions made)
  - In-flight: anything partially done or uncommitted
  - Blockers: problems encountered, unresolved questions
  - Next steps: ordered list of what to do next (be specific, include paths).
    Write steps as unconditional actions, not decision forks.
    Wrong: "If closing... If continuing..."
    Right: "1. Do X. 2. Do Y. 3. Do Z."
    If a genuine decision is needed, put it as a single step:
    "Decide X (options: A or B)" -- then continue with the next concrete step.
  - Context: non-obvious state the next session needs (branch name,
    temp files, test status, relevant findings)
- Update the Execution Plan to reflect remaining work only
- If a phase's completion criterion is met, mark it COMPLETE in the plan
  and ensure the next phase appears as the first item in Next steps
- If tests were run, record pass/fail summary under Done
- Do not move the file to another folder
- Report: updated file path + 5-bullet handoff summary
```

### 12) ▶️ Resume active item (new context)

Use at the start of a new context window to continue work.

```text
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
```

### 13) 📊 Board status review

Reports current state without making changes.

```text
Review the current state of the doc/pro board without modifying anything.

- Count items in each folder (inbox, queue, active, experiments)
- For each active item: one-line summary, last Updated date, flag if stale
  (Updated older than 7 days)
- For each inbox item: one-line summary
- Run: bash doc/pro/check-workflow.sh and report result
- Do not move or edit any files
- Suggest actions I should take, in priority order (max 5)
```

### 14) 🧹 Weekly maintenance sweep

```text
Perform a weekly doc/pro maintenance pass.

Do this in order:
1. Run bash doc/pro/check-workflow.sh; fix structural/naming issues only
   (checker failures are safe to fix autonomously)
2. List active items; flag stale ones (Updated older than 7 days)
3. For each stale item, recommend: keep active, complete, or dismiss
4. Review queue ordering; suggest top 3 execution candidates
5. Verify completed items are in completed/<topic>/
6. Re-run bash doc/pro/check-workflow.sh

Constraints:
- Fix only structural issues (checker failures) autonomously
- Do not move files between workflow states without my approval
- Present state-transition recommendations as a list for me to approve

Report:
- Checker results (before and after)
- Active summary with staleness flags
- Recommendation per stale item
- Queue priority ranking
- Structural fixes applied (if any)
```

---

## Strict mode add-on

Append to any template when you want the agent to halt on ambiguity instead
of inferring.

```text
Strict mode: do not infer missing details. If any required field, section,
or file is absent, stop and report exactly what is missing before proceeding.
```
