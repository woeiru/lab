# OpenCode Installation and Setup

This document records the `opencode` installation and basic setup on this machine.

## Installed Version

- `opencode 1.2.10`

## What Was Installed

OpenCode was installed using the official installer:

```bash
curl -fsSL https://opencode.ai/install | bash
```

The installer placed the binary at:

- `/home/es/.opencode/bin/opencode`

It also added this line to `/home/es/.bashrc`:

```bash
export PATH=/home/es/.opencode/bin:$PATH
```

## Activate in Current Shell

If `opencode` is not found in an already-open terminal, reload your shell:

```bash
source ~/.bashrc
```

Then verify:

```bash
opencode --version
```

## First Run

From any project directory:

```bash
cd /path/to/project
opencode
```

## Troubleshooting

- If you see a connectivity message like `Failed to fetch models.dev`, check network/DNS/proxy access and try again.
- If command is still not found, confirm:
  - `ls -l /home/es/.opencode/bin/opencode`
  - `echo "$PATH" | tr ':' '\n' | grep -F /home/es/.opencode/bin`
