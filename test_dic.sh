#!/bin/bash

# Set up test environment for DIC by sourcing proper config
source cfg/env/site1

echo "Test environment set up:"
echo "CLUSTER_NODES: ${CLUSTER_NODES[*]}"
echo "x2_NODE_PCI0: $x2_NODE_PCI0"

# Test the DIC system
echo ""
echo "Testing DIC system:"
# Source the script instead of executing it to preserve environment
OPS_DEBUG=1 bash src/dic/ops pve vck 100