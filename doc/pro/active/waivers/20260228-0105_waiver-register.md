# Waiver Register

- Status: active
- Owner: es
- Started: 2026-02-28
- Updated: 2026-03-03
- Links: `doc/pro/active/waivers/waiver-register-template.md`, `doc/pro/active/spec-hierarchy-and-enforcement-plan.md`

This register tracks temporary policy waivers with explicit owners and removal deadlines.

## Waiver entries

### WVR-2026-001

- Rule ID: `GLB-008`
- Location: `lib/gen/inf:90`
- Current finding: resolved (no active GLB-008 match at `lib/gen/inf:90`)
- Owner: `es`
- Approved on: `2026-02-28`
- Expires on: `2026-03-31`
- Risk level: `medium`
- Rationale: keep backward compatibility for current container-definition flows during report-mode stabilization and strict-mode cutover preparation.
- Removal criteria: replace hardcoded literal password default with env-backed or explicit-input path and verify container definition flows remain functional.
- Tracking link: `doc/pro/active/spec-hierarchy-and-enforcement-plan.md`
- Verification: `./val/core/glb_008_secret_scan_test.sh` -> `Potential secret matches: 0`.
- Status: `resolved`
