PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS plg_entity_type (
    type_id INTEGER PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS plg_entity (
    entity_id INTEGER PRIMARY KEY,
    type_id INTEGER NOT NULL,
    key TEXT NOT NULL UNIQUE,
    label TEXT NOT NULL,
    lifecycle TEXT NOT NULL DEFAULT 'active' CHECK (
        lifecycle IN ('active', 'planned', 'retired', 'unknown')
    ),
    meta_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (type_id) REFERENCES plg_entity_type(type_id)
);

CREATE TABLE IF NOT EXISTS plg_relation_type (
    relation_type_id INTEGER PRIMARY KEY,
    key TEXT NOT NULL UNIQUE,
    src_type_id INTEGER NOT NULL,
    dst_type_id INTEGER NOT NULL,
    cardinality TEXT NOT NULL CHECK (
        cardinality IN ('one_to_one', 'one_to_many', 'many_to_one', 'many_to_many')
    ),
    description TEXT NOT NULL,
    FOREIGN KEY (src_type_id) REFERENCES plg_entity_type(type_id),
    FOREIGN KEY (dst_type_id) REFERENCES plg_entity_type(type_id)
);

CREATE TABLE IF NOT EXISTS plg_relation (
    relation_id INTEGER PRIMARY KEY,
    relation_type_id INTEGER NOT NULL,
    src_entity_id INTEGER NOT NULL,
    dst_entity_id INTEGER NOT NULL,
    meta_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (relation_type_id) REFERENCES plg_relation_type(relation_type_id),
    FOREIGN KEY (src_entity_id) REFERENCES plg_entity(entity_id),
    FOREIGN KEY (dst_entity_id) REFERENCES plg_entity(entity_id),
    UNIQUE (relation_type_id, src_entity_id, dst_entity_id),
    CHECK (src_entity_id <> dst_entity_id)
);

CREATE TABLE IF NOT EXISTS plg_state (
    state_id INTEGER PRIMARY KEY,
    kind TEXT NOT NULL CHECK (kind IN ('inventory', 'present', 'prototype', 'desired')),
    name TEXT NOT NULL,
    baseline_state_id INTEGER,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (
        status IN ('draft', 'candidate', 'selected', 'archived')
    ),
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (baseline_state_id) REFERENCES plg_state(state_id),
    UNIQUE (kind, name)
);

CREATE TABLE IF NOT EXISTS plg_state_entity (
    state_entity_id INTEGER PRIMARY KEY,
    state_id INTEGER NOT NULL,
    entity_id INTEGER NOT NULL,
    presence TEXT NOT NULL DEFAULT 'included' CHECK (
        presence IN ('included', 'excluded', 'modified')
    ),
    override_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (state_id) REFERENCES plg_state(state_id) ON DELETE CASCADE,
    FOREIGN KEY (entity_id) REFERENCES plg_entity(entity_id),
    UNIQUE (state_id, entity_id)
);

CREATE TABLE IF NOT EXISTS plg_state_relation (
    state_relation_id INTEGER PRIMARY KEY,
    state_id INTEGER NOT NULL,
    relation_id INTEGER NOT NULL,
    presence TEXT NOT NULL DEFAULT 'included' CHECK (
        presence IN ('included', 'excluded', 'modified')
    ),
    override_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (state_id) REFERENCES plg_state(state_id) ON DELETE CASCADE,
    FOREIGN KEY (relation_id) REFERENCES plg_relation(relation_id),
    UNIQUE (state_id, relation_id)
);

CREATE TABLE IF NOT EXISTS plg_cfg_snapshot (
    snapshot_id INTEGER PRIMARY KEY,
    captured_at TEXT NOT NULL DEFAULT (datetime('now')),
    env_root TEXT NOT NULL,
    digest TEXT NOT NULL,
    raw_json TEXT NOT NULL DEFAULT '{}',
    UNIQUE (digest)
);

CREATE TABLE IF NOT EXISTS plg_cfg_binding (
    binding_id INTEGER PRIMARY KEY,
    snapshot_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    entity_id INTEGER NOT NULL,
    source_path TEXT NOT NULL,
    binding_key TEXT NOT NULL,
    confidence REAL NOT NULL DEFAULT 1.0 CHECK (confidence >= 0.0 AND confidence <= 1.0),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (snapshot_id) REFERENCES plg_cfg_snapshot(snapshot_id) ON DELETE CASCADE,
    FOREIGN KEY (state_id) REFERENCES plg_state(state_id),
    FOREIGN KEY (entity_id) REFERENCES plg_entity(entity_id),
    UNIQUE (snapshot_id, state_id, entity_id, source_path, binding_key)
);

CREATE TABLE IF NOT EXISTS plg_impl_plan (
    plan_id INTEGER PRIMARY KEY,
    present_state_id INTEGER NOT NULL,
    desired_state_id INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (
        status IN ('draft', 'approved', 'applied', 'archived')
    ),
    summary TEXT NOT NULL DEFAULT '',
    generated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (present_state_id) REFERENCES plg_state(state_id),
    FOREIGN KEY (desired_state_id) REFERENCES plg_state(state_id)
);

CREATE TABLE IF NOT EXISTS plg_impl_step (
    step_id INTEGER PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    ordinal INTEGER NOT NULL CHECK (ordinal > 0),
    action TEXT NOT NULL,
    target_ref TEXT NOT NULL,
    expected_result TEXT NOT NULL DEFAULT '',
    risk_level TEXT NOT NULL DEFAULT 'medium' CHECK (
        risk_level IN ('low', 'medium', 'high')
    ),
    patch_path TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (plan_id) REFERENCES plg_impl_plan(plan_id) ON DELETE CASCADE,
    UNIQUE (plan_id, ordinal)
);

CREATE INDEX IF NOT EXISTS idx_plg_entity_type_id ON plg_entity(type_id);
CREATE INDEX IF NOT EXISTS idx_plg_relation_src ON plg_relation(src_entity_id);
CREATE INDEX IF NOT EXISTS idx_plg_relation_dst ON plg_relation(dst_entity_id);
CREATE INDEX IF NOT EXISTS idx_plg_state_kind_status ON plg_state(kind, status);
CREATE INDEX IF NOT EXISTS idx_plg_cfg_binding_snapshot ON plg_cfg_binding(snapshot_id);
CREATE INDEX IF NOT EXISTS idx_plg_impl_plan_states ON plg_impl_plan(present_state_id, desired_state_id);

COMMIT;
