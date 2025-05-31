# Output and Verbosity Controls

This guide explains how to control what information appears on your terminal while using the Lab Environment Management System. You can customize your experience from completely silent operation to detailed debugging output.

## Quick Start

```bash
# Enable all output (verbose mode)
export MASTER_TERMINAL_VERBOSITY="on"
./bin/init

# Quiet mode (default - minimal output)
export MASTER_TERMINAL_VERBOSITY="off"
./bin/init

# Custom log directory
export LOG_DIR="/your/custom/log/path"
./bin/init
```

## Master Control

### MASTER_TERMINAL_VERBOSITY
**Purpose**: Controls all terminal output across the entire system
- **Default**: `"off"` (quiet mode)
- **Values**: `"on"` | `"off"`
- **Impact**: When `"off"`, all modules remain silent in the terminal (file logging continues)

```bash
# Enable verbose terminal output
export MASTER_TERMINAL_VERBOSITY="on"

# Return to quiet mode
export MASTER_TERMINAL_VERBOSITY="off"
```

## Module-Specific Controls

When `MASTER_TERMINAL_VERBOSITY="on"`, you can control individual system modules:

### Basic Module Controls
- **`DEBUG_LOG_TERMINAL_VERBOSITY`** - Early initialization messages
- **`LO1_LOG_TERMINAL_VERBOSITY`** - Advanced logging module output  
- **`ERR_TERMINAL_VERBOSITY`** - Error handling messages
- **`TME_TERMINAL_VERBOSITY`** - Timing and performance monitoring

```bash
# Enable master but disable specific modules
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="off"  # Disable debug messages
export TME_TERMINAL_VERBOSITY="off"        # Disable timing output
```

## Advanced: Timing Module Controls

The timing module (`TME`) offers the most granular control with four specific output types:

### Output Categories
- **Report Output** - Performance summaries and timing reports
- **Timing Output** - Detailed timing measurements  
- **Debug Output** - Timing system diagnostics
- **Status Output** - Configuration and status messages

### Runtime Control Functions

After system initialization, use these functions to adjust timing output:

```bash
# Control specific timing outputs
tme_set_output report on     # Enable performance reports
tme_set_output timing off    # Disable detailed measurements
tme_set_output debug off     # Disable debug messages
tme_set_output status on     # Enable status updates

# View current settings
tme_show_output_settings
```

### Pre-Initialization Control

Set these variables before running `./bin/init`:

```bash
export TME_REPORT_TERMINAL_OUTPUT="on"   # Performance reports
export TME_TIMING_TERMINAL_OUTPUT="off"  # Detailed measurements
export TME_DEBUG_TERMINAL_OUTPUT="off"   # Debug information
export TME_STATUS_TERMINAL_OUTPUT="on"   # Status messages
```

## Common Usage Scenarios

### Silent Operation
```bash
# Complete silence
export MASTER_TERMINAL_VERBOSITY="off"
./bin/init
```

### Minimal Feedback
```bash
# Errors and essential status only
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="off"
export LO1_LOG_TERMINAL_VERBOSITY="off"
export TME_TERMINAL_VERBOSITY="off"
./bin/init
```

### Development Mode
```bash
# Full output for debugging
export MASTER_TERMINAL_VERBOSITY="on"
./bin/init
# All other controls default to "on"
```

### Performance Monitoring
```bash
# Focus on performance data
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
./bin/init

# Configure for performance analysis
tme_set_output report on     # Essential performance data
tme_set_output timing on     # Detailed measurements
tme_set_output debug off     # Reduce noise
tme_set_output status off    # Reduce noise
```

### Custom Output Mix
```bash
# Enable master control
export MASTER_TERMINAL_VERBOSITY="on"
./bin/init

# Then selectively enable what you want
tme_set_output report on     # Performance summaries
tme_set_output debug off     # No debug noise
tme_set_output timing off    # No detailed measurements
tme_set_output status on     # Status feedback
```

## Environment Variables Summary

| Variable | Default | Purpose |
|----------|---------|---------|
| `MASTER_TERMINAL_VERBOSITY` | `"off"` | Master switch for all terminal output |
| `DEBUG_LOG_TERMINAL_VERBOSITY` | `"on"` | Early initialization debug messages |
| `LO1_LOG_TERMINAL_VERBOSITY` | `"on"` | Advanced logging module output |
| `ERR_TERMINAL_VERBOSITY` | `"on"` | Error handling messages |
| `TME_TERMINAL_VERBOSITY` | `"on"` | Timing module (enables nested controls) |
| `TME_REPORT_TERMINAL_OUTPUT` | `"on"` | Timing reports and summaries |
| `TME_TIMING_TERMINAL_OUTPUT` | `"on"` | Detailed timing measurements |
| `TME_DEBUG_TERMINAL_OUTPUT` | `"on"` | Timing system diagnostics |
| `TME_STATUS_TERMINAL_OUTPUT` | `"on"` | Timing configuration messages |

## Troubleshooting

### No Output Despite Settings
**Problem**: Expected output doesn't appear

**Solution**: Check the hierarchy
```bash
# Ensure master control is enabled
export MASTER_TERMINAL_VERBOSITY="on"

# Then check module-specific controls
echo "TME Module: ${TME_TERMINAL_VERBOSITY:-default}"
tme_show_output_settings
```

### Too Much Output
**Problem**: Terminal is too noisy

**Solution**: Reduce verbosity gradually
```bash
# Start by disabling debug messages
tme_set_output debug off

# Then disable detailed timing if still too verbose
tme_set_output timing off

# For minimal output, disable the timing module entirely
export TME_TERMINAL_VERBOSITY="off"
```

### Functions Not Available
**Problem**: `tme_set_output` command not found

**Solution**: Ensure system is initialized
```bash
# Make sure system is properly initialized
./bin/init

# Verify TME module is loaded
type -t tme_set_output
```

## Remember

- **File Logging Continues**: Disabling terminal output doesn't affect file logging
- **Master Control**: All module controls require `MASTER_TERMINAL_VERBOSITY="on"`
- **Runtime Changes**: Use `tme_set_output` functions after initialization
- **Persistent Settings**: Environment variables persist until you change them
- **Session Scope**: Controls affect only your current session

This system gives you complete control over your terminal experience while maintaining comprehensive logging for troubleshooting and analysis.
