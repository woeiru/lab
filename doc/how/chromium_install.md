# Chromium Installation and Smoke Test on Debian 13

This guide installs Chromium on Debian 13 (trixie) using APT, then validates it with a headless runtime test.

## Install

1. Refresh package metadata:
   ```bash
   sudo apt-get update
   ```
2. Install Chromium:
   ```bash
   sudo apt-get install -y chromium
   ```
3. Confirm the binary is present:
   ```bash
   command -v chromium
   chromium --version
   ```

## Functional Test (Headless)

Run a non-GUI smoke test to verify Chromium starts and renders a page:

```bash
chromium --headless --disable-gpu --dump-dom https://example.com | head -n 5
```

Expected result:
- Command exits with status `0`.
- Output begins with HTML from `example.com` (for example `<!doctype html>`).

Optional stricter check:

```bash
chromium --headless --disable-gpu --dump-dom https://example.com >/tmp/chromium_test.html
grep -qi "<title>Example Domain</title>" /tmp/chromium_test.html && echo "Chromium test passed"
```

## Validation Notes for This Repository Session

- Host detected: `Debian GNU/Linux 13 (trixie)`.
- Package availability verified:
  - `chromium` candidate: `145.0.7632.109-1~deb13u3`.
- Installation/test execution could not be completed in this non-interactive session because `sudo` requires a password prompt.
