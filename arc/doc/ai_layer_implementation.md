# AI Layer Implementation - Concrete Examples

## 🎯 What the AI Layer Actually Looks Like

The AI layer sits **on top** of your existing metadata extraction tools, transforming structured data into human-readable documentation.

## 🔧 Implementation Architecture

```
Your Existing Tools (Data Layer)
    ↓
AI Processing Layer (Analysis & Generation)
    ↓
Documentation Output (Human-Readable)
```

## 📋 Concrete Implementation Examples

### Example 1: Function Documentation AI Layer

**Input**: JSON from your existing `ana_laf` tool
```json
{
  "functions": [
    {
      "name": "gpu_vck_w",
      "arguments": "vm_id",
      "shortname": "gpu vm check wrapper",
      "description": "Checks GPU passthrough status for a VM using wrapper pattern",
      "size": 15,
      "line": 42,
      "calls_functions": ["pve-gpu-vck"],
      "calls_generated": ["pve_gpu_vck"]
    }
  ]
}
```

**AI Processing Layer**:
```bash
#!/bin/bash
# File: utl/doc/ai_function_docs
# AI-powered function documentation generator

generate_function_docs() {
    local json_file="$1"
    local output_file="$2"
    
    # Extract function data using your existing tools
    local function_data=$(cat "$json_file")
    
    # AI prompt for function documentation
    local ai_prompt="Based on this function metadata:
$function_data

Generate comprehensive documentation following this project's patterns:
- Use DIC operations patterns from src/dic/
- Include practical usage examples
- Follow emoji conventions (🔧, 📋, etc.)
- Reference related functions and dependencies"

    # Call AI service (examples below)
    generate_with_ai "$ai_prompt" > "$output_file"
}
```

**Output**: Enhanced documentation
```markdown
## 🔧 GPU Management Functions

### `gpu_vck_w` - GPU VM Check Wrapper
**Purpose**: Checks GPU passthrough status for virtual machines with automatic environment integration.

**Usage**:
```bash
# Check GPU status for VM 101
gpu_vck_w 101

# Check multiple VMs
for vm in 101 102 103; do
    gpu_vck_w "$vm"
done
```

**Integration**: This wrapper automatically resolves site-specific variables and calls the pure function `pve_gpu_vck` with proper parameters.

**Related Functions**: `gpu_pta_w`, `gpu_ptd_w`, `pve_gpu_vck`
```

### Example 2: Directory Analysis AI Layer

**Input**: Directory structure from `find` + file analysis
```bash
# Your existing analysis tools provide this data:
Directory: /home/es/lab/lib/ops/gpu
Files: gpu (210 lines, 15 functions)
Purpose: GPU passthrough management
Dependencies: lib/gen/inf, lib/core/err
Usage patterns: Called by src/dic/ops
```

**AI Processing Layer**:
```bash
#!/bin/bash
# File: utl/doc/ai_directory_docs

analyze_directory() {
    local dir_path="$1"
    
    # Use your existing tools to gather data
    local function_count=$(ana_laf "$dir_path"/* | wc -l)
    local file_stats=$(ana_lad "$dir_path")
    local variable_usage=$(ana_acu -j cfg/env "$dir_path")
    
    # Create comprehensive prompt
    local ai_prompt="Analyze this directory:
Path: $dir_path
Function count: $function_count
File statistics: $file_stats
Variable usage: $variable_usage

Generate a README.md that:
1. Explains the directory's role in the infrastructure
2. Documents key files and their relationships
3. Provides practical usage examples
4. Links to related directories following project patterns"

    # Generate documentation
    generate_directory_readme "$ai_prompt" "$dir_path/README.md"
}
```

## 🤖 AI Service Integration Options

### Option 1: Local AI (Privacy-First)
```bash
#!/bin/bash
# Using Ollama with DeepSeek Coder

generate_with_ai() {
    local prompt="$1"
    
    # Call local Ollama API
    curl -s http://localhost:11434/api/generate \
        -d "{
            \"model\": \"deepseek-coder\",
            \"prompt\": \"$prompt\",
            \"stream\": false
        }" | jq -r '.response'
}
```

### Option 2: OpenAI Integration
```bash
#!/bin/bash
# Using OpenAI API

generate_with_ai() {
    local prompt="$1"
    
    curl -s https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"gpt-4\",
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$prompt\"
            }]
        }" | jq -r '.choices[0].message.content'
}
```

### Option 3: GitHub Copilot CLI Integration
```bash
#!/bin/bash
# Using GitHub Copilot CLI

generate_with_ai() {
    local prompt="$1"
    
    echo "$prompt" | gh copilot suggest --type shell
}
```

## 🔄 Complete Workflow Example

### Phase 1: Data Collection (Your Existing Tools)
```bash
#!/bin/bash
# File: utl/doc/ai_workflow

# Step 1: Generate all metadata using your existing tools
echo "Generating metadata..."
./utl/doc/run_all_doc.sh

# Step 2: Extract JSON data for AI processing
ana_laf -j lib/ops/gpu > .tmp/gpu_functions.json
ana_acu -j cfg/env lib/ops > .tmp/variable_usage.json
ana_lad -j lib/ops > .tmp/directory_structure.json
```

### Phase 2: AI Processing Layer
```bash
#!/bin/bash
# File: utl/doc/ai_processor

process_directory_with_ai() {
    local dir_path="$1"
    local dir_name=$(basename "$dir_path")
    
    # Collect all available data
    local context="Directory Analysis for: $dir_path

$(if [[ -f ".tmp/${dir_name}_functions.json" ]]; then
    echo "Functions:"
    cat ".tmp/${dir_name}_functions.json"
fi)

$(if [[ -f ".tmp/variable_usage.json" ]]; then
    echo "Variable Usage:"
    cat ".tmp/variable_usage.json"
fi)

$(if [[ -f ".tmp/directory_structure.json" ]]; then
    echo "Directory Structure:"
    cat ".tmp/directory_structure.json"
fi)

Existing Documentation Style Examples:
$(find doc -name "*.md" -exec head -20 {} \; | head -100)"

    # Generate documentation with AI
    local ai_prompt="Using the data above, generate a comprehensive README.md for the directory $dir_path.

Follow these requirements:
1. Use the same emoji conventions as existing docs (🔧, 📋, 🚀, etc.)
2. Include practical usage examples
3. Document file relationships and dependencies
4. Add navigation links to related directories
5. Follow the project's technical writing style

Focus on practical value for developers and system administrators."

    # Call AI service and save result
    generate_with_ai "$ai_prompt" > "$dir_path/README.md"
    
    echo "Generated README for $dir_path"
}
```

### Phase 3: Quality Assurance Layer
```bash
#!/bin/bash
# File: utl/doc/ai_qa

validate_ai_documentation() {
    local generated_readme="$1"
    
    # Check for required elements
    local checks=(
        "grep -q '## ' $generated_readme"  # Has sections
        "grep -q '```' $generated_readme"  # Has code examples
        "grep -q '🔧\|📋\|🚀' $generated_readme"  # Has emojis
        "grep -q '\[.*\](.*)' $generated_readme"  # Has links
    )
    
    local passed=0
    for check in "${checks[@]}"; do
        if eval "$check"; then
            ((passed++))
        fi
    done
    
    if [[ $passed -ge 3 ]]; then
        echo "✅ Quality check passed for $generated_readme"
        return 0
    else
        echo "❌ Quality check failed for $generated_readme"
        return 1
    fi
}
```

## 🎯 Practical Implementation Script

Here's a complete working example:

```bash
#!/bin/bash
# File: utl/doc/ai_doc_generator
# Complete AI documentation generator

set -e

# Configuration
LAB_DIR="${LAB_DIR:-/home/es/lab}"
AI_SERVICE="ollama"  # or "openai" or "copilot"
MODEL="deepseek-coder"

# AI service function
call_ai() {
    local prompt="$1"
    
    case "$AI_SERVICE" in
        "ollama")
            curl -s http://localhost:11434/api/generate \
                -d "{\"model\": \"$MODEL\", \"prompt\": \"$prompt\", \"stream\": false}" \
                | jq -r '.response'
            ;;
        "openai")
            curl -s https://api.openai.com/v1/chat/completions \
                -H "Authorization: Bearer $OPENAI_API_KEY" \
                -H "Content-Type: application/json" \
                -d "{\"model\": \"gpt-4\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}" \
                | jq -r '.choices[0].message.content'
            ;;
        *)
            echo "Unsupported AI service: $AI_SERVICE" >&2
            exit 1
            ;;
    esac
}

# Main function
generate_ai_docs() {
    local target_dir="$1"
    
    echo "🤖 Generating AI documentation for: $target_dir"
    
    # Step 1: Collect metadata using existing tools
    echo "📊 Collecting metadata..."
    mkdir -p .tmp/ai_analysis
    
    # Use your existing tools
    if [[ -d "$target_dir" ]]; then
        # Get function metadata if it's a code directory
        if find "$target_dir" -name "*.sh" -o -name "*" -type f | head -1 | grep -q .; then
            ana_laf -j "$target_dir"/* > .tmp/ai_analysis/functions.json 2>/dev/null || true
        fi
        
        # Get directory structure
        ana_lad -j "$target_dir" > .tmp/ai_analysis/structure.json 2>/dev/null || true
    fi
    
    # Step 2: Build comprehensive prompt
    local context="$(cat << EOF
You are documenting a directory in a sophisticated infrastructure management system.

Target Directory: $target_dir

$(if [[ -f ".tmp/ai_analysis/functions.json" ]]; then
    echo "Available Functions:"
    cat ".tmp/ai_analysis/functions.json"
fi)

$(if [[ -f ".tmp/ai_analysis/structure.json" ]]; then
    echo "Directory Structure:"
    cat ".tmp/ai_analysis/structure.json"
fi)

File Listing:
$(ls -la "$target_dir" 2>/dev/null || echo "Directory not accessible")

Example Documentation Style:
$(find "$LAB_DIR/doc" -name "README.md" -exec head -30 {} \; | head -50)

Generate a comprehensive README.md that:
1. Explains the directory's purpose and role
2. Documents key files and their functions  
3. Provides practical usage examples with bash commands
4. Uses emoji section headers (🔧, 📋, 🚀, etc.)
5. Includes navigation links to related directories
6. Follows the established technical writing style

Focus on practical value for developers and system administrators.
EOF
)"

    # Step 3: Generate documentation
    echo "🧠 Generating documentation with AI..."
    local generated_docs=$(call_ai "$context")
    
    # Step 4: Save and validate
    echo "$generated_docs" > "$target_dir/README.md"
    
    # Step 5: Quality check
    if validate_ai_documentation "$target_dir/README.md"; then
        echo "✅ Successfully generated README for $target_dir"
    else
        echo "⚠️  Generated README may need manual review"
    fi
}

# Usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <directory_path>"
        echo "Example: $0 lib/ops/gpu"
        exit 1
    fi
    
    generate_ai_docs "$1"
fi
```

## 🚀 Quick Start Commands

```bash
# Install Ollama (local AI)
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull deepseek-coder

# Create the AI documentation generator
cp /path/to/ai_doc_generator utl/doc/ai_doc_generator
chmod +x utl/doc/ai_doc_generator

# Generate documentation for a specific directory
./utl/doc/ai_doc_generator lib/ops/gpu

# Generate for all directories without READMEs
find . -type d -not -path "*/.*" -exec test ! -f {}/README.md \; -print | \
    while read dir; do ./utl/doc/ai_doc_generator "$dir"; done
```

## 🎯 Summary

The AI layer is essentially:
1. **Data Collection**: Your existing tools (`ana_laf`, `ana_acu`, `ana_lad`)
2. **Context Building**: Structured prompts with metadata + style examples
3. **AI Processing**: Local or cloud AI services for natural language generation
4. **Quality Assurance**: Automated validation of generated content
5. **Integration**: Seamless integration with your existing documentation workflow

The key is that the AI doesn't replace your excellent metadata tools - it enhances them by generating human-readable documentation from the structured data they provide.
