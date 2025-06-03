# 🔧 Utility Scripts

**Purpose**: Metadata generation and system introspection tools

## Scripts Overview

### Documentation Generation
- **[`run_all_doc.sh`](run_all_doc.sh)** - **Orchestrator for all documentation generators with dependency management**
- **[`doc-func`](doc-func)** - Function metadata table generator using `aux_laf`
- **[`doc-var`](doc-var)** - Variable usage documentation generator using `aux_acu`  
- **[`doc-hub`](doc-hub)** - Documentation index generator using `aux_lad`
- **[`doc-stats`](doc-stats)** - System metrics generator with real-time codebase analysis

### Configuration Management
- **[`cfg-ali`](cfg-ali)** - Configuration alias management utility

## 🚀 Quick Start

### Generate All Documentation
```bash
# Run all documentation generators with intelligent dependency resolution
./utl/run_all_doc.sh

# Run in parallel where dependencies allow
./utl/run_all_doc.sh --parallel

# Preview what would be executed
./utl/run_all_doc.sh --dry-run --verbose

# Run specific generators only
./utl/run_all_doc.sh functions stats
```

### Individual Generator Usage
```bash
# Generate function metadata table
./utl/doc-func

# Generate variable usage documentation  
./utl/doc-var

# Generate documentation index
./utl/doc-hub

# Generate system metrics (formatted output)
./utl/doc-stats
./utl/doc-stats --update

# Generate markdown table format
./utl/doc-stats --markdown

# Generate raw numbers only
./utl/doc-stats --raw
```

## Generated Outputs

### Documentation Index
- **Output**: `DOCUMENTATION_INDEX.md` (at lab root)
- **Content**: Complete markdown file inventory with metadata
- **Features**: Cross-references, file statistics, categorized navigation

### Statistics Report
- **Output**: Console display with optional file output
- **Content**: Codebase metrics, file counts, size analysis
- **Features**: Real-time calculation, trend analysis

## Integration

These utility scripts support:
- **Documentation maintenance** - Keep documentation current and discoverable
- **Project oversight** - Understand codebase structure and growth
- **Reporting** - Generate metrics for project management
- **Navigation** - Provide organized access to project resources
