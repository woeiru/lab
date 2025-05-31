# 🧪 Validation Scripts

**Purpose**: Quality assurance, system health verification, and comprehensive testing tools

## Scripts Overview

### System Validation
- **[`system`](system)** - Quick health checks for lab environment operational status
- **[`environment`](environment)** - Environment configuration and loading validation
- **[`docs`](docs)** - Validates internal links in markdown files for documentation integrity

### Component-Specific Validation
- **[`gpu_refactoring`](gpu_refactoring)** - Specific validation for GPU refactoring completion
- **[`gpu_wrappers`](gpu_wrappers)** - GPU wrapper function validation and testing
- **[`verbosity_controls`](verbosity_controls)** - Comprehensive test for system verbosity control mechanisms

### Refactoring Validation
- **[`refactor`](refactor)** - Basic refactoring validation test
- **[`complete_refactor`](complete_refactor)** - Complete system refactoring validation

## Usage

```bash
# Quick system health check
./val/system

# Environment validation
./val/environment

# Documentation validation
./val/docs

# GPU component validation
./val/gpu_refactoring
./val/gpu_wrappers

# System feature validation
./val/verbosity_controls

# Refactoring validation
./val/refactor
./val/complete_refactor
```

## Naming Convention

All validation scripts follow a clean, simplified naming pattern:
- **Format**: Simple descriptive names without prefixes or suffixes
- **No prefixes**: Removed `validate_` prefix for cleaner names
- **No extensions**: Removed `.sh` suffixes for consistency
- **Underscores**: Used for word separation where needed

## Integration

These validation scripts are designed for:
- **Pre-deployment checks** - Ensure system readiness
- **CI/CD pipelines** - Automated quality gates
- **Development workflow** - Quick health verification and comprehensive testing
- **Troubleshooting** - Identify system issues
- **Feature validation** - Test specific functionality and components

All scripts return appropriate exit codes for automation and provide clear pass/fail indicators.

## Migration Notes

This directory consolidates both validation and testing scripts from the former `/tst` directory, providing a unified location for all quality assurance and verification tools with simplified, clean naming.
