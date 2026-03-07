# Confidence Policy

This policy defines confidence levels for LLM mapping outputs.

## Levels

| Level | Meaning | Reviewer expectation |
| --- | --- | --- |
| `high` | Deterministic extraction from stable pattern with direct source trace. | Spot-check only.
| `medium` | Mostly deterministic but includes assumptions (naming/context). | Targeted review required.
| `low` | Heuristic guess or incomplete context. | Explicit human approval required.

## Requirements

1. Every proposed entity must include one confidence value.
2. Every confidence claim must include rationale.
3. Every confidence claim must include source evidence (`source_path`, `binding_key`).

## Review gates

1. `high` and approved `medium` mappings can be included in `approved-mapping.json`.
2. `low` mappings cannot be auto-approved and must be explicitly accepted or rejected.
3. Unknown findings must be tracked even when confidence for other rows is high.
