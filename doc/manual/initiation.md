# User Interaction and Configuration Guide

This document outlines the various ways users can interact with and configure the behavior of this shell script system. These interactions primarily involve setting environment variables before script execution or calling specific functions provided by the system's modules once the environment is initialized.

## 1. Global Configuration via Environment Variables

These variables are typically set in your shell environment *before* executing the main initialization script (e.g., `bin/init`).

### `LOG_DEBUG_ENABLED` (for `lo1` module)
*   **Purpose**: Specifically enables or disables the `lo1_debug_log` messages from the advanced logging module `lo1`.
*   **Module Affected**: `lib/util/lo1`
*   **Usage**:
    *   `1`: Enable `lo1` debug messages (this is the default set within `lo1.sh`).
    *   `0`: Disable `lo1` debug messages.
*   **Example**:
    ```bash
    export LOG_DEBUG_ENABLED=0
    # Subsequent operations will have lo1_debug_log disabled
    ```

### Directory Path Overrides (`LOG_DIR`, `TMP_DIR`, etc.)
*   **Purpose**: Allows customization of base directories for logs, temporary files, and potentially other system artifacts. These are defined in `cfg/core/ric`.
*   **Modules Affected**: Potentially all modules that use these common paths (`err`, `lo1`, `lo2`, `tme`).
*   **Usage**: Set the desired environment variable to an absolute path.
*   **Example**:
    ```bash
    export LOG_DIR="/mnt/custom_storage/system_logs"
    export TMP_DIR="/fast_ssd/temp_files"
    ./bin/init
    ```

## 2. Runtime Control via Shell Functions

These functions are available after the system's modules have been sourced, typically after `bin/init` has completed or if individual modules are sourced in an interactive session.

### Error Handling (`lib/util/err`)

*   **`enable_error_trap()`**
    *   **Purpose**: Activates the shell's `ERR` trap. When enabled, the script will typically exit immediately if a command fails.
    *   **Usage**: `enable_error_trap`

*   **`disable_error_trap()`**
    *   **Purpose**: Deactivates the `ERR` trap.
    *   **Usage**: `disable_error_trap`

*   **Note**: The global variable `ERROR_TRAP_ENABLED` (set to `1` or `0`) also reflects and can control this state.

### Advanced Logging (`lib/util/lo1`)

*   **`setlog on|off`**
    *   **Purpose**: Enables or disables the console and file logging output of the `lo1` logging system.
    *   **Verification**: This function is defined in `lib/util/lo1` and works by writing "on" or "off" to the state file read by the main logging function.
    *   **Usage**:
        ```bash
        setlog on  # Enable lo1 console and file output
        setlog off # Disable lo1 console and file output
        ```

### Timing and Performance Monitoring (`lib/util/tme`)

*   **`settme [options]`**
    *   **Purpose**: The module comments in `lib/util/tme` suggest this function is intended to allow users to "control aspects of the timer's behavior or output."
    *   **Verification**: This function is **not currently implemented** in the provided `lib/util/tme` script, though its purpose is documented in the comments.
    *   **Usage**: `settme [specific_option_here]` (if implemented)

*   **`print_timing_report`**
    *   **Purpose**: Displays a formatted report of all timed events, including durations and statuses.
    *   **Usage**: `print_timing_report`

*   **Timing Report Sort Order (via `TME_SORT_ORDER_FILE_PATH`)**
    *   **Purpose**: The `tme` module uses a variable `TME_SORT_ORDER_FILE_PATH` which points to a configuration file. Users can potentially create and edit this file to define a custom sort order for the output of `print_timing_report`.
    *   **Usage**: The exact format and content of this file are not specified in the provided snippets and would be specific to the `tme` module's implementation. You would need to consult further documentation or the `tme` script's source for details on how to structure this file.

## General Usage Notes

*   To use the functions described above (e.g., `setlog`, `enable_error_trap`), the corresponding modules must have been loaded into your current shell environment. This is typically handled by the main `bin/init` script.
*   Environment variables should be set *before* the `init` script or relevant modules are loaded to ensure they take effect.
*   The availability and exact behavior of functions like `setlog` and `setlogcontrol` have been verified against their source code.
*   The function `settme` is mentioned in comments within `lib/util/tme` but is not implemented in the provided version of the script. Refer to the specific module source code for the most accurate implementation details.
