# System Verbosity Controls - User Guide

User guide for managing system verbosity and terminal output controls, including the TME (Timing and Performance Monitoring) module's output settings and configuration options.

## Overview

This document provides user instructions for configuring and managing system verbosity. For technical implementation details and developer information, see the related documentation.

The system provides a three-tier verbosity control system that allows you to manage what information appears in your terminal, from complete silence to detailed debugging output.

### What You Can Control

- **Master Verbosity**: Global system output control (affects all modules)
- **Module Controls**: Individual system modules (debugging, logging, errors, timing)
- **TME Module**: Timing and performance monitoring output  
- **Specific Output Types**: Reports, timing data, debug info, and status messages

### Key Principle

**File Logging Continues**: Disabling terminal output doesn't affect file logging. All information is still recorded for analysis and troubleshooting.

## Quick Start

### Control Hierarchy

The system uses a hierarchical control system where all levels must be "on" for output to appear:

```
Master Control (MASTER_TERMINAL_VERBOSITY)
    ↓
Module Controls (Individual system modules)
    ↓
TME Module Control (TME_TERMINAL_VERBOSITY)
    ↓
Output Type Controls (TME_*_TERMINAL_OUTPUT)
```

### Master Control

**MASTER_TERMINAL_VERBOSITY**: Controls all terminal output across the entire system
- **Default**: `"on"` (verbose mode)
- **Values**: `"on"` | `"off"`
- **Impact**: When `"off"`, all modules remain silent in the terminal

```bash
# Enable verbose terminal output
export MASTER_TERMINAL_VERBOSITY="on"
./bin/ini

# Return to quiet mode  
export MASTER_TERMINAL_VERBOSITY="off"
./bin/ini
```

### Module-Specific Controls

When `MASTER_TERMINAL_VERBOSITY="on"`, you can control individual system modules:

- **`DEBUG_LOG_TERMINAL_VERBOSITY`** - Early initialization messages
- **`LO1_LOG_TERMINAL_VERBOSITY`** - Advanced logging module output  
- **`ERR_TERMINAL_VERBOSITY`** - Error handling messages
- **`TME_TERMINAL_VERBOSITY`** - Timing and performance monitoring

```bash
# Enable master but disable specific modules
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="off"  # Disable debug messages
export TME_TERMINAL_VERBOSITY="off"        # Disable timing output
./bin/ini
```

### Common Commands

```bash
# View current settings
tme_show_output_settings

# Control master verbosity
export MASTER_TERMINAL_VERBOSITY="on"   # Enable all output
export MASTER_TERMINAL_VERBOSITY="off"  # Silent operation

# Control TME-specific output types
tme_set_output report on     # Enable performance reports
tme_set_output debug off     # Disable debug messages
tme_set_output timing on     # Enable timing measurements
tme_set_output status on     # Enable status updates
```

## Output Types

### Performance Reports (`report`)
**What it shows**: Summary of timing data and performance metrics
**When to use**: Performance analysis, system optimization
**Example output**:
```
TME Timing Report:
├─ SYSTEM_INIT: 2.34s
├─ CONFIG_LOAD: 0.45s
└─ Total: 2.79s
```

### Timing Measurements (`timing`)
**What it shows**: Real-time timing of individual operations
**When to use**: Detailed performance monitoring, debugging slow operations
**Example output**:
```
TME: Starting timer [DATABASE_QUERY]
TME: Timer [DATABASE_QUERY] completed in 0.123s
```

### Debug Information (`debug`)
**What it shows**: System warnings, initialization messages, configuration issues
**When to use**: Troubleshooting problems, understanding system behavior
**Example output**:
```
TME: Warning - Timer 'MISSING_TIMER' not found
TME: Debug - Configuration loaded successfully
```

### Status Updates (`status`)
**What it shows**: Configuration changes, operational status
**When to use**: Monitoring configuration changes, runtime feedback
**Example output**:
```
TME: Output setting changed - debug: off
TME: Current verbosity level: selective
```

## Usage Scenarios

### For Daily Development Work

**Recommended Settings**:
```bash
# Enable essential feedback, reduce noise
tme_set_output report on    # Keep performance data
tme_set_output timing off   # Too detailed for daily work
tme_set_output debug off    # Reduce terminal clutter
tme_set_output status on    # Keep configuration feedback
```

### For Complete Silence

**Complete System Silence**:
```bash
export MASTER_TERMINAL_VERBOSITY="off"
./bin/ini
```

**Selective Module Silence**:
```bash
# Enable master but disable specific modules
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="off"
export LO1_LOG_TERMINAL_VERBOSITY="off"
export TME_TERMINAL_VERBOSITY="off"
./bin/ini
```

## Configuration Methods

### Method 1: Runtime Controls (Recommended)

Use after system initialization:

```bash
# Initialize system first
./bin/ini

# Then configure verbosity
tme_set_output debug off
tme_set_output timing on
```

### Method 2: Environment Variables

Set before system initialization:

```bash
# Set before running bin/ini
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
export TME_DEBUG_TERMINAL_OUTPUT="off"
./bin/ini
```

### Method 3: Configuration File

Edit `cfg/core/ric` directly:

```bash
# Edit the configuration file
nano cfg/core/ric

# Look for TME settings and modify:
declare -g TME_DEBUG_TERMINAL_OUTPUT="off"
export TME_DEBUG_TERMINAL_OUTPUT
```

## Environment Variables Reference

### Setting Variables

**Pre-initialization** (before `./bin/ini`):
```bash
export MASTER_TERMINAL_VERBOSITY="on"
export TME_REPORT_TERMINAL_OUTPUT="on"
export TME_DEBUG_TERMINAL_OUTPUT="off"
./bin/ini
```

**Post-initialization** (after `./bin/ini`):
```bash
# Use runtime control functions for TME module
tme_set_output debug off
tme_set_output timing on
```

## Checking Your Settings

### View Current Configuration

```bash
# Show all current settings
tme_show_output_settings
```

### Quick Diagnostic

```bash
# Check if TME functions are available
type tme_set_output
type tme_show_output_settings

# Check individual environment variables
echo "Master: ${MASTER_TERMINAL_VERBOSITY:-default}"
echo "TME: ${TME_TERMINAL_VERBOSITY:-default}"
echo "Report: ${TME_REPORT_TERMINAL_OUTPUT:-default}"
echo "Debug: ${TME_DEBUG_TERMINAL_OUTPUT:-default}"
```

## Troubleshooting

### No Output Appearing (Any Module)

**Check the complete hierarchy**:
```bash
echo "Master: ${MASTER_TERMINAL_VERBOSITY:-unset}"
echo "Debug: ${DEBUG_LOG_TERMINAL_VERBOSITY:-unset}"
echo "Logging: ${LO1_LOG_TERMINAL_VERBOSITY:-unset}"
echo "Errors: ${ERR_TERMINAL_VERBOSITY:-unset}"
echo "TME: ${TME_TERMINAL_VERBOSITY:-unset}"
tme_show_output_settings
```

**Common fixes**:
```bash
# Enable master verbosity (required for all output)
export MASTER_TERMINAL_VERBOSITY="on"

# Enable specific modules
export DEBUG_LOG_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"

# Enable specific TME output types
tme_set_output report on
```

### Commands Not Working

**Check if system is initialized**:
```bash
# This should show function details, not "not found"
type tme_set_output
```

**Fix**:
```bash
# Initialize the system
./bin/ini
```

## Quick Reference

### Essential Commands
```bash
tme_show_output_settings                     # View current TME settings
tme_set_output <type> <on|off>              # Control specific TME output
export MASTER_TERMINAL_VERBOSITY="on/off"   # Master control for all output
export TME_TERMINAL_VERBOSITY="off"         # Disable all TME output
```

### Output Types (TME Module)
- `report` - Performance reports and summaries
- `timing` - Real-time timing measurements  
- `debug` - Debug messages and warnings
- `status` - Configuration and status updates

### System Modules
- `MASTER_TERMINAL_VERBOSITY` - Controls all terminal output
- `DEBUG_LOG_TERMINAL_VERBOSITY` - Early initialization messages
- `LO1_LOG_TERMINAL_VERBOSITY` - Advanced logging output
- `ERR_TERMINAL_VERBOSITY` - Error handling messages
- `TME_TERMINAL_VERBOSITY` - Timing and performance monitoring

### Key Points to Remember

- **File Logging Continues**: Disabling terminal output doesn't affect file logging
- **Hierarchical Control**: All module controls require `MASTER_TERMINAL_VERBOSITY="on"`
- **Master Override**: `MASTER_TERMINAL_VERBOSITY="off"` silences everything
- **Runtime Changes**: Use `tme_set_output` functions after initialization
- **Session Scope**: Controls affect only your current session
- **Default Behavior**: System defaults to verbose mode (`MASTER_TERMINAL_VERBOSITY="on"`)
