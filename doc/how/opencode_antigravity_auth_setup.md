# OpenCode Antigravity Auth Plugin Setup

This documents the installation of:

- OpenCode plugin repo: `/home/es/opencode-antigravity-auth`
- OpenCode config: `/home/es/.config/opencode/opencode.json`

## 1) Repository Installed

Cloned:

```bash
git clone https://github.com/NoeFabris/opencode-antigravity-auth.git /home/es/opencode-antigravity-auth
```

Dependencies installed and project build verified:

```bash
cd /home/es/opencode-antigravity-auth
npm ci
npm run build
```

## 2) OpenCode Configured

Created:

- `/home/es/.config/opencode/opencode.json`

Configured with:

- Plugin: `opencode-antigravity-auth@latest`
- Google provider model definitions (Antigravity + Gemini CLI model entries)

Verification command:

```bash
opencode models google
```

Expected to include models like:

- `google/antigravity-gemini-3-flash`
- `google/antigravity-gemini-3-pro`
- `google/antigravity-claude-opus-4-6-thinking`

## 3) Final Required Step (Interactive OAuth)

No Google credentials are currently configured yet. Complete login with:

```bash
opencode auth login
```

Then run a test prompt:

```bash
opencode run "Hello" --model=google/antigravity-gemini-3-flash --variant=low
```

## Notes

- If OpenCode is not found in an existing shell session, run:
  - `source ~/.bashrc`
- Current credential status was:
  - `opencode auth list` -> `0 credentials`
- The plugin README warns this is unofficial and can carry Google account risk; use at your own discretion.

## Fix Applied: "Invalid project resource name"

If you see an error like:

- `Invalid project resource name projects/<your-email>`

the stored `projectId` is invalid (email instead of GCP project id).

Fix:

1. Edit `~/.local/share/opencode/auth.json`
2. Ensure `google.refresh` does not include an email as project segment
3. Remove `google.projectId` if it is an email
4. Edit `~/.config/opencode/antigravity-accounts.json`
5. Remove account-level `projectId` when it is set to an email

After applying the fix, rerun:

```bash
opencode run "reply with one word" --model=google/antigravity-claude-opus-4-6-thinking --variant=low
```
