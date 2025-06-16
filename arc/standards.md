# Documentation Standards

Comprehensive documentation standards and conventions for the Lab Environment Management System, ensuring consistency, maintainability, and professional quality across all project documentation.

## 🎯 Overview

This document establishes the foundational standards for all documentation within the Lab Environment Management System. These standards ensure consistency, maintainability, and accessibility across technical guides, API references, and operational documentation.

## 📚 Documentation Philosophy: Two Distinct Types

### README Files → **Orientation and Quick Start**
**Purpose**: Immediate understanding and actionability  
**Location**: In each directory (`directory/README.md`)  
**Audience**: Anyone encountering this directory for the first time

**Characteristics**:
- **Immediate orientation** - "What is this folder/component for?"
- **Quick start focus** - "How do I use this right now?"
- **Self-contained** - Doesn't assume prior knowledge of the system
- **Action-oriented** - Focused on "what can I do here?"
- **Scannable format** - Quick overview with bullet points and tables

**Content Focus**:
- Directory structure and file purposes
- Essential usage examples and commands
- Basic troubleshooting
- Links to comprehensive documentation

### Comprehensive Documentation → **Deep Understanding and Mastery**
**Purpose**: Complete workflows and detailed explanations  
**Location**: In `doc/` folder organized by audience  
**Audience**: Users seeking thorough understanding and advanced usage

**Characteristics**:
- **Deep understanding** - "Why does this work this way?"
- **Complete workflows** - End-to-end procedures
- **Educational focus** - Teaches concepts and principles
- **Cross-cutting coverage** - Spans multiple components
- **Reference quality** - Comprehensive and authoritative

**Content Focus**:
- Conceptual foundations and design principles
- Complete step-by-step procedures
- Advanced use cases and edge cases
- Integration patterns and troubleshooting
- Cross-references to related topics

### Documentation Relationship
**Learning Progression**:
1. **README** → "I understand what this is and can use it immediately"
2. **Comprehensive Docs** → "I understand how this works and can master it completely"

**Cross-Reference Pattern**:
- README files link to comprehensive docs for deep dives
- Comprehensive docs assume basic familiarity from README files

---

## 📝 Document Structure Requirements

### Mandatory Header Format

Every documentation file must include the filepath header:

```markdown
<!-- filepath: /relative/path/to/file.md -->
# Document Title

Brief description of the document's purpose and scope.

## 🎯 Overview (if applicable)

High-level summary of contents and objectives.
```

### Required Sections

All documentation must include:
- **Document title** with clear, descriptive heading
- **Purpose statement** explaining what the document covers
- **Overview section** for complex documents
- **Navigation footer** linking to parent directories

## ✍️ Writing Guidelines

### Language and Style
- **Professional but approachable**: Technical accuracy without intimidation
- **Active voice**: "Configure the system" rather than "The system should be configured"
- **Direct and concise**: Eliminate unnecessary words
- **Inclusive language**: Use terms accessible to all skill levels

### Technical Conventions
- **Code and filenames**: Use backticks: `filename.md`, `function_name()`
- **Commands**: Use code blocks with language specification
- **Emphasis**: Use **bold** for important concepts, *italics* for emphasis
- **Lists**: Use bullet points for unordered items, numbers for sequential steps

### Visual Organization
- **Emojis for sections**: Use consistent emoji patterns for easy scanning
- **Hierarchical structure**: Clear heading hierarchy (H1 → H2 → H3)
- **Consistent formatting**: Uniform approach to code blocks, lists, and emphasis

## 📋 Document Templates

### README File Template
```markdown
<!-- filepath: /path/to/README.md -->
# Directory Name (`directory/`)

## 📋 Overview
[What this directory/component does - 1-2 sentences]

## 🗂️ Directory Structure / Key Files
[List of files/subdirs with brief purpose]
- `file1` - Purpose and basic usage
- `file2` - Purpose and basic usage
- `subdir/` - What this subdirectory contains

## 🚀 Quick Start
[Essential commands to get started immediately]
```bash
# Basic usage example
command --option value
```

## 📊 Quick Reference
[Most common usage patterns in table format]

| Command | Purpose | Example |
|---------|---------|---------|
| `cmd1` | Basic operation | `cmd1 --flag` |
| `cmd2` | Advanced operation | `cmd2 param` |

## 🔗 Related Documentation
[Links to comprehensive docs for deeper understanding]
- [Component Guide](../doc/category/component.md) - Complete workflows
- [Architecture Overview](../doc/dev/architecture.md) - Design principles
```

### Comprehensive Documentation Template
```markdown
<!-- filepath: /home/es/lab/doc/category/topic.md -->
# Topic Title

[What this document covers and who should read it]

## 🎯 Overview
[High-level summary and learning objectives]

## 🏗️ Concepts & Architecture
[How things work and why they're designed this way]

### Key Concepts
[Fundamental ideas and terminology]

### Design Patterns
[Architectural decisions and patterns used]

## 🔧 Complete Procedures
[Step-by-step workflows with examples]

### Basic Workflow
[Standard procedure with all steps]

### Advanced Usage
[Complex scenarios and edge cases]

## 🔍 Reference & Troubleshooting
[Quick reference tables, common issues, solutions]

### Configuration Reference
[Complete parameter listings]

### Common Issues
[Problem-solution pairs]

## 🔗 Related Topics
[Cross-references to other documentation]

---

**Navigation**: Return to [Parent](../README.md) | [Main](../../README.md)
```

### Content Guidelines by Documentation Type

#### README Files - DO Include:
- **Immediate purpose and context** - What is this directory for?
- **Directory structure overview** - What files/folders are here?
- **File-by-file descriptions** - Brief purpose of each component
- **Essential usage examples** - Copy-paste ready commands
- **Quick start instructions** - Get running immediately
- **Basic troubleshooting** - Common issues and quick fixes
- **Links to detailed docs** - Where to go for more information

#### README Files - DON'T Include:
- **Deep architectural explanations** - Save for comprehensive docs
- **Complete workflows** - Only essential steps
- **Complex troubleshooting** - Advanced scenarios go in comprehensive docs
- **Design philosophy** - Architectural decisions belong in design docs
- **Cross-component integration** - Complex interactions go in comprehensive docs

#### Comprehensive Docs - DO Include:
- **Conceptual foundations** - Why things work this way
- **Complete step-by-step procedures** - Full workflows with all details
- **Design principles and decisions** - Architectural reasoning
- **Advanced use cases and edge cases** - Complex scenarios
- **Integration patterns** - How components work together
- **Comprehensive troubleshooting** - Detailed problem-solving
- **Best practices and standards** - How to do things right
- **Cross-references** - Links to related concepts and procedures

#### Comprehensive Docs - DON'T Include:
- **Basic "what is this" orientation** - That belongs in README files
- **Simple copy-paste commands** - Without proper context and explanation
- **Directory-specific file listings** - That's README content
- **Redundant quick-start info** - Avoid duplicating README content

### Legacy Document Template

### Standard Document Template
```markdown
<!-- filepath: /path/to/document.md -->
# Document Title

Brief description explaining what this document covers and who should read it.

## 🎯 Overview

High-level summary of the document's purpose and key takeaways.

## 📋 Prerequisites (if applicable)

- Required knowledge or setup
- Dependencies that must be met
- Assumptions about reader's context

## 🚀 Main Content Sections

### Primary Topic 1

Detailed explanation with examples and practical guidance.

## 💡 Examples and Use Cases

Practical examples that readers can follow and adapt.

## 🔧 Troubleshooting (if applicable)

Common issues and their solutions.

## 📚 Related Documentation

Links to complementary documents and resources.

---

**Navigation**: Return to [Parent](../README.md) | [Main](../../README.md)
```

### Technical Reference Template
```markdown
<!-- filepath: /path/to/technical-doc.md -->
# Technical Component Reference

Technical reference for [specific component/system].

## 🎯 Overview

Purpose and scope of the technical component.

## 🏗️ Architecture

High-level architectural overview and design decisions.

## 📋 API Reference (if applicable)

### Functions/Methods

#### `function_name(parameters)`
- **Purpose**: What the function does
- **Parameters**: 
  - `param1`: Description
  - `param2`: Description
- **Returns**: What it returns
- **Example**: Code example

## 💻 Usage Examples

Practical implementation examples.

## 🔧 Configuration

Configuration options and setup instructions.

---

**Navigation**: Return to [Parent](../README.md) | [Main](../../README.md)
```

## 🔍 Quality Standards

### Content Quality
- **Accuracy**: All technical information must be current and tested
- **Completeness**: Cover all necessary aspects of the topic
- **Clarity**: Explanations should be understandable by the target audience
- **Examples**: Include practical, working examples where applicable

### Maintenance Standards
- **Regular updates**: Keep documentation current with system changes
- **Version tracking**: Document major changes and their impact
- **Link validation**: Ensure all internal and external links work
- **Automated generation**: Use tools like `doc-hub` for index maintenance

## 🛠️ Documentation Tools

### Automated Documentation
- **`utl/doc-hub`**: Updates documentation index automatically
- **`lib/gen/aux` (ana_lad)**: Documentation discovery and categorization
- **`utl/doc-func`**: Function metadata table generation
- **`utl/doc-stats`**: Codebase statistics and metrics

### Documentation Creation
- **[Documentation Creation Metaprompt](metaprompt.md)**: Comprehensive guide for creating new documentation using AI assistants and established patterns

### Manual Documentation
- Follow templates for consistency
- Use established emoji patterns for visual organization
- Maintain clear hierarchical structure
- Include practical examples and use cases

## 📊 Documentation Categories

### Audience-Based Organization
- **📋 Core**: Standards, architecture, foundational documents
- **👨‍💻 Developer**: Technical guides, API references, integration docs
- **🛠️ Admin**: Operations, configuration, system management
- **🏗️ Infrastructure**: IaC, deployment, environment management
- **📱 CLI**: Command-line guides, user interaction documentation

## 🔄 Review and Approval Process

### Documentation Review Criteria
1. **Technical accuracy**: Information is correct and current
2. **Standard compliance**: Follows established formatting and structure
3. **Clarity**: Target audience can understand and use the information
4. **Completeness**: Covers all necessary aspects of the topic
5. **Examples**: Includes working, practical examples

### Update Process
1. Identify documentation needs or changes
2. Draft updates following templates and standards
3. Review for technical accuracy and clarity
4. Update automated indices using `doc-hub`
5. Validate all links and references

---

**Navigation**: Return to [Core Documentation](README.md) | [Documentation Hub](../README.md) | [Main](../../README.md)
