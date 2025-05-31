# Logging System Documentation

This document provides a comprehensive analysis of the logging architecture, including log files in the `.log` directory, state files in the `.tmp` directory, and terminal verbosity controls.

## Overview

The lab system employs a sophisticated multi-layered logging architecture designed for both development debugging and production monitoring. The system consists of:

1. **Log Files** (`${LOG_DIR}/.log/`) - Human-readable logs for different system components
2. **State Files** (`${TMP_DIR}/.tmp/`) - Configuration and cache files for logging behavior
3. **Terminal Verbosity Controls** - Hierarchical control system for console output

### Hierarchical Verbosity System

The system uses a multi-tier verbosity control mechanism:

- **Master Control**: `MASTER_TERMINAL_VERBOSITY` (default: "off") - Master switch for all terminal output
- **Module-Specific Controls**: Individual verbosity settings that require master to be "on"
  - `DEBUG_LOG_TERMINAL_VERBOSITY` (default: "on") - Early initialization debug messages
  - `LO1_LOG_TERMINAL_VERBOSITY` (default: "on") - Advanced logging module
  - `ERR_TERMINAL_VERBOSITY` (default: "on") - Error handling module  
  - `TME_TERMINAL_VERBOSITY` (default: "on") - Timing module
- **Nested Controls**: Granular controls for specific output types within modules
  - TME Module has nested controls for reports, timing, debug, and status outputs

This design allows fine-grained control while maintaining simple master and module-level overrides.

## Log Files in `${LOG_DIR}/.log`

*   **`debug.log`**:
    *   **Purpose**: Records detailed debugging information during script execution, particularly during early initialization and system verification phases.
    *   **Format**: `[DEBUG] YYYY-MM-DD HH:MM:SS - [source_function] message`
    *   **Writing Functions**:
        *   `debug_log` in `bin/ini`: Simple version for early initialization before full logging system loads
        *   `debug_log` in `lib/core/ver`: Enhanced version with verbosity controls
    *   **Terminal Output**: Controlled by `MASTER_TERMINAL_VERBOSITY` + `DEBUG_LOG_TERMINAL_VERBOSITY`
    *   **Usage**: Primary debug channel for core system operations and modules without dedicated debug logs
    *   **Details**: Essential for diagnosing initialization issues, path verification failures, and module loading problems

*   **`err.log`**:
    *   **Purpose**: Centralized error and warning repository for all system components.
    *   **Format**: `[SEVERITY] YYYY-MM-DD HH:MM:SS - [component] message`
    *   **Writing Functions**: 
        *   `handle_error` in `lib/core/err`: Primary error logging function
        *   `error_handler` in `lib/core/err`: Automatic error trap handler  
        *   `err_process_error` in `lib/core/err`: Structured error processing
    *   **Terminal Output**: Controlled by `MASTER_TERMINAL_VERBOSITY` + `ERR_TERMINAL_VERBOSITY`
    *   **Environment Variable**: `ERROR_LOG` (defined in `cfg/core/ric`)
    *   **Features**: 
        *   Supports severity levels (ERROR, WARNING)
        *   Tracks error components and timestamps
        *   Provides error reporting and summary functions
    *   **Details**: Critical for production debugging and system health monitoring

*   **`lo1.log`**:
    *   **Purpose**: Main application log managed by the advanced logging module (`lib/core/lo1`). Features hierarchical indentation, color-coding, and comprehensive debug tracking.
    *   **Format**: 
        *   Standard: `HH:MM:SS.NN └─ message` (with colored indentation based on call stack depth)
        *   Debug: `[LO1-DEBUG] HH:MM:SS.NN - [source] message`
    *   **Writing Functions**:
        *   `log` in `lib/core/lo1`: Primary logging function with `log lvl "message"` syntax
        *   `lo1_log_message` in `lib/core/lo1`: Standardized module logging interface
        *   `lo1_tme_log_with_timer` in `lib/core/lo1`: Logging with timing integration
        *   `init_logger` in `lib/core/lo1`: Logger initialization messages
        *   `lo1_debug_log` in `lib/core/lo1`: Module-specific debug messages
    *   **Terminal Output**: Controlled by `MASTER_TERMINAL_VERBOSITY` + `LO1_LOG_TERMINAL_VERBOSITY` + local `setlog on|off`
    *   **Environment Variables**: 
        *   `LOG_FILE` (defined in `cfg/core/ric`)
        *   `LOG_DEBUG_ENABLED` (controls debug message generation)
    *   **Features**:
        *   16-level color gradient for depth visualization (red to deep violet)
        *   Performance-optimized depth caching
        *   Integration with timing system for performance logging
        *   Call stack analysis for intelligent indentation
    *   **State Control**: Persistent on/off state via `.tmp/lo1_state` file
    *   **Details**: The centerpiece of the logging system, providing structured hierarchical output ideal for complex script debugging

*   **`lo2.log`**:
    *   **Purpose**: Records debug messages specifically from the `lo2` module (`lib/util/lo2`), which handles runtime control structure tracking.
    *   **Writing Functions**:
        *   `lo2_debug_log` (in `lib/util/lo2`)
    *   **Details**: Contains `[LO2-DEBUG]` prefixed messages related to control flow depth calculation.

*   **`tme.log`**:
    *   **Purpose**: Performance monitoring and timing analysis log managed by the timing module (`lib/core/tme`). Provides detailed execution time tracking for system components.
    *   **Format**: 
        *   Headers: `RC Timing Log - [timestamp]` with startup information
        *   Entries: `[START] component_name`, `[END] component_name` with duration and status
    *   **Writing Functions**:
        *   `tme_init_timer` in `lib/core/tme`: Initializes log with header and startup time
        *   `tme_start_timer` in `lib/core/tme`: Records component start time with optional parent relationship
        *   `tme_end_timer` in `lib/core/tme`: Records end time, duration, and completion status
        *   `tme_print_timing_report` in `lib/core/tme`: Generates formatted performance summary
        *   `tme_cleanup_timer` in `lib/core/tme`: Final cleanup and total execution time
    *   **Terminal Output**: Controlled by `MASTER_TERMINAL_VERBOSITY` + `TME_TERMINAL_VERBOSITY`
    *   **Environment Variables**: 
        *   `TME_LOG_FILE` (defined in `cfg/core/ric`)
        *   `TME_STATE_FILE` (controls report generation)
        *   `TME_LEVELS_FILE` (controls report depth)
    *   **Features**:
        *   Hierarchical component timing (parent/child relationships)
        *   Configurable sort order (chronological or duration)
        *   Adjustable depth levels (1-9) for report detail
        *   Color-coded terminal reports with tree visualization
        *   Performance statistics and execution summaries
    *   **Control Functions**: `tme_settme report on|off`, `tme_settme sort chron|duration`, `tme_settme depth N`
    *   **Details**: Essential for performance analysis, bottleneck identification, and execution flow understanding

*   **`init_flow.log`**:
    *   **Purpose**: Tracks the execution flow and timing of the main initialization script (`bin/init`). Critical for debugging startup issues and module loading sequence problems.
    *   **Format**: `INIT_SCRIPT_FLOW: [description] - HH:MM:SS.NNNNNNNNN`
    *   **Writing Functions**: Direct `echo` statements in `bin/init` at key execution milestones
    *   **Key Tracking Points**:
        *   Module sourcing start/completion
        *   Component orchestrator loading
        *   Runtime system initialization
        *   Critical function calls (e.g., `setlogcontrol` calls)
    *   **Terminal Output**: File-only logging (no terminal output)
    *   **Usage Context**: Primarily used for correlating with other logs during troubleshooting
    *   **Details**: Provides high-precision timestamps for diagnosing initialization timing and sequencing issues

*   **Missing Log Files** (Referenced but not currently present):
    *   **`lo2.log`**: Would contain debug messages from the `lo2` module (`lib/util/lo2`) for runtime control structure tracking
        *   Expected format: `[LO2-DEBUG] timestamp - [source] message`
        *   Expected functions: `lo2_debug_log` in `lib/util/lo2`
        *   Purpose: Control flow depth calculation and DEBUG trap management
        *   Status: Module appears to be disabled or not fully integrated into current system
    
    *   **`lo2_entry_trace.log`**: Would record exact moment when `lo2` module begins execution
        *   Expected format: `LO2_TRACE: lo2 script execution started - timestamp`
        *   Purpose: Low-level diagnostic confirmation of module sourcing
        *   Status: Associated with the currently inactive `lo2` module

## State and Configuration Files in `${TMP_DIR}/.tmp`

These files control logging behavior, maintain performance caches, and store persistent configuration across system sessions.

### Core Logging State Files

*   **`lo1_state`**:
    *   **Purpose**: Stores persistent state ("on" or "off") for the main logging system (`lo1`). Controls whether logging output is enabled or disabled across sessions.
    *   **Environment Variable**: Referenced as `LOG_STATE_FILE` in `cfg/core/ric`
    *   **Writing Functions**:
        *   `setlog on|off` in `lib/core/lo1`: User-controlled state toggling
        *   `init_state_files` in `lib/core/lo1`: Initialization with default "on"
    *   **Reading Functions**: 
        *   `log` function reads this file before each log operation
        *   `init_logger` reads on startup to restore previous state
    *   **Valid Values**: "on" (enable logging) | "off" (disable logging)
    *   **Default Behavior**: If missing or empty, defaults to "on"
    *   **Integration**: The `tme` module temporarily modifies this file during its own logging operations to prevent recursion
    *   **Details**: Central control point for all `lo1` logging output, respected by both file and terminal logging

### Performance and Cache Files

*   **`lo1_depth_cache`**:
    *   **Purpose**: Performance optimization cache for call stack depth calculations in the `lo1` module. Stores computed depths to avoid expensive recalculation.
    *   **Environment Variable**: Referenced as `LOG_DEPTH_CACHE_FILE`
    *   **Writing Functions**:
        *   `get_base_depth` in `lib/core/lo1`: Automatically caches calculated depths
        *   `cleanup_cache` in `lib/core/lo1`: Periodic cache clearing (every 300 seconds)
        *   `init_state_files` in `lib/core/lo1`: Creates empty cache file on initialization
    *   **Cache Strategy**: 
        *   Key: Function name, Value: Calculated call stack depth
        *   Automatic cleanup every 5 minutes to prevent stale data
        *   Cleared on logger cleanup
    *   **Performance Impact**: Significantly reduces CPU overhead for hierarchical logging in deep call stacks
    *   **Data Format**: Internal associative array structure (not human-readable)
    *   **Details**: Critical for maintaining logging performance in complex script execution scenarios

### Timing System Configuration Files

*   **`tme_state`**:
    *   **Purpose**: Controls whether the timing module generates terminal reports. Separate from timing log file generation.
    *   **Environment Variable**: Referenced as `TME_STATE_FILE` in `cfg/core/ric`
    *   **Writing Functions**:
        *   `tme_settme report on|off` in `lib/core/tme`: User-controlled report toggling
        *   Automatic initialization in `tme_init_timer`: Defaults to "true" if missing
    *   **Reading Functions**:
        *   `tme_print_timing_report` checks this file before generating terminal output
    *   **Valid Values**: "true" (enable reports) | "false" (disable reports)
    *   **Default Behavior**: If missing or empty, defaults to "true"
    *   **Details**: Controls terminal report generation while timing data continues to be logged to `tme.log`

*   **`tme_levels`**:
    *   **Purpose**: Determines the maximum depth of component hierarchy displayed in timing reports.
    *   **Environment Variable**: Referenced as `TME_LEVELS_FILE` in `cfg/core/ric`
    *   **Writing Functions**:
        *   `tme_settme depth N` in `lib/core/tme`: User-controlled depth setting (1-9)
        *   Automatic initialization in `tme_init_timer`: Defaults to "9" if missing
    *   **Reading Functions**:
        *   `tme_print_timing_report` uses this value to limit tree depth in reports
        *   `print_tree_recursive` respects this depth limit during output generation
    *   **Valid Values**: Integer 1-9 (depth levels)
    *   **Default Behavior**: If missing or empty, defaults to "9" (maximum depth)
    *   **Details**: Allows users to focus on high-level timing without overwhelming detail

*   **`tme_sort_order`**:
    *   **Purpose**: Determines the sort order for components in timing reports.
    *   **Environment Variable**: Referenced as `TME_SORT_ORDER_FILE_PATH` in `cfg/core/ric`
    *   **Writing Functions**:
        *   `tme_settme sort chron|duration` in `lib/core/tme`: User-controlled sort order
        *   Automatic initialization in `tme_init_timer`: Defaults to "chron" if missing
    *   **Reading Functions**:
        *   `tme_print_timing_report` determines display order based on this setting
        *   `sort_components_by_duration` function triggered when set to "duration"
    *   **Valid Values**: "chron" (chronological order) | "duration" (longest first)
    *   **Default Behavior**: If missing or empty, defaults to "chron"
    *   **Details**: "chron" shows execution order; "duration" highlights performance bottlenecks

### Missing State Files (Referenced but not currently present)

*   **`lo2_state`**: Would store the persistent state for the `lo2` control structure tracking system
    *   Expected environment variable: `LOG_CONTROL_STATE_FILE`
    *   Expected functions: `setlogcontrol on|off` in `lib/util/lo2`
    *   Status: Associated with the currently inactive `lo2` module

*   **`err_state`**: Error handling system state file
    *   Expected functions: Error tracking and reporting state management
    *   Status: Referenced in documentation but not actively used in current system

## Environment Variables and Configuration

### Directory Configuration (`cfg/core/ric`)

```bash
# Base directories (can be overridden)
LOG_DIR="${LOG_DIR:-${LAB_DIR}/.log}"     # Log file location
TMP_DIR="${TMP_DIR:-${LAB_DIR}/.tmp}"     # State file location

# Log file paths
ERROR_LOG="${LOG_DIR}/err.log"            # Error log
LOG_DEBUG_FILE="${LOG_DIR}/debug.log"     # Debug log  
LOG_FILE="${LOG_DIR}/lo1.log"             # Main lo1 log
TME_LOG_FILE="${LOG_DIR}/tme.log"         # Timing log

# State file paths
LOG_STATE_FILE="${TMP_DIR}/lo1_state"     # Lo1 on/off state
TME_STATE_FILE="${TMP_DIR}/tme_state"     # Timing report state
TME_LEVELS_FILE="${TMP_DIR}/tme_levels"   # Timing report depth
```

### Terminal Verbosity Controls (`cfg/core/ric`)

```bash
# Master control (default: "off")
MASTER_TERMINAL_VERBOSITY="off"

# Module-specific controls (default: "on", require master "on")
DEBUG_LOG_TERMINAL_VERBOSITY="on"        # Early debug messages
LO1_LOG_TERMINAL_VERBOSITY="on"          # Advanced logging
ERR_TERMINAL_VERBOSITY="on"              # Error messages  
TME_TERMINAL_VERBOSITY="on"              # Timing reports

# TME nested terminal output controls (default: "on", require both master and TME "on")
TME_REPORT_TERMINAL_OUTPUT="on"          # TME timing reports
TME_TIMING_TERMINAL_OUTPUT="on"          # TME timing measurements
TME_DEBUG_TERMINAL_OUTPUT="on"           # TME debug information
TME_STATUS_TERMINAL_OUTPUT="on"          # TME status updates
```

### Behavioral Controls

```bash
# Lo1 module debug message generation (default: 1)
LOG_DEBUG_ENABLED=1                       # 1=enable, 0=disable lo1 debug

# Error handling (defined in lib/core/err)
ERROR_COUNT_FILE="${TMP_DIR}/err_count"   # Error statistics
ERROR_STATE_FILE="${TMP_DIR}/err_state"   # Error system state
```

## Module Architecture and Function Reference

### Debug Logging Module (`bin/init`, `lib/core/ver`)

**Primary Functions:**
- `debug_log(message, [source], [level])`: Core debug logging
  - **Location**: `bin/init` (simple), `lib/core/ver` (enhanced)
  - **Output**: `debug.log` + conditional terminal
  - **Format**: `[DEBUG] YYYY-MM-DD HH:MM:SS - [source] message`

**Key Features:**
- Early initialization logging before full system loads
- Path and variable verification logging  
- Conditional terminal output based on verbosity controls

### Advanced Logging Module (`lib/core/lo1`)

**Primary Functions:**
- `log lvl "message"`: Main logging interface
- `lo1_log_message(message, [level], [component])`: Module logging interface
- `lo1_debug_log(message, [source])`: Internal debug logging
- `setlog on|off`: Runtime logging control
- `init_logger()`: System initialization

**Key Features:**
- 16-level color gradient for depth visualization
- Hierarchical indentation based on call stack analysis
- Performance-optimized depth caching
- Integration with timing system
- Persistent state management

**Call Stack Analysis:**
- `get_base_depth()`: Calculate call stack depth with caching
- `get_indent(depth)`: Generate indentation string
- `get_color(depth)`: Select color based on depth
- `is_root_function(name)`: Identify execution entry points

### Error Handling Module (`lib/core/err`)

**Primary Functions:**
- `handle_error(message, [component], [exit_code], [severity])`: Structured error logging
- `error_handler(line_number, [error_code], [should_exit])`: Automatic trap handler
- `print_error_report()`: Generate error summaries
- `setup_error_handling()`: Initialize error tracking

**Key Features:**
- Severity levels (ERROR, WARNING)
- Component tracking and timestamps
- Automatic error statistics
- Terminal and file output with verbosity controls

### Timing Module (`lib/core/tme`)

**Primary Functions:**
- `tme_init_timer([log_dir])`: Initialize timing system
- `tme_start_timer(component, [parent])`: Begin timing
- `tme_end_timer(component, [status])`: End timing with status
- `tme_print_timing_report()`: Generate performance report
- `tme_settme report|sort|depth value`: Configure timing behavior

**Nested Terminal Output Controls:**
- `tme_set_output <type> <on|off>`: Runtime control of specific output types
- `tme_show_output_settings`: Display current nested control settings
- **Output Types**: `report` (timing reports), `timing` (measurements), `debug` (warnings), `status` (configuration)

**Key Features:**
- Hierarchical component timing with parent/child relationships
- Configurable sort order (chronological or duration)
- Adjustable report depth (1-9 levels)
- Color-coded terminal reports with tree visualization
- Granular terminal output control with nested switches
- Integration with lo1 logging system

**Control Hierarchy:**
1. `MASTER_TERMINAL_VERBOSITY` - Master switch
2. `TME_TERMINAL_VERBOSITY` - Module switch  
3. `TME_*_TERMINAL_OUTPUT` - Specific output type switches

**Timer Management:**
- Supports nested timing relationships
- Automatic cleanup on interrupted components
- Performance statistics and summaries
- File and terminal output with separate controls

For detailed information about TME nested terminal output controls, see the **[Verbosity Controls Reference](verbosity.md)**.

## User Interface and Control Commands

### Runtime Logging Control

```bash
# Advanced logging (lo1) control
setlog on          # Enable lo1 logging output
setlog off         # Disable lo1 logging output

# Timing system control
tme_settme report on|off              # Enable/disable timing reports
tme_settme sort chron|duration        # Set report sort order
tme_settme depth 1-9                  # Set report depth level

# TME nested output control
tme_set_output <type> <on|off>        # Control specific TME output types
tme_show_output_settings              # Display current TME output settings
```

### Environment Variable Overrides

```bash
# Override default directories
export LOG_DIR="/custom/log/path"
export TMP_DIR="/custom/tmp/path"

# Control debug message generation
export LOG_DEBUG_ENABLED=0            # Disable lo1 debug messages

# Override verbosity (requires master=on for effect)
export MASTER_TERMINAL_VERBOSITY="on"
export LO1_LOG_TERMINAL_VERBOSITY="off"

# TME nested control examples
export TME_TERMINAL_VERBOSITY="on"           # Enable TME module
export TME_REPORT_TERMINAL_OUTPUT="on"       # Enable timing reports
export TME_TIMING_TERMINAL_OUTPUT="off"      # Disable timing measurements
export TME_DEBUG_TERMINAL_OUTPUT="on"        # Enable debug output
export TME_STATUS_TERMINAL_OUTPUT="off"      # Disable status messages
```

## Troubleshooting and Diagnostics

### Common Issues and Solutions

**Issue**: No terminal output despite logging being "on"
- **Cause**: `MASTER_TERMINAL_VERBOSITY="off"` (default)
- **Solution**: `export MASTER_TERMINAL_VERBOSITY="on"`

**Issue**: Logging performance degradation in deep call stacks
- **Cause**: Depth cache not functioning or too frequent cleanup
- **Diagnostics**: Check `lo1_depth_cache` file and `[LO1-DEBUG]` messages
- **Solution**: Verify `TMP_DIR` writable, check cache cleanup interval

**Issue**: Timing reports not appearing
- **Cause**: `TME_STATE_FILE` set to "false" or verbosity disabled
- **Diagnostics**: Check file content and verbosity settings
- **Solution**: `tme_settme report on` and verify `TME_TERMINAL_VERBOSITY="on"`

**Issue**: Some TME outputs missing despite TME verbosity enabled
- **Cause**: Nested TME terminal output controls disabled
- **Diagnostics**: Check specific `TME_*_TERMINAL_OUTPUT` variables
- **Solution**: Use `tme_set_output <type> on` or `tme_show_output_settings` to verify configuration

**Issue**: TME nested controls not working
- **Cause**: Missing hierarchy requirements (master or module verbosity disabled)
- **Diagnostics**: Verify `MASTER_TERMINAL_VERBOSITY="on"` and `TME_TERMINAL_VERBOSITY="on"`
- **Solution**: Enable both master and module verbosity before using nested controls

**Issue**: Missing log files
- **Cause**: Directory creation failure or permission issues  
- **Diagnostics**: Check `LOG_DIR` and `TMP_DIR` existence and permissions
- **Solution**: Verify directory paths and create manually if needed

### Log File Analysis Workflow

1. **Check `init_flow.log`** for initialization sequence and timing
2. **Review `debug.log`** for early system issues and verification failures
3. **Examine `err.log`** for errors and warnings with component context
4. **Analyze `lo1.log`** for detailed application flow with hierarchical context
5. **Study `tme.log`** for performance bottlenecks and timing analysis

### Verbosity Configuration Matrix

| Scenario | Master | Debug | Lo1 | Err | Tme | TME Nested | Result |
|----------|--------|-------|-----|-----|-----|------------|---------|
| Silent   | off    | *     | *   | *   | *   | *          | File logging only |
| Selective| on     | off   | on  | on  | off | *          | Lo1 + errors only |
| Debug    | on     | on    | on  | on  | on  | all on     | Full output |
| Production| on    | off   | off | on  | off | *          | Errors only |
| TME Only | on     | off   | off | off | on  | selective  | TME outputs only |
| TME Reports| on   | off   | off | off | on  | report=on, others=off | TME reports only |

**TME Nested Controls Examples:**
- `report=off, timing=on, debug=on, status=off`: Show measurements and debug, no reports or status
- `report=on, timing=off, debug=off, status=off`: Show only timing reports, no other TME output
- All nested controls require both `MASTER_TERMINAL_VERBOSITY="on"` and `TME_TERMINAL_VERBOSITY="on"`

## Integration with External Systems

### TME Module Nested Terminal Output Controls

The TME module implements a sophisticated nested terminal output control system that provides granular control over different types of timing-related terminal output while maintaining the hierarchical verbosity requirements.

#### Control Variables

The following nested controls are available for the TME module:

- **`TME_REPORT_TERMINAL_OUTPUT`**: Controls timing reports generated by `tme_print_timing_report`
- **`TME_TIMING_TERMINAL_OUTPUT`**: Controls timing measurements and duration data output
- **`TME_DEBUG_TERMINAL_OUTPUT`**: Controls TME debug information and warning messages
- **`TME_STATUS_TERMINAL_OUTPUT`**: Controls TME status updates and configuration messages

#### Control Hierarchy

The nested controls implement a three-tier hierarchy:

1. **`MASTER_TERMINAL_VERBOSITY`** - Must be "on" (master switch)
2. **`TME_TERMINAL_VERBOSITY`** - Must be "on" (module switch)  
3. **`TME_*_TERMINAL_OUTPUT`** - Individual output type switches

All three levels must be "on" for specific TME output to appear in the terminal.

#### Runtime Control Functions

- **`tme_set_output <type> <on|off>`**: Dynamic control of output types
  - Types: `report`, `timing`, `debug`, `status`
  - Example: `tme_set_output debug off`
- **`tme_show_output_settings`**: Display current configuration
  - Shows all verbosity levels and nested control settings

#### Use Cases

**Development Mode**: Enable all outputs for comprehensive debugging
```bash
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
# All nested controls default to "on"
```

**Production Mode**: Show only essential timing reports
```bash
tme_set_output debug off    # Disable debug messages
tme_set_output timing off   # Disable detailed measurements
tme_set_output status off   # Disable status updates
# Keep report output enabled for performance monitoring
```

**Silent Timing**: Collect timing data without terminal output
```bash
export TME_TERMINAL_VERBOSITY="off"
# All nested controls become inactive, but file logging continues
```

### Log Rotation and Archival

The system creates new log files on each initialization by clearing existing files. For production use, consider:

```bash
# Backup logs before initialization
cp ${LOG_DIR}/*.log ${LOG_DIR}/archive/$(date +%Y%m%d_%H%M%S)/

# Or implement log rotation
logrotate /etc/logrotate.d/lab-system
```

### Monitoring Integration

Key files for monitoring systems:
- `${LOG_DIR}/err.log`: Error detection and alerting
- `${TMP_DIR}/err_state`: Error system health
- `${LOG_DIR}/tme.log`: Performance trending
- `${TMP_DIR}/*_state`: System component status

### Development Workflow

For debugging and development:
1. Enable full verbosity: `export MASTER_TERMINAL_VERBOSITY="on"`
2. Enable lo1 debugging: `export LOG_DEBUG_ENABLED=1`
3. Monitor real-time: `tail -f ${LOG_DIR}/*.log`
4. Analyze timing: `tme_settme sort duration && tme_settme depth 3`

For TME-specific debugging:
1. Enable TME verbosity: `export TME_TERMINAL_VERBOSITY="on"`
2. Enable selective output: `tme_set_output debug on && tme_set_output status on`
3. Monitor timing patterns: `tme_set_output timing on && tme_set_output report on`
4. Check configuration: `tme_show_output_settings`

For production monitoring:
1. Silent mode: `export MASTER_TERMINAL_VERBOSITY="off"`
2. Essential TME only: `tme_set_output report on && tme_set_output timing off`
3. Error tracking: Keep `ERR_TERMINAL_VERBOSITY="on"` with master enabled

## Summary of Key Logging Modules and Functions

*   **`bin/init` & `lib/core/ver` (`debug_log`)**:
    *   Writes to: `.log/debug.log`
    *   Purpose: Low-level debug messages, especially during initial system verification and for modules without dedicated debug logs.
*   **`lib/core/lo1` (Advanced Logging Module)**:
    *   `log`, `log_message`, `log_with_timer`, `lo1_debug_log`: Write to `.log/lo1.log` (main application and `lo1` module-specific debug log).
    *   Manages `.tmp/lo1_depth_cache` (performance cache) and `.tmp/log_state` (logging on/off).
*   **`lib/util/lo2` (Runtime Control Structure Tracking)**:
    *   `lo2_debug_log`: Writes to `.log/lo2.log`.
*   **`lib/core/tme` (Timing and Performance Module)**:
    *   `tme_start_timer`, `tme_end_timer`, `tme_print_timing_report`: Write to `.log/tme.log` (timing details).
    *   Manages `.tmp/tme_levels` (report depth) and `.tmp/tme_state` (report on/off).
*   **Error Handling (e.g., `lib/core/err`)**:
    *   Writes to: `.log/err.log` (via `ERROR_LOG` variable).
    *   Purpose: Centralized error reporting.
