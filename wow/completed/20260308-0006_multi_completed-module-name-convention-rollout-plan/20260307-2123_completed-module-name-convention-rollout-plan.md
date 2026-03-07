# Completed Folder Module Naming Convention Rollout Plan

- Status: completed
- Owner: es
- Started: 2026-03-07
- Updated: 2026-03-08 00:06
- Links: /home/es/lab/wow/completed/20260307-2048_multi_completed-folder-module-naming-unification-plan

## Goal
- Apply the required module-name convention consistently to all folders under `wow/completed/` before running the new maintenance workflow.

## Context
- A unification planning item was completed at `wow/completed/20260307-2048_multi_completed-folder-module-naming-unification-plan`.
- The next operational step is to execute the maintenance workflow, but naming alignment should be completed first to avoid checker noise and routing inconsistencies.
- Dry-run inventory shows 59 top-level completed folders: 2 v2 leaf folders, 56 legacy standard close folders, and 1 legacy bundle folder.
- Deterministic mapping checks for the 56 legacy standard folders found 0 duplicate rename targets and 0 conflicts with existing folder names.
- Applied the approved rename map and renamed all 56 targeted legacy-standard folders to v2-style `<timestamp>_<module>_<task-slug>` names.
- Post-rename reconciliation fixed two stale orchestration `Program` path references under `wow/completed/20260306-workflow_parallel-orchestration-upgrade-plan/20260306-2353_workflow_parallel-orchestration-upgrade-plan/`.

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
- Run `wow/task/completed-close` to close this active item with captured implementation and verification evidence.

## Triage Decision
- Why now: The maintenance workflow is blocked on naming consistency, so queueing this now prevents repeated checker failures and rework.
- Design classification:
  1. Are there meaningful alternatives for how to solve this? Yes.
  2. Will other code or users depend on the shape of the output? Yes.
  Design: required
- Justification: The rename strategy and report format drive downstream workflow execution and verification, so the implementation shape must be chosen deliberately.

## Documentation Impact
Docs: none

## Execution Plan
1. [done] Phase 1 (design): Define the deterministic rename design with inventory classes, constraints, trade-offs, and the selected mapping approach.
   Completion criterion met: this item now contains the design artifact with interfaces, constraints, trade-offs, chosen approach, and a concrete dry-run map.
2. [done] Phase 2 (implementation): Apply the approved rename map across `wow/completed/` while preserving v2 and legacy bundle/leaf validity.
   Completion criterion met: all 56 mapped legacy-standard folders were renamed with no duplicate targets and no invalid parent/leaf relationships introduced.
3. [done] Phase 3 (validation): Reconcile links and run workflow validation after rename application.
   Completion criterion met: stale path references were reconciled and `bash wow/check-workflow.sh` passed.

## Verification Plan
1. Create and review a dry-run inventory/mapping report before applying any rename operations.
2. Verify each applied rename preserves timestamp prefix semantics and expected module-key naming.
3. Verify bundle/leaf lineage remains intact for every nested completed artifact touched by the rename pass.
4. Run `bash wow/check-workflow.sh` after updates and record the output in workflow evidence.
5. Documentation verification: confirm this item remains `Docs: none`; if implementation introduces documentation-impacting workflow behavior changes, switch to `Docs: required` and update target docs in this same item before closeout.

## Exit Criteria
1. Rename design and approved mapping are documented in this active item.
2. All targeted `wow/completed/` folders are normalized to the required module-name convention without breaking compatibility allowances.
3. Checker validation and reconciliation evidence are captured with no unresolved blockers.

## Phase 1 Design Deliverable

## Interfaces (Contract)
1. Inventory input scope: top-level directories under `wow/completed/`.
2. Classification output classes: `v2 leaf`, `legacy standard`, `legacy bundle`, and `unknown`.
3. Rename contract for legacy standard folders: `<yyyymmdd-hhmm>_<legacy-slug>` -> `<yyyymmdd-hhmm>_<module>_<task-slug>`.
4. Module inference rule: `module` is the first token of `<legacy-slug>` before the first `-`; `task-slug` is the remainder after that first `-`.
5. Non-rename contract for this rollout: keep already-v2 leaf folders and legacy bundle folders unchanged.

## Constraints
1. Preserve close timestamp prefix (`yyyymmdd-hhmm`) exactly for every renamed folder.
2. Preserve semantic intent by retaining the remainder slug text verbatim after module extraction.
3. Reject any rename pass that introduces duplicate targets or target-name conflicts with existing folders.
4. Keep bundle/leaf lineage valid; no folder movement across parent containers during this phase.

## Trade-offs
1. First-token module inference is deterministic and fast, but may preserve historical module-token inconsistency where legacy slugs used broad tokens.
2. A manually curated mapping could improve semantic normalization, but adds subjective decisions and higher execution latency.
3. Single-pass bulk rename improves throughput, but demands strict preflight collision checks and clear rollback notes.

## Chosen Approach
1. Use deterministic first-token inference for module extraction from legacy standard slugs.
2. Approve a full dry-run map before any directory rename is applied.
3. Keep v2 leaf and legacy bundle names unchanged in this rollout.
4. Apply only non-conflicting renames and validate workflow integrity immediately after application.

## Dry-Run Inventory and Mapping Evidence
1. Inventory totals: 59 folders (`v2 leaf`: 2, `legacy standard`: 56, `legacy bundle`: 1, `unknown`: 0).
2. Candidate renames: 56.
3. Collision checks: 0 duplicate targets, 0 conflicts against existing folder names.

```text
20260227-0310_ana-module-expansion -> 20260227-0310_ana_module-expansion
20260227-0310_dic-framework-tests-fix -> 20260227-0310_dic_framework-tests-fix
20260227-0310_doc-overhaul -> 20260227-0310_doc_overhaul
20260228-1435_spec-hierarchy-and-enforcement-plan -> 20260228-1435_spec_hierarchy-and-enforcement-plan
20260228-1457_ana-rdp-callsite-profiles-implementation -> 20260228-1457_ana_rdp-callsite-profiles-implementation
20260228-2143_ana-doc-generators -> 20260228-2143_ana_doc-generators
20260228-2234_doc-json-temp-namespacing-plan -> 20260228-2234_doc_json-temp-namespacing-plan
20260301-0045_dep-pipeline-ref-expansion -> 20260301-0045_dep_pipeline-ref-expansion
20260301-0113_tst-pipeline-ref-expansion -> 20260301-0113_tst_pipeline-ref-expansion
20260301-0133_scp-pipeline-ref-expansion -> 20260301-0133_scp_pipeline-ref-expansion
20260301-0148_err-pipeline-ref-expansion -> 20260301-0148_err_pipeline-ref-expansion
20260301-0418_stats-generator-improvement-plan -> 20260301-0418_stats_generator-improvement-plan
20260301-1657_arc-docs-quality-upgrade -> 20260301-1657_arc_docs-quality-upgrade
20260301-2006_man-decision-flow-diagrams-plan -> 20260301-2006_man_decision-flow-diagrams-plan
20260301-2328_bootstrapper-performance-renewal -> 20260301-2328_bootstrapper_performance-renewal
20260302-0017_opencode-account-attribution -> 20260302-0017_opencode_account-attribution
20260303-0139_bootstrap-architectural-restructure-plan -> 20260303-0139_bootstrap_architectural-restructure-plan
20260303-0325_bootstrap-visual-output-redesign-plan -> 20260303-0325_bootstrap_visual-output-redesign-plan
20260304-0156_lazy-map-sync-requirement-gap -> 20260304-0156_lazy_map-sync-requirement-gap
20260304-0227_antigravity-account-reload-persistence -> 20260304-0227_antigravity_account-reload-persistence
20260304-0229_openai-account-visibility-in-osv -> 20260304-0229_openai_account-visibility-in-osv
20260304-0248_strict-mode-design-classification-mismatch-issue -> 20260304-0248_strict_mode-design-classification-mismatch-issue
20260304-2305_dev-oar-oad-removal-native-opencode -> 20260304-2305_dev_oar-oad-removal-native-opencode
20260304-2356_logging-performance-renewal -> 20260304-2356_logging_performance-renewal
20260305-0247_logging-architectural-restructure -> 20260305-0247_logging_architectural-restructure
20260305-0247_logging-visual-output-redesign -> 20260305-0247_logging_visual-output-redesign
20260305-0255_session-user-attribution-mismatch-issue -> 20260305-0255_session_user-attribution-mismatch-issue
20260305-2251_restore-dev-oar-dev-oad -> 20260305-2251_restore_dev-oar-dev-oad
20260305-2356_src-set-bootstrapper-logging-alignment -> 20260305-2356_src_set-bootstrapper-logging-alignment
20260306-0009_openai-user-unk-placeholder-regression-issue -> 20260306-0009_openai_user-unk-placeholder-regression-issue
20260306-0138_dev-default-active-account-integration-plan -> 20260306-0138_dev_default-active-account-integration-plan
20260306-0141_dev-osv-dev-olb-user-attribution-mismatch-issue -> 20260306-0141_dev_osv-dev-olb-user-attribution-mismatch-issue
20260306-0151_homelab-entity-playground-plan -> 20260306-0151_homelab_entity-playground-plan
20260306-0200_alias-generator-dissolve-into-lib-ops-usr-plan -> 20260306-0200_alias_generator-dissolve-into-lib-ops-usr-plan
20260306-0253_openai-account-switch-plan -> 20260306-0253_openai_account-switch-plan
20260306-0316_src-dic-preexisting-failures-followup-plan -> 20260306-0316_src_dic-preexisting-failures-followup-plan
20260306-0321_dic-debug-verbosity-coupling-followup-plan -> 20260306-0321_dic_debug-verbosity-coupling-followup-plan
20260306-2353_workflow-parallel-orchestration-upgrade-plan -> 20260306-2353_workflow_parallel-orchestration-upgrade-plan
20260307-0012_ref-pipeline-parity-validator-plan -> 20260307-0012_ref_pipeline-parity-validator-plan
20260307-0110_planning-workspace-session -> 20260307-0110_planning_workspace-session
20260307-0130_mapping-apply-phase-tooling -> 20260307-0130_mapping_apply-phase-tooling
20260307-0142_mapping-rules-v2-client-endpoints -> 20260307-0142_mapping_rules-v2-client-endpoints
20260307-0143_export-summary-naming-migration-plan -> 20260307-0143_export_summary-naming-migration-plan
20260307-0905_wow-root-migration-plan -> 20260307-0905_wow_root-migration-plan
20260307-0930_utl-ref-rename-plan -> 20260307-0930_utl_ref-rename-plan
20260307-0948_workflow-checker-completed-timestamp-regression-issue -> 20260307-0948_workflow_checker-completed-timestamp-regression-issue
20260307-1047_lib-architecture-review -> 20260307-1047_lib_architecture-review
20260307-1103_lib-confidence-gate-implementation -> 20260307-1103_lib_confidence-gate-implementation
20260307-1104_utl-doc-legacy-reference-cleanup-followup -> 20260307-1104_utl_doc-legacy-reference-cleanup-followup
20260307-1531_dev-ois-openai-switch-state-drift -> 20260307-1531_dev_ois-openai-switch-state-drift
20260307-1532_workflow-completed-folder-chronology-checker-issue -> 20260307-1532_workflow_completed-folder-chronology-checker-issue
20260307-1540_gen-aux-helper-contract-stabilization -> 20260307-1540_gen_aux-helper-contract-stabilization
20260307-1545_declarative-reconciliation-architecture -> 20260307-1545_declarative_reconciliation-architecture
20260307-1610_wow-legacy-reference-hard-purge -> 20260307-1610_wow_legacy-reference-hard-purge
20260307-1618_declarative-docs-alignment -> 20260307-1618_declarative_docs-alignment
20260307-2022_completed-close-bundle-auto-naming -> 20260307-2022_completed_close-bundle-auto-naming
```

## Progress Log
1. Completed Phase 1 design deliverable with interfaces, constraints, trade-offs, and chosen approach.
2. Generated and recorded a concrete 56-entry dry-run rename map with zero collision/conflict findings.
3. Transitioned immediately to Phase 2 and marked implementation as in progress.
4. Executed the approved rename pass and renamed 56 `wow/completed/` folders to v2 module-name format.
5. Resolved two post-rename stale orchestration program-path references in pilot workstream docs.
6. Completed Phase 3 validation with final checker pass.

## Reconciliation Report
1. Rename execution: 56 folder renames applied.
2. Path reconciliation: 2 stale links updated in:
   - `wow/completed/20260306-workflow_parallel-orchestration-upgrade-plan/20260306-2353_workflow_parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-checker-workstream-plan.md`
   - `wow/completed/20260306-workflow_parallel-orchestration-upgrade-plan/20260306-2353_workflow_parallel-orchestration-upgrade-plan/20260306-2343_orchestration-pilot-docs-workstream-plan.md`
3. Workflow validation:
   - First run after rename: failed with 2 missing Program-path targets.
   - Final run after reconciliation: `bash wow/check-workflow.sh` passed.

## What changed
- Applied and completed the module-name convention rollout across `wow/completed/`, including the 56-folder legacy-standard to v2-style rename pass described in this item.
- Reconciled two stale `Program` path references under the parallel orchestration pilot close leaf to match post-rename folder names.
- Closed this workflow item from `active` to `completed` state with immutable close-leaf placement.
- Documentation files updated: none.

## What was verified
- `bash wow/check-workflow.sh` -> pass.
- Dry-run mapping preflight and post-apply reconciliation evidence captured in this item (`0` duplicate targets, `0` conflicts; stale references resolved).
- Docs: none (workflow-state naming alignment only; no canonical doc content changed).

## What remains
- No mandatory follow-up items identified.
