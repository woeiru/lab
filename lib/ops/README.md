# Operations Library Standards

## Parameter Validation Standard

This document defines the mandatory parameter validation standard for all functions in the `ops` library. This standard ensures consistent error handling, improves usability, and follows software engineering best practices.

### Core Principle

**No function can run without proper parameter validation.** Every function must validate its parameters and provide clear usage information when called incorrectly.

### Implementation Requirements

#### 1. Parameter Validation Pattern

All functions must implement parameter validation using this enhanced pattern:

```bash
function_name() {
    # Handle help flag first
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    # Then validate parameter count
    if [ $# -ne EXPECTED_COUNT ]; then
        aux_use
        return 1
    fi
    
    # Function implementation...
}
```

#### 2. Comment Block Format

Functions must include properly formatted comment blocks for both `aux_use` and `aux_tec`:

```bash
# Function description
# shortname or mnemonic
# <parameter1> <parameter2> or (no parameters)
function_name() {
    # TECHNICAL DETAILS:
    # Detailed explanation of function behavior
    # Implementation notes, examples, edge cases
    
    # Implementation...
}
```

**Note**: 
- `aux_use` extracts the **three comment lines above** the function name for usage display
- `aux_tec` extracts the **technical details block under** the function name for detailed help

#### 3. Special Cases

- **Functions with no parameters**: Use `(no parameters)` in comment and validate `$# -ne 0`
- **Functions with optional parameters**: Document optional parameters as `[optional_param]`
- **Functions with variable parameters**: Implement smart validation counting required vs optional arguments

### Benefits

1. **Fail-Fast Principle**: Errors are caught immediately with clear feedback
2. **Consistent UX**: All functions provide uniform error messages via `aux_use`
3. **Self-Documenting**: Usage information is embedded in the code
4. **Maintainability**: Standard validation pattern across all functions

### Examples

#### Function with Required Parameters
```bash
# Copies files from source to destination
# copy files
# <source_path> <destination_path>
usr_copy() {
    # TECHNICAL DETAILS:
    # Performs recursive copy with preservation of permissions
    # Validates source exists before attempting copy
    # Creates destination directory if needed
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    if [ $# -ne 2 ]; then
        aux_use
        return 1
    fi
    
    local source="$1"
    local dest="$2"
    # Implementation...
}
```

#### Function with No Parameters
```bash
# Lists all available functions
# list functions
# (no parameters)
usr_list() {
    # TECHNICAL DETAILS:
    # Scans function files and extracts function names
    # Filters by prefix pattern, sorts alphabetically
    # Excludes internal helper functions
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    if [ $# -ne 0 ]; then
        aux_use
        return 1
    fi
    
    # Implementation...
}
```

#### Function with Optional Parameters
```bash
# Shows function overview with optional filtering
# overview functions
# [function_name_filter]
usr_fun() {
    # TECHNICAL DETAILS:
    # Optional parameters - no validation needed
    # Pass all arguments to processing function
    # Supports filtering by function name pattern
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    # Optional parameters - no validation needed
    # Pass all arguments to processing function
    aux_laf "$FILEPATH_usr" "$@"
}
```
    aux_laf "$FILEPATH_usr" "$@"
}
```


### Future Considerations

#### -x Flag Pattern for Action Functions

For functions that perform actions but traditionally take no parameters, consider implementing a `-x` flag pattern:

```bash
# Executes system cleanup
# cleanup system
# -x (execute)
sys_cleanup() {
    if [ $# -ne 1 ] || [ "$1" != "-x" ]; then
        aux_use
        return 1
    fi
    
    # Perform cleanup...
}
```

This pattern:
- Forces explicit intent for potentially dangerous operations
- Maintains the "no function without parameters" principle
- Provides safety for destructive actions

### Best Practices Alignment

This standard aligns with established software engineering principles:

1. **Unix Philosophy**: Tools should do one thing well and fail clearly
2. **Defensive Programming**: Validate inputs before processing
3. **Principle of Least Surprise**: Consistent behavior across all functions
4. **Self-Documenting Code**: Usage information embedded in source

### Migration Guide

To apply this standard to other libraries:

1. Audit all functions for parameter validation
2. Add `aux_use` calls for validation failures
3. Update comment blocks for proper `aux_use` display
4. Test each function with incorrect parameters
5. Document any special cases or exceptions

### Testing

Verify standard compliance by calling each function with incorrect parameters:
- Functions should display usage information via `aux_use`
- Functions should return non-zero exit codes
- No function should execute its main logic with invalid parameters

---

*This standard ensures robust, maintainable, and user-friendly functions across the operations library ecosystem.*
