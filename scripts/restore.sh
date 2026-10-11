#!/usr/bin/env bash
#
# restore.sh — restore the newest VS Code data snapshot, then reinstall the
# extensions it recorded. Safe to run when there is nothing to restore.
#
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BK="${CLOUDIDE_BACKUP_DIR:-$HOME/.cloud-ide/backups}"
DATA_PARENT="$HOME/.local/share/code-server"

# Optional: pull the latest backup from the git remote first
if [ -n "${CLOUDIDE_GIT_REMOTE:-}" ] && [ -d "$BK/.git" ]; then
  git -C "$BK" pull -q --rebase 2>/dev/null && echo "Pulled latest backup from remote."
fi

LATEST="$(ls -1t "$BK"/vscode-data-*.tar.gz 2>/dev/null | head -n1)"
if [ -n "$LATEST" ]; then
  mkdir -p "$DATA_PARENT"
  if tar -xzf "$LATEST" -C "$DATA_PARENT"; then
    echo "Restored VS Code data from $(basename "$LATEST")"
  else
    echo "! Could not extract $LATEST"
  fi
else
  echo "No snapshot found in $BK - nothing to restore."
fi

if [ -f "$BK/installed-extensions.txt" ]; then
  echo "Reinstalling recorded extensions..."
  CLOUDIDE_EXTENSIONS="$BK/installed-extensions.txt" bash "$ROOT/scripts/install-extensions.sh" || true
fi
exit 0
