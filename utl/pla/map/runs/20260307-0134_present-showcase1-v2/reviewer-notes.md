# Reviewer Notes

- Run: `20260307-0134_present-showcase1-v2`
- Target state: `present-showcase1`
- Reviewer decision: approved

## Summary

The v2 proposal preserves deterministic `HY_IPS` and `CT_IPS` mappings and adds
explicit client-endpoint classification for `CL_IPS[t1]` as a host endpoint.

## Accepted items

1. Accept host mappings: `h1`, `w2`, `t1`.
2. Accept container mappings: `pbs1`, `nfs1`, `smb1`, `pbs2`, `nfs2`, `smb2`.
3. Accept all proposed `present-showcase1` state bindings for accepted entities.

## Rejected or revision-needed items

None.

## Unknown findings review

1. `CL_IPS[t1]` moved from unresolved status in v1 to explicit v2 host-endpoint
   classification.
2. No remaining unknown findings for this run.

## Approval recommendation

Publish `approved-mapping.json` for v2 and update aggregated
`reports/unmapped-findings.md` to close the prior unresolved `CL_IPS[t1]`
finding.
