# Library (`lib/`)

## 📋 Overview
Pure function library providing reusable components for core system operations, utilities, and infrastructure management across the Lab Environment Management System.

## 🗂️ Directory Structure / Key Files
- `standards.md` - Library development and validation standards
- `core/` - Essential system modules (error handling, logging, timing, verification)
- `gen/` - General-purpose utilities (environment, infrastructure, security)
- `ops/` - Operations functions (GPU, networking, storage, services)

### Core Modules (`core/`)
- `err` - Error handling and stack traces
- `lo1` - Advanced debug logging with depth visualization
- `tme` - Performance timing and monitoring
- `ver` - Module and dependency verification

### General Utilities (`gen/`)
- `aux` - Auxiliary operations and discovery utilities
- `env` - Environment configuration management
- `inf` - Infrastructure deployment utilities  
- `sec` - Security and credential management

### Operations Functions (`ops/`)
- `gpu` - GPU passthrough management
- `net` - Network configuration and management
- `pbs` - Proxmox Backup Server operations
- `pve` - Proxmox VE cluster management
- `srv` - System service operations
- `ssh` - SSH key and connection management
- `sto` - Storage and filesystem operations
- `sys` - System-level operations
- `usr` - User account management

## 🚀 Quick Start
```bash
# Source a core module
source lib/core/lo1     # Advanced logging
source lib/core/tme     # Performance timing
source lib/core/err     # Error handling

# Use operations functions
source lib/ops/sys      # System operations
source lib/ops/net      # Network management

# Access general utilities
source lib/gen/env      # Environment utilities
source lib/gen/sec      # Security functions
```

## 📊 Quick Reference
| Module Category | Purpose | Key Functions |
|----------------|---------|---------------|
| `core/` | System fundamentals | `log`, `error`, `tme_start_timer`, `ver_verify_module` |
| `gen/` | General utilities | Environment, infrastructure, security helpers |
| `ops/` | Operations | GPU, network, storage, service management |

## 🔗 Related Documentation
- [Library Standards](standards.md) - Development standards and parameter validation
- [Functions Reference](../doc/dev/functions.md) - Complete function documentation
- [Logging System](../doc/dev/logging.md) - Core logging architecture
- [Developer Guide](../doc/dev/README.md) - Development workflows and patterns

---

**Navigation**: Return to [Main](../README.md)
