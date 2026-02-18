# Architecture Map

Status updated: 2026-02-18

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