# Test and Validation Scripts

This directory contains test and validation scripts for the lab environment management system.

> **📋 For comprehensive testing documentation, see [Developer Testing Guide](../doc/dev/testing.md)**

## Quick Reference

### Test Scripts

- **`test_verbosity_controls.sh`** - Comprehensive test for system verbosity control mechanisms
- **`test_complete_refactor.sh`** - Test script for complete system refactoring validation  
- **`test_refactor.sh`** - Basic refactoring validation test

### Running Tests

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

## Documentation

For detailed information about:
- **Testing Framework Architecture** → [Developer Testing Guide](../doc/dev/testing.md)
- **Writing New Tests** → [Developer Testing Guide](../doc/dev/testing.md#writing-tests)
- **Testing Standards** → [Developer Testing Guide](../doc/dev/testing.md#testing-standards)
- **Performance Testing** → [Developer Testing Guide](../doc/dev/testing.md#performance-testing)

## Quick Add Test Checklist

When adding new test scripts:

1. ✅ Follow naming convention: `test_<feature>_<purpose>.sh`
2. ✅ Include comprehensive technical headers with test coverage documentation
3. ✅ Make scripts executable: `chmod +x tst/<script_name>.sh`
4. ✅ Update [Developer Testing Guide](../doc/dev/testing.md) with new test documentation
4. Update this README.md to document the new test

## Dependencies

Most test scripts depend on:
- Lab initialization: `bin/init`
- Core modules: `lib/core/*`
- Environment configuration: `cfg/core/*`

Ensure the lab environment is properly initialized before running tests.

---

**Navigation**: Return to [Main Lab Documentation](../README.md)
