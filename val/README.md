# 🧪 Validation Scripts

**Purpose**: Quality assurance and system health verification tools

## Scripts Overview

### System Validation
- **[`validate_system`](validate_system)** - Quick health checks for lab environment operational status
- **[`validate-docs`](validate-docs)** - Validates internal links in markdown files for documentation integrity  
- **[`validate_gpu_refactoring.sh`](validate_gpu_refactoring.sh)** - Specific validation for GPU refactoring completion

## Usage

```bash
# Quick system health check
./val/validate_system

# Validate documentation links
./val/validate-docs

# Check GPU refactoring status
./val/validate_gpu_refactoring.sh
```

## Integration

These validation scripts are designed for:
- **Pre-deployment checks** - Ensure system readiness
- **CI/CD pipelines** - Automated quality gates
- **Development workflow** - Quick health verification
- **Troubleshooting** - Identify system issues

All scripts return appropriate exit codes for automation and provide clear pass/fail indicators.
