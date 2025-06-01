# Directory README Generator Template - Usage Example

This demonstrates how to use the directory README generator template to reproduce the same high-quality documentation we created for the integration folder.

## 🚀 Quick Usage

### Option 1: Using the Helper Script
```bash
# Navigate to prompts directory
cd /home/es/lab/res/prompts

# Generate README for any directory
./apply_readme_generator.sh /home/es/lab/path/to/target/directory
```

### Option 2: Direct Template Application
Copy this prompt and provide the target directory:

```
Please analyze the directory /path/to/target/directory and create a comprehensive README.md file that explains what each file does.

Requirements:
1. **Explore the directory**: Use the list_dir tool to see all files in the target directory
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
```

## 📋 What This Template Produces

The template will generate README files with:

### Structure
- **Purpose statement** explaining the directory's role
- **Logical file groupings** (Core Modules, Documentation, Tools, etc.)
- **Detailed descriptions** for each file
- **Professional formatting** with consistent styling

### Content Quality
- **File analysis** through actual code reading
- **Functional grouping** based on file purposes
- **Clear descriptions** explaining what each file contributes
- **System overview** showing how files work together

### Formatting Standards
- Emoji indicators for sections (🎯, 📁, 🚀)
- Bold file names for easy scanning
- Consistent paragraph structure
- Clear hierarchy with proper heading levels

## 🎯 Expected Output Quality

This template reproduces the same approach used to create the integration folder README:

1. **Comprehensive Analysis** - Explores directory structure and reads key files
2. **Logical Organization** - Groups files by function (Core Testing, Documentation, etc.)
3. **Detailed Descriptions** - Explains each file's purpose and capabilities
4. **Professional Presentation** - Uses consistent formatting and clear language
5. **Value Summary** - Concludes with the directory's overall purpose and benefits

## 📁 Template Location

- **Template File**: `res/prompts/templates/directory_readme_generator.yaml`
- **Helper Script**: `res/prompts/apply_readme_generator.sh`
- **Examples**: This file serves as usage documentation

The template follows the lab's standard YAML format and integrates with the existing prompt template system.
