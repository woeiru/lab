# Infrastructure as Code

Documentation for infrastructure deployment and environment management.

## Contents

- [deployment.md](deployment.md) - Deployment scripts, container/VM provisioning, and Proxmox VE setup
- [environment.md](environment.md) - Environment configuration hierarchy and multi-environment management

## Deployment Overview

Deployment scripts live under `src/set/`. Each subdirectory is a deployment target:

| Directory | Purpose |
|-----------|---------|
| `src/set/c1`, `c2`, `c3` | Container service deployments |
| `src/set/h1` | Hypervisor setup |
| `src/set/t1`, `t2` | Test environment provisioning |

Infrastructure library modules are in `lib/ops/`:

| Module | Purpose |
|--------|---------|
| `pve` | Proxmox VE cluster, VM, and container lifecycle |
| `gpu` | GPU passthrough management (`gpu_pts`, `gpu_ptd`, `gpu_pta`) |
| `sys` | System setup, package management, user provisioning |
| `net` | Network configuration and connectivity |
| `sto` | Storage pools and filesystem management |

## Environment Configuration

Configuration files are under `cfg/env/`. The loading order is:

```
cfg/env/<site>          base site config
cfg/env/<site>-<env>    environment override (dev, prod, etc.)
```

Runtime variables (`SITE`, `ENVIRONMENT`, `NODE`) select which config files load. See [environment.md](environment.md) for details.

## Running Tests

```bash
./val/run_all_tests.sh
```
