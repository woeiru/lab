# 🖥️ CLI Documentation

Documentation for command-line interface, system initialization, and user interaction with the Lab Environment Management System.

This documentation specializes in the `bin/ini` initialization process, verbosity controls, logging configuration, and runtime interaction with core modules (`err`, `lo1`, `tme`, `ver`). It covers everything needed to understand and control the system's startup behavior and operational settings.

## 🎯 Target Audience

Command-line users who need to:
- Initialize and configure the system via `bin/ini`
- Understand verbosity controls and logging configuration
- Interact with core modules (err, lo1, tme, ver) at runtime
- Control system behavior through environment variables and shell functions
- Troubleshoot initialization and module loading issues

## 📚 Documentation Index

### Getting Started
- **[Initialization Guide](initiation.md)** - Complete guide to system initialization, configuration, and runtime controls
- **[Quick Reference](quick-reference.md)** - Essential CLI commands and daily workflow operations
- **[Verbosity Controls](verbosity-controls.md)** - Comprehensive verbosity configuration and control options

### CLI Guidelines

#### System Initialization
```bash
# Initialize the system with default settings
./bin/ini

# Initialize with custom verbosity
export MASTER_TERMINAL_VERBOSITY="on"
./bin/ini

# Initialize with custom log directory
export LOG_DIR="/custom/log/path"
./bin/ini
```

#### Runtime Controls
```bash
# Available after ./bin/ini completes:
setlog on|off                 # Control lo1 logging
enable_error_trap             # Enable error handling
tme_settme report on          # Enable timing reports
tme_print_timing_report       # Display performance data
```

#### Core Module Interaction
```bash
# Error handling module (err)
enable_error_trap / disable_error_trap

# Advanced logging module (lo1)  
setlog on / setlog off

# Timing module (tme)
tme_settme report on|off
tme_settme sort chron|duration
tme_start_timer "COMPONENT"
tme_end_timer "COMPONENT" "success"
```

## 🔧 User Configuration

### Verbosity Control
```bash
# Master verbosity control
export MASTER_TERMINAL_VERBOSITY="on"    # Enable all terminal output
export MASTER_TERMINAL_VERBOSITY="off"   # Quiet mode (default)

# Initialize with custom settings
./bin/ini
```

### Custom Logging
```bash
# Custom log directory
export LOG_DIR="/your/custom/log/path"
./bin/ini

# Quiet mode for minimal output
export MASTER_TERMINAL_VERBOSITY="off"
./bin/ini
```

### Environment Context
```bash
# Set your working environment
export SITE="site1"
export ENVIRONMENT="dev"  # or "test", "prod"
export NODE="your-hostname"
```

## 💡 Common Operations

### System Health Checks
```bash
# Quick system validation
./val/validate_system

# Comprehensive testing
./tst/test_environment

# Check specific components
cd tst && ./test_complete_refactor.sh
```

### Performance Monitoring
```bash
# View system statistics
./stats.sh

# Monitor timing (when enabled)
tme_print_timing_report
tme_show_output_settings
```

### Basic Container Operations
```bash
# Interactive deployment
cd src/set/pve && ./pve

# Check system status
cd src/set/pve && ./pve a  # Execute specific task
```

## 🎛️ User Controls

### Output Management
- **Terminal Verbosity**: Control what appears on your terminal
- **Log File Output**: All operations logged to files regardless of terminal settings
- **Module-Specific Controls**: Fine-tune output from specific system components
- **Timing Reports**: Optional performance monitoring and timing analysis

### Configuration Options
- **Environment Selection**: Choose your working environment (dev/test/prod)
- **Custom Paths**: Set custom directories for logs and temporary files
- **Shell Integration**: Automatic setup for bash/zsh environments
- **Alias Management**: Dynamic and static alias configuration

### System Integration
- **Automatic Initialization**: Seamless integration with shell startup
- **Environment Awareness**: Context-sensitive operation based on your environment
- **Cross-Shell Support**: Compatible with bash and zsh shells
- **Persistent Configuration**: Settings maintained across sessions

## 🚀 Getting Help

### Documentation Navigation
- **Architecture Overview**: See `../dev/architecture.md` for system design
- **Advanced Configuration**: See `../adm/configuration.md` for detailed options
- **Infrastructure Operations**: See `../iac/infrastructure.md` for deployment

### Troubleshooting
- **Common Issues**: Check `../fix/` directory for known problems and solutions
- **Validation Errors**: Run `./val/validate_system` for diagnosis
- **Log Analysis**: Check `.log` directory for detailed error information

### Support Resources
- **System Statistics**: `./stats.sh` for current system metrics
- **Test Framework**: Comprehensive validation scripts in `tst/` directory
- **Example Configurations**: Reference configurations in `cfg/env/`

## 📋 Quick Reference

### Essential Commands
```bash
./entry.sh                    # Initialize system
./val/validate_system         # Quick health check
./tst/test_environment        # Comprehensive testing
./stats.sh                    # System statistics
source ~/.bashrc              # Reload environment
```

### Key Directories
- **Configuration**: `cfg/env/` - Environment settings
- **Testing**: `tst/` - Validation and test scripts  
- **Logs**: `.log/` - System log files
- **Documentation**: `doc/` - All documentation

### Testing and Validation
- **Quick Validation**: `./tst/validate_system` for rapid system health checks
- **Comprehensive Testing**: `./tst/test_environment` for full system validation
- **Component Testing**: `./tst/test_complete_refactor.sh` for system refactoring validation
- **Performance Testing**: TME timing framework for performance analysis

## 📖 Related Documentation

- **Testing Framework**: See `../dev/testing.md` for comprehensive testing infrastructure and procedures
- **Developers**: See `../dev/` for integration and technical details
- **System Administrators**: See `../adm/` for system management
- **Infrastructure Teams**: See `../iac/` for deployment automation
