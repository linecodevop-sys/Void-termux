#!/data/data/com.termux/files/usr/bin/bash
#
# Void-termux installer
# Installs Void Linux (glibc-full) inside Termux via proot-distro,
# sets up Node.js 26 (via nvm), pnpm, TypeScript/tsx/eslint,
# a custom colored prompt, and a `void` shortcut alias.
#
# Repo: https://github.com/linecodevop-sys/Void-termux
#
# Safe to re-run: every step checks for existing state before acting.

set -uo pipefail

# ---------- Pretty output helpers ----------
C_RESET='\033[0m'
C_BLUE='\033[1;34m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_CYAN='\033[1;36m'

info()  { printf "${C_BLUE}[*]${C_RESET} %s\n" "$1"; }
ok()    { printf "${C_GREEN}[OK]${C_RESET} %s\n" "$1"; }
warn()  { printf "${C_YELLOW}[!]${C_RESET} %s\n" "$1"; }
fail()  { printf "${C_RED}[FAIL]${C_RESET} %s\n" "$1"; }

DISTRO_ALIAS="void-glibc-full"
DISTRO_IMAGE="ghcr.io/void-linux/void-glibc-full"

# ---------- 0. Sanity check: must run in Termux ----------
if [ ! -d "/data/data/com.termux/files/usr" ]; then
  fail "This script must be run inside Termux."
  exit 1
fi

# ---------- 1. Ensure proot-distro is installed ----------
info "Checking proot-distro..."
if ! command -v proot-distro >/dev/null 2>&1; then
  info "Installing proot-distro..."
  pkg update -y && pkg install -y proot-distro
else
  ok "proot-distro already installed."
fi

# ---------- 2. Ensure pnpm global bin dir is on PATH (Termux side) ----------
TERMUX_BASHRC="$HOME/.bashrc"
touch "$TERMUX_BASHRC"
if ! grep -q 'pnpm' "$TERMUX_BASHRC" 2>/dev/null; then
  info "Adding pnpm global bin dir to Termux PATH..."
  echo 'export PATH="$PATH:/root/.local/share/pnpm/bin:/data/data/com.termux/files/home/.local/share/pnpm/bin"' >> "$TERMUX_BASHRC"
fi

# ---------- 3. Install Void Linux container ----------
info "Checking for existing '$DISTRO_ALIAS' container..."
if proot-distro list 2>/dev/null | grep -q "$DISTRO_ALIAS"; then
  ok "Container '$DISTRO_ALIAS' already installed. Skipping install."
else
  info "Installing Void Linux ($DISTRO_IMAGE)... this may take a few minutes."
  proot-distro install "$DISTRO_IMAGE" --override-alias "$DISTRO_ALIAS"
  if [ $? -ne 0 ]; then
    fail "Void Linux installation failed. Check your internet connection and try again."
    exit 1
  fi
fi

# ---------- 4. Build the in-container setup scripts ----------
# Step A runs via /bin/sh (the only shell a fresh image has) and ONLY installs
# bash + base packages. Must stay strict POSIX-sh (no bashisms).
BOOTSTRAP_SCRIPT='
set -u
echo "[*] Updating xbps and base system..."
xbps-install -Sy xbps >/dev/null 2>&1
xbps-install -Suy >/dev/null 2>&1
echo "[*] Installing base packages (bash, curl, git, github-cli, vim, nano, wget, libatomic)..."
xbps-install -y bash curl git github-cli wget vim nano libatomic ca-certificates >/dev/null 2>&1
echo "[OK] Base packages installed."
'

# Step B runs via /bin/bash (now installed by Step A). nvm REQUIRES bash to be
# sourced (it uses bash-only syntax), so this entire block must run under bash,
# not sh. Heredocs use UNQUOTED delimiters here on purpose so that \xXX byte
# escapes in the prompt string are interpreted by the shell at write-time
# (printf) rather than written literally.
VOID_SETUP_SCRIPT='
set -u
BASHRC="/root/.bashrc"
touch "$BASHRC"

# Colored two-line prompt (idempotent). Uses a quoted heredoc so backslash
# sequences (\[ \033 \u \w etc.) are written literally for bash to interpret
# later when the prompt is drawn. ASCII-only arrows (->  `-) are used instead
# of Unicode glyphs to avoid encoding issues across different shells/locales.
if ! grep -q "Custom prompt" "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" << "PROMPT_EOF"

# Custom prompt
PS1="\[\033[1;35m\][\[\033[1;36m\]keyreyla\[\033[1;35m\]] \[\033[1;32m\]\u\[\033[0m\]@\[\033[1;33m\]localhost\[\033[0m\] \[\033[1;34m\]->\[\033[0m\]  \[\033[1;36m\]\w\[\033[0m\]\n\[\033[1;35m\]\`-\[\033[0m\] "
PROMPT_EOF
fi

# nvm setup
if [ ! -d "/root/.nvm" ]; then
  echo "[*] Installing nvm..."
  curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash >/dev/null 2>&1
fi

if ! grep -q "NVM_DIR" "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" << "NVM_EOF"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
NVM_EOF
fi

export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "[*] Installing Node.js 26 via nvm (this may take a moment)..."
nvm install 26 >/dev/null 2>&1
nvm alias default 26 >/dev/null 2>&1
nvm use 26 >/dev/null 2>&1

echo "[*] Installing pnpm..."
npm install -g pnpm >/dev/null 2>&1

mkdir -p "/root/.local/share/pnpm/bin"
if ! grep -q "PNPM_HOME" "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" << "PNPM_EOF"

export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"
PNPM_EOF
fi
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME/bin:$PATH"

echo "[*] Installing global dev tools via pnpm (typescript, tsx, eslint)..."
pnpm add -g typescript tsx eslint >/dev/null 2>&1

echo "[OK] Void Linux environment is ready."
echo "[OK] Node: $(node --version 2>/dev/null)"
echo "[OK] pnpm: $(pnpm --version 2>/dev/null)"
echo "[OK] tsc:  $(tsc --version 2>/dev/null)"
'

# ---------- 5. Run bootstrap (sh) then main setup (bash) ----------
# A freshly-installed void-glibc-full image has NO bash yet (only /bin/sh), and
# it defines its own Entrypoint/Cmd, so `proot-distro login -- /bin/bash` fails
# until bash is installed. Step A bootstraps bash via /bin/sh; Step B then runs
# everything else (nvm, pnpm, prompt) via /bin/bash, since nvm requires bash.
info "Installing base packages (bash, git, curl, etc.)..."
proot-distro run "$DISTRO_ALIAS" -- /bin/sh -c "$BOOTSTRAP_SCRIPT"

info "Configuring Node 26, pnpm, typescript, tsx, eslint, and prompt..."
proot-distro run "$DISTRO_ALIAS" -- /bin/bash -c "$VOID_SETUP_SCRIPT"

if [ $? -ne 0 ]; then
  warn "Some steps inside the container may have failed. Check the output above."
fi

# ---------- 6. Add the `void` shortcut alias in Termux ----------
if ! grep -q "alias void=" "$TERMUX_BASHRC" 2>/dev/null; then
  info "Adding 'void' shortcut alias to Termux..."
  echo "alias void='proot-distro login $DISTRO_ALIAS -- /bin/bash'" >> "$TERMUX_BASHRC"
fi

ok "Installation complete!"
echo ""
echo -e "${C_CYAN}Run this to apply changes to your current Termux session:${C_RESET}"
echo "    source ~/.bashrc"
echo ""
echo -e "${C_CYAN}Then enter Void Linux anytime with:${C_RESET}"
echo "    void"
echo ""
