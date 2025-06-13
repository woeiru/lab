# Library Standards
# Technical Standards and Compliance Framework for lib/ops
# 
# Purpose: Mandatory technical requirements and implementation patterns
# Type: Compliance Framework - defines WHAT must be implemented and HOW
# Scope: All operational functions in lib/ops modules
# Companion: .guide (Best Practices and Excellence Framework)
#
# Last Updated: 2025-06-14
# Maintainer: Lab Environment Management System

# Library Standards

## Function Naming Convention

To ensure clarity, prevent naming collisions, and enhance maintainability, especially when this toolkit is sourced into other projects, all primary functions within modules in the `/lib` directory must adhere to a three-letter module prefix convention.

**Convention:** `[module_prefix]_[function_name]`

*   **Purpose:** The prefix immediately identifies the module a function belongs to, acting as a de facto namespace in the global Bash environment. This is crucial for preventing conflicts when the toolkit is integrated into diverse projects.
*   **Application:** This convention applies to all functions intended for external use or those representing core functionalities of a module.
*   **Exceptions:** Internal helper functions, not intended for direct external calls, may omit the prefix if their scope is strictly confined to their defining module and they do not risk global name collisions.

## Parameter Validation Standard

This document defines the mandatory parameter validation standard for all functions in the `ops` library. This standard ensures consistent error handling, improves usability, and follows software engineering best practices.

### Core Principle

**No function can run without proper parameter validation.** Every function must validate its parameters and provide clear usage information when called incorrectly.

**Functions without parameters do not exist.** All functions must require at least one parameter. For functions that traditionally would take no parameters, use the `-x` (execute) flag pattern to ensure explicit intent and maintain consistency across the library.

### Return Code Standards

Functions must follow consistent exit codes:
- `0`: Success
- `1`: Parameter validation failure or user error  
- `2`: System/dependency error
- `127`: Required command not found

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
- **Infrastructure/Utility Functions within ops**: Internal helper functions may omit the prefix if their scope is strictly confined to their defining module and they do not risk global name collisions. **Functions with variable parameter counts may implement smart validation instead of strict count checking.**

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
- **Functions should output errors to stderr when appropriate**
- **Return codes should follow the standard conventions**

## Auxiliary Functions Integration Standard

Beyond the core help system (`aux_use` and `aux_tec`), functions should leverage the comprehensive `aux` library to ensure consistent behavior, proper error handling, and enhanced functionality across the operations library.

### Decision Framework: When to Use Auxiliary Functions

#### Critical Integration Points (ALWAYS Required)

**Every function MUST include:**

1. **Parameter Validation (`aux_val`)** - Required for ALL functions
   ```bash
   # WHEN: Every function with parameters
   # WHY: Fail-fast principle, consistent error handling
   if ! aux_val "$param" "not_empty"; then
       aux_err "Parameter cannot be empty: $param"
       aux_use
       return 1
   fi
   ```

2. **Usage Help (`aux_use`) and Technical Help (`aux_tec`)** - Required for ALL functions
   ```bash
   # WHEN: Every function
   # WHY: Self-documenting code, user assistance
   if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
       aux_tec
       return 0
   fi
   ```

#### Mandatory Integration Points (Required in Specific Scenarios)

**System-Dependent Functions MUST include:**

3. **Dependency Checks (`aux_chk`)** - Required when function depends on external commands/resources
   ```bash
   # WHEN: Function uses external commands, files, or network resources
   # WHY: Clear error messages, early failure detection
   # EXAMPLES: Functions using docker, systemctl, remote hosts, config files
   
   if ! aux_chk "command" "docker"; then
       aux_err "Docker command not found - required for container operations"
       return 127
   fi
   
   if ! aux_chk "file_exists" "$config_file"; then
       aux_err "Configuration file not found: $config_file"
       return 2
   fi
   ```

**Error-Prone Functions MUST include:**

4. **Operational Logging (`aux_log`, `aux_info`, `aux_warn`, `aux_err`)** - Required for production operations
   ```bash
   # WHEN: Functions that modify system state, handle sensitive data, or could fail
   # WHY: Audit trails, troubleshooting, monitoring
   # EXAMPLES: Service management, file operations, network changes, user actions
   
   aux_info "Starting service deployment" "service=$service_name,environment=$env"
   aux_warn "Configuration file missing, using defaults" "file=$config_file"
   aux_err "Failed to connect to database" "host=$db_host,error=$error_msg"
   ```

#### Optional Integration Points (Use When Beneficial)

**Development and Troubleshooting:**

5. **Debug Logging (`aux_dbg`)** - Optional but recommended for complex functions
   ```bash
   # WHEN: Functions with complex logic, multiple steps, or frequent debugging needs
   # WHY: Development efficiency, production troubleshooting
   # EXAMPLES: Multi-step workflows, data processing, configuration parsing
   
   aux_dbg "Processing configuration section: $section_name"
   aux_dbg "Found $count items to process"
   aux_dbg "Validation completed, proceeding to execution phase"
   ```

**Interactive Functions:**

6. **User Interaction (`aux_ask`)** - Required for functions needing user input
   ```bash
   # WHEN: Functions require user confirmation or input
   # WHY: Consistent user experience, input validation
   # EXAMPLES: Destructive operations, configuration setup, interactive wizards
   
   local confirm=$(aux_ask "Delete all data in $directory? (yes/no)" "no")
   local port=$(aux_ask "Enter port number" "8080" "numeric")
   ```

**Command Execution:**

7. **Safe Command Execution (`aux_cmd`)** - Recommended for external command execution
   ```bash
   # WHEN: Executing external commands that could fail
   # WHY: Consistent error handling, command validation
   # EXAMPLES: System commands, service operations, file manipulations
   
   if aux_cmd "systemctl" "restart" "$service"; then
       aux_info "Service restarted successfully: $service"
   else
       aux_err "Failed to restart service: $service"
       return 2
   fi
   ```

**Data Processing:**

8. **Array Operations (`aux_arr`)** - Optional for functions working with arrays
   ```bash
   # WHEN: Functions manipulating lists, collections, or arrays
   # WHY: Consistent data handling, reduced code complexity
   # EXAMPLES: Configuration processing, batch operations, data analysis
   
   aux_arr "add" "processed_items" "$new_item"
   if aux_arr "contains" "required_items" "$item"; then
       # Process item
   fi
   ```

### Function Classification and Integration Requirements

#### Category 1: Core System Functions (Infrastructure)
**Examples:** Service management, system configuration, network setup
**Required:** `aux_val`, `aux_chk`, `aux_log`, `aux_info`, `aux_warn`, `aux_err`
**Optional:** `aux_dbg`, `aux_cmd`, `aux_ask` (for confirmations)

```bash
# System service enable/start function (actual example from sys module)
sys_sdc() {
    # Validation (REQUIRED)
    if ! aux_val "$service_name" "not_empty"; then
        aux_err "Service name cannot be empty"
        aux_use
        return 1
    fi
    
    # Dependency checks (REQUIRED)
    if ! aux_chk "command" "systemctl"; then
        aux_err "systemctl command not found"
        return 127
    fi
    
    # Operational logging (REQUIRED)
    aux_info "Enabling and starting service" "service=$service_name"
    
    # Safe command execution (RECOMMENDED)
    if aux_cmd "systemctl" "enable" "$service_name" && aux_cmd "systemctl" "start" "$service_name"; then
        aux_info "Service operation successful" "service=$service_name"
    else
        aux_err "Service operation failed" "service=$service_name"
        return 2
    fi
}
```

#### Category 2: User-Facing Functions (Interactive)
**Examples:** Configuration wizards, setup scripts, user management
**Required:** `aux_val`, `aux_ask`, `aux_info`, `aux_warn`
**Optional:** `aux_dbg`, `aux_chk`, `aux_cmd`

```bash
# Interactive network interface setup function (actual example from net module)
net_uni() {
    # User interaction (REQUIRED)
    local interface=$(aux_ask "Enter network interface name" "eth0" "not_empty")
    local new_name=$(aux_ask "Enter new interface name" "" "not_empty")
    
    # Validation (REQUIRED)
    if ! aux_val "$interface" "alphanum"; then
        aux_err "Interface name must be alphanumeric"
        return 1
    fi
    
    # User feedback (REQUIRED)
    aux_info "Configuring network interface: $interface -> $new_name"
}
```

#### Category 3: Data Processing Functions (Computational)
**Examples:** Log analysis, configuration parsing, data transformation
**Required:** `aux_val`, `aux_dbg` (recommended)
**Optional:** `aux_arr`, `aux_info`, `aux_warn`

```bash
# Data processing function example (using actual aux functions)
usr_cff() {
    # Validation (REQUIRED)
    if ! aux_val "$directory_path" "dir_exists"; then
        aux_err "Directory not found: $directory_path"
        return 2
    fi
    
    # Debug logging (RECOMMENDED for complex processing)
    aux_dbg "Starting file count analysis for directory: $directory_path"
    
    # Array operations (OPTIONAL for data manipulation)
    local file_list=()
    aux_arr "add" "file_list" "$file_entry"
    
    local file_count=$(aux_arr "length" "file_list")
    aux_dbg "Processed $file_count files from directory"
}
```

#### Category 4: Utility Functions (Helpers)
**Examples:** String manipulation, file operations, format conversion
**Required:** `aux_val` (minimal)
**Optional:** `aux_dbg`, `aux_info`

```bash
# Simple utility function example (using actual pattern from usr module)
usr_fun() {
    # Validation (REQUIRED)
    if ! aux_val "$function_filter" "not_empty"; then
        # Optional parameter - no error needed
    fi
    
    # Optional debug for development
    aux_dbg "Listing functions with filter: ${function_filter:-none}"
    
    # Implementation using ana_laf
    ana_laf "$FILEPATH_usr" "$@"
}
```

### Integration Decision Tree

```
Does the function...

├── Modify system state? (services, files, network)
│   ├── YES → MUST use: aux_val, aux_chk, aux_log/info/warn/err, aux_cmd
│   └── NO → Continue...
│
├── Require user input or confirmation?
│   ├── YES → MUST use: aux_ask, aux_val, aux_info
│   └── NO → Continue...
│
├── Process complex data or multiple steps?
│   ├── YES → SHOULD use: aux_dbg, aux_arr (if arrays), aux_info
│   └── NO → Continue...
│
├── Execute external commands?
│   ├── YES → SHOULD use: aux_cmd, aux_chk, aux_err
│   └── NO → Continue...
│
└── Simple utility or calculation?
    └── MINIMUM use: aux_val (for inputs)
```

### Integration Priority Matrix

| Function Type | aux_val | aux_chk | aux_log | aux_dbg | aux_ask | aux_cmd | aux_arr |
|--------------|---------|---------|---------|---------|---------|---------|---------|
| **System Ops** | MUST | MUST | MUST | SHOULD | OPTIONAL | SHOULD | OPTIONAL |
| **User Interactive** | MUST | OPTIONAL | SHOULD | OPTIONAL | MUST | OPTIONAL | OPTIONAL |
| **Data Processing** | MUST | OPTIONAL | OPTIONAL | SHOULD | OPTIONAL | OPTIONAL | SHOULD |
| **Utilities** | MUST | OPTIONAL | OPTIONAL | OPTIONAL | OPTIONAL | OPTIONAL | OPTIONAL |
| **Network Ops** | MUST | MUST | MUST | SHOULD | OPTIONAL | SHOULD | OPTIONAL |
| **File Ops** | MUST | SHOULD | SHOULD | OPTIONAL | OPTIONAL | SHOULD | OPTIONAL |

### Environment-Based Integration

#### Development Environment
```bash
# Enhanced debugging and verbose output
export AUX_DEBUG_ENABLED=1
export MASTER_TERMINAL_VERBOSITY="on"
export AUX_LOG_FORMAT="human"

# More liberal use of aux_dbg for development insights
```

#### Production Environment
```bash
# Structured logging for monitoring
export AUX_DEBUG_ENABLED=0
export AUX_LOG_FORMAT="json"
export LOG_DIR="/var/log/operations"

# Focus on aux_log, aux_info, aux_warn, aux_err for operational visibility
```

#### Testing Environment
```bash
# Comprehensive logging for test analysis
export AUX_DEBUG_ENABLED=1
export AUX_LOG_FORMAT="kv"

# Use all auxiliary functions to validate behavior
```

### Common Integration Patterns

#### Pattern 1: Simple Validation Function
```bash
# Minimal integration for basic utilities
function_name() {
    # Help (ALWAYS)
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    # Parameter validation (ALWAYS)
    if [ $# -ne 1 ]; then
        aux_use
        return 1
    fi
    
    if ! aux_val "$1" "not_empty"; then
        aux_err "Parameter cannot be empty"
        return 1
    fi
    
    # Implementation...
}
```

#### Pattern 2: System Operation Function
```bash
# Full integration for system-level operations
function_name() {
    # Help (ALWAYS)
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    # Parameter validation (ALWAYS)
    if [ $# -ne 2 ]; then
        aux_use
        return 1
    fi
    
    # Input validation (ALWAYS)
    if ! aux_val "$1" "not_empty"; then
        aux_err "Service name cannot be empty"
        aux_use
        return 1
    fi
    
    # Dependency checks (MUST for system functions)
    if ! aux_chk "command" "systemctl"; then
        aux_err "systemctl command not found"
        return 127
    fi
    
    # Debug logging (SHOULD for complex operations)
    aux_dbg "Starting service operation: $1 -> $2"
    
    # Operational logging (MUST for system changes)
    aux_info "Performing service operation" "service=$1,action=$2"
    
    # Safe command execution (SHOULD for external commands)
    if aux_cmd "systemctl" "$2" "$1"; then
        aux_info "Service operation successful" "service=$1,action=$2"
    else
        aux_err "Service operation failed" "service=$1,action=$2"
        return 2
    fi
}
```

#### Pattern 3: Interactive Configuration Function
```bash
# User-focused integration for interactive functions
function_name() {
    # Help (ALWAYS)
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        aux_tec
        return 0
    fi
    
    # User interaction (MUST for interactive functions)
    local config_file=$(aux_ask "Enter configuration file path" "/etc/default/config" "file_exists")
    local service_name=$(aux_ask "Enter service name" "" "not_empty")
    
    # Validation (ALWAYS)
    if ! aux_val "$service_name" "alphanum"; then
        aux_err "Service name must be alphanumeric"
        return 1
    fi
    
    # User feedback (MUST for user-facing functions)
    aux_info "Configuring service: $service_name"
    
    # Implementation with continued user feedback...
}
```

### Migration Strategy

#### Phase 1: Critical Integration (Week 1)
1. Add `aux_val` to all functions for parameter validation
2. Ensure `aux_use` and `aux_tec` are properly implemented
3. Add `aux_err` for critical error conditions

#### Phase 2: System Integration (Week 2)
1. Add `aux_chk` to system-dependent functions
2. Implement `aux_log`, `aux_info`, `aux_warn` for operational functions
3. Add `aux_cmd` for external command execution

#### Phase 3: Enhanced Integration (Week 3)
1. Add `aux_dbg` to complex functions for development support
2. Implement `aux_ask` for interactive functions
3. Add `aux_arr` where array operations are beneficial

#### Phase 4: Optimization (Week 4)
1. Review and optimize auxiliary function usage
2. Implement tracing for distributed operations
3. Add metrics collection where appropriate

---
