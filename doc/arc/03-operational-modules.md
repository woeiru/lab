# 03 - Operational Modules (`lib/ops`)

The `lib/ops/` directory is the core operational heart of the framework. It houses the libraries responsible for enacting all infrastructure changes (e.g., configuring networks, managing virtual machines, handling packages). 

The architectural design of these modules follows a **Parameter-Driven Operational Interface** model, ensuring high predictability, testability, and safety.

## Interface Paradigm

Every function inside `lib/ops/` is designed to expose a parameter-driven Bash interface. In this context, this means:
*   **Explicit Contracts First:** Functions are intended to avoid hidden dependencies and take required data through parameters. Some modules still mutate runtime globals for coordination, but caller-facing contracts remain parameter-driven.
*   **Explicit Parameterization:** All required data (e.g., IPs, hostnames, passwords) must be passed directly as arguments.
*   **Single Responsibility:** Each function performs one logical, atomic operation (e.g., `net_hos` to manage `/etc/hosts` entries, `pve_vmc` to create a VM).

This decoupling ensures that `lib/ops/` functions can be safely executed in isolation, tested independently via the `val/` framework, and reused across completely different deployment topologies.

## Naming Conventions

The modules follow a strict prefix-based naming convention:
*   **Public Functions:** `[module]_[action]` or `[module]_[target]_[action]`. Examples: `pve_cdo` (Proxmox CD-ROM operation), `gpu_ptd` (GPU passthrough configuration), `net_hos` (host-entry management).
*   **Internal Helpers:** Functions meant only for internal module use are prefixed with an underscore, e.g., `_pve_helper`.
*   **Case:** `snake_case` is used consistently for all functions and local variables.

## Safety and Idempotency

Infrastructure operations are inherently risky. To mitigate this, `lib/ops/` enforces strict safety paradigms:
1.  **Fail-Fast Error Handling:** Functions validate their inputs immediately using `lib/gen/aux_val`. If a parameter is missing or malformed, the function exits with `return 1` before performing any operations.
2.  **Dependency Verification:** Functions use `aux_chk` to confirm that required binaries (e.g., `ip`, `zfs`, `qm`) are available and that the executing user has sufficient privileges. If dependencies are unmet, the function returns `127`.
3.  **Atomic Modifications:** When editing system files, functions create atomic backups before applying changes, ensuring a rollback path exists if the operation is interrupted.
4.  **Idempotency:** Functions are designed to be run multiple times safely. If the desired state (e.g., a network bridge exists) is already achieved, the function succeeds without making redundant changes.

## Dual-Mode Execution Integration

Because `lib/ops/` functions require explicit arguments, they can be cumbersome to call manually for complex deployments. To solve this, the framework supports a **Dual-Mode Execution** model:

1.  **Standalone / Manual Mode:** The user (or a test script) provides all arguments explicitly:
    ```bash
    pve_vpt "100" "on" "0000:01:00.0" "0000:01:00.1" "8" "4" "usb-a usb-b" "/etc/pve/qemu-server"
    ```
2.  **Dependency Injection Container (DIC) Mode:** Deployment scripts call the DIC wrapper (`src/dic/ops`), which automatically inspects the environment configuration (`cfg/env/`) and injects the required arguments into the target operational function.
    ```bash
    ops pve vpt -j
    ```

This division ensures that `lib/ops/` remains agnostic to *where* it is running, while `src/dic/` and `src/set/` handle the *context* of the deployment.
