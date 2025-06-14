# 📁 Source Code (`src/`) - Infrastructure Management Scripts

[![Infrastructure](https://img.shields.io/badge/Type-Infrastructure%20Management-blue)](#) [![Bash](https://img.shields.io/badge/Language-Bash-green)](#) [![Environment](https://img.shields.io/badge/Environment-Multi--Site-orange)](#)

## 🎯 Purpose

The `src/` directory contains the operational source code for infrastructure management, providing distinct operational paradigms: **dependency injection operations** (`dic/`) and **initial deployment automation** (`set/`). This directory represents the active execution layer of the infrastructure management system.

## 📋 Quick Contents Overview

| Directory | Purpose | Usage Pattern | Dependencies |
|-----------|---------|---------------|--------------|
| [`dic/`](#srcdic---dependency-injection-operations) | Dependency Injection Operations | Unified Operations Interface | Requires DIC configuration |
| [`set/`](#srcset---deployment--initial-setup) | Deployment & Initial Setup | Batch/Multi-node Operations | Self-sufficient via `src/set/.menu` |

---

## 🔧 `src/dic/` - Dependency Injection Operations

### **Architecture: Unified Operations Interface**

The `dic/` (dependency injection container) directory provides a **unified operations interface** that has successfully replaced the legacy wrapper function architecture. This system provides streamlined infrastructure administration through a standardized dependency injection pattern.

```bash
# DIC Architecture Flow
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Admin CLI     │ -> │  DIC Operations  │ -> │  Pure Functions │
│   Commands      │    │  src/dic/ops     │    │  lib/ops/*      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                v
                       ┌──────────────────┐
                       │  DIC Container   │
                       │  Configuration   │
                       │  (src/dic/config)│
                       └──────────────────┘
```

### **Key Characteristics**

- **Configuration Driven**: Uses DIC container configuration for dependency resolution
- **Unified Interface**: Single operations interface across all infrastructure functions  
- **Type-Safe Operations**: Strongly typed function parameters and return values
- **Production Ready**: Optimized for reliability and performance

### **Files in `src/dic/`**

| File | Purpose | Key Functions | Documentation |
|------|---------|---------------|---------------|
| **`ops`** | Main Operations Interface | All infrastructure operations | [`dic/README.md`](dic/README.md) |
| **`config/`** | DIC Configuration | Container setup and dependencies | Configuration documentation |

### **Usage Examples**

```bash
# DIC operations (no environment initialization required)
source src/dic/ops

# GPU passthrough operations
ops gpu passthrough enable 100   # Enable GPU passthrough for VM 100
ops gpu check 101               # Check GPU configuration for VM 101

# Proxmox VE operations  
ops pve vm status 102           # Check VM status
ops pve vm create newvm         # Create new VM with configuration
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
│                 │    │  src/set/h1      │    │  a_xall, b_xall │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                v
                       ┌──────────────────┐
                       │   src/set/.menu  │
                       │  (Auto-sourced)  │
                       │  Interactive UI  │
                       └──────────────────┘
```

### **Key Characteristics**

- **Self-Sufficient**: Each script sources `src/set/.menu` directly, no initialization required
- **Hostname-Based Naming**: Files correspond to actual infrastructure hostnames
- **Section Organization**: Functions named with patterns like `a_xall`, `b_xall` for logical grouping
- **Interactive Framework**: Built-in menu system via `src/set/.menu` for guided deployment
- **Multi-Node Capable**: Designed for remote execution and batch operations

### **Files in `src/set/`**

| File | Hostname | Purpose | Key Sections |
|------|----------|---------|--------------|
| **`h1`** | Hypervisor 1 | Primary hypervisor setup | `a_xall` (repo setup), `b_xall` (packages), `c_xall` (networking) |
| **`c1`** | Container 1 | Container host setup | `a_xall` (NFS), `b_xall` (services), `c_xall` (users) |
| **`c2`** | Container 2 | Secondary container host | Similar to c1 with environment-specific variations |
| **`c3`** | Container 3 | Tertiary container host | Similar to c1 with environment-specific variations |
| **`t1`** | Test Node 1 | Development/testing setup | Test-specific deployment sections |
| **`t2`** | Test Node 2 | Secondary test node | Test-specific deployment sections |

### **Section Naming Convention**

> **Section Naming Convention**
>
> Each `src/set/` script organizes its deployment logic into *sections*, implemented as Bash functions with names like `a_xall`, `b_xall`, etc. The specific sections and their purposes can vary between files, depending on the needs of each host or deployment scenario. This flexible pattern allows each script to group related setup steps logically (e.g., repositories, packages, networking, storage, containers, VMs), but the exact set and order of sections is not fixed—it's tailored to the requirements of each environment.
>
> Typical examples:
>
> ```bash
> # Example section pattern (actual sections may differ per script)
> a_xall()  # Primary setup (e.g., repositories, basic config)
> b_xall()  # Package installation and services
> c_xall()  # Network configuration
> d_xall()  # SSH keys and authentication
> # ...additional sections as needed...
> ```
>
> This approach ensures scripts remain organized and maintainable, while allowing for host-specific customization.
```

### **Usage Examples**

```bash
# Interactive deployment menu
./src/set/h1 -i

# Direct section execution
./src/set/c1 -x a_xall     # Execute NFS server setup
./src/set/h1 -x b_xall     # Execute package installation

# Multi-node deployment via sys-sca
sys-sca usr all SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/h1 -x a_xall"
```

### **Integration with Multi-Node Operations**

The `set/` scripts are specifically designed to work with the `sys-sca` function from [`lib/ops/sys`](../lib/ops/sys) for simultaneous multi-node deployment:

```bash
# Deploy section 'a' across all hypervisor nodes
sys-sca usr hy SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/h1 -x a_xall"

# Deploy section 'b' across container nodes  
sys-sca usr ct SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/c1 -x b_xall"
```

---

## 🔨 `src/too/` - Specialized Tools

### **Purpose**

Contains specialized tools and utilities that don't fit the standard operational patterns. These are purpose-built solutions for specific infrastructure needs.

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
src/dic/* 
├── Uses: src/dic/config/* (DIC configuration)
├── Uses: lib/ops/* (pure functions)
└── Accesses: cfg/env/* (site configurations)

src/set/*
├── Sources: src/set/.menu (interactive framework)
├── Uses: lib/ops/* (direct function calls)
└── Self-manages: Configuration loading and variable resolution
```

### **Configuration Integration**

- **`src/dic/`**: Uses DIC container configuration for dependency injection
- **`src/set/`**: Automatically loads configuration through `src/set/.menu`
- **Both**: Access site-specific variables from `cfg/env/site*` files

---

## 🎛️ Usage Patterns

### **DIC Operations Pattern (`src/dic/`)**

```bash
# 1. Source DIC operations
source src/dic/ops

# 2. Execute operations through unified interface
ops pve vm start 100         # Start VM with automatic configuration resolution
ops gpu passthrough 101      # Configure GPU passthrough with site-specific settings
```

### **Deployment Pattern (`src/set/`)**

```bash
# 1. Interactive deployment
./src/set/h1 -i
# > Select sections from menu
# > Execute with guided prompts

# 2. Direct section execution
./src/set/c1 -x a_xall

# 3. Multi-node batch deployment
sys-sca usr all SSH_USERS ALL_IP_ARRAYS ARRAY_ALIASES "./src/set/h1 -x b_xall"
```

---

## 🔄 Architectural Benefits

### **Separation of Concerns**

| Aspect | `src/dic/` | `src/set/` |
|--------|------------|------------|
| **Purpose** | Unified operations | Initial deployment |
| **Dependencies** | DIC configuration | Self-sufficient |
| **Variable Resolution** | Dependency injection | Auto-loading |
| **Use Case** | All admin tasks | Batch deployment |
| **Testing** | Type-safe operations | Sections testable |

### **Design Principles**

1. **Operational Unification**: Single interface for all operational needs
2. **Dependency Injection**: Clean separation of concerns through DIC pattern
3. **Scalability**: Both patterns enable efficient operations at scale
4. **Maintainability**: Clear separation between operations and deployment automation
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
# 1. Source DIC operations
source src/dic/ops

# 2. Use unified operations interface
ops gpu list          # List available GPU functions
ops pve list          # List available Proxmox functions
```

### **For Deployment Operations**

```bash
# 1. Interactive deployment
./src/set/h1 -i       # Guided deployment for hypervisor

# 2. Direct execution
./src/set/c1 -x a_xall # Direct NFS setup
```

---

## 🎯 Summary

The `src/` directory represents the **active execution layer** of the infrastructure management system, providing two complementary operational paradigms:

- **`dic/`**: Unified dependency injection operations for all infrastructure control
- **`set/`**: Self-sufficient deployment scripts for initial setup and multi-node operations

This dual approach ensures both efficient operational control through a standardized interface and systematic infrastructure deployment, supporting the complete lifecycle of infrastructure management from initial deployment through ongoing operations.

---

**Navigation**: Return to [Main Lab Documentation](../README.md)
