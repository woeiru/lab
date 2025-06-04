# Documentation Generation System

**Location**: `/home/es/lab/utl/doc/`  
**Status**: ✅ Portable, Self-Contained Documentation Project  
**Version**: Portable v1.0

## 🎯 Overview

This is a portable documentation generation system that can be moved to any location and will automatically adapt to generate documentation for the Lab Environment project. The system consists of modular generators and a centralized orchestrator.

## 📁 Project Structure

```
utl/doc/
├── .doc_config                 # Configuration file for paths and settings
├── README.md                   # This documentation
├── run_all_doc.sh             # 🌟 Main orchestrator (recommended)
├── run_all_doc_portable.sh    # Advanced orchestrator with parallel support
├── run_all_doc_production.sh  # Full-featured orchestrator
├── doc-func                    # Function metadata generator
├── doc-hub                     # Documentation index generator
├── doc-stats                   # System metrics generator
├── doc-var                     # Variable documentation generator
└── test_*.sh                   # Testing utilities
```

## 🚀 Quick Start

### Basic Usage
```bash
# Run all documentation generators
cd /home/es/lab/utl/doc
./run_all_doc.sh

# Run specific generators
./run_all_doc.sh functions variables

# Preview what will be executed
./run_all_doc.sh --dry-run

# Show detailed output
./run_all_doc.sh --verbose
```

### Available Commands
```bash
./run_all_doc.sh --help          # Show help
./run_all_doc.sh --list          # List all generators
./run_all_doc.sh --dry-run       # Preview execution plan
./run_all_doc.sh functions       # Run specific generator
./run_all_doc.sh hub             # Run hub (includes dependencies)
```

## 📋 Available Generators

| Generator | Script | Description | Dependencies |
|-----------|--------|-------------|--------------|
| `functions` | `doc-func` | Function metadata table generator | None |
| `variables` | `doc-var` | Variable usage documentation | None |
| `stats` | `doc-stats` | System metrics generator | None |
| `hub` | `doc-hub` | Documentation index generator | functions, variables |

## ⚙️ Configuration

The system uses `.doc_config` to configure paths and behavior:

```bash
# Key configuration settings
PROJECT_ROOT="/home/es/lab"              # Lab environment root
DOC_OUTPUT_DIR="$PROJECT_ROOT/doc"       # Where to write documentation
LOG_OUTPUT_DIR="$PROJECT_ROOT/.tmp/doc"  # Where to write logs
VERBOSE=false                            # Enable detailed output
PARALLEL=false                           # Enable parallel execution
```

## 🔄 Portability Features

### ✅ Location Independence
- Can be moved to any directory
- Automatically detects project root from relative paths
- No hardcoded absolute paths in scripts

### ✅ Configuration-Driven
- All paths configurable via `.doc_config`
- Environment variables override config file settings
- Graceful fallbacks for missing configuration

### ✅ Dependency Resolution
- Automatic dependency ordering (`hub` depends on `functions` and `variables`)
- Prevents execution conflicts
- Smart execution planning

## 🛠️ Technical Details

### Path Detection Logic
```bash
# Scripts auto-detect their location and calculate project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  # Two levels up from utl/doc
```

### Environment Variables
```bash
export LAB_DIR="/home/es/lab"           # Set by orchestrator
export DOC_DIR="/home/es/lab/doc"       # Set by orchestrator
```

### Generator Execution
1. **Path Detection**: Auto-detect script location and project root
2. **Configuration Loading**: Read `.doc_config` for custom settings
3. **Dependency Resolution**: Order generators based on dependencies
4. **Environment Setup**: Export LAB_DIR and DOC_DIR for generators
5. **Execution**: Run generators in correct order with error handling

## 📊 Orchestrator Options

### Simple Orchestrator (`run_all_doc.sh`) 🌟 **RECOMMENDED**
- ✅ Lightweight and reliable
- ✅ Dependency resolution
- ✅ Configuration file support
- ✅ Clear error messages
- ✅ Dry-run capability

### Portable Orchestrator (`run_all_doc_portable.sh`)
- ✅ Advanced parallel execution
- ✅ Enhanced logging with timestamps
- ✅ Lock file mechanism
- ✅ More configuration options

### Production Orchestrator (`run_all_doc_production.sh`)
- ✅ Full-featured with all bells and whistles
- ✅ Comprehensive error handling
- ✅ Performance reporting
- ✅ Extended configuration support

## 🧪 Testing

```bash
# Test path detection
./test_paths.sh

# Test basic functionality
./test_portable.sh

# Verify all generators work
./run_all_doc.sh --dry-run
```

## 🔧 Troubleshooting

### Generator Not Found
```bash
# Ensure scripts are executable
chmod +x doc-*

# Check project root detection
./run_all_doc.sh --list
```

### Missing Dependencies
```bash
# Verify lab environment structure
ls -la /home/es/lab/lib/gen/aux

# Check LAB_DIR detection
LAB_DIR=/home/es/lab ./doc-func --help
```

### Configuration Issues
```bash
# Verify configuration file
cat .doc_config

# Test with explicit paths
PROJECT_ROOT=/home/es/lab ./run_all_doc.sh --dry-run
```

## 🎯 Migration Guide

To move this system to a different location:

1. **Copy the entire `doc/` folder to new location**
2. **Update `.doc_config` with new paths**:
   ```bash
   PROJECT_ROOT="/new/project/root"
   DOC_OUTPUT_DIR="$PROJECT_ROOT/doc"
   ```
3. **Test the new setup**:
   ```bash
   ./run_all_doc.sh --dry-run
   ```

## 📈 Output

The system generates documentation in:
- `/home/es/lab/doc/dev/functions.md` - Function metadata table
- `/home/es/lab/doc/dev/variables.md` - Variable documentation  
- `/home/es/lab/README.md` - System metrics section
- `/home/es/lab/doc/README.md` - Documentation index

## 🏆 Success Indicators

When everything works correctly, you'll see:
```
[INFO] Starting documentation generation...
[INFO] Project Root: /home/es/lab
[INFO] Output Directory: /home/es/lab/doc
[INFO] Running functions...
[SUCCESS] Completed functions
[INFO] Running variables...
[SUCCESS] Completed variables
[INFO] Running stats...
[SUCCESS] Completed stats
[INFO] Running hub...
[SUCCESS] Completed hub
[INFO] Completed: 4/4 generators
[SUCCESS] All generators completed successfully!
```

---

**Note**: This system has been designed to be completely self-contained and portable. All generators have been updated to work from the new `utl/doc/` location and automatically detect the correct project root path.
