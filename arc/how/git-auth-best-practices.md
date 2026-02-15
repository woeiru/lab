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
