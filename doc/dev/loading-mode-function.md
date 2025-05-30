# Loading Configuration Control Function

**Function**: `loading_mode` (alias: `lm`)  
**Location**: `../../lib/utl/env`  
**Purpose**: Control between parallel and sequential loading modes

## Quick Usage

```bash
# Initialize lab environment first
source ../../bin/init

# Check current loading mode
loading_mode

# Switch to parallel loading (faster, ~1.7s)
loading_mode parallel

# Switch to sequential loading (traditional, ~2.7s)  
loading_mode sequential

# Short aliases
lm p          # Enable parallel
lm s          # Enable sequential  
lm            # Show status
lm help       # Show detailed help
```

## Available Modes

### Parallel Loading (Default)
- **Performance**: ~1.7s initialization time
- **Benefits**: 35% faster than sequential, utilizes multiple CPU cores
- **Safety**: Automatic fallback to sequential if parallel fails
- **Best for**: Development environments, fast iteration cycles

### Sequential Loading  
- **Performance**: ~2.7s initialization time
- **Benefits**: Maximum reliability, single-threaded simplicity
- **Safety**: Traditional proven loading method
- **Best for**: Production environments, debugging, older systems

## Configuration Control

The loading mode is controlled by environment variables in `cfg/core/ric`:

```bash
# Enable/disable parallel loading
PARALLEL_LOADING_ENABLED="on"    # "on" or "off"

# Enable/disable automatic fallback
PARALLEL_LOADING_FALLBACK="on"   # "on" or "off"  
```

## Environment Variable Override

You can also control loading mode via environment variables:

```bash
# Force sequential loading for this session
export PARALLEL_LOADING_ENABLED="off"
./bin/init

# Force parallel loading  
export PARALLEL_LOADING_ENABLED="on"
./bin/init
```

## Function Details

### Status Display
```bash
loading_mode status    # or just: loading_mode
```
Shows:
- Current mode (parallel/sequential)
- Configuration settings
- Performance comparison
- Available commands

### Mode Switching
```bash
loading_mode parallel     # Full command
loading_mode p           # Short alias
loading_mode sequential  # Full command  
loading_mode s           # Short alias
```

### Help System
```bash
loading_mode help        # Detailed usage guide
loading_mode --help      # Same as above
loading_mode -h          # Same as above
```

## Integration with Lab System

The `loading_mode` function is automatically available after lab initialization:

1. **Sourcing**: Function is loaded when utilities are sourced (`lib/utl/env`)
2. **Persistence**: Settings persist for the current shell session
3. **Integration**: Works seamlessly with existing parallel loading system
4. **Fallback**: Respects all existing fallback and error handling mechanisms

## Performance Comparison

| Mode | Time | Improvement | CPU Usage | Reliability |
|------|------|-------------|-----------|-------------|
| **Sequential** | ~2.7s | Baseline | Single core | Maximum |
| **Parallel** | ~1.7s | 35% faster | Multi-core | High* |

*High reliability due to automatic fallback to sequential mode on any parallel loading failures.

## Examples

### Development Workflow
```bash
# Fast iteration during development
loading_mode parallel
./bin/init    # ~1.7s

# Switch to sequential for debugging
loading_mode sequential  
./bin/init    # ~2.7s
```

### Production Deployment
```bash
# Use sequential for maximum reliability
loading_mode sequential
./bin/init
```

### Quick Status Check
```bash
# Check current configuration
lm
```

This function provides a convenient, user-friendly interface to control the lab environment's loading performance while maintaining full compatibility with all existing functionality.
