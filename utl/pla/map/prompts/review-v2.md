# Review Prompt v2

Use this prompt to review a v2 proposed mapping output and produce reviewer
notes.

## Task

Review `llm-proposal.json` against v2 rules and contracts, then decide for each
item:

- accept
- reject
- needs revision

## Inputs

1. `input-manifest.json`
2. `llm-proposal.json`
3. Contracts under `utl/pla/map/contracts/`
4. Rules under `utl/pla/map/rules/` (`cfg-env-v2.yaml`)

## Output

Write `reviewer-notes.md` with:

1. Decision summary
2. Accepted items
3. Rejected/revision-needed items with reasons
4. Unknown findings review
5. Approval recommendation for `approved-mapping.json`

## Review checks

1. Evidence completeness (`source_path`, `binding_key`).
2. Confidence alignment with policy.
3. Key naming compliance.
4. Duplicate/conflicting keys.
5. v2 endpoint policy conformance (`CL_IPS[*]` mapped as `host` with
   `Client endpoint <alias>` labels).
6. Unknown findings are explicit and actionable.
