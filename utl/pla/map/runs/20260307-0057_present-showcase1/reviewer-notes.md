# Reviewer Notes

- Run: `20260307-0057_present-showcase1`
- Target state: `present-showcase1`
- Reviewer decision: conditionally approved

## Summary

The proposal maps deterministic `HY_IPS` and `CT_IPS` aliases with high
confidence and complete source evidence.

## Accepted items

1. Accept host mappings: `h1`, `w2`.
2. Accept container mappings: `pbs1`, `nfs1`, `smb1`, `pbs2`, `nfs2`, `smb2`.
3. Accept all proposed `present-showcase1` state bindings for accepted entities.

## Rejected or revision-needed items

None.

## Unknown findings review

1. `CL_IPS[t1]` remains unresolved in v1 because role semantics are ambiguous.
2. Keep as unmapped until explicit type decision is documented.

## Approval recommendation

Publish `approved-mapping.json` with accepted entities and keep unknown findings
open in `reports/unmapped-findings.md`.
