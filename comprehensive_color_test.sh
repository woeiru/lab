#!/bin/bash
# Comprehensive test for aux and col integration

echo "=== Comprehensive Color Integration Test ==="

echo
echo "1. Testing without col module (fallback mode):"
unset COL_LOADED
source /home/es/lab/lib/gen/aux

echo "   AUX_LOADED: ${AUX_LOADED:-not set}"
echo "   COL_LOADED: ${COL_LOADED:-not set}"
echo -e "   Fallback color test: ${AUX_LOG_INFO}Info${AUX_LOG_NC} ${AUX_LOG_WARN}Warning${AUX_LOG_NC} ${AUX_LOG_ERROR}Error${AUX_LOG_NC}"
echo -n "   aux_get_log_color test: "
echo -e "$(aux_get_log_color "info")Info via function${AUX_LOG_NC}"

echo
echo "2. Testing with col module (integrated mode):"
# Fresh start - unset the AUX_LOADED to allow re-sourcing
unset AUX_LOADED

# Source col first
source /home/es/lab/lib/core/col
echo "   COL_LOADED: ${COL_LOADED:-not set}"

# Then source aux
source /home/es/lab/lib/gen/aux
echo "   AUX_LOADED: ${AUX_LOADED:-not set}"

echo -e "   Integrated color test: ${AUX_LOG_INFO}Info${AUX_LOG_NC} ${AUX_LOG_WARN}Warning${AUX_LOG_NC} ${AUX_LOG_ERROR}Error${AUX_LOG_NC}"
echo -n "   aux_get_log_color test: "
echo -e "$(aux_get_log_color "info")Info via function${AUX_LOG_NC}"
echo -n "   col_get_semantic test: "
echo -e "$(col_get_semantic "info")Info via col function${COL_RESET}"

echo
echo "3. Testing color consistency:"
col_info=$(col_get_semantic "info")
aux_info=$(aux_get_log_color "info")
if [[ "$col_info" == "$aux_info" ]]; then
    echo "   ✅ Color consistency: PASS - Both functions return the same color"
else
    echo "   ❌ Color consistency: FAIL - Colors differ"
    echo "     col_get_semantic: '$col_info'"
    echo "     aux_get_log_color: '$aux_info'"
fi

echo
echo "4. Testing backward compatibility aliases:"
echo "   AUX_LOG_INFO from col: '$AUX_LOG_INFO'"
echo "   COL_INFO direct: '$COL_INFO'"
if [[ "$AUX_LOG_INFO" == "$COL_INFO" ]]; then
    echo "   ✅ Backward compatibility: PASS"
else
    echo "   ❌ Backward compatibility: FAIL"
fi

echo
echo "5. Testing specialized logging functions:"
echo -n "   aux_info: "; aux_info "Test info message"
echo -n "   aux_warn: "; aux_warn "Test warning message"
echo -n "   aux_err: "; aux_err "Test error message"

echo
echo "=== Test completed ==="
