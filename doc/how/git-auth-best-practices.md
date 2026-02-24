# Git Authentication: The Minimalist & Scalable Path

## 🧠 The Minimalist Philosophy
In a complex lab environment, the most "minimalist" approach isn't just about using fewer tools—it's about using the **right abstractions**. 

The goal is to rely on **Standard Unix Protocols** (SSH) that are:
1.  **Built-in**: No extra software to install or maintain.
2.  **Stateless on Targets**: Your Virtual Machines never store your "secrets" (tokens or private keys). Access exists only as long as your session is active.
3.  **Universal**: The same workflow works for GitHub, a private GitLab, or a simple Linux folder.

---

## 🏛️ Scalable Recommendations

### 1. SSH Agent Forwarding (The "Minimalist King")
**Best for**: Complete control across infinite VMs with zero "leakage."
*   **Concept**: You store your private key **only** on your main workstation. When you SSH into a VM, your workstation "lends" its identity to that session.
*   **The Minimalist Advantage**: One key, one entry in Git settings, zero configuration on the VMs themselves.

### 2. SSH Config Mapping
**Best for**: Speed and avoiding long IP addresses/URLs.
*   **Concept**: Use `~/.ssh/config` to create human-readable aliases for your servers.
*   **Example**: `git push lab-local` instead of `git push es@192.168.178.50:/srv/git/lab.git`.

### 3. Git Credential Cache (HTTPS Alternative)
**Best for**: Users who must use HTTPS but want to avoid manual pasting.
*   **Concept**: Git keeps your token in memory for a temporary window.
*   **Security Note**: ⚠️ **Less Secure.** While `cache` stores credentials in RAM, they are still sent over HTTPS, and bad helper choices (for example `store`) can leave tokens on disk.
*   **Important Clarification**: `cache` is only one HTTPS credential helper. Other common helpers include:
    *   `manager` (Git Credential Manager)
    *   `libsecret` (Linux secret store)
    *   `osxkeychain` (macOS keychain)

---

## 🧭 Pick One Strategy (Decision Table)

| Strategy | Best For | Security | Effort |
|---|---|---|---|
| SSH + Agent Forwarding | Labs, VMs, multi-host workflows | High | Medium (initial setup) |
| HTTPS + Secure Helper (`manager`/`libsecret`/`osxkeychain`) | Desktop-only workflows | Medium-High | Low |
| HTTPS + `cache` | Temporary sessions, quick tests | Medium | Low |

Recommendation for this lab-style environment: **SSH + agent forwarding**.

---

## 🧩 Why IDE Push Works but CLI Fails

Your IDE (VSCode/VSCodium) and terminal `git` may use different authentication paths:

*   **IDE push/sync** often uses an IDE-managed GitHub OAuth/session token.
*   **CLI git push** uses your shell's git credential helper or SSH keys.

So it's normal for IDE push to succeed while `git push` in terminal fails with credential errors.

---

## 🔍 Quick Diagnostics

Run these to inspect how your current shell is authenticating:

```bash
git remote -v
git config --show-origin --get-all credential.helper
gh auth status 2>/dev/null || true
```

Interpretation:

*   `origin` starts with `https://...` + helper is `cache` => using recommendation #3.
*   `origin` starts with `https://...` + helper is `manager`/`libsecret`/`osxkeychain` => HTTPS with secure credential storage.
*   `origin` starts with `git@github.com:...` => SSH workflow (recommendations #1/#2).

---

## 🛠️ Setup Guide: SSH Agent Forwarding

### A. On your Main Host (Local Machine)
1.  **Generate a modern key**:
    ```bash
    ssh-keygen -t ed25519 -C "lab-access"
    ```
2.  **Start the agent and add your key**:
    ```bash
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    ```
3.  **Configure global forwarding** in `~/.ssh/config`:
    ```text
    Host *
      ForwardAgent yes
      AddKeysToAgent yes
    ```

### B. On the Lab VMs
**Nothing**. Because of the config above, any VM you enter will automatically have access to your Git identity for the duration of the session.

### C. Setting up Git Credential Cache (HTTPS)
Use this if you cannot use SSH but want to "log in" once per session.

1.  **Enable the cache**:
    ```bash
    # Set cache to 8 hours (28800 seconds)
    git config --global credential.helper 'cache --timeout=28800'
    ```
2.  **Authenticate**:
    *   Run `git push`.
    *   Enter your username and Personal Access Token (PAT).
    *   Git will now keep these in memory. You won't be asked again until the timeout expires or the machine reboots.

---

## 📂 Moving to a Local Git Server (Future-Proofing)

If you decide to stop using GitHub, you can host your own "Server" in minutes with zero extra software.

### 1. Create the Local Repo (On your Server/Pi)
```bash
mkdir -p /srv/git/lab.git
cd /srv/git/lab.git
git init --bare
```

### 2. Point your VMs to the Local Server
On any VM, add the new remote:
```bash
# Using the standard SSH syntax
git remote add local-lab ssh://user@server-ip/srv/git/lab.git

# Push to it
git push local-lab master
```

### 3. The Pro Minimalist Move: SSH Aliases
Add this to your workstation's `~/.ssh/config`:
```text
Host lab-srv
  HostName 192.168.178.50  # Your local server IP
  User es
  IdentityFile ~/.ssh/id_ed25519
```
Now your Git commands on any VM (via Forwarding) become:
```bash
git clone lab-srv:/srv/git/lab.git
```

---

## 🔁 Migration Playbook: HTTPS to SSH (GitHub)

If your repo currently uses HTTPS, migrate once:

```bash
git remote set-url origin git@github.com:<owner>/<repo>.git
ssh -T git@github.com
git push
```

After this, your CLI and automation will use SSH identity instead of PAT prompts.

---

## 🛡️ Security Recap
*   **Tokens (HTTPS)**: High risk of leakage in logs/history. High maintenance (expiration).
*   **SSH Keys**: Highly secure. No passwords sent over the wire.
*   **Agent Forwarding**: The gold standard. If a VM is compromised and you disconnect your session, the attacker **does not** have your Git credentials. They were never there to begin with.

---

## 🧹 Cleanup Note
If you have ever used a token in a command (e.g., `git push https://user:token@...`), **your token is in your history.**

1.  Run `history -c` to clear the current session.
2.  Edit `~/.bash_history` and remove any line containing your token.
3.  **Revoke the token on GitHub immediately.**
