# Bash Logging and Redirection Reminder

## File Descriptors in Bash

Bash uses file descriptors (FDs) for input/output operations. The standard FDs are:

- 0: stdin (Standard Input)
- 1: stdout (Standard Output)
- 2: stderr (Standard Error)

## Redirection Operators

- `>`: Redirect output, overwriting the file
- `>>`: Redirect output, appending to the file
- `2>`: Redirect stderr
- `&>`: Redirect both stdout and stderr

## Our Current Setup

```bash
exec 2>>/tmp/up_error.log
set -x
```

### What This Does

1. `exec 2>>`: Redirects stderr (FD 2) to append to `/tmp/up_error.log`
2. `set -x`: Enables debug mode, printing each command before execution

### Logging Functions

```bash
log_error() {
    echo "ERROR: $1" >&2
}

log_info() {
    echo "INFO: $1"
}
```

- `log_error`: Writes to stderr (FD 2), which is redirected to the log file
- `log_info`: Writes to stdout (FD 1), which goes to the console

## Important Notes

1. Only `log_error` and other stderr output go to the log file
2. `log_info` messages appear in the console, not the log file
3. The `set -x` output goes to the log file (it uses stderr)

## Alternative Setups

### Redirect Both stdout and stderr

```bash
exec &>>/tmp/up_error.log
```

This captures all output in the log file.

### Use a Custom File Descriptor

```bash
exec 3>>/tmp/up_error.log

log_error() {
    echo "ERROR: $1" >&3
}

log_info() {
    echo "INFO: $1" >&3
}
```

This allows fine-grained control over logging.

## Best Practices

1. Be consistent with logging destinations
2. Use appropriate log levels (ERROR, INFO, DEBUG, etc.)
3. Include timestamps in log messages
4. Consider using a logging library for complex scripts

## Troubleshooting

If logs are not appearing as expected:
1. Check file permissions
2. Verify the log file path
3. Ensure redirection is set up before any logging occurs
4. Use `set -x` to debug the script execution

Remember: Understanding your logging setup is crucial for effective debugging and monitoring of your bash scripts.
