# Completed Folder Module Naming Convention Rollout Plan

- Status: inbox
- Owner: es
- Started: n/a
- Updated: 2026-03-07
- Links: /home/es/lab/wow/completed/20260307-2048_multi_completed-folder-module-naming-unification-plan

## Goal
- Apply the required module-name convention consistently to all folders under `wow/completed/` before running the new maintenance workflow.

## Context
- A unification planning item was completed at `wow/completed/20260307-2048_multi_completed-folder-module-naming-unification-plan`.
- The next operational step is to execute the maintenance workflow, but naming alignment should be completed first to avoid checker noise and routing inconsistencies.

## Scope
- Inventory every folder in `wow/completed/` and classify each as v2-compliant, legacy-compatible, or requiring rename.
- Define a deterministic rename map that applies the module-name convention without changing timestamps or semantic intent.
- Include safeguards for bundle/leaf relationships so nested close artifacts remain valid.
- Validate post-rename state with `bash wow/check-workflow.sh`.

## Risks
- Over-aggressive renaming could break bundle lineage or violate legacy-compatibility allowances.
- Timestamp/module-key collisions may occur when normalizing multiple folders in the same day/module window.
- External references in docs or follow-up links may require synchronized updates.

## Next Step
- Promote this inbox item to active and execute a staged rename pass (dry-run mapping, apply, checker validation, and final reconciliation report).
