# 01 - Installation and Initialization

This guide is for operators setting up the lab framework on a workstation or host.
The system is Bash-native (no compile/build step) and is activated by shell integration.

## 1. Prerequisites and Safety

- **Platform:** Linux (Debian/Proxmox-oriented workflows are the main target).
- **Shell:** Bash 4+ (Zsh 5+ also supported by `./go init`).
- **Tools:** standard Unix utilities (`coreutils`, `findutils`, `grep`, `systemd`, `awk`, `sed`).
- **Repository root:** run commands from your clone root (for example `/home/es/lab`).

Side effects to expect:
- `./go init` modifies your shell startup file and creates backup files.
- `./go on` and `./go off` toggle an auto-load block in that startup file.
- `./go purge` removes both helper functions and auto-load integration.

## 2. Install the Repository

```bash
git clone https://github.com/woeiru/lab.git
cd lab
```

## 3. Initialize Shell Integration (One-Time)

```bash
./go init
```

`./go setup` is an alias for `./go init`.

During initialization, `go`:
1. checks shell compatibility,
2. stores integration settings in `.tmp/go_settings`,
3. injects persistent helper functions into your shell profile: `lab`, `lab-on`, `lab-off`.

Non-interactive setup is available:

```bash
./go init -y
```

## 4. Activate the Environment

After `init`, reload your shell profile once (or open a new shell):

```bash
source ~/.bashrc
```

Then choose one activation pattern:

### Current shell only (recommended default)

```bash
lab
```

This sources `bin/ini` into the current shell and does not enable auto-load for future shells.

### Auto-load for every new shell

```bash
lab-on
```

To disable auto-load later:

```bash
lab-off
```

## 5. Validate Setup

Basic status:

```bash
./go status
```

Validation:

```bash
./go validate
```

In CI/clean contexts, prefer direct validation scripts:

```bash
./val/run_all_tests.sh --quick
```

## 6. Troubleshooting and Recovery

### `lab: command not found`

Your shell profile was not reloaded yet.

```bash
source ~/.bashrc
```

### `Please run './go init' first`

Initialization marker/settings are missing.

```bash
./go init
```

### `LIB_OPS_DIR not set. Please run 'source bin/ini' first.`

The runtime environment is not loaded in the current shell.

```bash
lab
```

### Reset shell integration cleanly

```bash
./go purge
./go init
source ~/.bashrc
```

## 7. Related Docs

- Next: [02 - Environment and Configuration](02-configuration.md)
- Architecture context: [doc/arc/01-bootstrap-and-orchestration.md](../arc/01-bootstrap-and-orchestration.md)
