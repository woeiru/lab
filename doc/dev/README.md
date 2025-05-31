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

### Testing & Validation
- **[Testing Framework](testing.md)** - Comprehensive testing infrastructure, validation procedures, and testing standards

### Integration Guidelines

#### Library Integration
- **Stateless Functions**: Import pure functions from `lib/ops/` with explicit parameters
- **Wrapper Pattern**: Use environment-aware wrappers from `src/mgt/` for runtime integration
- **Function Separation**: Understand the distinction between pure and wrapper functions

#### Environment Awareness
- **Hierarchical Configuration**: Leverage the base → environment → node configuration cascade
- **Context Loading**: Use automatic environment context loading for development workflows

#### Testing Framework
- **Comprehensive Testing Infrastructure**: 499+ lines of validation logic across multiple test scripts
- **Test Categories**: System validation, component testing, integration testing, performance testing
- **Testing Standards**: Pure function testing, wrapper function validation, environment testing
- **Debug Workflows**: Comprehensive debug logging and error handling systems
- **Validation Scripts**: Quick validation (`validate_system`) and comprehensive testing (`test_environment`)

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

### Testing Infrastructure
- **Comprehensive Validation**: 499+ lines of validation logic across all test scripts
- **Component Isolation**: Individual module testing with pure function separation
- **Integration Testing**: End-to-end system validation and workflow testing
- **Performance Monitoring**: Built-in timing and performance analysis during testing

### Testing Categories
- **System Validation**: Quick health checks and comprehensive system testing
- **Component Testing**: Module-specific validation (GPU, PVE, verbosity controls)
- **Security Testing**: Password management, permissions, and credential validation
- **Environment Testing**: Multi-environment test scenarios and configuration validation

### Development Testing Workflow
- **Pre-Development**: `./tst/validate_system` for rapid system health checks
- **During Development**: Component-specific testing for targeted validation
- **Post-Development**: `./tst/test_environment` for comprehensive validation
- **Performance Analysis**: TME timing framework for performance impact assessment

## 📖 Related Documentation

- **System Administration**: See `../adm/` for operational procedures
- **Infrastructure Teams**: See `../iac/` for deployment patterns
- **End Users**: See `../user/` for user-facing documentation
