# Log File Analysis

This document provides an analysis of the log files found in the `.log` directory and related state files in the `.tmp` directory.

## Log Files in `/home/es/lab/.log`

*   **`debug.log`**:
    *   **Purpose**: Records detailed debugging information during script execution. It's used by the `debug_log` function, which is present in both `/home/es/lab/bin/init` (a simpler version for early initialization) and `/home/es/lab/lib/core/ver` (a more robust version).
    *   **Writing Functions**:
        *   `debug_log` (in `bin/init` and `lib/core/ver`)
    *   **Details**: This log captures timestamps, source functions, and messages. Its verbosity is controlled by the `DEBUG_VERBOSITY` environment variable. The `verify_path` and `verify_var` functions in `lib/core/ver` extensively use `debug_log` to record their actions. It should primarily contain messages from the core system and modules that do not have their own dedicated debug logs.

*   **`err.log`**:
    *   **Purpose**: Stores error messages encountered during script execution. It's the primary destination for error output.
    *   **Writing Functions**: Primarily written to by functions that use the `ERROR_LOG` variable, which is defined in `cfg/core/ric` and points to this file. The `handle_error` function (likely in a module like `lib/util/err`) and `error_handler` would write to this.
    *   **Details**: This file aggregates critical errors and warnings.

*   **`lo1.log`**:
    *   **Purpose**: This is the main application log file managed by the `lo1` logging module (`lib/util/lo1`). It captures formatted log messages with timestamps, color-coding (for console output, which is also mirrored here), and indentation based on call stack depth. It also now contains debug messages specific to the `lo1` module.
    *   **Writing Functions**:
        *   `log` (in `lib/util/lo1`): The core logging function in `lo1`.
        *   `log_message` (in `lib/util/lo1`): A standardized logging function for modules.
        *   `log_with_timer` (in `lib/util/lo1`): Logs messages with timing information if the `tme` module is available.
        *   `init_logger` (in `lib/util/lo1`): Writes an initialization message to this log.
        *   `lo1_debug_log` (in `lib/util/lo1`): Writes `[LO1-DEBUG]` prefixed messages to this log.
    *   **Details**: Provides a structured and hierarchical view of the `lo1` module's operations and general application messages.

*   **`lo2.log`**:
    *   **Purpose**: Records debug messages specifically from the `lo2` module (`lib/util/lo2`), which handles runtime control structure tracking.
    *   **Writing Functions**:
        *   `lo2_debug_log` (in `lib/util/lo2`)
    *   **Details**: Contains `[LO2-DEBUG]` prefixed messages related to control flow depth calculation.

*   **`tme.log`**:
    *   **Purpose**: Records timing information for different components and functions, managed by the `tme` module (`lib/util/tme`). It logs start times, end times, durations, and statuses of timed operations.
    *   **Writing Functions**:
        *   `init_timer` (in `lib/util/tme`): Writes an initial header and startup time.
        *   `start_timer` (in `lib/util/tme`): Logs the start of a timed component.
        *   `end_timer` (in `lib/util/tme`): Logs the end and duration of a timed component.
        *   `print_timing_report` (in `lib/util/tme`): Appends a formatted performance report to this log.
        *   `cleanup_timer` (in `lib/util/tme`): Logs cleanup information and total execution time.
    *   **Details**: Essential for performance analysis and understanding execution flow timing.

## State/Temporary Files in `/home/es/lab/.tmp`

These are not traditional log files but rather state files used by the logging and timing systems.

*   **`log_state`**:
    *   **Purpose**: This file is referenced by the `LOG_STATE_FILE` variable (defined in `cfg/core/ric`). It controls the overall logging state (on/off) for the `lo1` module.
    *   **Writing Functions**:
        *   `init_state_files` (in `lib/util/lo1`): Initializes this file (e.g., to "true").
        *   `setlog` (in `lib/util/lo1`): Toggles the content to "true" or "false" to enable/disable logging.
        *   The `tme` module (`start_timer`, `end_timer`, `print_timing_report`, `cleanup_timer`) temporarily sets this to "false" to prevent its own internal logging messages from being processed by `lo1` during sensitive operations, then restores the original state.
    *   **Details**: Acts as a toggle for the `lo1` logging output.

*   **`lo1_depth_cache.log`**:
    *   **Purpose**: Used by the `lo1` module (`lib/util/lo1`) to cache calculated log depths. This is a performance optimization to avoid recalculating call stack depths repeatedly.
    *   **Writing Functions**:
        *   `cleanup_cache` (in `lib/util/lo1`): Clears this cache file periodically.
        *   `init_state_files` (in `lib/util/lo1`): Touches/creates this file on logger initialization.
    *   **Details**: This is more of a state/cache file than a traditional human-readable log. It's managed internally by `lo1`. Its location is now `${TMP_DIR}/lo1_depth_cache.log`.

*   **`tme_levels`**:
    *   **Purpose**: Controlled by the `TME_LEVELS_FILE` variable (defined in `cfg/core/ric`). It's used by the `tme` module to determine the maximum depth of the component timing tree to display in the `print_timing_report`.
    *   **Writing Functions**:
        *   `settme` (in `lib/util/tme`): Allows the user to set the desired depth level (1-9) or turn timing on/off.
    *   **Details**: Affects the verbosity of the timing report.

*   **`tme_state`**:
    *   **Purpose**: Controlled by the `TME_STATE_FILE` variable (defined in `cfg/core/ric`). This file determines if the `tme` module's timing report output is enabled or disabled.
    *   **Writing Functions**:
        *   `settme` (in `lib/util/tme`): Sets this to "true" or "false" to enable/disable the timing report.
    *   **Details**: A flag file to control the output of `print_timing_report`.

## Summary of Key Logging Modules and Functions

*   **`bin/init` & `lib/core/ver` (`debug_log`)**:
    *   Writes to: `.log/debug.log`
    *   Purpose: Low-level debug messages, especially during initial system verification and for modules without dedicated debug logs.
*   **`lib/util/lo1` (Advanced Logging Module)**:
    *   `log`, `log_message`, `log_with_timer`, `lo1_debug_log`: Write to `.log/lo1.log` (main application and `lo1` module-specific debug log).
    *   Manages `.tmp/lo1_depth_cache.log` (performance cache) and `.tmp/log_state` (logging on/off).
*   **`lib/util/lo2` (Runtime Control Structure Tracking)**:
    *   `lo2_debug_log`: Writes to `.log/lo2.log`.
*   **`lib/util/tme` (Timing and Performance Module)**:
    *   `start_timer`, `end_timer`, `print_timing_report`: Write to `.log/tme.log` (timing details).
    *   Manages `.tmp/tme_levels` (report depth) and `.tmp/tme_state` (report on/off).
*   **Error Handling (e.g., `lib/util/err`)**:
    *   Writes to: `.log/err.log` (via `ERROR_LOG` variable).
    *   Purpose: Centralized error reporting.
