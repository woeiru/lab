# Architecture Map

## Architecture Map
- `./go` is the user-facing CLI and shell-integrator, not the runtime loader itself (`go:30`, `go:521`).
- Runtime boot path is:
1. `bin/ini` (core bootstrap, module/runtime init, logging/timing setup) (`bin/ini:202`, `bin/ini:706`)
2. `bin/orc` (component sourcing orchestration) (`bin/orc:595`, `bin/orc:622`)
3. Loads config + ops/gen libs + aliases, then exposes `ops` alias to DIC (`cfg/ali/sta:168`)
- Operational execution splits into:
1. `src/dic/ops` generic dispatch/injection engine (`src/dic/ops:126`, `src/dic/ops:315`)
2. `lib/ops/*` pure-ish domain functions (`lib/ops/pve`, `lib/ops/sys`, `lib/ops/sto`, etc.)
3. `src/set/*` playbook-style section scripts calling `ops ... -j` (`src/set/h1:52`, `src/set/t1:31`)
- Configuration model:
1. Runtime constants in `cfg/core/ric` (`cfg/core/ric:94`)
2. Environment selector in `cfg/core/ecc` (`cfg/core/ecc:24`)
3. Site/env/node overlays (`cfg/core/ric:99`, `cfg/env/site1`, `cfg/env/site1-dev`, `cfg/env/site1-w2`)
- No conventional build system (`Makefile`, `package.json`, `go.mod`, etc.) is present; this is a sourced Bash platform.

## Key Module Responsibilities
- `go`: install/remove managed shell block + invoke validation (`go:172`, `go:531`)
- `bin/ini`: bootstrap core modules (`ver/err/lo1/tme`), then orchestrate components (`bin/ini:418`, `bin/ini:329`)
- `bin/orc`: source env, aliases, ops libs, gen libs, aux (optional) (`bin/orc:473`, `bin/orc:524`, `bin/orc:622`)
- `src/dic/ops`: validate module/function, resolve/inject args, execute target function (`src/dic/ops:204`, `src/dic/ops:396`)
- `src/dic/lib/*`: signature extraction + variable resolver + injection strategies (`src/dic/lib/introspector`, `src/dic/lib/resolver`, `src/dic/lib/injector`)
- `src/set/*`: grouped deployment workflows (`a_xall/b_xall/...`) mapped to ops calls (`src/set/h1`, `src/set/c1`)
- `lib/gen/inf`: declarative CT/VM definitions and defaults (`lib/gen/inf:115`, `lib/gen/inf:176`)
- `lib/gen/sec`: password generation/storage/init (`lib/gen/sec:107`, `lib/gen/sec:225`)
- `val/run_all_tests.sh`: category-based test runner (`val/run_all_tests.sh:24`, `val/run_all_tests.sh:195`)

## Dependency Map
- Internal:
1. `go` injects `. <repo>/bin/ini` into shell (`go:60`)
2. `bin/ini` sources `cfg/core/{ric,rdc,mdc}` + `lib/core/ver` then `bin/orc` (`bin/ini:168`, `bin/ini:294`)
3. `bin/orc` loads `cfg/*`, `lib/ops/*`, `lib/gen/*` (`bin/orc:341`, `bin/orc:473`, `bin/orc:524`)
4. `ops` resolves module file at `${LIB_OPS_DIR}/${module}` then calls `${module}_${function}` (`src/dic/ops:209`, `src/dic/ops:199`)
5. `src/set/*` depends on `.menu` + DIC + env vars (`src/set/c1:16`, `src/set/c1:20`)
- External/system:
- Bash 4+, `awk`, `find`, `sort`, `mktemp`, `diff`, `bc` (explicitly required by tme) (`cfg/core/mdc:63`)
- Proxmox/admin tools inferred from ops modules (`lib/ops/pve`, `lib/ops/sto`, `lib/ops/sys`)

## Identified Risks
1. Module name mismatch likely breaks workflows: `ops nfs set -j` / `ops smb set -j` in set scripts, but no `lib/ops/nfs` or `lib/ops/smb` module exists (`src/set/c1:36`, `src/set/c2:37`, `src/dic/ops:326`, `lib/ops/srv`).
2. Config references non-existent aux directory: `SRC_AUX_DIR="${LAB_DIR}/src/aux"` while `src/aux` is missing (`cfg/core/ric:126`). It is optional, but this degrades intended orchestration (`bin/orc:628`).
3. Doc/runtime naming drift: docs describe `bin/init`, code uses `bin/ini` and `go` injects `bin/ini` (`bin/README.md`, `go:30`).
4. Security drift in configs: hardcoded dev passwords and insecure default `CT_DEFAULT_PASSWORD="password"` (`cfg/env/site1-dev:14`, `lib/gen/inf:87`).
5. Test harness fragility: `TEST_LAB_DIR="$LAB_ROOT"` can be empty if environment is not preloaded (`val/run_all_tests.sh:16`).

## Suggested Improvements
1. Fix set-to-ops module mapping: either rename calls to `ops srv nfs_set`/`ops srv smb_set` style or add compatibility modules/aliases.
2. Remove or implement `src/aux`; if intentionally absent, stop exporting `SRC_AUX_DIR` and remove component loading noise.
3. Standardize naming/docs on `ini` vs `init` across `README`, `bin/README.md`, and help text.
4. Replace insecure defaults with `sec_*` generated credentials and disallow plaintext dev passwords in committed env files.
5. Add a lightweight bootstrap checker command (`./go doctor`) to validate expected dirs/modules/env before running set scripts.
6. Make tests self-contained by deriving repo root from script location instead of `LAB_ROOT` env dependency.

Architecture model confidence is above 90% for control flow, module boundaries, and main failure modes.
