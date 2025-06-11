#!/bin/bash

# DIC Integration Test - Complete Functionality Test
echo "============================================================================"
echo "DIC SYSTEM COMPREHENSIVE INTEGRATION TEST"
echo "============================================================================"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo

# Initialize environment
cd /home/es/lab
source bin/ini

# Setup test variables for current hostname
hostname_short=$(hostname | cut -d'.' -f1)
echo "Setting up test environment for hostname: $hostname_short"

# Export test variables
export "${hostname_short}_NODE_PCI0"="0000:01:00.0"
export "${hostname_short}_NODE_PCI1"="0000:01:00.1" 
export "${hostname_short}_CORE_COUNT_ON"="8"
export "${hostname_short}_CORE_COUNT_OFF"="4"
export PVE_CONF_PATH_QEMU="/etc/pve/qemu-server"
export CLUSTER_NODES=("x1" "x2")

echo "Test variables set:"
echo "  ${hostname_short}_NODE_PCI0 = 0000:01:00.0"
echo "  ${hostname_short}_NODE_PCI1 = 0000:01:00.1"
echo "  PVE_CONF_PATH_QEMU = /etc/pve/qemu-server"
echo

# Test 1: Core functionality
echo "TEST 1: DIC Core Functionality"
echo "----------------------------------------"
echo "Help system:"
src/dic/ops --help 2>/dev/null | head -3
echo
echo "Module listing:"
src/dic/ops --list 2>/dev/null
echo

# Test 2: Utility functions
echo "TEST 2: Utility Functions (No injection needed)"
echo "----------------------------------------"
echo "PVE utilities:"
src/dic/ops pve fun 2>/dev/null | head -3
echo

# Test 3: Parameter injection
echo "TEST 3: Parameter Injection with Debug"
echo "----------------------------------------"
echo "Testing pve_vpt function with complete parameter injection:"
echo "Command: OPS_DEBUG=1 src/dic/ops pve vpt 100 on"
echo
OPS_DEBUG=1 src/dic/ops pve vpt 100 on 2>&1
echo

# Test 4: Simpler function test
echo "TEST 4: Simple Function Test"
echo "----------------------------------------"
echo "Testing sys_dpa function:"
echo "Command: src/dic/ops sys dpa -x"
echo
src/dic/ops sys dpa -x 2>&1
echo

echo "============================================================================"
echo "INTEGRATION TEST COMPLETED"
echo "============================================================================"
