# 02 - Installation and Initialization

The lab infrastructure automation framework is a Bash-native environment. Setup is shell-hook based, with no compile/build step. Runtime operations rely on standard Linux utilities plus module-specific host commands, with Bash 4.0+.

## Requirements

- **Operating System:** Linux (developed and tested primarily on Debian). Some modules (like `pve`, `pbs`, `gpu`) are specific to Proxmox VE environments.
- **Shell:** Bash 4.0+ (or Zsh 5+).
- **Core Tools:** standard UNIX utilities (e.g., `coreutils`, `findutils`, `grep`, `systemd`).

## Step 1: Clone the Repository

Clone the project to your local machine or target hypervisor.

```bash
git clone https://github.com/woeiru/lab.git
cd lab
```

All interactions must occur from the repository root `/home/es/lab` (or wherever you cloned it).

## Step 2: System Initialization

The primary entrypoint for the system is the `./go` script. Your first step is to initialize shell integration. This is a one-time setup step.

```bash
./go init
```

Note: `./go setup` is an alias for this command.

**What this does:**
- It performs a compatibility check on your shell.
- It prepares the internal configuration directories.
- It injects three permanent helper functions directly into your `~/.bashrc` (or equivalent shell profile): `lab-on`, `lab-off`, and `lab`.

## Step 3: Activating the Environment

After initialization, the framework's functions and commands are not yet available. You must activate the environment in your shell session. You have three choices on how to do this:

### Option A: Auto-load (Persistent)

If you want the framework available in every new shell session you open automatically, run:

```bash
lab-on
```

You can disable this later with `lab-off`. This requires restarting your shell or sourcing your `~/.bashrc` again.

### Option B: On-Demand (Current Shell Only)

If you prefer to keep your shell environment clean and only load the framework when you need it, simply run:

```bash
lab
```

This command directly sources the initialization controller (`bin/ini`) and orchestrator (`bin/orc`) into your current shell session without modifying your bash configuration for future sessions.

## Step 4: Verification

To verify that the framework is loaded and healthy, use the status check command:

```bash
./go status
```

This will output the current state of the initialization chain, verify that all core components and operational modules are sourced, and confirm the active environment configuration.

If you ever wish to remove the helper functions from your shell profile entirely, you can run `./go purge`.

## Running the Test Suite (Optional)

You can validate the entire framework and ensure no local environment issues exist by running the primary test runner:

```bash
./go validate
```

Alternatively, run `./val/run_all_tests.sh` directly.

Note: `./go validate` checks initialization state first. In clean or CI-like contexts where shell integration is not initialized, prefer direct validation scripts (for example, `./val/run_all_tests.sh` or a targeted `./val/..._test.sh`).

Continue to [03 - Environment and Configuration](03-configuration.md) to learn how to define your infrastructure.
