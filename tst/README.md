# Test and Validation Scripts

This directory contains test and validation scripts for the lab environment management system.

## Directory Contents

### Test Scripts

- **`test_verbosity_controls.sh`** - Comprehensive test for system verbosity control mechanisms
- **`test_complete_refactor.sh`** - Test script for complete system refactoring validation
- **`test_refactor.sh`** - Basic refactoring validation test

## Usage

All test scripts should be run from the lab root directory:

```bash
# Navigate to lab root (if not already there)
cd lab/

# Test system verbosity controls functionality
./tst/test_verbosity_controls.sh

# Test complete refactoring
./tst/test_complete_refactor.sh

# Test basic refactoring
./tst/test_refactor.sh
```

## Test Categories

### Performance Testing
- System verbosity controls and TME module functionality
- Timing and performance monitoring validation

### System Integration Testing
- Complete system refactoring validation
- Component integration and functionality testing

### Module Testing
- Individual module functionality validation
- Wrapper function testing

## Adding New Tests

When adding new test scripts to this directory:

1. Follow the naming convention: `test_<feature>_<purpose>.sh`
2. Include comprehensive technical headers with test coverage documentation
3. Make scripts executable: `chmod +x tst/<script_name>.sh`
4. Update this README.md to document the new test

## Dependencies

Most test scripts depend on:
- Lab initialization: `bin/init`
- Core modules: `lib/core/*`
- Environment configuration: `cfg/core/*`

Ensure the lab environment is properly initialized before running tests.

---

**Navigation**: Return to [Main Lab Documentation](../README.md)
