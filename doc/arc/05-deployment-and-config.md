# 05 - Deployment and Configuration Layer

The deployment layer manages the orchestration of infrastructure changes. It is where pure functions (`lib/ops`) and the Dependency Injection Container (`src/dic`) converge with environment-specific variables (`cfg/env`) to execute tasks.

This layer is governed by the `src/set/.menu` framework and utilizes **hostname-based script conventions**.

## The `.menu` Framework (`src/set/.menu`)

The `.menu` script is the core execution engine for deployment manifests. It serves two distinct purposes:
1. **Environment Loader:** Dynamically resolves and sources infrastructure modules (`lib/ops/`) and hierarchical configurations (`cfg/env/`).
2. **Execution Router:** Provides a standardized CLI interface for all deployment scripts within `src/set/`.

### Interactive and Direct Execution Modes
The framework parses the calling deployment script for specific functions ending in `_xall` (e.g., `a_xall`, `b_xall`) and offers two execution modes:
*   **Interactive (`-i`):** A menu-driven terminal interface. It displays available tasks, allows users to inspect the underlying Bash code (expanding variables), and selectively execute tasks.
*   **Direct Execution (`-x <section>`):** Command-line automation allowing headless execution of a specific section (e.g., `./h1 -x a`).

## Hostname-Based Deployment Scripts

Deployment scripts located in `src/set/` are named after the specific node they configure (e.g., `h1`, `c1`, `t1`). 

| Script | Hostname | Infrastructure Role |
| :--- | :--- | :--- |
| `h1` | Hypervisor 1 | Proxmox VE cluster setup |
| `c1` | Container 1 | NFS Server Deployment |
| `c2` | Container 2 | Samba/SMB Services |
| `c3` | Container 3 | Proxmox Backup Server |
| `t1` | Test Node 1 | Developer Workstation |

These manifests rarely contain raw Bash commands. Instead, they structure tasks within `MENU_OPTIONS` and rely entirely on `src/dic/ops` to execute abstracted operations (e.g., `ops nfs set -j`).

At the end of each script, they delegate execution back to the `.menu` framework by calling `setup_main "$@"`.

## Configuration Hierarchy (`cfg/env/`)

Configurations are defined as pure Bash scripts containing variables and associative arrays. This makes them instantly sourceable by `.menu`.

The framework relies on a **Hierarchical Configuration Loading** pattern:
1.  **Base Site:** (e.g., `site1`)
2.  **Environment Override:** (e.g., `site1-dev`)
3.  **Node Override:** (e.g., `site1-w2`)

These configuration files act as the "state" or "inventory" of the environment, defining:
*   **Topologies:** Dictionaries of IP addresses for hypervisors (`HY_IPS`) and containers (`CT_IPS`).
*   **Infrastructure as Code (IaC):** Declarative parameter blocks for provisioning (e.g., `define_containers`, `set_vm_defaults`), specifying CPU, RAM, and OS templates.
*   **Runtime Variables:** Hostname-prefixed variables (e.g., `h1_CORE_COUNT_ON`) that the Dependency Injection Container will map to pure functions at runtime.