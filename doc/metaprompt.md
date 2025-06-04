# Documentation Standard & AI Guide

**Single unified standard for creating documentation in the Lab Environment Management System.**  
*For both AI assistants and human writers.*

## 🎯 Simple Usage

**For AI Assistants**: 
```
Create documentation for [COMPONENT/PATH] using this Lab Environment Management System standard. 
Follow the patterns and templates defined below.
```

**For Humans**: Use the templates and guidelines below to maintain consistency.

## 📋 Project Context

**System Type**: Infrastructure automation and environment management platform  
**Architecture**: Modular, hierarchical design with domain-oriented organization  
**Key Patterns**: 
- Pure functions (`lib/`) - Stateless, parameterized
- Wrapper functions (`src/mgt/`) - Environment integration  
- Deployment scripts (`src/set/`) - Initial setup automation
- Hierarchical config (`cfg/`) - Base → environment → node overrides

---

## 📖 Two Documentation Types

### README Files → **Quick Start & Orientation**
**Purpose**: Immediate understanding and basic usage  
**Location**: In each directory (`directory/README.md`)

```markdown
<!-- filepath: /path/to/README.md -->
# Directory Name (`dir/`)

## 📋 Overview
[What this directory/component does - 1-2 sentences]

## 🗂️ Directory Structure / Key Files
[List of files/subdirs with brief purpose]

## 🚀 Quick Start
[Essential commands to get started]

## 📊 Quick Reference  
[Most common usage patterns]

## 🔗 Related Documentation
[Links to comprehensive docs if needed]
```

### Comprehensive Docs → **Deep Understanding & Mastery**
**Purpose**: Complete workflows and detailed explanations  
**Location**: In `doc/` folder organized by audience

```markdown
<!-- filepath: /home/es/lab/doc/category/topic.md -->
# Topic Title

[What this document covers and who should read it]

## 🎯 Overview
[High-level summary and objectives]

## 🏗️ Concepts & Architecture
[How things work and why they're designed this way]

## 🔧 Complete Procedures
[Step-by-step workflows with examples]

## 🔍 Reference & Troubleshooting
[Quick reference tables, common issues, solutions]

## 🔗 Related Topics
[Cross-references to other documentation]
```

---

## 🎨 Universal Standards

### File Header (Always Required)
```markdown
<!-- filepath: /relative/path/to/file.md -->
# Document Title

Brief description of what this document covers.
```

### Visual Patterns
- **Section emojis**: 🎯 📋 🗂️ 🚀 📊 🔗 🏗️ 🔧 🔍 🧪
- **Code formatting**: Use backticks for `filenames`, `functions()`, `commands`
- **Emphasis**: **Bold** for key concepts, *italics* for emphasis
- **Structure**: H1 (title) → H2 (sections) → H3 (subsections)

### Language Style
- **Direct and actionable**: "Configure the system" not "The system can be configured"
- **Professional but accessible**: Technical accuracy without intimidation
- **Practical focus**: Include working examples and real commands

---

## 🏗️ Directory-Specific Patterns

### `lib/` (Library Functions)
**README**: List available functions, basic usage examples  
**Comprehensive**: Function signatures, parameters, integration patterns, design principles

### `src/` (Source Code) 
**README**: What scripts do, how to run them, directory overview  
**Comprehensive**: Complete deployment workflows, automation procedures

### `cfg/` (Configuration)
**README**: What config files exist, basic descriptions  
**Comprehensive**: Configuration hierarchy, environment management, override patterns

### `bin/` (Executables)
**README**: What executables do, basic usage, initialization flow  
**Comprehensive**: System architecture, component orchestration, troubleshooting

---

## ✅ Quality Checklist

**Every document must have:**
- [ ] Correct filepath header
- [ ] Clear purpose statement  
- [ ] Appropriate template (README vs comprehensive)
- [ ] Working code examples
- [ ] Proper emoji section headers
- [ ] Cross-references where relevant

**README specific:**
- [ ] Immediate orientation ("what is this?")
- [ ] Quick start commands
- [ ] File/directory listings with purpose
- [ ] No deep architectural explanations

**Comprehensive docs specific:**
- [ ] Conceptual explanations ("why/how")
- [ ] Complete step-by-step procedures
- [ ] Advanced scenarios and troubleshooting
- [ ] Integration with other components

---

*This standard ensures consistency while keeping documentation creation simple for both AI assistants and human writers.*
