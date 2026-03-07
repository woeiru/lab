# Extract Prompt v1

Use this prompt to generate `llm-proposal.json` from a selected planning snapshot.

## Task

Extract mapping candidates from the provided snapshot evidence into typed planning entities.

## Inputs

1. `input-manifest.json` for snapshot metadata and selected source files.
2. Active rule set under `utl/pla/map/rules/`.
3. Contract files under `utl/pla/map/contracts/`.

## Output contract

1. Output must validate against `contracts/mapping-output.schema.json`.
2. Set `output_kind` to `proposal`.
3. Populate all required fields.

## Required behavior

1. Use only evidence from listed source files.
2. Include `source_path` and `binding_key` for every proposed entity.
3. Assign confidence using `contracts/confidence-policy.md`.
4. Keep keys compliant with `contracts/key-naming-policy.md`.
5. Emit unknown patterns in `unmapped_findings`; do not hide or coerce unknowns.

## Safety constraints

1. Do not execute infrastructure operations.
2. Do not mutate planning DB tables.
3. Do not infer hidden rules outside declared rule files.
