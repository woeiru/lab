# Quick Reference Guide

Essential commands and operations for daily use of the Lab Environment Management System.

## 🚀 Getting Started

### Initial Setup
```bash
# Initialize the system
./entry.sh

# Verify installation
./tst/validate_system

# Check system health
./tst/test_environment
```

### Daily Startup
```bash
# Environment is automatically loaded after initial setup
# If you need to reload manually:
source ~/.bashrc  # or ~/.zshrc
```

## ⚡ Essential Commands

### System Health & Status
```bash
./tst/validate_system         # Quick system validation
./tst/test_environment        # Comprehensive testing
./stats.sh                    # Current system statistics
```

### System Information
```bash
# View system metrics
./stats.sh                    # Live system statistics
./stats.sh --formatted        # Formatted output
./stats.sh --markdown         # Markdown format
./stats.sh --raw             # Raw metrics

# Check current environment
echo "Site: $SITE"
echo "Environment: $ENVIRONMENT"  
echo "Node: $NODE"
```

### Container Operations
```bash
# Interactive container deployment
cd src/set/pve && ./pve

# Specific deployment tasks
cd src/set/pve && ./pve a     # Configure repositories
cd src/set/pve && ./pve b     # Install packages
cd src/set/pve && ./pve c     # Setup /etc/hosts
cd src/set/pve && ./pve d     # Generate SSH keys
cd src/set/pve && ./pve q     # Create containers
```

## 🔧 Configuration Commands

### Environment Control
```bash
# Set environment context
export SITE="site1"
export ENVIRONMENT="dev"      # or "test", "prod"
export NODE="$(hostname)"

# Reload environment
source ~/.bashrc
```

### Verbosity Control
```bash
# Enable all terminal output
export MASTER_TERMINAL_VERBOSITY="on"

# Quiet mode (default)
export MASTER_TERMINAL_VERBOSITY="off"

# Custom log directory
export LOG_DIR="/custom/log/path"
```

## 📊 Monitoring Commands

### Performance Monitoring
```bash
# View timing reports (when enabled)
tme_print_timing_report

# Check output settings  
tme_show_output_settings

# Control output levels
tme_set_output debug off     # Disable debug messages
tme_set_output report on     # Enable timing reports
```

### Log Management
```bash
# View log files (located in ${LOG_DIR}/.log/)
tail -f .log/debug.log       # Debug information
tail -f .log/err.log         # Error messages  
tail -f .log/lo1.log         # Module-specific logs

# View log directory
ls -la ${LOG_DIR}/.log/
```

## 🏗️ Infrastructure Commands

### Container Management
```bash
# Define containers with utility functions
source lib/utl/inf
define_containers "111:pbs:192.168.178.111:112:nfs:192.168.178.112"
validate_config && show_config_summary

# Set container defaults
set_container_defaults memory=4096 storage="local-lvm"
```

### GPU Management
```bash
# Check GPU status
gpu-pts-w                    # GPU passthrough status

# GPU operations
gpu-ptd-w 1                  # Detach GPU for passthrough
gpu-pta-w 1                  # Attach GPU back to host
```

### Service Deployment
```bash
# Container services
cd src/set/c1 && ./c1        # Container deployment 1
cd src/set/c2 && ./c2        # Container deployment 2  
cd src/set/c3 && ./c3        # Container deployment 3

# Test deployments
cd src/set/t1 && ./t1        # Test deployment 1
cd src/set/t2 && ./t2        # Test deployment 2

# Workstation setup
cd src/set/w1 && ./w1        # Workstation configuration
```

## 🧪 Testing Commands

### System Validation
```bash
# Quick validation
./tst/validate_system

# Comprehensive testing
./tst/test_environment

# Component-specific testing
./tst/test_complete_refactor.sh     # Complete system test
./tst/test_gpu_wrappers.sh          # GPU wrapper testing
./tst/test_verbosity_controls.sh    # Verbosity system test
./tst/validate_gpu_refactoring.sh   # GPU refactoring validation
```

### Performance Testing
```bash
# Enable timing for performance analysis
export TME_TERMINAL_VERBOSITY="on"
tme_start_timer "OPERATION_NAME"
# ... perform operations ...
tme_end_timer "OPERATION_NAME" "success"
tme_print_timing_report
```

## 🔐 Security Commands

### Credential Management
```bash
# Credentials are managed automatically through lib/utl/sec
# No manual credential commands needed
# All files automatically get proper permissions (600)
```

### SSH Management
```bash
# SSH keys managed through deployment scripts
cd src/set/pve && ./pve d    # Generate and distribute SSH keys
```

## 📂 Important Directories

### Configuration
```bash
cfg/env/site1               # Base site configuration
cfg/env/site1-dev           # Development environment
cfg/env/site1-w2            # Workstation configuration
cfg/core/                   # Core system configuration
```

### Documentation
```bash
doc/user/                   # User documentation (this guide)
doc/dev/                    # Developer documentation  
doc/adm/                    # Administrator documentation
doc/iac/                    # Infrastructure documentation
```

### Libraries
```bash
lib/core/                   # Core system libraries
lib/ops/                    # Operations libraries
lib/utl/                    # Utility libraries
```

### Scripts
```bash
src/set/                    # Deployment scripts
src/mgt/                    # Management wrappers
tst/                        # Testing and validation
```

## 🆘 Troubleshooting

### Common Issues
```bash
# System not responding
./tst/validate_system       # Check system health

# Environment not loading
source ~/.bashrc            # Reload environment
export MASTER_TERMINAL_VERBOSITY="on"  # Enable debug output

# Permissions issues
# System automatically handles permissions
# Check .log/err.log for permission-related errors
```

### Debug Mode
```bash
# Enable comprehensive debugging
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="on"
export LO1_LOG_TERMINAL_VERBOSITY="on"
export ERR_TERMINAL_VERBOSITY="on"

# Run operation with full debugging
./entry.sh
```

### Log Analysis
```bash
# Check recent errors
tail -20 .log/err.log

# Monitor debug output  
tail -f .log/debug.log

# View module-specific logs
tail -f .log/lo1.log
```

## 📞 Getting Help

### Documentation
- **[User Guide](initiation.md)** - Complete user interaction guide
- **[Developer Docs](../dev/README.md)** - Technical documentation
- **[Admin Docs](../adm/README.md)** - System administration
- **[Infrastructure Docs](../iac/README.md)** - Deployment automation

### System Information
```bash
./stats.sh                  # Current system statistics
./tst/validate_system       # System health check
ls doc/                     # Available documentation
```

### Known Issues
- **[Audio Fix](../fix/audioroot.md)** - Audio system troubleshooting
- **[Container Persistence](../fix/podman_persistent_container.md)** - Container issues

## 📋 Daily Workflow

### Morning Startup
1. `./tst/validate_system` - Check system health
2. `./stats.sh` - Review system metrics  
3. `tail -10 .log/err.log` - Check for overnight errors

### Development Work
1. Set environment: `export ENVIRONMENT="dev"`
2. Reload config: `source ~/.bashrc`
3. Deploy/test: `cd src/set/pve && ./pve`

### End of Day
1. `./tst/test_environment` - Final system validation
2. `./stats.sh` - Review daily metrics
3. Check logs: `tail -20 .log/debug.log`
