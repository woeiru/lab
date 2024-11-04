# Bash Scripting Best Practices - Function Output and Variable Handling

## Problem Statement
When executing functions in Bash scripts that need to:
- Maintain variable state between function calls
- Capture and process function output
- Handle errors properly
- Manage resources safely

## Common Pitfalls

### 1. Subshell Variable Isolation
```bash
# BAD PRACTICE: Creates subshell, variables don't persist
output=$("$func")
```
Variables modified in subshells are lost when the subshell exits.

### 2. Unclear Variable Scope
```bash
# BAD PRACTICE: Implicit variable scope
some_var="value"
function_call
```
Variables can be accidentally modified or lost without explicit scope declaration.

## Best Practice Implementation

### 1. Variable Scope Management
```bash
# Explicitly declare global variables
declare -g CONFIG_FILE
declare -g TARGET_USER
declare -g TARGET_HOME
declare -g YES_FLAG
declare -g LOG_LEVEL

# Export variables needed by child processes
export CONFIG_FILE
export TARGET_USER
export TARGET_HOME
export YES_FLAG
export LOG_LEVEL
```

### 2. Function Output Capture
```bash
# Create temporary file safely
local temp_output=$(mktemp)

# Execute function in current shell context
if ! eval "$func" > "$temp_output" 2>&1; then
    local ret=$?
    # Handle error...
    rm "$temp_output"
    return 1
fi
```

### 3. Output Processing
```bash
# Process output line by line
while IFS= read -r line; do
    if [[ "$line" =~ ^CONFIG=(.*) ]]; then
        CONFIG_FILE="${BASH_REMATCH[1]}"
        export CONFIG_FILE
    fi
done < "$temp_output"

# Display output if needed
cat "$temp_output"
```

### 4. Error Handling
```bash
if ! eval "$func" > "$temp_output" 2>&1; then
    local ret=$?
    log "lvl-4" "\033[31m ✗\033[0m"
    if [[ -s "$temp_output" ]]; then
        cat "$temp_output"
    else
        echo "Failed with return code $ret"
    fi
    rm "$temp_output"
    return 1
fi
```

## Complete Example Implementation

```bash
execute_functions() {
    log "lvl-2" "Starting function execution sequence"

    # Ensure global scope for critical variables
    declare -g CONFIG_FILE
    declare -g TARGET_USER
    declare -g TARGET_HOME
    declare -g YES_FLAG
    declare -g LOG_LEVEL

    export CONFIG_FILE
    export TARGET_USER
    export TARGET_HOME
    export YES_FLAG
    export LOG_LEVEL

    for func in "${functions[@]}"; do
        log "lvl-3" "Step ${step_numbers[$func]}: ${func} ..."

        # Create temporary file for output capture
        local temp_output=$(mktemp)
        
        # Execute function in current shell context
        if ! eval "$func" > "$temp_output" 2>&1; then
            local ret=$?
            log "lvl-4" "\033[31m ✗\033[0m"
            if [[ -s "$temp_output" ]]; then
                cat "$temp_output"
            else
                echo "Failed with return code $ret"
            fi
            rm "$temp_output"
            return 1
        fi

        # Process output if exists
        if [[ -s "$temp_output" ]]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ^CONFIG=(.*) ]]; then
                    CONFIG_FILE="${BASH_REMATCH[1]}"
                    export CONFIG_FILE
                fi
            done < "$temp_output"
            cat "$temp_output"
        fi

        rm "$temp_output"
        log "lvl-4" "\033[32m ✓\033[0m"
        echo
    done

    return 0
}
```

## Benefits

1. **Reliability**
   - Consistent variable state
   - Predictable behavior
   - No unexpected variable loss

2. **Maintainability**
   - Clear variable scope
   - Explicit state management
   - Easy to debug

3. **Resource Management**
   - Proper cleanup
   - Safe temporary file handling
   - File descriptor management

4. **Error Handling**
   - Comprehensive error capture
   - Meaningful error messages
   - Proper exit codes

## Additional Considerations

1. Always cleanup temporary files
2. Use proper error logging
3. Handle both stdout and stderr appropriately
4. Consider using trap for cleanup
5. Export variables when needed by child processes
6. Use explicit variable declarations

Remember: The goal is to make scripts that are reliable, maintainable, and behave predictably even in edge cases.
