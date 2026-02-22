# AGENTS How-To

Quick guide for using `AGENTS.md` effectively.

## What this file is

`AGENTS.md` is the repository-specific operating manual for coding agents.
It tells an agent:
- how to run tests/lint/build-like checks in this repo,
- what coding conventions to follow,
- and where special policy files (Cursor/Copilot rules) live.

## When to use it

Use it at the start of any agent task that edits code, tests, docs, or scripts.

Typical moments:
- before asking an agent to implement a feature,
- before bugfix/refactor work,
- before asking for test-only or lint-only tasks,
- before code review style/compliance checks.

## How to use it (practical workflow)

1. Start your prompt by anchoring the agent to this file.
2. State the task clearly.
3. Ask the agent to follow `AGENTS.md` command/style rules.
4. Ask for proof: which commands were run and which files changed.

Example prompt:

```text
Please implement X in this repository.
Read and follow /home/es/lab/AGENTS.md first.
Use the test commands from that file, and run the smallest relevant tests.
After changes, report:
1) files changed
2) commands executed
3) test results
```

## How to use it for test tasks

If you only want validation, be explicit:

```text
Follow /home/es/lab/AGENTS.md.
Do not change code. Run the relevant single test(s) only.
Report failures with likely root cause.
```

This works well because `AGENTS.md` already documents single-test execution patterns.

## How to keep it accurate

Update `AGENTS.md` whenever one of these changes:
- test runner flags/paths,
- new lint/static-check tooling,
- style conventions,
- Cursor/Copilot rule files added or moved.

Good maintenance rule:
- Any PR that changes developer workflow should also update `AGENTS.md`.

## Common mistakes to avoid

- Treating `AGENTS.md` as optional background context.
- Asking agents to "just do it" without requiring its rules.
- Forgetting to update it after adding new scripts or conventions.
- Duplicating conflicting instructions across multiple docs.

## Suggested team convention

- Keep one canonical agent policy file: `AGENTS.md`.
- In tickets/PR templates, include: "Follow AGENTS.md".
- Keep this `agents-howto.md` short and onboarding-focused.

## Reusable prompt template

Use this as a copy/paste starting point:

```text
Task: <what you want done>

Requirements:
- Read and follow /home/es/lab/AGENTS.md first.
- Follow code style and command guidance from AGENTS.md.
- Prefer smallest relevant tests first, then broader tests if needed.

Output format:
1) Summary of changes
2) Files changed
3) Commands executed
4) Test results
5) Risks / follow-ups
```
