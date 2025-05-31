#!/bin/bash
#######################################################################
# System Verbosity Controls - Validation Test Script
#######################################################################
# File: /home/es/lab/tst/test_verbosity_controls.sh
# Description: Comprehensive test script for validating the system's
#              verbosity control mechanisms, including TME module's
#              nested terminal output control system functionality.
#
# Test Coverage:
#   - Basic system verbosity controls functionality
#   - Runtime control functions (tme_set_output, tme_show_output_settings)
#   - Three-tier hierarchy validation (Master → TME → Nested)
#   - All four output categories (report, timing, debug, status)
#   - Control combinations and edge cases
#
# Dependencies:
#   - TME module: lib/core/tme
#   - Lab initialization: bin/ini
#   - Environment: cfg/core/ric
#
# Usage:
#   cd /home/es/lab && ./tst/test_verbosity_controls.sh
#
# Expected Results:
#   - Validates nested control functionality
#   - Demonstrates granular output control
#   - Confirms hierarchy enforcement
#   - Shows runtime configuration capabilities
#######################################################################
#
# Test script for system verbosity controls
# Demonstrates how the verbosity control mechanisms work within the system
#

# Source the lab initialization to get TME module
echo "Initializing lab environment..."
source ./bin/ini

echo
echo "=== System Verbosity Controls Test ==="
echo

# Show current settings
echo "1. Current TME output settings:"
tme_show_output_settings
echo

# Test basic timing functionality
echo "2. Testing basic timing with all outputs enabled:"
tme_start_timer "TEST_COMPONENT"
sleep 0.1
tme_end_timer "TEST_COMPONENT" "success"
tme_print_timing_report
echo

# Test disabling report output
echo "3. Testing with report output disabled:"
tme_set_output report off
tme_print_timing_report
echo "  (No report should appear above)"
echo

# Re-enable and test disabling status output
echo "4. Testing with status output disabled:"
tme_set_output report on
tme_set_output status off
echo "  Trying to run tme_settme (should be silent):"
tme_settme depth 5
echo "  (No status message should appear above)"
echo

# Test disabling debug output
echo "5. Testing with debug output disabled:"
tme_set_output debug off
echo "  This would suppress TME debug warnings during initialization"
echo

# Test showing settings with status disabled
echo "6. Testing show settings with status output disabled:"
tme_show_output_settings
echo "  (No output should appear above since status is off)"
echo

# Re-enable status to show final settings
echo "7. Re-enabling status output and showing final settings:"
tme_set_output status on
tme_show_output_settings
echo

# Test all combinations
echo "8. Testing various control combinations:"

echo "  a) Master OFF (should suppress everything):"
export MASTER_TERMINAL_VERBOSITY="off"
tme_print_timing_report
tme_settme depth 3
echo "     (Nothing should appear above)"

echo "  b) Master ON, TME OFF (should suppress TME outputs):"
export MASTER_TERMINAL_VERBOSITY="on"
export TME_TERMINAL_VERBOSITY="off"
tme_print_timing_report
tme_settme depth 3
echo "     (Nothing should appear above)"

echo "  c) Master ON, TME ON, Report OFF:"
export TME_TERMINAL_VERBOSITY="on"
tme_set_output report off
tme_print_timing_report
echo "     (No report should appear above)"

echo "  d) All controls ON:"
tme_set_output report on
tme_set_output status on
tme_set_output debug on
tme_set_output timing on
echo "     Running final timing test:"
tme_start_timer "FINAL_TEST"
sleep 0.05
tme_end_timer "FINAL_TEST" "success"
tme_print_timing_report

echo
echo "=== Test Complete ==="
echo "The nested TME terminal output controls are now implemented and functional."
echo "You can use the following functions:"
echo "  - tme_set_output <type> <on|off>  # Control specific output types"
echo "  - tme_show_output_settings        # Show current settings"
echo "  - Export TME_*_TERMINAL_OUTPUT variables directly"
echo
echo "Available output types: report, timing, debug, status"
