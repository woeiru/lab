# Homelab Entity Playground Plan

- Status: completed
- Owner: es
- Started: 2026-03-06
- Updated: 2026-03-06 01:50:09
- Links: cfg/env/, doc/pro/task/inbox-capture, doc/pro/task/RULES.md

## Goal

Design a `utl/` playground module for homelab entities that combines inventory
tracking with planning/simulation, so an agent can maintain state and generate
implementation plans from present state to desired state.

## Context

1. The user wants planning/simulation and inventory to work together, not as
   separate tracks.
2. The planned workflow includes inventory data, present state, desired state,
   and many prototype states explored in between.
3. Present state should mirror `cfg/env/`, while planning artifacts should be
   represented in a normalized model that can meet `cfg/env/` at a clear
   interface boundary.
4. The preferred storage choice is SQLite in-repo (commit all for now), with
   human-readable exports for direct repository consumption.
5. Initial operating model is single-owner usage; direct agent writes are
   allowed when intent is clear.
6. Execution entrypoint selected: start with design-first delivery under this
   active item before implementation scaffolding.
7. Source-of-truth split candidate identified: `cfg/env/` for present-state
   extraction, SQLite for inventory/scenario/desired-state planning artifacts.
8. Workflow needs explicit plan/diff/apply checkpoints before modifying
   `cfg/env/` to avoid unsafe direct drift.
9. Existing repository shape confirms `utl/` is the right home for
   out-of-band helper workflows and generators.
10. V1 should stay local-first and single-owner, with an operation layer that
    can be exposed via MCP later without reworking storage.
11. Human-readable exports are required companions to committed SQLite changes
    to keep review and archive workflows understandable.
12. Folder naming decision applied: implementation root is `utl/pla/` (not
    `utl/playground/`) across docs, schema paths, and CLI defaults.
13. Baseline scaffold delivered: `utl/pla/cli`, `utl/pla/sql/*`,
    `utl/pla/data/`, `utl/pla/export/`, and `utl/pla/ops/`.
14. CLI now supports `init-db`, `import-present`, and `export-md` using
    Python's built-in SQLite driver for portability.
15. Validation evidence captured: syntax check passed, DB initialized,
    `cfg/env` imported into present state, and markdown snapshot generated.
16. Planning-loop operations now include `create-state`, `upsert-entity`,
    `set-state-entity`, and `plan-implementation` to model desired states and
    produce ordered implementation steps.
17. A sample present->desired plan was generated in the playground DB and is
    visible in markdown exports for review.

## Scope

1. Define v1 entity model and relations for host/switch machines, host
   hardware components, hypervisor/OS layers, VMs, CTs, pools, and services.
2. Define state model for inventory, present state, desired state, and
   prototype scenario states.
3. Define normalized sync interface between `cfg/env/` data and planning data.
4. Define workflow structure for brainstorming in playground, selecting desired
   state, generating implementation plan, and archiving completed runs.
5. Define repository exports for readable Markdown snapshots of inventory/state
   data.
6. Define agent interaction guardrails for direct writes vs plan-first changes,
   especially when affecting `cfg/env/`.
7. Evaluate MCP as a future integration layer, but do not require it for v1.

## Triage Decision

- Why now: this unlocks a concrete planning workflow and schema boundary before
  future `cfg/env` convergence work increases rework risk.
- Meaningful alternatives for solving this: yes.
- Other code or users depending on output shape: yes.
- Design: required.
- Justification: entity relationships, state boundaries, and sync contracts will
  define downstream tooling and agent behavior, so design choices must be
  explicit early.

## Execution Plan

### Phase 1 -- Define Design Contract (completed)

- [x] Lock v1 domain vocabulary and state boundaries (inventory, present,
  desired, prototype scenarios).
- [x] Draft normalized entity/relation and state model shape for SQLite.
- [x] Draft normalized interface contract between `cfg/env/` and planning data.
- [x] Finalize the Phase 1 design decision record (interfaces, constraints,
  trade-offs, chosen approach) in this file.

Completion criterion: this file contains a concrete design decision record with
interfaces, constraints, trade-offs, and a chosen v1 approach.

### Phase 2 -- Scaffold `utl/` Playground Baseline (completed)

- [x] Confirm `utl/` scaffold location and naming aligned with existing
  repository utility conventions.
- [x] Create module layout and SQLite schema/migration scaffolding.
- [x] Add seed and export plumbing for human-readable repository output.

Completion criterion: baseline module skeleton and schema scaffolding exist with
no unresolved structural TODOs.

### Phase 3 -- Implement Planning Loop (completed)

- [x] Implement present-state import from `cfg/env/` into normalized records.
- [x] Implement scenario/desired-state workflows and implementation-plan output.
- [x] Implement markdown export artifacts for inventory/state snapshots.

Completion criterion: present->desired planning loop produces deterministic plan
artifacts from repository data.

### Phase 4 -- Verify and Archive Workflow (completed)

- [x] Validate affected behavior with targeted checks and workflow checker.
- [x] Prepare handoff notes and archive path for completed run.

Completion criterion: verification evidence is recorded and item is ready for
`completed/` transition.

## Verification Plan

1. Validate workflow document integrity with `bash doc/pro/check-workflow.sh`.
2. When implementation starts, run nearest targeted validation commands for
   changed files and scripts.
3. Confirm generated markdown exports are readable and stable for git review.

## Exit Criteria

1. A finalized design decision record exists for schema, state model, and
   `cfg/env` integration contract.
2. The playground can represent inventory, present state, desired state, and
   prototype scenarios with explicit relations.
3. Implementation-plan artifacts can be generated from present->desired
   transitions and reviewed in repository-friendly format.

## Phase 1 Design Decision Record

Date: 2026-03-06
Design classification: required

1. Chosen architecture:
   - SQLite-backed typed graph model (entities + relations + state overlays).
   - Repository-local database under `utl/pla/data/` with schema SQL in
     `utl/pla/sql/`.
   - Operation layer in `utl/pla/ops/` so agent interactions call
     validated actions instead of mutating DB tables or `cfg/env/` directly.
2. Source-of-truth split (v1):
   - Inventory, prototype scenarios, desired states, and implementation plans:
     SQLite is authoritative.
   - Present state: imported from `cfg/env/` snapshots; `cfg/env/` remains the
     operational truth until an implementation plan is explicitly applied.
3. Table-level contract (v1):
   - `plg_entity_type(type_id, key, category, description)` defines allowed
     entity kinds (`host`, `switch`, `hardware`, `hypervisor_os`, `vm`, `ct`,
     `pool`, `service`).
   - `plg_entity(entity_id, type_id, key, label, lifecycle, meta_json)` stores
     canonical entities independent of any one scenario.
   - `plg_relation_type(relation_type_id, key, src_type_id, dst_type_id,
     cardinality, description)` defines allowed typed edges.
   - `plg_relation(relation_id, relation_type_id, src_entity_id, dst_entity_id,
     meta_json)` stores canonical relationships.
   - `plg_state(state_id, kind, name, baseline_state_id, status, notes)` stores
     inventory/present/prototype/desired snapshots and lineage.
   - `plg_state_entity(state_id, entity_id, presence, override_json)` overlays
     entity participation per state.
   - `plg_state_relation(state_id, relation_id, presence, override_json)`
     overlays relationship participation per state.
   - `plg_cfg_snapshot(snapshot_id, captured_at, env_root, digest, raw_json)`
     records normalized imports from `cfg/env/`.
   - `plg_cfg_binding(binding_id, snapshot_id, state_id, entity_id,
     source_path, binding_key, confidence)` maps imported config material to
     modeled entities.
   - `plg_impl_plan(plan_id, present_state_id, desired_state_id, status,
     summary, generated_at)` stores transition plans.
   - `plg_impl_step(step_id, plan_id, ordinal, action, target_ref,
     expected_result, risk_level, patch_path)` stores ordered execution steps.
4. Validation defaults (non-negotiable in v1):
   - Every `hardware` entity links to exactly one `host` via typed relation.
   - Every `hypervisor_os` links to exactly one `host`.
   - Every `vm`/`ct` links to exactly one runtime host.
   - Every `pool` links to exactly one host.
   - Every `service` must run on exactly one runtime target (`host`, `vm`, or
     `ct`).
   - Desired states must descend from an existing present/prototype lineage.
   - Implementation plan generation requires one present and one desired state.
5. Normalized `cfg/env/` integration contract:
   - `import-present`: parse and normalize `cfg/env/` into `plg_cfg_snapshot`,
     then materialize a new `present` `plg_state` plus bindings.
   - `plan-implementation`: compute present->desired delta and emit ordered
     `plg_impl_step` actions with optional patch artifact paths.
   - `apply-plan`: apply generated patches to `cfg/env/` only from persisted
     plan steps; never from ad-hoc freeform updates.
6. Human-readable export contract:
   - For each selected state and plan, write Markdown snapshots under
     `utl/pla/export/` (inventory graph, state summary, plan steps).
   - Keep exports deterministic so git diffs remain reviewable alongside DB
     updates.
7. Alternatives considered and trade-offs:
   - JSON-only files: simpler initially, weaker relational integrity and query
     reliability at scenario scale.
   - Direct agent edits to `cfg/env/`: faster but unsafe for traceability and
     change intent review.
   - Graph DB: expressive but unnecessary operational complexity for v1.
8. Final choice rationale:
   - SQLite + typed operation layer provides strong integrity, local simplicity,
     and a clean future bridge to MCP when multi-client or remote tooling is
     needed.

## Progress Checkpoint

### Done

1. Added baseline module scaffold in `utl/pla/` with README, operation folder,
   data/export folders, and SQL assets.
2. Added core schema and seed scripts:
   `utl/pla/sql/001_init_schema.sql` and `utl/pla/sql/010_seed_reference.sql`.
3. Added executable CLI entrypoint `utl/pla/cli` with `init-db`,
   `import-present`, `create-state`, `upsert-entity`, `set-state-entity`,
   `plan-implementation`, and `export-md` commands.
4. Imported `cfg/env/` into a first present snapshot/state and generated
   markdown summary output.
5. Created a sample desired state, attached a service entity, generated an
   implementation plan, and exported it to markdown.

### Validation status

1. `bash -n /home/es/lab/utl/pla/cli` -> pass
2. `/home/es/lab/utl/pla/cli init-db /home/es/lab/utl/pla/data/ply.db` -> pass
3. `/home/es/lab/utl/pla/cli import-present /home/es/lab/utl/pla/data/ply.db /home/es/lab/cfg/env` -> pass
4. `/home/es/lab/utl/pla/cli create-state /home/es/lab/utl/pla/data/ply.db desired desired-site1 present-20260306-013604 candidate` -> pass
5. `/home/es/lab/utl/pla/cli upsert-entity /home/es/lab/utl/pla/data/ply.db service svc-traefik "Traefik"` -> pass
6. `/home/es/lab/utl/pla/cli set-state-entity /home/es/lab/utl/pla/data/ply.db desired-site1 svc-traefik included` -> pass
7. `/home/es/lab/utl/pla/cli plan-implementation /home/es/lab/utl/pla/data/ply.db present-20260306-013604 desired-site1` -> pass
8. `/home/es/lab/utl/pla/cli export-md /home/es/lab/utl/pla/data/ply.db /home/es/lab/utl/pla/export/inventory-summary.md` -> pass
9. `bash doc/pro/check-workflow.sh` -> pass

## Handoff Notes

1. Core scaffold and CLI are in `utl/pla/` with schema, seed data, runtime DB,
   and markdown export baseline.
2. Main operator entrypoint is `utl/pla/cli`; commands implemented:
   `init-db`, `import-present`, `create-state`, `upsert-entity`,
   `set-state-entity`, `plan-implementation`, `export-md`.
3. Verified sample artifacts:
   - DB: `utl/pla/data/ply.db`
   - Export: `utl/pla/export/inventory-summary.md`
4. Recommended completed archive target:
   `doc/pro/completed/20260306-0143_homelab-entity-playground-plan/`

## What changed

1. Added a new homelab playground module at `utl/pla/` with schema, seed,
   operation placeholders, runtime data path, and export path.
2. Implemented `utl/pla/cli` commands for database bootstrap, present-state
   import from `cfg/env/`, state/entity modeling, plan generation, and markdown
   export.
3. Created baseline runtime artifacts for review:
   `utl/pla/data/ply.db` and `utl/pla/export/inventory-summary.md`.
4. Updated utility documentation in `utl/README.md` and `utl/pla/README.md` to
   document the new command surface and workflow.

## What was verified

1. `bash -n /home/es/lab/utl/pla/cli` -> pass
2. `/home/es/lab/utl/pla/cli init-db /home/es/lab/utl/pla/data/ply.db` -> pass
3. `/home/es/lab/utl/pla/cli import-present /home/es/lab/utl/pla/data/ply.db /home/es/lab/cfg/env` -> pass
4. `/home/es/lab/utl/pla/cli create-state /home/es/lab/utl/pla/data/ply.db desired desired-site1 present-20260306-013604 candidate` -> pass
5. `/home/es/lab/utl/pla/cli upsert-entity /home/es/lab/utl/pla/data/ply.db service svc-traefik "Traefik"` -> pass
6. `/home/es/lab/utl/pla/cli set-state-entity /home/es/lab/utl/pla/data/ply.db desired-site1 svc-traefik included` -> pass
7. `/home/es/lab/utl/pla/cli plan-implementation /home/es/lab/utl/pla/data/ply.db present-20260306-013604 desired-site1` -> pass
8. `/home/es/lab/utl/pla/cli export-md /home/es/lab/utl/pla/data/ply.db /home/es/lab/utl/pla/export/inventory-summary.md` -> pass
9. `bash doc/pro/check-workflow.sh` -> pass

## What remains

1. No required follow-up captured from this baseline close.

## Risks

1. State drift between `cfg/env/` and database records if sync contracts are
   ambiguous.
2. Incorrect direct agent writes could create invalid transitions without
   stronger validation gates.
3. Early schema overreach could slow iteration before core planning loops are
   proven.
4. Committing binary SQLite files can reduce diff clarity unless paired with
   reliable readable exports.

## Next Step

Closed into completed archive: `doc/pro/completed/20260306-0151_homelab-entity-playground-plan/`.
