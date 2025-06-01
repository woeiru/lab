#!/bin/bash
#######################################################################
# Directory README Generator - Template Application Script
#######################################################################
# File: res/prompts/apply_readme_generator.sh
# Description: Easy-to-use script for applying the directory README 
#              generator template to any target directory.
#######################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
readonly TEMPLATE_FILE="$SCRIPT_DIR/templates/directory_readme_generator.yaml"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

show_usage() {
    cat << EOF
📝 Directory README Generator

Usage: $0 <target_directory> [options]

Parameters:
  target_directory    Absolute path to directory needing a README.md

Options:
  --no-purpose       Skip the purpose section
  --no-grouping      Don't group files logically
  --help            Show this help message

Examples:
  # Generate README for integration directory
  $0 /home/es/lab/val/lib/integration

  # Generate README with minimal grouping
  $0 /home/es/lab/src/management --no-grouping

  # Generate README without purpose section
  $0 /home/es/lab/lib/core --no-purpose

The script will:
1. Analyze all files in the target directory
2. Read key files to understand their purpose
3. Create logical groupings based on file functions
4. Generate a comprehensive README.md file
5. Place the README.md directly in the target directory

Template: directory_readme_generator.yaml
EOF
}

validate_directory() {
    local target_dir="$1"
    
    if [[ ! -d "$target_dir" ]]; then
        echo -e "${RED}❌ Error: Directory '$target_dir' does not exist${NC}"
        exit 1
    fi
    
    if [[ ! -w "$target_dir" ]]; then
        echo -e "${RED}❌ Error: No write permission for directory '$target_dir'${NC}"
        exit 1
    fi
}

apply_template() {
    local target_dir="$1"
    local include_purpose="${2:-true}"
    local group_files="${3:-true}"
    
    echo -e "${BLUE}📝 Generating README for: $target_dir${NC}"
    echo -e "${YELLOW}📋 Template: directory_readme_generator.yaml${NC}"
    echo
    
    # Note: In a full implementation, this would interface with an AI system
    # to process the YAML template. For now, we provide the structured prompt.
    
    cat << EOF
🤖 Apply this prompt to your AI assistant:

---
Please analyze the directory $target_dir and create a comprehensive README.md file that explains what each file does.

Requirements:
1. **Explore the directory**: Use the list_dir tool to see all files in $target_dir
2. **Analyze key files**: Read portions of important files to understand their purpose and functionality
3. **Logical organization**: Group files by their function or purpose (e.g., Core Modules, Documentation, Tools, etc.)
4. **Comprehensive descriptions**: For each file, provide a clear paragraph explaining:
   - What the file does
   - Its key features or capabilities  
   - How it fits into the overall system
5. **Professional formatting**: Use markdown formatting with:
   - Clear section headers with emoji indicators
   - File names in bold
   - Consistent structure and spacing
   - Descriptive but concise language

Focus on creating documentation that helps users quickly understand:
- The purpose of the directory
- What each file contributes
- How the files work together as a system
- The overall value and capabilities provided

Create the README.md file directly in the target directory using the create_file tool.

Settings:
- Include Purpose Section: $include_purpose
- Group Files Logically: $group_files
---

EOF
    
    echo -e "${GREEN}✅ Prompt ready for AI assistant${NC}"
    echo -e "${BLUE}💡 Copy the prompt above and provide it to your AI assistant${NC}"
}

main() {
    local target_dir=""
    local include_purpose=true
    local group_files=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-purpose)
                include_purpose=false
                shift
                ;;
            --no-grouping)
                group_files=false
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$target_dir" ]]; then
                    target_dir="$1"
                else
                    echo -e "${RED}❌ Too many arguments${NC}"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$target_dir" ]]; then
        echo -e "${RED}❌ Error: target_directory is required${NC}"
        show_usage
        exit 1
    fi
    
    # Validate directory
    validate_directory "$target_dir"
    
    # Apply template
    apply_template "$target_dir" "$include_purpose" "$group_files"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
