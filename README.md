# Void-termux

<p align="center">
  <img src="https://img.shields.io/badge/Void%20Linux-glibc-478061?style=for-the-badge&logo=voidlinux&logoColor=white" alt="Void Linux" />
  <img src="https://img.shields.io/badge/Termux-proot--distro-2E7D32?style=for-the-badge&logo=android&logoColor=white" alt="Termux" />
  <img src="https://img.shields.io/badge/Node.js-26.x-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js 26" />
</p>

<p align="center">
  <img src="https://img.shields.io/github/license/linecodevop-sys/Void-termux?style=flat-square" alt="License" />
  <img src="https://img.shields.io/github/stars/linecodevop-sys/Void-termux?style=flat-square" alt="Stars" />
  <img src="https://img.shields.io/github/forks/linecodevop-sys/Void-termux?style=flat-square" alt="Forks" />
  <img src="https://img.shields.io/github/last-commit/linecodevop-sys/Void-termux?style=flat-square" alt="Last commit" />
  <img src="https://img.shields.io/badge/platform-aarch64-blue?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/shell-bash-89e051?style=flat-square&logo=gnubash&logoColor=white" alt="Shell" />
</p>

One-command setup for a full **Void Linux** environment inside **Termux**,
complete with Node.js 26, pnpm, TypeScript tooling, GitHub CLI, and a clean
colored shell prompt — no manual troubleshooting required.

---

## ✨ What this installs

| Component | Details |
|---|---|
| 🐧 **Void Linux** | `void-glibc-full` via `proot-distro` (OCI image from `ghcr.io/void-linux`) |
| 🟢 **Node.js** | v26 (Current), installed via `nvm` |
| 📦 **pnpm** | Global package manager, PATH pre-configured |
| 🛠️ **Dev tools** | `typescript` (`tsc`), `tsx`, `eslint` — installed globally via pnpm |
| 🔧 **CLI tools** | `git`, `curl`, `wget`, `github-cli` (`gh`), `vim`, `nano` |
| 🎨 **Custom prompt** | Two-line colored prompt: `[user] root@localhost ➜ ~/path` |
| ⚡ **Shortcut** | `void` command to jump straight into the container with bash |

Every step is idempotent — re-running the installer **will not** break an
existing setup or throw errors on things that are already installed.

---

## 🚀 Quick Installation

Run this one-liner inside Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/linecodevop-sys/Void-termux/main/install.sh | bash
```

> 💡 **Tip:** Prefer to review the script before running it? That's good
> practice for *any* `curl | bash` install:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/linecodevop-sys/Void-termux/main/install.sh
> ```

After installation finishes, reload your shell config and jump in:

```bash
source ~/.bashrc
void
```

---

## 📖 Usage

| Command | What it does |
|---|---|
| `void` | Enter the Void Linux container (bash, colored prompt) |
| `exit` | Leave the container and return to Termux |
| `xbps-install <pkg>` | Install a package inside Void |
| `xbps-query -Rs <term>` | Search for a package in the Void repos |
| `nvm install <version>` | Install a different Node.js version |
| `pnpm add -g <pkg>` | Install a global npm package |

---

## 🧯 Troubleshooting

This installer exists *because* the manual setup has a few sharp edges.
Here's what it handles automatically, and what to check if something still
goes wrong:

<details>
<summary><strong>"command not found" after install</strong></summary>

Run `source ~/.bashrc` (or open a new Termux session) so your `PATH`
changes take effect.
</details>

<details>
<summary><strong>Prompt shows raw escape codes like <code>\[\033[1;35m\]</code></strong></summary>

This means you're in `/bin/sh`, not `bash`. Use the `void` alias (which
always launches `bash` directly), or run `bash` manually inside the
container.
</details>

<details>
<summary><strong><code>node: error while loading shared libraries: libatomic.so.1</code></strong></summary>

Already fixed by this installer (`libatomic` is installed automatically).
If you see this on a manual setup, run `xbps-install libatomic` inside
Void.
</details>

<details>
<summary><strong><code>proot-distro should not be executed under PRoot</code></strong></summary>

You tried to run `proot-distro` from *inside* the Void container. Exit
back to Termux first (`exit`), then run `proot-distro` commands from there.
</details>

<details>
<summary><strong>pnpm: "global bin directory is not in PATH"</strong></summary>

Already handled by this installer. If it recurs, make sure the path
includes the `/bin` suffix:
```bash
export PATH="/root/.local/share/pnpm/bin:$PATH"
```
</details>

---

## 📜 License

[Apache-2.0](./LICENSE)
