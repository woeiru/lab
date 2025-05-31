# 🔧 Utility Scripts

**Purpose**: Metadata generation and system introspection tools

## Scripts Overview

### Documentation Tools
- **[`doc-index`](doc-index)** - Generates comprehensive documentation index with cross-references and metadata
- **[`doc-stats`](doc-stats)** - Generates real-time statistics about the lab environment codebase and updates README metrics

## Usage

```bash
# Generate documentation index
./utl/doc-index

# Generate codebase statistics
# Generate system metrics (formatted output)
./utl/doc-stats

# Update README.md with current metrics
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
