# Lab Environment Setup

A lightweight shell environment management system for Bash (4+) and Zsh (5+).

## Quick Setup

```bash
./entry.sh
```

This symlink runs `bin/env/inject`, which:

1. Checks shell compatibility
2. Modifies your shell configuration (`.bashrc` or `.zshrc`)
3. Adds initialization code that runs `bin/init` on shell startup
4. Restarts your shell to apply changes

## Configuration Options

For detailed information on configuration options and runtime controls, see:
- [User Interaction and Configuration Guide](doc/manual/initiation.md)

## Command Line Options

The `entry.sh` script (or `bin/env/inject`) supports these options:
```
-y          Non-interactive mode
-u USER     Specify target user
-c FILE     Specify config file
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
