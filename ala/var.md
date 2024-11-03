# Verification Systems Documentation

This document describes the coexisting verification systems in the runtime environment: Essential Verification and Advanced Verification (var module).

## Overview

The verification system consists of two complementary layers:

1. **Essential Verification**
   - Always available (part of rc)
   - Basic safety checks
   - Used during early initialization
   - No dependencies

2. **Advanced Verification** (var module)
   - Optional enhanced features
   - Caching capabilities
   - Type checking
   - Detailed debugging
   - Built on top of essential verification

## Essential Verification

### Core Functions

```bash
essential_verify_var "VARIABLE_NAME"              # Single variable check
essential_verify_path "PATH_VAR" "dir|file" true  # Path verification with creation
essential_verify_vars VAR1 VAR2 VAR3              # Multiple variable check
```

### Basic Usage

```bash
#!/bin/bash

# Check single variable
if ! essential_verify_var "LAB_DIR"; then
    echo "Fatal: LAB_DIR not set" >&2
    exit 1
fi

# Check multiple variables
if ! essential_verify_vars LAB_DIR TMP_DIR LOG_DIR; then
    echo "Fatal: Missing required variables" >&2
    exit 1
fi

# Verify and create directory if needed
if ! essential_verify_path "LOG_DIR" "dir" true; then
    echo "Fatal: Cannot access log directory" >&2
    exit 1
fi
```

## Advanced Verification (var module)

### Enhanced Functions

```bash
verify "VARIABLE_NAME" "type"                    # Type-aware verification
verify_path "PATH_VAR" "dir|file" true          # Enhanced path verification
verify_batch "([VAR]=type [VAR2]=type2 ...)"    # Batch verification with types
```

### Advanced Usage

```bash
#!/bin/bash

# Type-aware verification
verify "PORT" "number" || exit 1
verify "CONFIG_PATH" "path" || exit 1

# Batch verification
declare -A requirements=(
    ["PORT"]="number"
    ["CONFIG_PATH"]="path"
    ["LOG_DIR"]="path"
    ["DEBUG_LEVEL"]="number"
)
verify_batch "${requirements[@]}" || exit 1

# Enhanced path verification
verify_path "CONFIG_FILE" "file" true || exit 1  # Create if missing
```

## Combined Usage Examples

### Basic Script
Minimal verification using only essential functions:

```bash
#!/bin/bash

# Basic environment checks
if ! essential_verify_vars LAB_DIR TMP_DIR; then
    echo "Fatal: Missing required variables" >&2
    exit 1
fi

# Create log directory if needed
essential_verify_path "LOG_DIR" "dir" true || exit 1
```

### Advanced Script
Using advanced features with fallback:

```bash
#!/bin/bash

# Try advanced verification, fall back to essential if needed
if type verify >/dev/null 2>&1; then
    # Advanced verification available
    verify "PORT" "number" || exit 1
    verify_path "CONFIG_FILE" "file" true || exit 1
else
    # Fall back to essential
    essential_verify_vars PORT CONFIG_FILE || exit 1
fi
```

### Complex Script
Using both systems together:

```bash
#!/bin/bash

# Essential checks first
essential_verify_vars LAB_DIR TMP_DIR || exit 1

# Then advanced checks if available
if type verify >/dev/null 2>&1; then
    # Configuration requirements
    declare -A requirements=(
        ["PORT"]="number"
        ["CONFIG_PATH"]="path"
        ["LOG_DIR"]="path"
    )
    verify_batch "${requirements[@]}" || exit 1
    
    # Additional path verifications
    verify_path "DATA_DIR" "dir" true || exit 1
fi

# Script continues...
```

## Best Practices

1. **Always use essential verification for critical variables**
   - Early initialization
   - Core environment variables
   - Basic path checks

2. **Use advanced verification when available for:**
   - Type checking
   - Complex validations
   - Batch operations
   - Performance-critical sections (caching)

3. **Implement fallbacks where needed**
   - Check for advanced functions before using them
   - Fall back to essential verification when needed
   - Handle missing features gracefully

4. **Debug logging**
   - Essential verification provides basic error messages
   - Advanced verification offers detailed debug logging
   - Enable VAR_DEBUG_ENABLED=1 for more verbose output

## Error Handling

Both systems return:
- 0 for success
- 1 for failure

Error messages are written to stderr and, in the case of advanced verification, to the debug log when enabled.

## Dependencies

- Essential Verification: None (part of rc)
- Advanced Verification: Requires essential verification, LOG_DIR

## Notes

- Essential verification is always available after rc initialization
- Advanced verification requires the var module to be loaded
- Both systems can be used together safely
- Advanced verification includes caching for better performance
- Type checking is only available in advanced verification
