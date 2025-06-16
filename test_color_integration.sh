#!/bin/bash
# Test script to demonstrate color integration between col and aux modules

echo "Testing color integration between col and aux modules..."

# Source the modules
echo "1. Sourcing col module..."
source /home/es/lab/lib/core/col

echo "2. Sourcing aux module..."
source /home/es/lab/lib/gen/aux

echo "3. Testing color variables exist:"
echo "   COL_LOADED: ${COL_LOADED:-not set}"
echo "   AUX_LOADED: ${AUX_LOADED:-not set}"

echo "4. Testing backward compatibility aliases:"
echo -e "   Info color: ${AUX_LOG_INFO}This is info colored text${AUX_LOG_NC}"
echo -e "   Warning color: ${AUX_LOG_WARN}This is warning colored text${AUX_LOG_NC}"
echo -e "   Error color: ${AUX_LOG_ERROR}This is error colored text${AUX_LOG_NC}"

echo "5. Testing aux_get_log_color function:"
echo -n "   Info color via function: "
echo -e "$(aux_get_log_color "info")This is info via function${AUX_LOG_NC}"
echo -n "   Warning color via function: "
echo -e "$(aux_get_log_color "warn")This is warning via function${AUX_LOG_NC}"

echo "6. Testing col_get_semantic function directly:"
echo -n "   Info color via col function: "
echo -e "$(col_get_semantic "info")This is info via col function${COL_RESET}"

echo "Test completed!"
