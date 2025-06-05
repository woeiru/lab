# String Replacement Project

This project provides a set of tools for performing string replacements in various files, particularly useful for updating function and variable descriptions in shell scripts.

## Contents

1. [replace.json](#replacejson)
2. [replace.log](#replacelog)
3. [replace.sh](#replacesh)

## replace.json

This file contains the replacement rules in JSON format. Each rule specifies:
- `item`: The identifier for the replacement
- `old`: The original text to be replaced
- `new`: The new text to replace the original

Example:
```json
{
  "replacements": [
    {
      "item": "smb-fun",
      "old": "show an overview of specific functions",
      "new": "Displays an overview of specific Samba-related functions in the script, showing their usage, shortname, and description"
    },
    // ... more replacements ...
  ]
}
```

## replace.log

This log file records the details of each replacement operation, including:
- The target file being modified
- For each replacement:
  - The item identifier
  - The old text
  - The new text
- Timestamps for the start and completion of the replacement process

## replace.sh

This Bash script performs the actual string replacements. It takes two arguments:

1. Path to the JSON file containing replacements
2. Path to the target file to be modified

Usage:
```bash
./replace.sh <path_to_json_file> <path_to_target_file>
```

Features:
- Uses `jq` to parse the JSON file
- Escapes special characters for `sed`
- Logs all operations to `replace.log`
- Provides error handling for missing `jq` and incorrect usage

## Requirements

- Bash shell
- `jq` for JSON parsing

## Installation

1. Ensure you have `jq` installed. If not, install it using your system's package manager.
2. Clone this repository or download the script files.
3. Make the script executable:
   ```bash
   chmod +x replace.sh
   ```

## Usage

1. Prepare your `replace.json` file with the desired replacements.
2. Run the script:
   ```bash
   ./replace.sh replace.json /path/to/your/target/file
   ```
3. Check the `replace.log` file for details on the replacements made.

## Note

Always backup your target files before running this script, as it modifies files in-place.

## License

[Specify your license here]

## Contributing

[Add contribution guidelines if applicable]

## Contact

[Your contact information or project maintainer's contact]
