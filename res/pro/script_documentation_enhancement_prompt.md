# Shell Script Documentation Enhancement Prompt

## Purpose
To systematically improve the inline documentation of a given shell script file by synchronizing summary descriptions with detailed function comments and adding comprehensive technical descriptions for each function.

## Required Inputs
- `{{script_file_path}}`: The absolute path to the shell script file that needs documentation enhancement.

## Instructions

**Phase 1: Analyze and Prepare**
1.  Read the content of the shell script located at `{{script_file_path}}`.
2.  Identify the main "Function Summary" block, usually at the beginning of the script, which lists functions and their one-liner descriptions.
3.  Identify all function definitions within the script.

**Phase 2: Synchronize One-Liner Descriptions**
1.  For each function listed in the "Function Summary" block:
    a.  Locate the corresponding function definition in the script.
    b.  Identify the one-liner descriptive comment(s) immediately preceding the function definition (typically 1-3 lines starting with `#`).
    c.  Compare the one-liner from the "Function Summary" with the one-liner(s) preceding the function definition.
    d.  If they differ, update the description in the "Function Summary" block to match the more accurate or comprehensive version found near the function definition. Ensure the updated description remains a concise one-liner.

**Phase 3: Add/Update Technical Descriptions**
1.  For each function defined in `{{script_file_path}}`:
    a.  Ensure there is exactly one blank line between the function signature (e.g., `function_name() {`) and the start of its technical description block or its first line of code if no technical description exists yet.
    b.  Insert or update a commented block for the "Technical Description" immediately after this blank line.
    c.  This block must:
        i.  Start with a comment line: `# Technical Description:`
        ii. Follow with commented lines detailing:
            - Key internal logic or algorithms.
            - Important variables used, modified, or expected as input (beyond formal parameters if they are complex).
            - Interactions with other functions, external commands, or system files.
            - Any non-obvious behaviors, side effects, or assumptions.
        iii. Include a sub-section for dependencies: `# Dependencies:`
            - List external commands (e.g., `sed`, `awk`, `qm`).
            - List other functions within the same script that are called.
            - List crucial environment variables the function relies on.
        iv. Be a maximum of 10 comment lines in total (including the `# Technical Description:` and `# Dependencies:` lines, and any blank comment lines used for readability within the block).
        v.  Be entirely composed of comment lines (each line starting with `#`).
    d.  Ensure there is exactly one blank line after the technical description block before the function's actual code begins.

## Constraints
-   All modifications must be applied directly to the file specified by `{{script_file_path}}`.
-   Preserve the existing shell script syntax, indentation, and overall formatting style.
-   Technical descriptions should be factual, concise, and targeted at developers maintaining the script.
-   Do not remove or alter existing functional code unless it's a comment being updated.

## Expected Output
-   The fully modified content of the shell script at `{{script_file_path}}`, incorporating all the documentation enhancements.
-   A brief confirmation message stating the process is complete for the specified file.

## Example Snippet (Illustrative - for one function)

**Before:**
```bash
#   my-func : Does something cool.
# ... (in header summary)

# Does something very cool and important.
my-func() {
    local var1="$1"
    echo "Processing $var1"
    external_command --option
}
```

**After:**
```bash
#   my-func : Does something very cool and important.
# ... (in header summary)

# Does something very cool and important.
my-func() {

    # Technical Description:
    #   This function processes the input argument and uses an external command.
    #   It logs the processing action to standard output.
    #   Assumes 'external_command' is in PATH.
    # Dependencies:
    #   - 'external_command' utility.
    #   - Relies on $1 being provided.

    local var1="$1"
    echo "Processing $var1"
    external_command --option
}
```
