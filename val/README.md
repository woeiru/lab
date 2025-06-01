# 🧪 Validation Scripts

**Purpose**: Quality assurance, system health verification, and comprehensive testing tools

## 🏗️ Testing Architecture

### New Structured Testing Framework
```
val/
├── helpers/           # Test framework and utilities
├── core/             # Core system tests (ini, modules, config)
├── lib/              # Library function tests (ops/, gen/)
├── integration/      # End-to-end integration tests
├── fixtures/         # Test data and mocks
└── legacy/           # Existing validation scripts
```

### 🚀 Quick Start

**Run All Tests:**
```bash
./val/run_all_tests.sh
```

**Run Specific Categories:**
```bash
./val/run_all_tests.sh core           # Core system tests
./val/run_all_tests.sh lib            # Library function tests
./val/run_all_tests.sh integration    # Integration tests
./val/run_all_tests.sh legacy         # Legacy validation scripts
```

**Test Options:**
```bash
./val/run_all_tests.sh --list         # List available tests
./val/run_all_tests.sh --quick        # Skip slow integration tests
./val/run_all_tests.sh --help         # Show usage information
```

## Scripts Overview

### Legacy Validation Scripts (Current)
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

### New Structured Tests

#### Core System Tests (`val/core/`)
- **Initialization Tests**: `ini_test.sh`, `orc_test.sh`
- **Module Tests**: `err_test.sh`, `lo1_test.sh`, `tme_test.sh`, `ver_test.sh`
- **Configuration Tests**: `ric_test.sh`, `mdc_test.sh`, `rdc_test.sh`

#### Library Function Tests (`val/lib/`)
- **Operations**: `gpu_test.sh`, `pve_test.sh`, `sys_test.sh`, `usr_test.sh`
- **General Utilities**: `aux_test.sh`, `env_test.sh`, `inf_test.sh`, `sec_test.sh`
- **Integration**: `wrapper_test.sh`, `pure_function_test.sh`

#### Integration Tests (`val/integration/`)
- **Complete Workflow**: End-to-end system testing
- **Security Integration**: Security system validation
- **Environment Management**: Multi-environment testing

## 🔧 Test Development

### Creating New Tests

1. **Use the test framework:**
```bash
source val/helpers/test_framework.sh
```

2. **Follow the naming convention:**
```bash
# Core tests: val/core/<category>/<component>_test.sh
# Library tests: val/lib/<category>/<component>_test.sh
# Integration tests: val/integration/<feature>_test.sh
```

3. **Use standardized functions:**
```bash
test_function_exists "my_function" "Description"
test_file_exists "/path/to/file" "Description"
run_test "Test name" command_to_test
```

4. **Include performance testing:**
```bash
start_performance_test "operation name"
# ... perform operation ...
end_performance_test "operation name" 1000  # 1 second threshold
```

### Test Framework Features

- **Standardized Output**: Color-coded results with consistent formatting
- **Test Isolation**: Temporary environments for safe testing
- **Performance Monitoring**: Built-in timing and thresholds
- **Error Handling**: Graceful failure handling and reporting
- **Test Discovery**: Automatic test discovery and categorization

## Integration

These validation scripts are designed for:
- **Development Workflow**: Quick health verification during development
- **Continuous Integration**: Automated testing in CI/CD pipelines
- **Pre-deployment Validation**: System readiness verification
- **Component Testing**: Individual module and function validation
- **Integration Testing**: Cross-component functionality verification
- **Performance Monitoring**: System performance validation

## Migration Strategy

### Phase 1: Framework Establishment ✅
- Test framework created (`helpers/test_framework.sh`)
- Master test runner implemented (`run_all_tests.sh`)
- Example tests created for core areas

### Phase 2: Test Migration (In Progress)
- Migrate existing legacy scripts to new framework
- Create comprehensive test coverage for all components
- Add performance benchmarks and thresholds

### Phase 3: Enhanced Testing (Future)
- Add automated test generation
- Implement test coverage reporting
- Create visual test reports
- Add integration with monitoring systems

All scripts return appropriate exit codes for automation and provide clear pass/fail indicators.
