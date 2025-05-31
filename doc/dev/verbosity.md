# System Verbosity Controls - Technical Implementation

Technical documentation for developers implementing and extending the system's verbosity control mechanisms, including the TME (Timing and Performance Monitoring) module's nested terminal output control system architecture.

## 🎯 Developer Overview

This document covers the **technical implementation details** of the verbosity control system. For user-facing configuration and usage instructions, see the [User Verbosity Controls Guide](../user/verbosity-controls.md).

The TME module implements a sophisticated three-tier hierarchical verbosity control system that provides granular management of terminal output while maintaining backward compatibility with existing logging architecture.

### Technical Architecture

- **Modular Design**: Separation of concerns between control levels and output types
- **Hierarchical Implementation**: Three-tier control system with logical AND operation
- **Runtime API**: Function-based interface for dynamic configuration
- **Integration Points**: Seamless integration with existing TME timing functions
- **Performance Optimized**: Minimal overhead when output is disabled

## Control Hierarchy

The nested controls implement a three-tier hierarchy where all levels must be enabled for output to appear:

```
┌─────────────────────────────┐
│ MASTER_TERMINAL_VERBOSITY   │ ← Tier 1: Master Control
│         (on/off)            │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│ TME_TERMINAL_VERBOSITY      │ ← Tier 2: Module Control  
│         (on/off)            │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│ TME_*_TERMINAL_OUTPUT       │ ← Tier 3: Output Type Control
│ - TME_REPORT_TERMINAL_OUTPUT│    (on/off for each type)
│ - TME_TIMING_TERMINAL_OUTPUT│
│ - TME_DEBUG_TERMINAL_OUTPUT │
│ - TME_STATUS_TERMINAL_OUTPUT│
└─────────────────────────────┘
```

### Control Logic

For any TME output to appear in the terminal, the following condition must be met:

```bash
MASTER_TERMINAL_VERBOSITY="on" AND 
TME_TERMINAL_VERBOSITY="on" AND 
TME_[SPECIFIC]_TERMINAL_OUTPUT="on"
```

## 🔧 Implementation Architecture

### Control Hierarchy Design

The nested controls implement a three-tier hierarchy with logical AND operation:

```
┌─────────────────────────────┐
│ MASTER_TERMINAL_VERBOSITY   │ ← Tier 1: Master Control
│         (on/off)            │   Global system control
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│ TME_TERMINAL_VERBOSITY      │ ← Tier 2: Module Control  
│         (on/off)            │   TME module enable/disable
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│ TME_*_TERMINAL_OUTPUT       │ ← Tier 3: Output Type Control
│ - TME_REPORT_TERMINAL_OUTPUT│   Individual output categories
│ - TME_TIMING_TERMINAL_OUTPUT│
│ - TME_DEBUG_TERMINAL_OUTPUT │
│ - TME_STATUS_TERMINAL_OUTPUT│
└─────────────────────────────┘
```

### Control Logic Implementation

```bash
# Logical AND operation for output control
show_output() {
    [[ "${MASTER_TERMINAL_VERBOSITY:-off}" == "on" ]] && \
    [[ "${TME_TERMINAL_VERBOSITY:-off}" == "on" ]] && \
    [[ "${TME_${TYPE}_TERMINAL_OUTPUT:-off}" == "on" ]]
}
```

## 📊 Output Categories - Technical Specifications

### TME_REPORT_TERMINAL_OUTPUT
- **Function Integration**: `tme_print_timing_report`
- **Implementation**: Hierarchical timing summaries with depth control
- **Performance Impact**: High (report generation)
- **Use Cases**: Performance analysis, bottleneck identification, system optimization

### TME_TIMING_TERMINAL_OUTPUT  
- **Function Integration**: `tme_start_timer`, `tme_end_timer`
- **Implementation**: Real-time timing measurements and duration calculations
- **Performance Impact**: Low (minimal overhead)
- **Use Cases**: Real-time monitoring, detailed timing analysis, development debugging

### TME_DEBUG_TERMINAL_OUTPUT
- **Function Integration**: Debug warnings throughout TME module
- **Implementation**: Initialization warnings, configuration validation
- **Performance Impact**: Low (conditional execution)
- **Use Cases**: Troubleshooting, system validation, development debugging

### TME_STATUS_TERMINAL_OUTPUT
- **Function Integration**: `tme_set_output`, `tme_show_output_settings`
- **Implementation**: Configuration changes and operational status
- **Performance Impact**: Minimal (infrequent calls)
- **Use Cases**: Configuration management, operational monitoring, runtime feedback

## 🔧 Runtime Configuration API

### Core Configuration Functions

```bash
# Set specific output type control
tme_set_output() {
    local output_type="$1"
    local setting="$2"
    
    case "$output_type" in
        "report"|"timing"|"debug"|"status")
            local var_name="TME_${output_type^^}_TERMINAL_OUTPUT"
            declare -g "$var_name"="$setting"
            export "$var_name"
            ;;
    esac
}

# Display current configuration
tme_show_output_settings() {
    echo "TME Terminal Output Settings:"
    echo "  Master: ${MASTER_TERMINAL_VERBOSITY:-off}"
    echo "  TME Module: ${TME_TERMINAL_VERBOSITY:-off}"
    echo "  Report: ${TME_REPORT_TERMINAL_OUTPUT:-off}"
    echo "  Timing: ${TME_TIMING_TERMINAL_OUTPUT:-off}"
    echo "  Debug: ${TME_DEBUG_TERMINAL_OUTPUT:-off}"
    echo "  Status: ${TME_STATUS_TERMINAL_OUTPUT:-off}"
}
```

## ⚙️ Environment Variable Configuration

### Configuration Location
All TME nested terminal output controls are defined in `/home/es/lab/cfg/core/ric`:

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

### Setting Environment Variables

#### Before System Initialization
```bash
# Set before running bin/ini
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
export TME_DEBUG_TERMINAL_OUTPUT="off"  # Disable debug messages
./bin/ini
```

#### After System Initialization
Use the runtime control functions (recommended):
```bash
# After system initialization, use runtime controls
tme_set_output debug off
tme_set_output status off
```

## Runtime Control Functions

### tme_set_output

**Purpose**: Runtime control of specific TME terminal output types

**Syntax**: `tme_set_output <type> <on|off>`

**Parameters**:
- `type`: Output type (`report`, `timing`, `debug`, `status`)
- `setting`: Control setting (`on` or `off`)

**Examples**:
```bash
# Disable debug output
tme_set_output debug off

# Enable only timing reports
tme_set_output report on
tme_set_output timing off
tme_set_output debug off
tme_set_output status off

# Re-enable all outputs
tme_set_output report on
tme_set_output timing on
tme_set_output debug on
tme_set_output status on
```

**Error Handling**:
```bash
# Invalid type
tme_set_output invalid on
# Output: Invalid output type: invalid. Use: report, timing, debug, status

# Invalid setting
tme_set_output debug maybe
# Output: Invalid setting: maybe. Use 'on' or 'off'.
```

### tme_show_output_settings

**Purpose**: Display current TME terminal output configuration

**Syntax**: `tme_show_output_settings`

**Example Output**:
```bash
$ tme_show_output_settings
TME Terminal Output Settings:
  Master Terminal Verbosity: on
  TME Terminal Verbosity: on
  ├─ Report Output: on
  ├─ Timing Output: off
  ├─ Debug Output: off
  └─ Status Output: on
```

## Usage Scenarios

### Development Environment
```bash
# Full verbosity for debugging
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
# All nested controls default to "on"
./bin/ini

# Later, reduce noise while keeping essential info
tme_set_output debug off    # Reduce debug noise
tme_set_output timing off   # Hide detailed timing
# Keep reports and status for essential feedback
```

### Production Monitoring
```bash
# Enable master controls but selective TME output
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
./bin/ini

# Configure for production monitoring
tme_set_output report on    # Performance reports
tme_set_output timing off   # Too verbose for production
tme_set_output debug off    # No debug in production
tme_set_output status on    # Status updates useful
```

### Performance Analysis
```bash
# Focus on timing and performance data
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
./bin/ini

# Configure for performance analysis
tme_set_output report on    # Essential for analysis
tme_set_output timing on    # Detailed timing data
tme_set_output debug on     # Helpful for issues
tme_set_output status off   # Reduce noise
```

### Silent Operation
```bash
# Complete silence from TME module
export MASTER_TERMINAL_VERBOSITY="on"  # Keep other modules
export TME_TERMINAL_VERBOSITY="off"    # Disable all TME output
./bin/ini

# Or selectively disable all TME outputs
export TME_TERMINAL_VERBOSITY="on"
./bin/ini
tme_set_output report off
tme_set_output timing off  
tme_set_output debug off
tme_set_output status off
```

## Implementation Details

### Control Check Pattern
Throughout the TME module, terminal output is controlled using this pattern:

```bash
if [[ "${MASTER_TERMINAL_VERBOSITY:-on}" == "on" && "${TME_TERMINAL_VERBOSITY:-on}" == "on" && "${TME_DEBUG_TERMINAL_OUTPUT:-on}" == "on" ]]; then
    printf "Debug message here\n" >&2
fi
```

### Function Integration
The nested controls are integrated into all relevant TME functions:

- **tme_init_timer**: Uses `TME_DEBUG_TERMINAL_OUTPUT` for warnings
- **tme_print_timing_report**: Uses `TME_REPORT_TERMINAL_OUTPUT` for reports  
- **tme_settme**: Uses `TME_STATUS_TERMINAL_OUTPUT` for configuration feedback
- **tme_set_output**: Uses `TME_STATUS_TERMINAL_OUTPUT` for confirmation messages

### Backward Compatibility
- Existing `TME_TERMINAL_VERBOSITY` continues to work as before
- New nested controls default to "on" for full compatibility
- No breaking changes to existing functionality

## Troubleshooting

### Common Issues

#### No TME Output Despite Settings
**Problem**: TME outputs not appearing even with nested controls enabled

**Diagnosis**:
```bash
# Check hierarchy
echo "Master: ${MASTER_TERMINAL_VERBOSITY:-default}"
echo "TME: ${TME_TERMINAL_VERBOSITY:-default}" 
tme_show_output_settings
```

**Solutions**:
```bash
# Ensure master verbosity is enabled
export MASTER_TERMINAL_VERBOSITY="on"

# Ensure TME module verbosity is enabled  
export TME_TERMINAL_VERBOSITY="on"

# Check specific output controls
tme_set_output report on
```

#### Nested Controls Not Working
**Problem**: `tme_set_output` commands have no effect

**Diagnosis**:
```bash
# Verify TME module is loaded
type -t tme_set_output
```

**Solutions**:
```bash
# Ensure system is initialized
./bin/ini

# Verify module loading
source lib/core/tme
```

#### Partial Output Missing
**Problem**: Some TME outputs appear but others don't

**Diagnosis**:
```bash
# Check individual control settings
tme_show_output_settings
```

**Solutions**:
```bash
# Enable missing output types
tme_set_output debug on
tme_set_output timing on
```

### Debug Commands

```bash
# Complete diagnostic
echo "=== TME Control Hierarchy ==="
echo "Master: ${MASTER_TERMINAL_VERBOSITY:-default}"
echo "TME Module: ${TME_TERMINAL_VERBOSITY:-default}"
echo "Report: ${TME_REPORT_TERMINAL_OUTPUT:-default}"
echo "Timing: ${TME_TIMING_TERMINAL_OUTPUT:-default}"
echo "Debug: ${TME_DEBUG_TERMINAL_OUTPUT:-default}"
echo "Status: ${TME_STATUS_TERMINAL_OUTPUT:-default}"

# Function availability
echo "=== Function Availability ==="
type -t tme_set_output
type -t tme_show_output_settings

# Test output
echo "=== Test Output ==="
tme_show_output_settings
```

## Integration Examples

### Script Integration
```bash
#!/bin/bash
# Example script using TME nested controls

# Initialize with selective output
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
source ./bin/ini

# Configure for script needs
tme_set_output debug off    # Reduce noise
tme_set_output status on    # Keep feedback

# Use TME as normal
tme_start_timer "SCRIPT_EXECUTION"
# ... script logic ...
tme_end_timer "SCRIPT_EXECUTION" "success"
tme_print_timing_report
```

### Automation Integration
```bash
# Automation script example
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
source ./bin/ini
tme_set_output report on    # Keep performance data
tme_set_output debug off    # Reduce automation noise
tme_set_output timing off   # Too verbose for automation
    tme_set_output status off   # Reduce noise
```

### Development Workflow
```bash
# Development session setup
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
source ./bin/ini

# Start with full debugging
echo "Development mode - full TME output"
tme_show_output_settings

# Later, reduce noise while keeping essential info
echo "Reducing TME noise for focused work..."
tme_set_output debug off
tme_set_output timing off

# Re-enable when needed
echo "Re-enabling debug for troubleshooting..."
tme_set_output debug on
```

## Best Practices

### Configuration Management
1. **Use runtime controls** over environment variables when possible
2. **Document output requirements** for different operational modes
3. **Test configurations** before deploying to production
4. **Use `tme_show_output_settings`** to verify current state

### Development Guidelines
1. **Start with full output** for initial development and debugging
2. **Gradually reduce verbosity** as systems stabilize
3. **Keep status output enabled** for operational feedback
4. **Use debug output** for troubleshooting specific issues

### Production Recommendations
1. **Enable reports only** for production monitoring
2. **Disable debug and timing** to reduce log noise
3. **Monitor status output** for configuration changes
4. **Use selective enabling** for troubleshooting

### Performance Considerations
1. **Disable unused outputs** to reduce overhead
2. **Monitor log file sizes** with high verbosity
3. **Use timing output judiciously** in performance-critical paths
4. **Consider master verbosity** for complete silence when needed

## Version History

- **v1.0**: Initial implementation of nested TME terminal output controls
- **Integration**: Part of TME module enhancement in lab environment system
- **Status**: Production ready, fully tested and documented

## See Also

- **[Initiation Guide](initiation.md)**: User interaction and configuration
- **[Logging Documentation](logging.md)**: Complete logging system reference
- **[Architecture Guide](architecture.md)**: System design and patterns
- **TME Module**: `/home/es/lab/lib/core/tme`
- **Configuration**: `/home/es/lab/cfg/core/ric`
