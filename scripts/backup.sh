#!/usr/bin/env bash
#
# backup.sh — snapshot your VS Code data so it can be restored later or on
# another host.
#
# Saves code-server's User data (settings, keybindings, snippets, global and
# workspace storage) plus the list of installed extensions. Extension *binaries*
# are not archived - restore.sh reinstalls them from the list, which is far
# smaller and always pulls current builds.
#
# Where it lands: $CLOUDIDE_BACKUP_DIR (default ~/.cloud-ide/backups). On Cloud
# Shell that path is already persistent. To also copy it off-box, set
# CLOUDIDE_GIT_REMOTE to a private git repo URL (see docs/cloud-shell.md).
#
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

BK="${CLOUDIDE_BACKUP_DIR:-$HOME/.cloud-ide/backups}"
DATA_PARENT="$HOME/.local/share/code-server"
DATA="$DATA_PARENT/User"
mkdir -p "$BK"
TS="$(date +%Y%m%d-%H%M%S)"

# 1. Installed extensions list
if command -v code-server >/dev/null 2>&1; then
  code-server --list-extensions 2>/dev/null | sort > "$BK/installed-extensions.txt"
  echo "Saved extension list: $(wc -l < "$BK/installed-extensions.txt") entries"
fi

# 2. User data tarball
if [ -d "$DATA" ]; then
  ARCHIVE="$BK/vscode-data-$TS.tar.gz"
  if tar -czf "$ARCHIVE" -C "$DATA_PARENT" User 2>/dev/null; then
    echo "Saved $ARCHIVE"
  else
    echo "! Could not create archive"
  fi
else
  echo "No code-server User data to back up yet."
fi

# 3. Keep only the 5 most recent archives
ls -1t "$BK"/vscode-data-*.tar.gz 2>/dev/null | tail -n +6 | while read -r f; do rm -f "$f"; done

# 4. Optional: push to a private git remote (needs a stored credential/token)
if [ -n "${CLOUDIDE_GIT_REMOTE:-}" ]; then
  if [ ! -d "$BK/.git" ]; then
    git -C "$BK" init -q
    git -C "$BK" remote add origin "$CLOUDIDE_GIT_REMOTE" 2>/dev/null || true
    git -C "$BK" checkout -q -b main 2>/dev/null || true
  fi
  git -C "$BK" add -A
  git -C "$BK" commit -q -m "backup $TS" 2>/dev/null || true
  if git -C "$BK" push -q origin HEAD 2>/dev/null; then
    echo "Pushed backup to $CLOUDIDE_GIT_REMOTE"
  else
    echo "! Could not push to $CLOUDIDE_GIT_REMOTE (check credentials/remote)"
  fi
fi

echo "Backups in $BK:"
ls -1 "$BK"
exit 0
