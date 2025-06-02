# Terminal Crash Prevention

## Issue Description

Previously, the lab environment terminal would crash when users ran non-existent commands (like `fun` or any typo). This was caused by the `set -e` (errexit) option being enabled during the initialization process, which forces the shell to exit immediately when any command returns a non-zero exit status.

## Root Cause

The issue originated from the Component Orchestrator (`/home/es/lab/bin/orc`) which was setting `set -eo pipefail` unconditionally. When a command like `fun` is executed:

1. Bash returns exit code 127 (command not found)
2. With `set -e` enabled, this triggers an immediate shell exit
3. The terminal session terminates, appearing as a "crash" to the user

## Solution Implemented

### 1. Interactive Shell Detection

Modified `/home/es/lab/bin/orc` to detect interactive shells and apply different error handling strategies:

```bash
#!/bin/bash
# Only enable strict error handling in non-interactive shells to prevent terminal crashes
if [[ ! -t 0 || "${-}" != *i* ]]; then
    set -eo pipefail  # Exit on error and pipe failures, but allow unbound variables for compatibility
else
    # In interactive shells, use a more lenient error handling approach
    set -o pipefail  # Still catch pipe failures, but don't exit on errors
fi
```

This approach:
- Maintains strict error handling for scripts and automated processes
- Prevents terminal crashes in interactive sessions
- Still catches pipe failures which are important for script reliability

### 2. Command Not Found Handler

Added a `command_not_found_handle` function to `/home/es/lab/lib/core/err`:

```bash
command_not_found_handle() {
    local command="$1"
    local exit_code=127
    
    # Display a user-friendly error message
    echo "bash: $command: command not found" >&2
    
    # Log the command not found event if logging is available
    if type err_process_error &>/dev/null; then
        err_process_error "command_not_found" "Command not found: $command" "$exit_code" "WARNING"
    fi
    
    # Return the standard exit code for command not found, but don't exit the shell
    return $exit_code
}
```

This function:
- Provides consistent error messages for command not found scenarios
- Integrates with the existing error logging system
- Returns the correct exit code without terminating the shell

## Verification

To verify the fix is working:

1. **Test non-existent commands:**
   ```bash
   fun
   nonexistentcommand123
   ```
   Should display "command not found" without crashing the terminal.

2. **Verify normal commands work:**
   ```bash
   echo "test"
   ls
   ```
   Should work normally.

3. **Check error handling:**
   ```bash
   ls /nonexistent/directory
   ```
   Should show error message without crashing.

4. **Verify function availability:**
   ```bash
   type command_not_found_handle
   ```
   Should show the function is available.

## Prevention Guidelines

### For Script Development

1. **Use conditional errexit in scripts:**
   ```bash
   # Only enable strict mode when executed directly
   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
       set -e
   fi
   ```

2. **Detect interactive vs non-interactive execution:**
   ```bash
   if [[ ! -t 0 || "${-}" != *i* ]]; then
       set -e  # Safe for non-interactive
   fi
   ```

### For Environment Configuration

1. **Avoid global errexit in sourced scripts** - Use it only when necessary for specific script execution
2. **Test initialization scripts in interactive shells** - Ensure they don't break user experience
3. **Implement graceful error handling** - Use error functions instead of shell exits in shared modules

## Benefits

- **User Experience**: No more terminal crashes from typos or unknown commands
- **Script Reliability**: Maintains strict error handling for automated processes
- **Error Logging**: Unknown commands are logged for analysis
- **Backward Compatibility**: Existing scripts continue to work without modification

## Related Files

- `/home/es/lab/bin/orc` - Component Orchestrator (modified)
- `/home/es/lab/lib/core/err` - Error handling module (enhanced)
- `/home/es/lab/bin/ini` - Main initialization script (uses modified orchestrator)

## References

- [Bash Set Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
- [Bash Error Handling](https://www.gnu.org/software/bash/manual/html_node/Exit-Status.html)
- [Interactive Shell Detection](https://www.gnu.org/software/bash/manual/html_node/Is-this-Shell-Interactive_003f.html)
