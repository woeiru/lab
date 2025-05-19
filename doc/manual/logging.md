# Log File Analysis

This document provides an analysis of the log files found in the `.log` directory and related state files in the `.tmp` directory.

## Log Files in `/home/es/lab/.log`

*   **`debug.log`**:
    *   **Purpose**: Records detailed debugging information during script execution. It's used by the `debug_log` function, which is present in both `/home/es/lab/bin/init` (a simpler version for early initialization) and `/home/es/lab/lib/core/ver` (a more robust version).
    *   **Writing Functions**:
        *   `debug_log` (in `bin/init` and `lib/core/ver`)
    *   **Details**: This log captures timestamps, source functions, and messages. The `verify_path` and `verify_var` functions in `lib/core/ver` extensively use `debug_log` to record their actions. It should primarily contain messages from the core system and modules that do not have their own dedicated debug logs.

*   **`err.log`**:
    *   **Purpose**: Stores error messages encountered during script execution. It's the primary destination for error output.
    *   **Writing Functions**: Primarily written to by functions that use the `ERROR_LOG` variable, which is defined in `cfg/core/ric` and points to this file. The `handle_error` function (likely in a module like `lib/core/err`) and `error_handler` would write to this.
    *   **Details**: This file aggregates critical errors and warnings.

*   **`lo1.log`**:
    *   **Purpose**: This is the main application log file managed by the `lo1` logging module (`lib/core/lo1`). It captures formatted log messages with timestamps, color-coding (for console output, which is also mirrored here), and indentation based on call stack depth. It also now contains debug messages specific to the `lo1` module.
    *   **Writing Functions**:
        *   `log` (in `lib/core/lo1`): The core logging function in `lo1`.
        *   `log_message` (in `lib/core/lo1`): A standardized logging function for modules.
        *   `log_with_timer` (in `lib/core/lo1`): Logs messages with timing information if the `tme` module is available.
        *   `init_logger` (in `lib/core/lo1`): Writes an initialization message to this log.
        *   `lo1_debug_log` (in `lib/core/lo1`): Writes `[LO1-DEBUG]` prefixed messages to this log.
    *   **Details**: Provides a structured and hierarchical view of the `lo1` module's operations and general application messages.

*   **`lo2.log`**:
    *   **Purpose**: Records debug messages specifically from the `lo2` module (`lib/util/lo2`), which handles runtime control structure tracking.
    *   **Writing Functions**:
        *   `lo2_debug_log` (in `lib/util/lo2`)
    *   **Details**: Contains `[LO2-DEBUG]` prefixed messages related to control flow depth calculation.

*   **`tme.log`**:
    *   **Purpose**: Records timing information for different components and functions, managed by the `tme` module (`lib/core/tme`). It logs start times, end times, durations, and statuses of timed operations.
    *   **Writing Functions**:
        *   `init_timer` (in `lib/core/tme`): Writes an initial header and startup time.
        *   `start_timer` (in `lib/core/tme`): Logs the start of a timed component.
        *   `end_timer` (in `lib/core/tme`): Logs the end and duration of a timed component.
        *   `print_timing_report` (in `lib/core/tme`): Appends a formatted performance report to this log.
        *   `cleanup_timer` (in `lib/core/tme`): Logs cleanup information and total execution time.
    *   **Details**: Essential for performance analysis and understanding execution flow timing.

*   **`init_flow.log`**:
    *   **Purpose**: Tracks the execution flow of the main initialization script (`bin/init`). It records key milestones and timestamps during the module loading process, especially for debugging startup issues or verifying the order and timing of module sourcing.
    *   **Writing Functions**: Direct `echo` statements in `bin/init` (e.g., `echo "INIT_SCRIPT_FLOW: ..."`).
    *   **Details**: Useful for correlating with other logs (such as `lo2_entry_trace.log` and `lo2.log`) to diagnose initialization problems or unexpected script exits.

*   **`lo2_entry_trace.log`**:
    *   **Purpose**: Records the exact moment the `lo2` module (`lib/util/lo2`) is sourced and begins execution. Each entry includes a timestamp, providing a trace of when the control structure tracking module is entered.
    *   **Writing Functions**: The very first line of `lib/util/lo2` appends a message to this file (e.g., `echo "LO2_TRACE: lo2 script execution started - $(date '+%T.%N')" >> ...`).
    *   **Details**: Used for low-level diagnostics to confirm that the `lo2` module is being sourced as expected during initialization.

## State/Temporary Files in `/home/es/lab/.tmp`

These are not traditional log files but rather state files used by the logging and timing systems.

*   **`log_state`**:
    *   **Purpose**: This file is referenced by the `LOG_STATE_FILE` variable (defined in `cfg/core/ric`). It controls the overall logging state (on/off) for the `lo1` module.
    *   **Writing Functions**:
        *   `init_state_files` (in `lib/core/lo1`): Initializes this file (e.g., to "true").
        *   `setlog` (in `lib/core/lo1`): Toggles the content to "true" or "false" to enable/disable logging.
        *   The `tme` module (`start_timer`, `end_timer`, `print_timing_report`, `cleanup_timer`) temporarily sets this to "false" to prevent its own internal logging messages from being processed by `lo1` during sensitive operations, then restores the original state.
    *   **Details**: Acts as a toggle for the `lo1` logging output.

*   **`lo1_depth_cache`** (was `lo1_depth_cache.log`):
    *   **Purpose**: Used by the `lo1` module (`lib/core/lo1`) to cache calculated log depths. This is a performance optimization to avoid recalculating call stack depths repeatedly.
    *   **Writing Functions**:
        *   `cleanup_cache` (in `lib/core/lo1`): Clears this cache file periodically.
        *   `init_state_files` (in `lib/core/lo1`): Touches/creates this file on logger initialization.
    *   **Details**: This is more of a state/cache file than a traditional human-readable log. It's managed internally by `lo1`. Its location is now `${TMP_DIR}/lo1_depth_cache`.

*   **`tme_levels`**:
    *   **Purpose**: Controlled by the `TME_LEVELS_FILE` variable (defined in `cfg/core/ric`). It's used by the `tme` module to determine the maximum depth of the component timing tree to display in the `print_timing_report`.
    *   **Writing Functions**:
        *   `settme` (in `lib/core/tme`): Allows the user to set the desired depth level (1-9) or turn timing on/off.
    *   **Details**: Controls the depth of the timing report output.

*   **`tme_state`**:
    *   **Purpose**: Controlled by the `TME_STATE_FILE` variable (defined in `cfg/core/ric`). This file determines if the `tme` module's timing report output is enabled or disabled.
    *   **Writing Functions**:
        *   `settme` (in `lib/core/tme`): Sets this to "true" or "false" to enable/disable the timing report.
    *   **Details**: A flag file to control the output of `print_timing_report`.

*   **`lo1_state`**:
    *   **Purpose**: Stores the persistent state ("on" or "off") of the main logging system (`lo1`). Controls whether logging output is enabled or disabled across sessions.
    *   **Writing Functions**: `setlog` and `init_state_files` in `lib/core/lo1` write to this file. The logger reads this file on initialization to restore the previous state.
    *   **Details**: If missing or empty, logging defaults to "on". The file is referenced as `LOG_STATE_FILE` in the environment.

*   **`lo2_state`**:
    *   **Purpose**: Stores the persistent state ("on" or "off") of the control structure tracking system (`lo2`). Controls whether runtime tracking of shell control structures is enabled.
    *   **Writing Functions**: `setlogcontrol` and initialization logic in `lib/util/lo2` write to this file. The module reads this file on initialization to restore the previous state.
    *   **Details**: If missing or empty, tracking defaults to "on". The file is referenced as `LOG_CONTROL_STATE_FILE` in the environment.

*   **`tme_sort_order`**:
    *   **Purpose**: Determines the sort order for the timing report generated by the `tme` module. The file contains either `chron` (chronological order) or `dura` (duration, descending).
    *   **Writing Functions**: The `settme sort` command in `lib/core/tme` writes to this file. The `print_timing_report` function reads this file to determine how to order components in the report.
    *   **Details**: Defaults to `chron` if missing or empty. The file is referenced as `TME_SORT_ORDER_FILE_PATH` in the environment.

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
    *   `start_timer`, `end_timer`, `print_timing_report`: Write to `.log/tme.log` (timing details).
    *   Manages `.tmp/tme_levels` (report depth) and `.tmp/tme_state` (report on/off).
*   **Error Handling (e.g., `lib/core/err`)**:
    *   Writes to: `.log/err.log` (via `ERROR_LOG` variable).
    *   Purpose: Centralized error reporting.
