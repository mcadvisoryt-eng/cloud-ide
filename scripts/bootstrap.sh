#!/usr/bin/env bash
#
# bootstrap.sh — provision or refresh the cloud IDE. Idempotent; safe to run on
# every boot. This is the script the autostart hook calls.
#
# Order: code-server -> restore saved data if the home is fresh -> seed
# settings/keybindings -> install extensions -> optional toolchains -> start.
#
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.cloud-ide"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

say "cloud-ide bootstrap starting ($(date '+%Y-%m-%d %H:%M:%S'))"

# 1. code-server
if command -v code-server >/dev/null 2>&1; then
  say "code-server present: $(code-server --version 2>/dev/null | tail -n1)"
else
  say "Installing code-server..."
  bash "$ROOT/scripts/setup.sh" || warn "setup.sh had trouble - continuing"
fi

# 2. Restore saved VS Code data if this is a fresh home
if [ ! -f "$HOME/.local/share/code-server/User/settings.json" ]; then
  say "No local VS Code data found - attempting restore from backup..."
  bash "$ROOT/scripts/restore.sh" || warn "restore.sh had trouble - continuing"
else
  say "Local VS Code data present - no restore needed."
fi

# 3. Seed default settings/keybindings (never clobbers your own edits)
say "Applying settings and keybindings..."
bash "$ROOT/scripts/apply-config.sh" || warn "apply-config.sh had trouble"

# 4. Extensions
say "Ensuring extensions are installed..."
bash "$ROOT/scripts/install-extensions.sh" || warn "install-extensions.sh had trouble"

# 5. Optional toolchains (only if config/toolchains.txt has an uncommented entry)
if [ -f "$ROOT/config/toolchains.txt" ] && grep -qE '^[[:space:]]*[^#[:space:]]' "$ROOT/config/toolchains.txt"; then
  say "Installing optional toolchains (mise)..."
  bash "$ROOT/scripts/install-toolchains.sh" || warn "install-toolchains.sh had trouble"
fi

# 6. Start code-server
say "Starting code-server..."
bash "$ROOT/scripts/start.sh" || warn "start.sh had trouble"

# 7. Snapshot the current data (keeps the last 5) so a recent backup always exists.
#    Set CLOUDIDE_AUTOBACKUP=0 to skip.
if [ "${CLOUDIDE_AUTOBACKUP:-1}" = "1" ]; then
  say "Snapshotting VS Code data..."
  bash "$ROOT/scripts/backup.sh" >/dev/null 2>&1 || warn "backup.sh had trouble"
fi

say "cloud-ide bootstrap done."
