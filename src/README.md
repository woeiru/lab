# 📁 Source C| [`set/`](#srcset---deployment--initial-setup) | Deployment & Initial Setup | Ba- **Self-Sufficient**: Each script sources `lib/laz/src` directly, no initialization required
- **Hostname-Based Naming**: Files correspond to actual infrastructure hostnames
- **Section Organization**: Functions named with patterns like `a_xall`, `b_xall` for logical grouping
- **Interactive Framework**: Built-in menu system via `lib/laz/src` for guided deploymentMulti-node Operations | Self-sufficient via `lib/laz/src` |de (`src/`) - Infrastructure Management Scripts

[![Infrastructure](https://img.shields.io/badge/Type-Infrastructure%20Management-blue)](#) [![Bash](https://img.shields.io/badge/Language-Bash-green)](#) [![Environment](https://img.shields.io/badge/Environment-Multi--Site-orange)](#)

## 🎯 Purpose

The `src/` directory contains the operational source code for infrastructure management, providing two distinct operational paradigms: **immediate runtime control** (`mgt/`) and **initial deployment automation** (`set/`). This directory represents the active execution layer of the infrastructure management system.

## 📋 Quick Contents Overview

| Directory | Purpose | Usage Pattern | Dependencies |
|-----------|---------|---------------|--------------|
| [`mgt/`](#srcmgt---runtime-infrastructure-control) | Runtime Infrastructure Control | Interactive/Individual Operations | Requires `bin/init` environment |
| [`set/`](#srcset---deployment--initial-setup) | Deployment & Initial Setup | Batch/Multi-node Operations | Self-sufficient via `lib/aux/src` |
| [`too/`](#srctoo---specialized-tools) | Specialized Tools | Specific Use Cases | Varies by tool |

---

## 🔧 `src/mgt/` - Runtime Infrastructure Control

### **Architecture: Wrapper Pattern for Immediate Operations**

The `mgt/` (management) directory implements a **wrapper function architecture** designed for spontaneous infrastructure administration tasks. Each function in `lib/ops/` receives a corresponding `-w` (wrapper) function that handles global variable extraction and environment-specific operations.

```bash
# Architecture Flow
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Admin CLI     │ -> │  Wrapper (-w)    │ -> │  Pure Function  │
│   Commands      │    │  src/mgt/*       │    │  lib/ops/*      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                v
                       ┌──────────────────┐
                       │  Global Config   │
                       │  Environment     │
                       │  (bin/init)      │
                       └──────────────────┘
```

### **Key Characteristics**

- **Environment Dependent**: Requires `bin/init` initialization and configuration hierarchy
- **Global Variable Extraction**: Wrappers resolve site-specific variables automatically
- **One-to-One Mapping**: Each `lib/ops/` function gets exactly one wrapper function
- **Immediate Operations**: Perfect for day-to-day operational tasks and troubleshooting

### **Files in `src/mgt/`**

| File | Purpose | Key Functions | Related Lib Module |
|------|---------|---------------|-------------------|
| **`gpu`** | GPU Passthrough Management | `gpu-*-w` functions | [`lib/ops/gpu`](../lib/ops/gpu) |
| **`pve`** | Proxmox VE Operations | `pve-*-w` functions | [`lib/ops/pve`](../lib/ops/pve) |

### **Usage Examples**

```bash
# Initialize environment (required for mgt/ scripts)
source bin/init

# GPU passthrough operations
./src/mgt/gpu-vpt-w 100 on    # Enable GPU passthrough for VM 100
./src/mgt/gpu-vck-w 101       # Check GPU configuration for VM 101

# Proxmox VE operations  
./src/mgt/pve-vst-w 102       # Check VM status
./src/mgt/pve-vcr-w newvm     # Create new VM with site-specific config
```

---

## 🚀 `src/set/` - Deployment & Initial Setup

### **Architecture: Self-Contained Section-Based Deployment**

The `set/` (setup) directory implements a **section-based deployment architecture** designed for initial infrastructure setup and multi-node deployment operations. Each script is named after a hostname and contains organized sections that can be executed individually or interactively.

```bash
# Architecture Flow - Self-Sufficient Pattern
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Deployment     │ -> │   Hostname       │ -> │  Section-Based  │
│  Command        │    │   Script         │    │  Functions      │
│                 │    │  src/set/w1      │    │  a_xall, b_xall │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                v
                       ┌──────────────────┐
                       │   lib/laz/src    │
                       │  (Auto-sourced)  │
                       │  Interactive UI  │
                       └──────────────────┘
```

### **Key Characteristics**

- **Self-Sufficient**: Each script sources `lib/aux/src` directly, no initialization required
- **Hostname-Based Naming**: Files correspond to actual infrastructure hostnames
- **Section Organization**: Functions named with patterns like `a_xall`, `b_xall` for logical grouping
- **Interactive Framework**: Built-in menu system via `lib/aux/src` for guided deployment
- **Multi-Node Capable**: Designed for remote execution and batch operations

### **Files in `src/set/`**

| File | Hostname | Purpose | Key Sections |
|------|----------|---------|--------------|
| **`w1`** | Workstation 1 | Primary workstation setup | `a_xall` (repo setup), `b_xall` (packages), `c_xall` (networking) |
| **`c1`** | Container 1 | Container host setup | `a_xall` (NFS), `b_xall` (services), `c_xall` (users) |
| **`c2`** | Container 2 | Secondary container host | Similar to c1 with environment-specific variations |
| **`c3`** | Container 3 | Tertiary container host | Similar to c1 with environment-specific variations |
| **`t1`** | Test Node 1 | Development/testing setup | Test-specific deployment sections |
| **`t2`** | Test Node 2 | Secondary test node | Test-specific deployment sections |

### **Section Naming Convention**

```bash
# Standard section pattern
a_xall()  # Primary setup (repositories, basic config)
b_xall()  # Package installation and services
c_xall()  # Network configuration and connectivity
d_xall()  # SSH keys and authentication
i_xall()  # Storage setup (Btrfs, RAID)
j_xall()  # Advanced storage (ZFS datasets)
p_xall()  # Container templates
q_xall()  # Container creation
r_xall()  # Container configuration
s_xall()  # Virtual machine setup
```

### **Usage Examples**

```bash
# Interactive deployment menu
./src/set/w1 -i

# Direct section execution
./src/set/c1 -x a_xall     # Execute NFS server setup
./src/set/w1 -x b_xall     # Execute package installation

# Multi-node deployment via sys-sca
sys-sca usr all SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/w1 -x a_xall"
```

### **Integration with Multi-Node Operations**

The `set/` scripts are specifically designed to work with the `sys-sca` function from [`lib/ops/sys`](../lib/ops/sys) for simultaneous multi-node deployment:

```bash
# Deploy section 'a' across all workstation nodes
sys-sca usr ws SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/w1 -x a_xall"

# Deploy section 'b' across container nodes  
sys-sca usr ct SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/c1 -x b_xall"
```

---

## 🔨 `src/too/` - Specialized Tools

### **Purpose**

Contains specialized tools and utilities that don't fit the standard `mgt/` or `set/` patterns. These are purpose-built solutions for specific infrastructure needs.

### **Contents**

| Directory | Purpose | Usage |
|-----------|---------|-------|
| **`acpi/`** | ACPI Power Management | Device wake configuration, systemd services |
| **`replace/`** | File Replacement Utilities | Template processing, configuration updates |

---

## 🔗 Integration with Core System

### **Relationship to Core Libraries**

```bash
# Dependencies Flow
src/mgt/* 
├── Requires: bin/init (environment initialization)
├── Uses: lib/ops/* (pure functions)
└── Accesses: cfg/env/* (site configurations)

src/set/*
├── Sources: lib/aux/src (interactive framework)
├── Uses: lib/ops/* (direct function calls)
└── Self-manages: Configuration loading and variable resolution
```

### **Configuration Integration**

- **`src/mgt/`**: Leverages the full configuration hierarchy via `bin/init`
- **`src/set/`**: Automatically loads configuration through `lib/aux/src`
- **Both**: Access site-specific variables from `cfg/env/site*` files

---

## 🎛️ Usage Patterns

### **Operational Control Pattern (`src/mgt/`)**

```bash
# 1. Initialize environment
source bin/init

# 2. Execute wrapper functions with automatic variable resolution
pve-vpt-w 100 on     # Variables like NODE_PCI0 resolved automatically
gpu-vck-w 101        # Site-specific GPU configurations applied
```

### **Deployment Pattern (`src/set/`)**

```bash
# 1. Interactive deployment
./src/set/w1 -i
# > Select sections from menu
# > Execute with guided prompts

# 2. Direct section execution
./src/set/c1 -x a_xall

# 3. Multi-node batch deployment
sys-sca usr all SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/w1 -x b_xall"
```

---

## 🔄 Architectural Benefits

### **Separation of Concerns**

| Aspect | `src/mgt/` | `src/set/` |
|--------|------------|------------|
| **Purpose** | Runtime operations | Initial deployment |
| **Dependencies** | Environment-dependent | Self-sufficient |
| **Variable Resolution** | Global environment | Auto-loading |
| **Use Case** | Individual admin tasks | Batch deployment |
| **Testing** | Pure functions testable | Sections testable |

### **Design Principles**

1. **Operational Flexibility**: Two distinct patterns for different operational needs
2. **Environment Isolation**: `mgt/` for environment-aware, `set/` for self-contained
3. **Scalability**: `set/` enables multi-node operations, `mgt/` enables rapid iteration
4. **Maintainability**: Clear separation between immediate control and deployment automation
5. **Testability**: Pure functions in `lib/ops/` can be tested independently

---

## 📚 Related Documentation

- [**Architecture Overview**](../doc/man/architecture.md) - Complete system architecture
- [**Configuration Management**](../doc/man/configuration.md) - Environment and site setup
- [**Library Operations**](../lib/README.md) - Core functionality modules
- [**Infrastructure Management**](../doc/man/infrastructure.md) - Infrastructure concepts
- [**Initiation Guide**](../doc/man/initiation.md) - Environment initialization

---

## 🚦 Quick Start

### **For Runtime Operations**

```bash
# 1. Initialize environment
source bin/init

# 2. Use management wrappers
./src/mgt/gpu         # List available GPU functions
./src/mgt/pve         # List available Proxmox functions
```

### **For Deployment Operations**

```bash
# 1. Interactive deployment
./src/set/w1 -i       # Guided deployment for workstation

# 2. Direct execution
./src/set/c1 -x a_xall # Direct NFS setup
```

---

## 🎯 Summary

The `src/` directory represents the **active execution layer** of the infrastructure management system, providing two complementary operational paradigms:

- **`mgt/`**: Environment-aware wrappers for immediate operational control
- **`set/`**: Self-sufficient deployment scripts for initial setup and multi-node operations

This dual approach ensures both rapid administrative response capabilities and systematic infrastructure deployment, supporting the complete lifecycle of infrastructure management from initial deployment through ongoing operations.

---

**Navigation**: Return to [Main Lab Documentation](../README.md)
