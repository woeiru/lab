# Git Authentication Best Practices for Lab Environments

## 🎯 The Problem: "Token Fatigue" and Security
When developing strictly in the terminal, especially across multiple Virtual Machines (VMs), using HTTPS with Personal Access Tokens (PATs) leads to two major issues:
1.  **TEDIUM**: Manually pasting tokens for every push/pull operation.
2.  **SECURITY**: Tokens appearing in `~/.bash_history` or system process logs when passed via URL or command line.

---

## 🏛️ Scalable Recommendations

### 1. SSH Agent Forwarding (Top Recommendation)
**Best for**: Developers jumping between multiple VMs from a single "Host" machine.
*   **Concept**: You store your private key **only** on your local machine. When you SSH into a lab VM, your local SSH identity is "tunneled" to the VM.
*   **Pros**: You only need one key in GitHub. No keys are ever stored on the VMs. Scales to infinite VMs instantly.
*   **Cons**: Requires SSH access from a "master" machine.

### 2. GitHub CLI (`gh` tool)
**Best for**: A modern, feature-rich terminal experience.
*   **Concept**: An official tool that handles OAuth authentication and stores tokens securely in the OS keyring or a config file.
*   **Pros**: No manual token management. Supports PRs, Issues, and Releases from CLI.
*   **Cons**: Requires installing an extra package on the VM.

### 3. Git Credential Helper (Cache)
**Best for**: Users who prefer HTTPS but want to "log in" once per session.
*   **Concept**: Git keeps your token in memory for a specified duration.
*   **Pros**: Simple setup. No SSH configuration needed.
*   **Cons**: Token is stored in cleartext if using the `store` mode (avoided by using `cache`).

### 4. Repository Deploy Keys
**Best for**: Automated scripts or "Static" VMs that only need access to one project.
*   **Concept**: A specific SSH key added to the **Repository Settings** instead of your Account.
*   **Pros**: Limited scope (cannot access your other repos).
*   **Cons**: One key per repo per machine (if not shared).

---

## 🛠️ Setup Guides

### A. Setting up SSH Agent Forwarding
This allows any VM you enter to "become" you for Git operations.

1.  **On your Main Host (Local Machine)**:
    *   Generate a key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
    *   Add the public key (`~/.ssh/id_ed25519.pub`) to **GitHub Settings -> SSH and GPG keys**.
    *   Add the key to your local agent:
        ```bash
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        ```
2.  **Configure SSH Client**:
    *   Edit `~/.ssh/config` on your Host machine:
        ```text
        Host *
          ForwardAgent yes
        ```
3.  **On the VM**:
    *   Switch your repo from HTTPS to SSH:
        ```bash
        git remote set-url origin git@github.com:woeiru/lab.git
        ```
    *   Test it: `ssh -T git@github.com` (Should say "Hi woeiru!")

### B. Setting up Git Credential Cache (HTTPS)
If you must use tokens, make Git remember them for the day.

1.  **Enable the cache**:
    ```bash
    # Set cache to 8 hours (28800 seconds)
    git config --global credential.helper 'cache --timeout=28800'
    ```
2.  **First Push**:
    *   Run `git push`.
    *   Enter your username and PAT.
    *   Git will not ask again until the timer expires or you reboot.

### C. Using GitHub CLI (`gh`)
1.  **Install**: `sudo apt install gh` (or equivalent).
2.  **Authenticate**:
    ```bash
    gh auth login
    ```
    *   Select `GitHub.com` -> `SSH` or `HTTPS` -> `Paste an authentication token`.
3.  **Done**: All Git commands will now use the authenticated session.

---

## 🛡️ Security Cleanup: Fixing the History Leak
Because we previously pushed using the token in the URL, your token is likely in your history file.

**Immediate Action**:
1.  Open your history: `nano ~/.bash_history`
2.  Search for the line containing `ghp_...` and delete it.
3.  Alternatively, clear current session history: `history -c && history -w`
4.  **Recommended**: Go to GitHub Settings and **Revoke** that specific token, then create a new one. This invalidates the leaked string entirely.
