# Bash Script Exit Handling Guide

## Core Components

### 1. Error Handler
Located in `rc1`, handles unexpected errors via trap mechanism:
```bash
error_handler() {
    local exit_code=$?
    local command="$BASH_COMMAND"
    local line_number="$1"
    local source_file="${BASH_SOURCE[1]:-${0:-$command}}"
    source_file="${source_file:-"<unknown-source>"}"  # Final fallback
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error in $source_file on line $line_number: Command '$command' exited with status $exit_code" | tee -a "$ERROR_LOG" >&2
}

# Set up error handling trap
trap 'error_handler $LINENO' ERR
```

### 2. Clean Exit Function
Also in `rc1`, provides controlled script termination:
```bash
clean_exit() {
    local exit_code=${1:-0}
    trap - ERR  # Remove error trap
    trap - EXIT # Remove exit trap
    exit $exit_code
}

# Export for global availability
export -f clean_exit
```

## Usage Patterns

### When to Use Clean Exit
1. Early argument validation:
```bash
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    log_error "Incorrect number of arguments."
    print_usage
    clean_exit 0
fi
```

2. Expected termination points:
```bash
case "$mode" in
    -h|--help)
        print_usage
        clean_exit 0
        ;;
esac
```

3. After completing operations:
```bash
setup_main "$@" || clean_exit 0
```

### When Error Handler Triggers
- Unhandled script errors
- Command failures when `set -e` is active
- Explicit exit with non-zero status without using clean_exit
- Pipeline failures when `set -o pipefail` is active

## Key Differences

| Aspect | clean_exit | error_handler |
|--------|------------|---------------|
| Purpose | Controlled termination | Error catching |
| Usage | Explicit calls | Automatic via trap |
| Export | Yes | No |
| Trigger | Manual | Automatic on error |
| Scope | Global | Local to error source |

## Best Practices

1. **Early Exit**
   - Use clean_exit as early as possible when invalid conditions are detected
   - Don't let scripts continue unnecessarily

2. **Error Trapping**
   - Let error_handler catch genuine errors
   - Don't call error_handler directly

3. **Exit Codes**
   - Use 0 for successful completion
   - Use non-zero for actual errors
   ```bash
   clean_exit 0  # Success
   clean_exit 1  # Error condition
   ```

4. **Trap Management**
   - Remove traps before exiting
   - Consider adding new traps for specific cleanup needs

5. **Logging**
   - Always log the reason for exit
   - Use appropriate log levels
   ```bash
   log_error "Invalid input provided"
   clean_exit 1
   ```

## Common Patterns

### Script Template
```bash
#!/bin/bash

# Early validation
validate_args() {
    if [ "$#" -lt 1 ]; then
        log_error "Insufficient arguments"
        print_usage
        clean_exit 1
    fi
}

# Main execution with error handling
main() {
    validate_args "$@"
    
    # Operations that might fail
    if ! some_operation; then
        log_error "Operation failed"
        clean_exit 1
    fi
    
    clean_exit 0
}

main "$@"
```

### Cleanup on Exit
```bash
cleanup() {
    # Cleanup operations
    rm -f /tmp/tempfile
}

trap cleanup EXIT
trap 'error_handler $LINENO' ERR
```

## Notes
- The error handler provides debugging information via `$BASH_SOURCE`, `$LINENO`, and `$BASH_COMMAND`
- clean_exit ensures traps are removed before exiting
- Error handling should be set up as early as possible in scripts
- Always consider cleanup needs when planning exit strategies

## Troubleshooting

### Common Issues
1. Error handler not triggering
   - Check if ERR trap is still active
   - Verify `set -e` status

2. Multiple error messages
   - Check for nested error handlers
   - Verify trap inheritance

3. Missing source information
   - Use fallback mechanisms in error_handler
   - Check `BASH_SOURCE` array content

### Debug Tips
```bash
# Add to script for debugging
set -x  # Enable command tracing
trap 'echo "EXIT trap triggered"' EXIT
trap 'echo "ERR trap triggered"' ERR
```
