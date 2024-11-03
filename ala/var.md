# Verification Systems Documentation

This document describes the coexisting verification systems in the runtime environment: Essential Verification and Advanced Verification (var module).

## Overview

The verification system consists of two complementary layers:

1. **Essential Verification**
   - Always available (part of rc)
   - Basic safety checks
   - Used during early initialization
   - No dependencies
   - Supports both RC and FALLBACK modes

2. **Advanced Verification** (var module)
   - Optional enhanced features
   - Caching capabilities
   - Detailed debugging with VAR_DEBUG_ENABLED
   - Built on top of essential verification
   - Automatic parent directory creation

## Essential Verification

### Core Functions

```bash
essential_verify_var "VARIABLE_NAME"              # Single variable check
essential_verify_path "PATH_VAR" "dir|file" true  # Path verification with creation
essential_verify_vars VAR1 VAR2 VAR3              # Multiple variable check
essential_check                                   # Complete environment verification
```

### Basic Usage

```bash
#!/bin/bash

# Set verification mode (RC or FALLBACK)
set_verification_mode "RC"

# Complete environment check
if ! essential_check; then
    echo "Fatal: Environment verification failed" >&2
    return 1
fi

# Check single variable
if ! essential_verify_var "LAB_DIR"; then
    printf "[%s] Variable 'LAB_DIR' is empty\n" "$VERIFICATION_MODE" >&2
    return 1
fi

# Check multiple variables
if ! essential_verify_vars LAB_DIR TMP_DIR LOG_DIR; then
    printf "[%s] Missing required variables\n" "$VERIFICATION_MODE" >&2
    return 1
fi

# Verify and create directory if needed
if ! essential_verify_path "LOG_DIR" "dir" true; then
    printf "[%s] Cannot access log directory\n" "$VERIFICATION_MODE" >&2
    return 1
fi
```

## Advanced Verification (var module)

### Enhanced Functions

```bash
var_debug_log "message" "source"                 # Debug logging with timestamps
verify_var "VARIABLE_NAME"                       # Cached verification
verify_path "PATH_VAR" "dir|file" "create"       # Enhanced path verification
verify_path_auto "PATH" "type"                   # Auto-creates parent directories
```

### Advanced Usage

```bash
#!/bin/bash

# Enable debug logging
VAR_DEBUG_ENABLED=1

# Cached variable verification
verify_var "CONFIG_PATH" || exit 1

# Path verification with parent directory creation
verify_path_auto "LOG_DIR/app/debug" "dir" || exit 1

# Debug logging
var_debug_log "Starting verification" "init"
```

## Initialization and Cleanup

### Essential Verification

```bash
# Initialize verification system
init_verification || init_fallback_verification

# Debug mode for initialization
debug_rc_init  # Shows critical paths and permissions
```

### Advanced Verification

```bash
# Clean up cached verifications
cleanup_var

# Cache debugging
var_debug_log "Cache status" "debug"
```

## Error Handling and Logging

### Essential Verification
- Uses printf for error messages
- Includes verification mode in messages
- Supports both RC and FALLBACK modes
- Creates /tmp/rc_init.log during initialization

### Advanced Verification
- Supports detailed debug logging when VAR_DEBUG_ENABLED=1
- Caches successful verifications
- Logs to LOG_DEBUG_FILE
- Includes timestamps and source information

## Best Practices

1. **Initialization Order**
   - Start with essential verification
   - Fall back to init_fallback_verification if needed
   - Load var module for advanced features
   - Enable debug logging when troubleshooting

2. **Directory Handling**
   - Use verify_path_auto for nested directories
   - Enable creation flag when appropriate
   - Check parent directory permissions

3. **Cache Management**
   - Clear cache when needed using cleanup_var
   - Monitor cache size in long-running scripts
   - Use var_debug_log for cache debugging

4. **Error Recovery**
   - Implement fallbacks for critical operations
   - Use appropriate verification mode
   - Check debug logs for detailed error information

## Environment Variables

- `VAR_DEBUG_ENABLED`: Enable detailed logging (0/1)
- `VERIFICATION_MODE`: Current verification mode (RC/FALLBACK)
- `CONS_LOADED`: Indicates if constants are loaded

## Limitations and Notes

- Essential verification is always available after rc sourcing
- Advanced verification requires functioning LOG_DIR
- Cache entries persist until cleanup_var is called
- Debug logging requires write access to LOG_DEBUG_FILE
- Parent directory creation may require elevated permissions
- VERIFICATION_MODE affects error message format

## Exit Codes

Both systems use consistent exit codes:
- 0: Success
- 1: General failure
- Other codes as defined in ERROR_CODES array

## See Also

- err.md: Error handling documentation
- lo1.md: Logging system documentation
- rc.md: Runtime configuration documentation
