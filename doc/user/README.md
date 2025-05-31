# 👤 User Documentation

Documentation for end users operating the Lab Environment Management System.

## 🎯 Target Audience

End users who need to:
- Get started with the system quickly and efficiently
- Understand basic system operations and controls
- Configure user-accessible system options
- Perform common tasks and operations

## 📚 Documentation Index

### Getting Started
- **[User Guide](initiation.md)** - Complete user interaction and configuration guide, runtime controls, and system operation
- **[Quick Reference](quick-reference.md)** - Essential commands and daily workflow operations
- **[Verbosity Controls](verbosity-controls.md)** - User-facing verbosity configuration and control options

### User Guidelines

#### Quick Start
```bash
# Initialize the environment
./entry.sh

# Verify installation  
./tst/validate_system

# Check system status
./tst/test_environment
```

#### Basic Operations
```bash
# Source core system (automatic after setup)
source ~/.bashrc  # or ~/.zshrc

# Available core modules:
# - err: Advanced error handling and stack traces
# - lo1: Module-specific debug logging  
# - tme: Performance timing and monitoring
```

#### User Controls
- **Environment Variables**: Configure system behavior before initialization
- **Verbosity Controls**: Manage terminal output and logging levels
- **Runtime Configuration**: Customize system operation for your workflow

## 🔧 User Configuration

### Verbosity Control
```bash
# Master verbosity control
export MASTER_TERMINAL_VERBOSITY="on"    # Enable all terminal output
export MASTER_TERMINAL_VERBOSITY="off"   # Quiet mode (default)

# Initialize with custom settings
./bin/init
```

### Custom Logging
```bash
# Custom log directory
export LOG_DIR="/your/custom/log/path"
./bin/init

# Quiet mode for minimal output
export MASTER_TERMINAL_VERBOSITY="off"
./bin/init
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
./tst/validate_system

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
- **Validation Errors**: Run `./tst/validate_system` for diagnosis
- **Log Analysis**: Check `.log` directory for detailed error information

### Support Resources
- **System Statistics**: `./stats.sh` for current system metrics
- **Test Framework**: Comprehensive validation scripts in `tst/` directory
- **Example Configurations**: Reference configurations in `cfg/env/`

## 📋 Quick Reference

### Essential Commands
```bash
./entry.sh                    # Initialize system
./tst/validate_system         # Quick health check
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
