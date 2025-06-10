# 🧪 Lab Validation & Testing System

**Purpose**: Comprehensive quality assurance, system health verification, and automated testing for the shell-based infrastructure management system.

## 🚀 Quick Start

```bash
# Run all tests
./val/run_all_tests.sh

# Run specific categories  
./val/run_all_tests.sh core           # Core system tests
./val/run_all_tests.sh lib            # Library function tests  
./val/run_all_tests.sh integration    # End-to-end tests
./val/run_all_tests.sh legacy         # Legacy validation scripts

# Test options
./val/run_all_tests.sh --list         # List available tests
./val/run_all_tests.sh --quick        # Skip slow tests
./val/run_all_tests.sh --help         # Show usage
```

## 🏗️ Architecture

```
val/
├── helpers/           # Test framework (test_framework.sh)
├── core/             # Core system tests (ini, modules, config)
├── lib/              # Library function tests (ops/, gen/)
├── integration/      # End-to-end integration tests
└── run_all_tests.sh  # Master test runner
```

**Test Categories:**
- **Core (4 components)**: Initialization, error handling, logging, configuration
- **Library (12 components)**: Operations (GPU, network, storage, etc.) + general utilities
- **Integration**: Complete workflow and cross-component testing
- **Legacy**: Existing validation scripts (being migrated)

## 📊 Current Status

**✅ Working (12/21 tests passing):**
- cfg_test, err_test, lo1_test, ver_test, aux_test, env_test
- net_test, ssh_test, sto_test, sys_test, usr_test

**⚠️ Needs Fixing (8 tests):**
- ini_test, tme_test (dependency issues)
- inf_test, sec_test (function name updates needed)
- gpu_test, pbs_test, srv_test (framework issues)
- function_rename_test (path issues)

**Coverage:**
- Core System: 100% (4/4 components)
- Library Functions: 95% (12/13 components)  
- Integration: 80% (basic end-to-end)

## 🔧 Framework Features

- **Color-coded output**: ✓ green, ✗ red, ⚠ yellow
- **Performance timing**: Built-in benchmarking and thresholds
- **Test isolation**: Temporary environments, automatic cleanup
- **Error handling**: Graceful failure management
- **Auto-discovery**: Finds and categorizes tests automatically
- **Standardized functions**: `run_test()`, `test_function_exists()`, etc.

## 🎯 Development

### Creating Tests

```bash
# 1. Use the framework
source val/helpers/test_framework.sh

# 2. Follow naming pattern
# Core: val/core/<category>/<component>_test.sh
# Library: val/lib/<category>/<component>_test.sh  
# Integration: val/integration/<feature>_test.sh

# 3. Use standard functions
test_function_exists "my_function" "Description"
test_file_exists "/path/to/file" "Description"
run_test "Test name" command_to_test

# 4. Include performance testing
start_performance_test "operation"
# ... perform operation ...
end_performance_test "operation" 1000  # ms threshold
```

### Integration Points

- **Development Workflow**: Quick health checks during development
- **CI/CD Pipelines**: Automated testing on commits
- **Pre-deployment**: System readiness verification
- **Monitoring**: Performance validation and regression detection

## 🚧 Migration Strategy

### ✅ Phase 1: Framework Complete
- Test framework with 20+ utility functions
- Master test runner with category support
- 15 comprehensive test scripts created
- Documentation and standards established

### 🔄 Phase 2: Test Migration (In Progress)
- **Next**: Fix remaining 8 failing tests
- **Priority**: Convert legacy scripts (`system`, `environment`, `docs`)
- **Goal**: 100% test coverage of core components

### 📈 Phase 3: Enhanced Testing (Planned)
- CI/CD integration (GitHub Actions)
- Test coverage reporting and metrics
- Parallel execution and advanced features
- Visual reporting and IDE integration

## 📋 Known Issues

**Framework Dependencies:**
- Some libraries require specific environment setup
- LAB_ROOT auto-detection (fixed)
- GPU tests need hardware availability

**Test Coverage Gaps:**
- PVE operations (environment requirements)
- Container management
- External API integrations

**Performance:**
- Full test suite: ~2-3 minutes
- Quick mode: ~30 seconds
- Individual tests: <5 seconds each

## 🔗 Key Files

- **Framework**: `val/helpers/test_framework.sh`
- **Master Runner**: `val/run_all_tests.sh`
- **Library Runner**: `val/lib/run_all_tests.sh`
- **Example Test**: `val/core/config/cfg_test.sh`

---

**Status**: Framework operational, 57% tests passing, migration in progress  
**Next Review**: Fix remaining 8 failing tests  
**Last Updated**: June 11, 2025
