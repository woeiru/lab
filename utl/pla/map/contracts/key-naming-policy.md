# Key Naming Policy

This policy defines stable entity-key conventions for mapping outputs.

## General format

1. Use lowercase alphanumeric with optional hyphens: `^[a-z0-9][a-z0-9-]*$`.
2. Avoid underscores and spaces.
3. Preserve stable existing aliases when available (for example `h1`, `w2`, `pbs1`).

## Type guidance

1. `host`: use host alias when present (`h1`, `w2`).
2. `ct`: use container alias when present (`pbs1`, `nfs1`).
3. `vm`: use VM alias or deterministic VM key (`vm-<id>` if alias is unavailable).
4. `service`: use service role key (`svc-traefik`, `svc-nfs`, `svc-smb`).
5. Other types: use deterministic short keys with meaningful role intent.

## Collision policy

1. Keys must be unique across `plg_entity`.
2. If a collision occurs, do not auto-rename silently.
3. Record the collision in unmapped findings and require reviewer decision.
