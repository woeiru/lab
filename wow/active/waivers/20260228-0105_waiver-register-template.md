# Waiver Register Template

Use this template to track temporary policy waivers in one place.

## When to use

- A rule violation is known and accepted temporarily.
- Immediate remediation is intentionally deferred.
- There is a clear owner and deadline to remove the waiver.

## Register fields (required)

- `Waiver ID`: unique id (example: `WVR-2026-001`)
- `Rule ID`: policy id (example: `GLB-008`)
- `Location`: file and line (example: `lib/gen/inf:90`)
- `Current finding`: exact matched pattern/value
- `Owner`: accountable person
- `Approved on`: date waiver was accepted
- `Expires on`: removal deadline (must not be open-ended)
- `Risk level`: low | medium | high
- `Rationale`: why temporary acceptance is needed
- `Removal criteria`: what must be true to close waiver
- `Tracking link`: active plan/issue path
- `Verification`: last command + result snapshot
- `Status`: active | expired | removed

## Entry template

```md
### <Waiver ID>

- Rule ID: <GLB-xxx or OPS-xxx>
- Location: <path:line>
- Current finding: <exact matched string>
- Owner: <name>
- Approved on: YYYY-MM-DD
- Expires on: YYYY-MM-DD
- Risk level: low | medium | high
- Rationale: <short justification>
- Removal criteria: <specific completion condition>
- Tracking link: <wow/... or issue link>
- Verification: `<command>` -> <key output>
- Status: active
```

## Example entry

```md
### WVR-2026-001

- Rule ID: GLB-008
- Location: lib/gen/inf:90
- Current finding: declare -g CT_DEFAULT_PASSWORD="password"
- Owner: es
- Approved on: 2026-02-28
- Expires on: 2026-03-31
- Risk level: medium
- Rationale: keep backward compatibility during strict-mode rollout
- Removal criteria: replace literal default with env or explicit input path
- Tracking link: wow/active/spec-hierarchy-and-enforcement-plan.md
- Verification: `./val/core/glb_008_secret_scan_test.sh --report` -> Potential secret matches: 1
- Status: active
```

## Lifecycle rules

- Review all `active` waivers at least weekly.
- If `Expires on` is reached, set status to `expired` and prioritize remediation.
- When fixed, set status to `removed` and include final verification command output.
