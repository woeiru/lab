#!/bin/bash
cd /home/es/lab
source ./cfg/core/ric
source ./cfg/core/rdc  
source ./lib/core/ver

echo "Testing verify_var with REGISTERED_FUNCTIONS..."
verify_var "REGISTERED_FUNCTIONS"
echo "Exit code: $?"

echo "Array contents:"
declare -p REGISTERED_FUNCTIONS
