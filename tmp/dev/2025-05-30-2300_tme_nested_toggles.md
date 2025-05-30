# TME Module Nested Terminal Output Controls Implementation

## Overview

The TME (Timing and Performance Monitoring) module now supports nested terminal output controls that provide granular control over different types of terminal output while maintaining the hierarchical verbosity system.

## Implementation Details

### New Environment Variables

The following nested terminal output controls have been added to the RIC configuration:

- `TME_REPORT_TERMINAL_OUTPUT` - Controls timing reports
- `TME_TIMING_TERMINAL_OUTPUT` - Controls timing measurements  
- `TME_DEBUG_TERMINAL_OUTPUT` - Controls debug information
- `TME_STATUS_TERMINAL_OUTPUT` - Controls status updates

### Control Hierarchy

The nested controls follow this hierarchy:

1. **MASTER_TERMINAL_VERBOSITY** (master switch)
2. **TME_TERMINAL_VERBOSITY** (module switch)
3. **TME_*_TERMINAL_OUTPUT** (specific output type switches)

All three levels must be "on" for specific TME output to appear in the terminal.

### Implementation Changes

#### RIC Configuration (cfg/core/ric)
```bash
# Controls terminal verbosity for the tme timing module
declare -g TME_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY

  # TME Module Nested Terminal Output Controls
  # Individual switches for specific TME module outputs
  # All require both MASTER_TERMINAL_VERBOSITY and TME_TERMINAL_VERBOSITY to be "on"
  
  # Controls terminal output for TME timing reports
  declare -g TME_REPORT_TERMINAL_OUTPUT="on"
  export TME_REPORT_TERMINAL_OUTPUT
  
  # Controls terminal output for TME timing measurements
  declare -g TME_TIMING_TERMINAL_OUTPUT="on"
  export TME_TIMING_TERMINAL_OUTPUT
  
  # Controls terminal output for TME debug information
  declare -g TME_DEBUG_TERMINAL_OUTPUT="on"
  export TME_DEBUG_TERMINAL_OUTPUT
  
  # Controls terminal output for TME status updates
  declare -g TME_STATUS_TERMINAL_OUTPUT="on"
  export TME_STATUS_TERMINAL_OUTPUT
```

#### TME Module Updates (lib/core/tme)

1. **Debug/Warning Messages**: Updated to check `TME_DEBUG_TERMINAL_OUTPUT`
2. **Status Messages**: Updated to check `TME_STATUS_TERMINAL_OUTPUT`
3. **Timing Reports**: Updated to check `TME_REPORT_TERMINAL_OUTPUT`
4. **New Functions**: Added `tme_set_output()` and `tme_show_output_settings()`

### New Functions

#### `tme_set_output <output_type> <on|off>`
Controls specific TME terminal output types.

**Output types:**
- `report` - Timing reports
- `timing` - Timing measurements
- `debug` - Debug information
- `status` - Status updates

**Example:**
```bash
tme_set_output report off    # Disable timing reports
tme_set_output debug off     # Disable debug messages
```

#### `tme_show_output_settings`
Displays current TME terminal output settings in a hierarchical format.

**Example output:**
```
TME Terminal Output Settings:
  Master Terminal Verbosity: on
  TME Terminal Verbosity: on
  ├─ Report Output: on
  ├─ Timing Output: on
  ├─ Debug Output: on
  └─ Status Output: on
```

### Usage Examples

#### Basic Control
```bash
# Disable all TME terminal output
export TME_TERMINAL_VERBOSITY="off"

# Disable only timing reports
tme_set_output report off

# Disable debug messages during initialization
export TME_DEBUG_TERMINAL_OUTPUT="off"
```

#### Environment Variable Control
```bash
# Set before initialization
export TME_REPORT_TERMINAL_OUTPUT="off"
export TME_DEBUG_TERMINAL_OUTPUT="off"
source ./bin/init
```

#### Runtime Control
```bash
# After initialization
tme_set_output status off     # Disable status messages
tme_set_output report on      # Enable reports
tme_show_output_settings      # Show current settings
```

### Control Matrix

| Master | TME | Report | Debug | Status | Result |
|--------|-----|--------|-------|--------|---------|
| off    | *   | *      | *     | *      | No TME terminal output |
| on     | off | *      | *     | *      | No TME terminal output |
| on     | on  | off    | *     | *      | No timing reports |
| on     | on  | on     | off   | *      | Reports only, no debug |
| on     | on  | on     | on    | off    | Reports + debug, no status |
| on     | on  | on     | on    | on     | All TME terminal output |

### Testing

Use the provided test script to verify functionality:
```bash
./test_verbosity_controls.sh
```

### Benefits

1. **Granular Control**: Individual control over different types of TME output
2. **Hierarchical Design**: Maintains the existing master/module structure
3. **Backward Compatibility**: Existing TME_TERMINAL_VERBOSITY still works
4. **Production Ready**: Allows selective output in production environments
5. **Debug Flexibility**: Can disable noisy debug output while keeping reports

### File Modifications Summary

- **cfg/core/ric**: Added 4 new nested terminal output variables
- **lib/core/tme**: Updated all terminal output checks to use nested controls
- **lib/core/tme**: Added 2 new control functions
- **test_verbosity_controls.sh**: Created comprehensive test script
