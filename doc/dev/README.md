# 👨‍💻 Developer Documentation

Documentation for developers integrating with the Lab Environment Management System.

## 🎯 Target Audience

Software developers who need to:
- Integrate with the system's library functions
- Understand the system architecture and design patterns
- Implement testing and debugging workflows
- Work with the logging and verbosity control systems

## 📚 Documentation Index

### System Architecture & Design
- **[System Architecture](architecture.md)** - Complete system design overview, modular architecture, and design patterns
- **[API Reference](api-reference.md)** - Quick reference for library functions and integration patterns
- **[Logging System](logging.md)** - Comprehensive logging architecture, debug systems, and log management
- **[Verbosity Controls](verbosity.md)** - Output control mechanisms and terminal verbosity management

### Integration Guidelines

#### Library Integration
- **Stateless Functions**: Import pure functions from `lib/ops/` with explicit parameters
- **Wrapper Pattern**: Use environment-aware wrappers from `src/mgt/` for runtime integration
- **Function Separation**: Understand the distinction between pure and wrapper functions

#### Environment Awareness
- **Hierarchical Configuration**: Leverage the base → environment → node configuration cascade
- **Context Loading**: Use automatic environment context loading for development workflows

#### Testing Framework
- **Validation Infrastructure**: Leverage the 375+ lines of existing validation logic
- **Test Patterns**: Follow established testing patterns in `tst/` directory
- **Debug Workflows**: Use comprehensive debug logging and error handling systems

## 🔧 Development Workflows

### Library Function Development
```bash
# Pure function pattern (lib/ops/)
function_name() {
    local param1="$1"
    local param2="$2"
    # Pure logic with explicit parameters
}

# Wrapper function pattern (src/mgt/)
function_name-w() {
    local env_param="${ENV_VARIABLE}"
    function_name "$param" "$env_param"
}
```

### Debug and Testing
```bash
# Enable debug logging
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="on"

# Run validation
./tst/validate_system
./tst/test_environment
```

### Performance Analysis
```bash
# Use timing framework
tme_start_timer "OPERATION_NAME"
# ... your code ...
tme_end_timer "OPERATION_NAME" "success"
tme_print_timing_report
```

## 🧪 Testing Standards

- **Comprehensive Validation**: 499 lines of validation logic
- **Function Separation**: Pure functions with testable parameters
- **Environment Testing**: Multi-environment test scenarios
- **Performance Monitoring**: Built-in timing and performance analysis

## 📖 Related Documentation

- **System Administration**: See `../adm/` for operational procedures
- **Infrastructure Teams**: See `../iac/` for deployment patterns
- **End Users**: See `../user/` for user-facing documentation
