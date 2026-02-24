# OpenCode Installation and Setup

This document records the `opencode` installation and basic setup on this machine.
Replace `<YOUR_USER>` with your local Linux username in absolute path examples.

## Installed Version

- `opencode 1.2.10`

## What Was Installed

OpenCode was installed using the official installer:

```bash
curl -fsSL https://opencode.ai/install | bash
```

The installer placed the binary at:

- `/home/<YOUR_USER>/.opencode/bin/opencode`

It also added this line to `/home/<YOUR_USER>/.bashrc`:

```bash
export PATH=/home/<YOUR_USER>/.opencode/bin:$PATH
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

If your current shell still does not resolve `opencode`, verify with the absolute path:

```bash
/home/<YOUR_USER>/.opencode/bin/opencode --version
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
  - `ls -l /home/<YOUR_USER>/.opencode/bin/opencode`
  - `echo "$PATH" | tr ':' '\n' | grep -F /home/<YOUR_USER>/.opencode/bin`
- On first run, OpenCode creates local data under:
  - `/home/<YOUR_USER>/.local/share/opencode`
  - If this directory cannot be created due permissions/sandboxing, run in a normal user shell and try again.
