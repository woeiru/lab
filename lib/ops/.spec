# Operations and DIC Standards
# Type: Infrastructure Specification & Guidelines
# Scope: All operational functions in `lib/ops/`
#
# This specification EXTENDS `lib/.spec` and aligns with `lib/.standards`.
# It defines the strict contracts required by the Dependency Injection
# Container (DIC) and best practices for managing real infrastructure state.

## 1. The DIC Contract (Stateless & Pure)
The Dependency Injection Container (`src/dic/`) dynamically parses `lib/ops/` functions to map and inject environment variables to arguments.
- **Statelessness:** Functions MUST NOT hardcode environment variables (e.g., do not use `$VM_ID` directly in the function body). All data MUST be passed as parameters.
- **Predictable Mapping:** The DIC matches environment variables to function arguments based on local variable names. You MUST assign positional arguments to well-named local variables immediately.
  ```bash
  local vm_id="$1"      # DIC maps this to the VM_ID environment variable
  local node_pci="$2"   # DIC maps this to NODE_PCI
  ```

## 2. The `-x` (Explicit Execution) Pattern
Because the DIC can fully automate deployment manifests, destructive infrastructure commands must be explicitly intended.
- **Rule:** Functions without parameters DO NOT EXIST.
- **Action Functions:** Functions that traditionally require no arguments (e.g., `gpu_pts` to apply a setting) MUST require the `-x` (execute) flag.
  ```bash
  if [ $# -ne 1 ] || [ "$1" != "-x" ]; then
      aux_use
      return 1
  fi
  ```
- This directly supports the DIC's Mode 3 (Explicit Execution).

## 3. Structured Logging (No Raw Output)
`lib/ops/` functions are often orchestrated in pipelines. Raw `echo` or `printf` can break data returns and logging aggregators.
- **Rule:** Functions MUST NOT use `printf` or `echo` for user-facing messages. Use structured loggers: `aux_info`, `aux_warn`, `aux_err`, `aux_dbg`.
- **Exception:** `echo` and `printf` MUST ONLY be used for returning data pipeline values (e.g., `echo "$driver_name"`).
- **Context Format:** All log messages MUST include contextual key-value pairs representing the infrastructure state:
  ```bash
  # FORMAT: "key1=value1,key2=value2"
  aux_info "GPU detached" "component=gpu,operation=detach,pci_id=$pci_id"
  aux_err "VM creation failed" "component=pve,operation=create,vm_id=$vm_id,error=no_ram"
  ```

## 4. Infrastructure Safety & Recovery (Best Practices)
Managing real infrastructure requires extreme caution.
- **System Checks:** ALWAYS validate the system state before executing a change. (e.g., Check if a VM is stopped before attempting to pass through a GPU).
- **Dry-runs & Testing:** Where applicable, operations SHOULD validate configurations before applying them (e.g., `nginx -t`).
- **Rollback Awareness:** Functions that modify complex states (e.g., network interfaces in `net_`, storage in `sto_`) SHOULD be written in a way that is easily reversible or leaves the system in a safe degraded state rather than completely broken.
- **Separation of Concerns:** 
  - `gpu`, `pve`, `sto`: Treat as critical system operations. Verify IOMMU, disk locks, etc.
  - `net`, `srv`, `ssh`: Treat as network-critical. Be aware of locking yourself out of the host.
