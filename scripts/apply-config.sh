#!/usr/bin/env bash
#
# apply-config.sh — seed VS Code settings and keybindings into code-server.
#
# Copies config/settings.json and config/keybindings.json into code-server's
# User directory ONLY if those files are not already there. This means the
# repo provides sane defaults on first run, but your own edits in the browser
# (which are what gets saved/backed up) are never overwritten.
#
# Set CLOUDIDE_FORCE_CONFIG=1 to overwrite anyway.
#
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USERDIR="$HOME/.local/share/code-server/User"
mkdir -p "$USERDIR"

seed() {
  local src="$1" dst="$2"
  [ -f "$src" ] || return 0
  if [ ! -f "$dst" ] || [ "${CLOUDIDE_FORCE_CONFIG:-0}" = "1" ]; then
    cp "$src" "$dst" && echo "  seeded $(basename "$dst")"
  else
    echo "  kept existing $(basename "$dst")"
  fi
}

seed "$ROOT/config/settings.json"    "$USERDIR/settings.json"
seed "$ROOT/config/keybindings.json" "$USERDIR/keybindings.json"
exit 0
