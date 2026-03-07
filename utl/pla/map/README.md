# LLM Mapping Workspace (`utl/pla/map`)

This workspace stores contracts, prompts, rules, and run artifacts for
LLM-assisted mapping from `cfg/env` snapshots into planning entities.

The workflow is artifact-first:

1. Capture snapshot (`import-present`).
2. Produce proposal artifacts (`input-manifest.json`, `llm-proposal.json`).
3. Review and approve (`reviewer-notes.md`, `approved-mapping.json`).
4. Track unknowns (`reports/unmapped-findings.md`).

## Directory layout

```text
utl/pla/map/
├── contracts/   # output schema and policy contracts
├── prompts/     # extraction/review prompt templates
├── rules/       # mapping rules by config convention
├── runs/        # timestamped run artifacts
└── reports/     # aggregated unresolved findings
```

## Safety boundaries

- Mapping phases are capture/modeling only.
- Do not call `lib/ops/*` functions.
- Do not execute infrastructure mutations.
- Do not write directly to planning DB tables during extraction/review.

## Run contract

Every run folder under `runs/` should contain:

- `input-manifest.json`
- `llm-proposal.json`
- `reviewer-notes.md`
- `approved-mapping.json`

## Related files

- `contracts/mapping-output.schema.json`
- `contracts/confidence-policy.md`
- `contracts/key-naming-policy.md`
- `prompts/extract-v1.md`
- `prompts/review-v1.md`
