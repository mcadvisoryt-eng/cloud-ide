#!/usr/bin/env bash
#
# setup.sh — install code-server (VS Code in the browser) into $HOME and configure it.
#
# Designed for Google Cloud Shell, but works on any Debian/Ubuntu host.
# It installs into ~/.local, which is inside Cloud Shell's *persistent* $HOME,
# so the install survives even when the session's VM is recycled.
#
# No root required. No secrets are written anywhere except the local config file.
#
set -euo pipefail

PORT="${CODE_SERVER_PORT:-8080}"
BIND_ADDR="${CODE_SERVER_BIND:-0.0.0.0:${PORT}}"
CONFIG_DIR="$HOME/.config/code-server"
CONFIG="$CONFIG_DIR/config.yaml"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# --- 1. Install code-server -------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
if command -v code-server >/dev/null 2>&1; then
  say "code-server is already installed: $(code-server --version | head -n1)"
else
  say "Installing code-server into \$HOME (persists across sessions)..."
  curl -fsSL https://code-server.dev/install.sh | sh
fi

# --- 2. Make ~/.local/bin available in future shells ------------------------
if ! grep -qs '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
  say "Added ~/.local/bin to PATH in ~/.bashrc."
fi

# --- 3. Write the config (with a password) ----------------------------------
mkdir -p "$CONFIG_DIR"

if [ -n "${CODE_SERVER_PASSWORD:-}" ]; then
  PW="$CODE_SERVER_PASSWORD"
  say "Using CODE_SERVER_PASSWORD from the environment."
elif [ -f "$CONFIG" ] && grep -q '^password:' "$CONFIG"; then
  PW="$(sed -n 's/^password: *//p' "$CONFIG" | head -n1)"
  say "Reusing the existing code-server password."
else
  PW="$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)"
  say "Generated a new code-server password."
fi

cat > "$CONFIG" <<EOF
bind-addr: ${BIND_ADDR}
auth: password
password: ${PW}
cert: false
EOF
chmod 600 "$CONFIG"

say "Config written to $CONFIG"
printf '\n    Password: %s\n\n' "$PW"

say "Done. Next:"
echo "    ./scripts/start.sh"
echo "    then in Cloud Shell click 'Web Preview' -> 'Change port' -> ${PORT}"
