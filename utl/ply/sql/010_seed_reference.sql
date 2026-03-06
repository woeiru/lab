PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

INSERT OR IGNORE INTO plg_entity_type (key, category, description) VALUES
    ('host', 'machine', 'Physical or virtual host machine'),
    ('switch', 'machine', 'Network switching machine'),
    ('hardware', 'component', 'Hardware component inside a host'),
    ('hypervisor_os', 'runtime', 'Installed host hypervisor or operating system'),
    ('vm', 'runtime', 'Virtual machine'),
    ('ct', 'runtime', 'Container runtime instance'),
    ('pool', 'storage', 'Storage pool definition on a host'),
    ('service', 'service', 'Service running on host, VM, or container');

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'contains_hardware',
    src.type_id,
    dst.type_id,
    'one_to_many',
    'Host contains hardware component'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'host' AND dst.key = 'hardware';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'runs_hypervisor_os',
    src.type_id,
    dst.type_id,
    'one_to_one',
    'Host runs installed hypervisor or operating system'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'host' AND dst.key = 'hypervisor_os';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'hosts_vm',
    src.type_id,
    dst.type_id,
    'one_to_many',
    'Host provides runtime for virtual machine'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'host' AND dst.key = 'vm';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'hosts_ct',
    src.type_id,
    dst.type_id,
    'one_to_many',
    'Host provides runtime for container'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'host' AND dst.key = 'ct';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'owns_pool',
    src.type_id,
    dst.type_id,
    'one_to_many',
    'Host owns storage pool'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'host' AND dst.key = 'pool';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'connected_to_switch',
    src.type_id,
    dst.type_id,
    'many_to_one',
    'Host connected to upstream switch'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'host' AND dst.key = 'switch';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'switch_link',
    src.type_id,
    dst.type_id,
    'many_to_many',
    'Switch uplink or peer link'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'switch' AND dst.key = 'switch';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'vm_uses_pool',
    src.type_id,
    dst.type_id,
    'many_to_one',
    'Virtual machine consumes storage pool'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'vm' AND dst.key = 'pool';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'ct_uses_pool',
    src.type_id,
    dst.type_id,
    'many_to_one',
    'Container consumes storage pool'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'ct' AND dst.key = 'pool';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'service_runs_on_host',
    src.type_id,
    dst.type_id,
    'many_to_one',
    'Service instance runs on host runtime target'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'service' AND dst.key = 'host';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'service_runs_on_vm',
    src.type_id,
    dst.type_id,
    'many_to_one',
    'Service instance runs inside VM runtime target'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'service' AND dst.key = 'vm';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'service_runs_on_ct',
    src.type_id,
    dst.type_id,
    'many_to_one',
    'Service instance runs inside container runtime target'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'service' AND dst.key = 'ct';

INSERT OR IGNORE INTO plg_relation_type (
    key,
    src_type_id,
    dst_type_id,
    cardinality,
    description
)
SELECT
    'service_depends_on_service',
    src.type_id,
    dst.type_id,
    'many_to_many',
    'Service depends on another service'
FROM plg_entity_type src
JOIN plg_entity_type dst
WHERE src.key = 'service' AND dst.key = 'service';

COMMIT;
