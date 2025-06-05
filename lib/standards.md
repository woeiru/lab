# Library Standards

## Parameter Validation Standard

This document defines the mandatory parameter validation standard for all functions in the `ops` library. This standard ensures consistent error handling, improves usability, and follows software engineering best practices.

### Core Principle

**No function can run without proper parameter validation.** Every function must validate its parameters and provide clear usage information when called incorrectly.

**Functions without parameters do not exist.** All functions must require at least one parameter. For functions that traditionally would take no parameters, use the `-x` (execute) flag pattern to ensure explicit intent and maintain consistency across the library.

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
# <parameter1> <parameter2> or -x (execute)
function_name() {
    # Technical Description:
    #   Detailed explanation of function behavior and implementation
    #   Step-by-step description of what the function does
    #   Any important implementation notes or algorithms used
    # Dependencies:
    #   - Required external commands or utilities
    #   - Required functions from other modules
    #   - Required system permissions or privileges
    #   - Network access or file system requirements
    # Arguments:
    #   $1: parameter_name - description of the parameter and its purpose
    #   $2: parameter_name - description of the parameter and its purpose
    #   [For functions requiring execution flag, use -x pattern]
    #   [For functions with optional parameters, mark them as optional]
    
    # Implementation...
}
```

**Note**: 
- `aux_use` extracts the **three comment lines above** the function name for usage display
- `aux_tec` extracts the **technical details block under** the function name for detailed help
- Technical details should be structured with clear sections: Technical Description, Dependencies, and Arguments
- Use proper indentation (3 spaces for section content) and formatting for readability
- Each section should start with a descriptive header followed by detailed bullet points
- Maintain consistent formatting across all functions in the module

#### 3. Technical Details Structure

The technical details block must follow this structured format:

- **Technical Description**: A comprehensive explanation of what the function does, including:
  - Step-by-step breakdown of the function's operation
  - Implementation approach and algorithms used
  - Important behavioral notes and edge cases
  - Integration with other system components

- **Dependencies**: A complete list of requirements, including:
  - External command-line utilities needed
  - Required functions from other modules
  - System permissions or privileges required
  - Network access, file system, or hardware requirements

- **Arguments**: Detailed parameter documentation:
  - Each parameter with its variable name and purpose
  - Expected format, type, or valid values
  - Optional parameters clearly marked
  - Variable parameter functions with explanation
  - For execution-only functions, document the `-x` flag requirement

#### 4. Execution Flag Pattern for Action Functions

Functions that perform actions and traditionally would take no parameters must use the `-x` (execute) flag pattern:

```bash
# Function description
# shortname or mnemonic  
# -x (execute)
function_name() {
    # Technical Description: [detailed explanation]
    # Dependencies: [requirements list]
    # Arguments:
    #   $1: -x - explicit execution flag required for safety and consistency
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    if [ $# -ne 1 ] || [ "$1" != "-x" ]; then
        aux_use
        return 1
    fi
    
    # Function implementation...
}
```

This pattern:
- Forces explicit intent for all function executions
- Maintains the "no function without parameters" principle
- Provides safety for potentially destructive actions
- Ensures consistency across all library functions

#### 5. Special Cases

- **Functions with optional parameters**: Document optional parameters as `[optional_param]`
- **Functions with variable parameters**: Implement smart validation counting required vs optional arguments
- **Infrastructure/Utility Functions**: Core utility functions in the `aux` module (like `aux_use`, `aux_tec`, `ana_laf`, `ana_acu`) are exempted from the `-x` flag requirement as they are infrastructure functions designed to be called by other functions to implement the standards themselves

### Benefits

1. **Fail-Fast Principle**: Errors are caught immediately with clear feedback
2. **Consistent UX**: All functions provide uniform error messages via `aux_use`
3. **Self-Documenting**: Usage information is embedded in the code
4. **Maintainability**: Standard validation pattern across all functions
5. **Comprehensive Documentation**: Structured technical details with clear sections
6. **Dependency Tracking**: Clear identification of external requirements and prerequisites
7. **Operational Clarity**: Detailed understanding of function behavior and integration

### Examples

#### Function with Required Parameters
```bash
# Copies files from source to destination
# copy files
# <source_path> <destination_path>
usr_copy() {
    # Technical Description:
    #   Performs recursive copy with preservation of permissions and metadata
    #   Validates source exists before attempting copy operation
    #   Creates destination directory structure if needed
    #   Handles symbolic links and special files appropriately
    # Dependencies:
    #   - 'cp' command with recursive support
    #   - 'mkdir' for directory creation
    #   - Read permissions on source directory
    #   - Write permissions on destination parent directory
    # Arguments:
    #   $1: source_path - absolute or relative path to source file or directory
    #   $2: destination_path - absolute or relative path to destination location
    
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

#### Function with Execution Flag
```bash
# Lists all available functions
# list functions
# -x (execute)
usr_list() {
    # Technical Description:
    #   Scans function files and extracts function names using pattern matching
    #   Filters functions by prefix pattern to exclude internal helpers
    #   Sorts results alphabetically for consistent output
    #   Provides clean, formatted output suitable for user interaction
    # Dependencies:
    #   - 'grep' for pattern matching in source files
    #   - 'sort' for alphabetical ordering
    #   - Read access to function definition files
    #   - Standard POSIX shell utilities
    # Arguments:
    #   $1: -x - explicit execution flag required for consistency
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    if [ $# -ne 1 ] || [ "$1" != "-x" ]; then
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
    # Technical Description:
    #   Displays comprehensive overview of available functions with optional filtering
    #   Processes all arguments and forwards them to the analysis function
    #   Supports pattern-based filtering for function name matching
    #   Provides formatted output with usage information and descriptions
    # Dependencies:
    #   - 'ana_laf' function for list and filter operations
    #   - Access to function definition files
    #   - Pattern matching utilities for filtering
    # Arguments:
    #   $1: function_name_filter (optional) - pattern to filter function names
    #   Additional arguments are passed through to ana_laf
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    # Optional parameters - no validation needed
    # Pass all arguments to processing function
    ana_laf "$FILEPATH_usr" "$@"
}
```

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
4. **Convert functions without parameters to use `-x` flag pattern**
5. **Restructure technical details with proper sections**:
   - Technical Description (comprehensive function explanation)
   - Dependencies (all requirements and prerequisites)
   - Arguments (detailed parameter documentation)
6. Test each function with incorrect parameters
7. Verify help functionality with `--help` flag
8. Ensure no function can execute without explicit parameters

### Enhanced Technical Documentation

The improved technical details format provides:

1. **Structured Information**: Clear separation of description, dependencies, and arguments
2. **Comprehensive Coverage**: Detailed explanation of function behavior and requirements
3. **Maintenance Clarity**: Easy identification of external dependencies and system requirements
4. **User Guidance**: Detailed parameter documentation for proper function usage
5. **Operational Context**: Understanding of how functions integrate with the broader system

### Testing

Verify standard compliance by calling each function with incorrect parameters:
- Functions should display usage information via `aux_use`
- Functions should return non-zero exit codes
- No function should execute its main logic with invalid parameters
- All functions must require at least one parameter (no parameter-less functions)
- Execution-only functions must validate the `-x` flag specifically

---

*This standard ensures robust, maintainable, and user-friendly functions across the operations library ecosystem.*
