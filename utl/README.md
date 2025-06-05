# Utilities (`utl/`)

## 📋 Overview
System utilities and tools for configuration management, documentation generation, and operational maintenance of the Lab Environment Management System.

## 🗂️ Directory Structure / Key Files
- `cfg/` - Configuration utilities and management tools
- `doc/` - Documentation generation and maintenance utilities

### Configuration Utilities (`cfg/`)
- `ali` - Alias management and configuration utility

### Documentation Tools (`doc/`)
- `hub` - Automated documentation index generator using ana_lad
- `func` - Function metadata table generation utility
- `stats` - Codebase statistics and metrics generator
- `var` - Variable documentation and analysis tool
- `run_all_doc.sh` - Comprehensive documentation generation script
- `orchestrator-development-summary.md` - Development workflow documentation
- `.doc_config` - Documentation generation configuration

## 🚀 Quick Start
```bash
# Generate documentation index
./utl/doc/hub

# Update function documentation
./utl/doc/func

# Generate codebase statistics
./utl/doc/stats

# Run comprehensive documentation update
./utl/doc/run_all_doc.sh

# Manage system aliases
./utl/cfg/ali --help
```

## 📊 Quick Reference
| Tool | Purpose | Example Usage |
|------|---------|---------------|
| `doc/hub` | Update documentation index | `./utl/doc/hub --update` |
| `doc/func` | Generate function metadata | `./utl/doc/func` |
| `doc/stats` | System metrics | `./utl/doc/stats` |
| `doc/var` | Variable analysis | `./utl/doc/var` |
| `cfg/ali` | Alias management | `./utl/cfg/ali list` |

## 🔧 Documentation Generation Process
1. **Index Generation**: `hub` discovers and categorizes all documentation
2. **Function Metadata**: `func` extracts function signatures and documentation
3. **Statistics**: `stats` analyzes codebase metrics and complexity
4. **Variable Documentation**: `var` documents environment variables and configurations
5. **Comprehensive Update**: `run_all_doc.sh` orchestrates complete documentation refresh

## 🔗 Related Documentation
- [Documentation Standards](../doc/standards.md) - Documentation creation and maintenance guidelines
- [Documentation Creation Metaprompt](../doc/metaprompt.md) - AI-assisted documentation patterns
- [Developer Documentation](../doc/dev/README.md) - Development workflows and tools
- [CLI Documentation](../doc/cli/README.md) - Command-line interface guides

---

**Navigation**: Return to [Main](../README.md)
