# Extract Prompt v2

Use this prompt to generate `llm-proposal.json` from a selected planning
snapshot using v2 client-endpoint rules.

## Task

Extract mapping candidates from provided snapshot evidence into typed planning
entities.

## Inputs

1. `input-manifest.json` for snapshot metadata and selected source files.
2. Active rule set under `utl/pla/map/rules/` (`cfg-env-v2.yaml` for this flow).
3. Contract files under `utl/pla/map/contracts/`.

## Output contract

1. Output must validate against `contracts/mapping-output.schema.json`.
2. Set `output_kind` to `proposal`.
3. Keep `contract_version` at `v1` for apply compatibility.
4. Populate all required fields.

## Required behavior

1. Use only evidence from listed source files.
2. Include `source_path` and `binding_key` for every proposed entity.
3. Assign confidence using `contracts/confidence-policy.md`.
4. Keep keys compliant with `contracts/key-naming-policy.md`.
5. Apply v2 endpoint policy: `CL_IPS[*]` aliases map to `host` with labels in
   the format `Client endpoint <alias>`.
6. Emit unknown patterns in `unmapped_findings`; do not hide or coerce unknowns.

## Safety constraints

1. Do not execute infrastructure operations.
2. Do not mutate planning DB tables.
3. Do not infer hidden rules outside declared rule files.
