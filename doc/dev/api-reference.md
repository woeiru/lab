# API Reference Guide

Quick reference for developers using the Lab Environment Management System libraries.

## 🎯 Core Libraries

### Error Handling (`lib/core/err`)
```bash
# Error handling functions
handle_error "component" "message" "severity"
error_handler                    # Automatic error trap handler
err_process_error               # Structured error processing

# Usage example
handle_error "deployment" "Container creation failed" "ERROR"
```

### Logging System (`lib/core/lo1`)
```bash
# Advanced logging functions
lo1_log "module" "message" "level"
lo1_debug "module" "debug_message"
lo1_info "module" "info_message"

# Usage example
lo1_log "gpu" "GPU detached successfully" "info"
```

### Timing Module (`lib/core/tme`)
```bash
# Performance timing functions
tme_start_timer "operation_name"
tme_end_timer "operation_name" "status"
tme_print_timing_report
tme_set_output debug off
tme_show_output_settings

# Usage example
tme_start_timer "CONTAINER_DEPLOYMENT"
# ... your operations ...
tme_end_timer "CONTAINER_DEPLOYMENT" "success"
```

## 🚀 Operations Libraries

### Proxmox VE (`lib/ops/pve`)
```bash
# Pure functions (parameterized)
pve-vmc vm_id cluster_nodes           # VM cluster management
pve-ctc container_id nodes            # Container cluster creation
pve-nds node_list                     # Node status check

# Wrapper functions (environment-aware)
pve-vmc-w vm_id                       # Uses CLUSTER_NODES environment
pve-ctc-w container_id                # Uses environment configuration
```

### GPU Management (`lib/ops/gpu`)
```bash
# Pure functions
gpu-pts gpu_id                        # GPU passthrough status
gpu-ptd gpu_id                        # Detach GPU for passthrough
gpu-pta gpu_id                        # Attach GPU to host

# Wrapper functions
gpu-pts-w                             # Status check (environment-aware)
gpu-ptd-w gpu_id                      # Detach with environment context
gpu-pta-w gpu_id                      # Attach with environment context
```

### System Operations (`lib/ops/sys`)
```bash
# System management functions
sys-pkg-install package_list          # Package installation
sys-usr-create username options       # User creation
sys-host-config hostname settings     # Host configuration
```

## 🛠️ Utility Libraries

### Infrastructure Utilities (`lib/gen/inf`)
```bash
# Container management
define_containers "id:name:ip:id2:name2:ip2"
set_container_defaults memory=4096 storage="local-lvm"
validate_config
show_config_summary

# Usage example
define_containers "111:pbs:192.168.178.111:112:nfs:192.168.178.112"
validate_config && show_config_summary
```

### Security Utilities (`lib/gen/sec`)
```bash
# Credential management (120+ lines of secure handling)
# - Zero hardcoded passwords
# - Automatic 600 permissions
# - Graceful fallback mechanisms
# Functions are internal - use through wrapper scripts
```

### Environment Utilities (`lib/gen/env`)
```bash
# Environment configuration
load_environment_config site environment
validate_environment_hierarchy
set_node_specific_overrides
```

## 🔧 Integration Patterns

### Pure Function Pattern
```bash
# Library function (lib/ops/)
function_name() {
    local param1="$1"
    local param2="$2"
    local param3="$3"
    
    # Pure logic with explicit parameters
    # No environment dependencies
    # Fully testable
}
```

### Wrapper Function Pattern
```bash
# Wrapper function (src/mgt/)
function_name-w() {
    local env_param1="${ENV_VARIABLE1}"
    local env_param2="${ENV_VARIABLE2}"
    
    # Call pure function with environment context
    function_name "$param" "$env_param1" "$env_param2"
}
```

### Environment Integration
```bash
# Load environment context
source lib/gen/env
load_environment_config "$SITE" "$ENVIRONMENT"

# Use environment-aware functions
pve-vmc-w "$vm_id"  # Uses CLUSTER_NODES from environment
gpu-pts-w           # Uses GPU configuration from environment
```

## 📊 Function Reference

### Core Modules (4 modules)
- **err**: Error handling and stack traces
- **lo1**: Module-specific debug logging  
- **tme**: Performance timing and monitoring
- **ver**: Module version verification

### Operations Modules (8 modules)
- **gpu**: GPU passthrough management (9 functions)
- **net**: Network configuration and management
- **pbs**: Proxmox Backup Server operations
- **pve**: Proxmox VE cluster management (15 functions)
- **srv**: System service operations
- **sto**: Storage and filesystem management
- **sys**: System-level operations
- **usr**: User account management

### Utility Modules (5 modules)
- **ali**: System alias management
- **env**: Environment configuration utilities
- **inf**: Infrastructure deployment utilities (355+ lines)
- **sec**: Security and credential management (120+ lines)
- **ssh**: SSH key and connection management

## 🧪 Testing Integration

### Function Testing
```bash
# Test pure functions with explicit parameters
pve-vmc "101" "node1,node2,node3"

# Test wrapper functions with environment
export CLUSTER_NODES=("test-node1" "test-node2")
pve-vmc-w "101"
```

### Validation Framework
```bash
# Use existing validation infrastructure
./tst/validate_system
./tst/test_environment
./tst/test_complete_refactor.sh

# Component-specific testing
./tst/test_gpu_wrappers.sh
./tst/validate_gpu_refactoring.sh
```

## 📖 Related Documentation

- **[System Architecture](architecture.md)** - Complete system design
- **[Logging System](logging.md)** - Debug and logging frameworks
- **[Verbosity Controls](verbosity.md)** - Output control mechanisms
