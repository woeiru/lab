# System Verbosity Controls - User Guide

User guide for managing system verbosity and terminal output controls, including the TME (Timing and Performance Monitoring) module's output settings and configuration options.

## 🎯 Overview

This document provides **user instructions** for configuring and managing system verbosity. For technical implementation details and developer information, see the [Developer Verbosity Guide](../dev/verbosity.md).

The system provides a three-tier verbosity control system that allows you to manage what information appears in your terminal, from complete silence to detailed debugging output.

### What You Can Control

- **Master Verbosity**: Global system output control (affects all modules)
- **Module Controls**: Individual system modules (debugging, logging, errors, timing)
- **TME Module**: Timing and performance monitoring output  
- **Specific Output Types**: Reports, timing data, debug info, and status messages

### Key Principle

**File Logging Continues**: Disabling terminal output doesn't affect file logging - all information is still recorded for analysis and troubleshooting.

## 🔧 Quick Start

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
- **Default**: `"off"` (quiet mode)
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

## 📊 Output Types

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

## 🚀 Usage Scenarios

### For Daily Development Work

**Recommended Settings**:
```bash
# Enable essential feedback, reduce noise
tme_set_output report on    # Keep performance data
tme_set_output timing off   # Too detailed for daily work
tme_set_output debug off    # Reduce terminal clutter
tme_set_output status on    # Keep configuration feedback
```

**Why**: Provides performance insights without overwhelming detail.

### For Troubleshooting Issues

**Recommended Settings**:
```bash
# Enable everything for maximum visibility
tme_set_output report on    # See performance impact
tme_set_output timing on    # Detailed operation timing
tme_set_output debug on     # System warnings and issues
tme_set_output status on    # Configuration changes
```

**Why**: Maximum information to diagnose problems.

### For Performance Analysis

**Recommended Settings**:
```bash
# Focus on performance data
tme_set_output report on    # Essential for analysis
tme_set_output timing on    # Detailed timing measurements
tme_set_output debug on     # Potential performance issues
tme_set_output status off   # Reduce non-performance noise
```

**Why**: Focuses on timing and performance information.

### For Clean Production Logs

**Recommended Settings**:
```bash
# Minimal output for production
tme_set_output report on    # Basic performance monitoring
tme_set_output timing off   # Too verbose for production
tme_set_output debug off    # No debug info in production
tme_set_output status off   # Reduce log volume
```

**Why**: Clean, minimal logging suitable for production environments.

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

**TME Module Only Silence**:
```bash
export TME_TERMINAL_VERBOSITY="off"
./bin/ini
# OR disable all TME output types individually:
tme_set_output report off
tme_set_output timing off
tme_set_output debug off
tme_set_output status off
```

## ⚙️ Configuration Methods

### Method 1: Runtime Controls (Recommended)

Use after system initialization:

```bash
# Initialize system first
./bin/ini

# Then configure verbosity
tme_set_output debug off
tme_set_output timing on
```

**Advantages**: 
- Easy to change during work session
- Immediate effect
- No need to restart system

### Method 2: Environment Variables

Set before system initialization:

```bash
# Set before running bin/ini
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
export TME_DEBUG_TERMINAL_OUTPUT="off"
./bin/ini
```

**Advantages**:
- Persistent across sessions
- Set once, use everywhere
- Good for scripting

### Method 3: Configuration File

Edit `/home/es/lab/cfg/core/ric` directly:

```bash
# Edit the configuration file
nano /home/es/lab/cfg/core/ric

# Look for TME settings and modify:
declare -g TME_DEBUG_TERMINAL_OUTPUT="off"
export TME_DEBUG_TERMINAL_OUTPUT
```

**Advantages**:
- Permanent configuration
- Part of system defaults
- Version controlled

## 📋 Environment Variables Reference

### Complete Variable Summary

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

## 🔍 Checking Your Settings

### View Current Configuration

```bash
# Show all current settings
tme_show_output_settings
```

**Example Output**:
```
TME Terminal Output Settings:
  Master Terminal Verbosity: on
  TME Terminal Verbosity: on
  ├─ Report Output: on
  ├─ Timing Output: off
  ├─ Debug Output: off
  └─ Status Output: on
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

## 🛠️ Troubleshooting

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

### Partial Output Missing

**Check individual settings**:
```bash
tme_show_output_settings
```

**Enable missing types**:
```bash
tme_set_output debug on    # Enable debug output
tme_set_output timing on   # Enable timing output
```

### Too Much Output

**Reduce verbosity systematically**:
```bash
# Option 1: Disable debug messages first
export DEBUG_LOG_TERMINAL_VERBOSITY="off"  # System debug messages
tme_set_output debug off                    # TME debug messages

# Option 2: Disable detailed timing
tme_set_output timing off   # Remove detailed timing measurements

# Option 3: Disable entire modules
export TME_TERMINAL_VERBOSITY="off"        # All TME output
export LO1_LOG_TERMINAL_VERBOSITY="off"    # Advanced logging

# Option 4: Keep only essential feedback
export MASTER_TERMINAL_VERBOSITY="on"
export ERR_TERMINAL_VERBOSITY="on"         # Keep error messages
# Disable everything else
```

### Functions Not Available

**Problem**: Commands like `tme_set_output` not found

**Check system initialization**:
```bash
# Ensure system is properly initialized
./bin/ini

# Verify TME module is loaded
type -t tme_set_output
type -t tme_show_output_settings
```

## 📝 Examples for Common Tasks

### Setting Up for a New Project

```bash
# Initialize system
./bin/ini

# Start with moderate verbosity
tme_set_output report on    # Track performance
tme_set_output timing off   # Not needed initially  
tme_set_output debug on     # Catch issues early
tme_set_output status on    # Monitor changes

# Later, as project stabilizes
tme_set_output debug off    # Reduce noise
```

### Investigating Performance Issues

```bash
# Enable all timing-related output
tme_set_output report on    # See overall performance
tme_set_output timing on    # Detailed measurements
tme_set_output debug on     # Catch warnings
tme_set_output status on    # Track changes

# Run your operations, then analyze output
```

### Preparing for Production Deployment

```bash
# Set production-appropriate levels
tme_set_output report on    # Basic monitoring
tme_set_output timing off   # Too verbose
tme_set_output debug off    # No debug in production
tme_set_output status off   # Reduce log volume

# Test the configuration
tme_show_output_settings
```

### Creating a Clean Demo Environment

```bash
# Minimal output for presentations
tme_set_output report off   # No performance details
tme_set_output timing off   # No timing measurements
tme_set_output debug off    # No debug messages  
tme_set_output status off   # No status updates

# Or completely disable TME output
export TME_TERMINAL_VERBOSITY="off"
```

## 🎯 Best Practices

### Daily Development
- Start with moderate verbosity (reports + status)
- Enable debug only when troubleshooting
- Use timing output for performance work
- Adjust based on current task

### Code Reviews and Demos
- Disable debug and timing output
- Keep reports if relevant to discussion
- Clean terminal makes better presentations

### Production Systems
- Enable only essential monitoring
- Avoid debug output in production
- Monitor log file sizes with high verbosity
- Document your production settings

### Troubleshooting Sessions
- Enable all output types temporarily
- Start broad, then narrow focus
- Document settings that reveal issues
- Return to normal settings when done

## 📚 Related Documentation

- **[Initiation Guide](initiation.md)**: System startup and initialization
- **[Configuration Guide](../adm/configuration.md)**: System configuration management

For technical details and implementation information, see:
- **[Developer Verbosity Guide](../dev/verbosity.md)**: Technical implementation details
- **[Architecture Guide](../core/architecture.md)**: System design patterns

## 🔧 Quick Reference

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

### Common Combinations
```bash
# Development mode (all output)
export MASTER_TERMINAL_VERBOSITY="on"
# All other controls default to "on"

# Minimal feedback mode
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="off"
export LO1_LOG_TERMINAL_VERBOSITY="off"
export TME_TERMINAL_VERBOSITY="off"

# Performance analysis mode
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="on"
tme_set_output report on; tme_set_output timing on; tme_set_output debug on; tme_set_output status off

# Production mode (errors only)
export MASTER_TERMINAL_VERBOSITY="on"
export DEBUG_LOG_TERMINAL_VERBOSITY="off"
export LO1_LOG_TERMINAL_VERBOSITY="off"
export TME_TERMINAL_VERBOSITY="off"
# ERR_TERMINAL_VERBOSITY remains "on" by default

# Complete silence
export MASTER_TERMINAL_VERBOSITY="off"
```

## 💡 Key Points to Remember

- **File Logging Continues**: Disabling terminal output doesn't affect file logging
- **Hierarchical Control**: All module controls require `MASTER_TERMINAL_VERBOSITY="on"`
- **Master Override**: `MASTER_TERMINAL_VERBOSITY="off"` silences everything
- **Runtime Changes**: Use `tme_set_output` functions after initialization
- **Session Scope**: Controls affect only your current session
- **Default Behavior**: System defaults to quiet mode (`MASTER_TERMINAL_VERBOSITY="off"`)
