#!/usr/bin/env bash
#
# enable-autostart.sh — make the IDE provision and start itself on each new
# session by adding a guarded block to ~/.bashrc.
#
# The block runs bootstrap.sh once per boot (tracked by a marker keyed to the
# kernel boot id), in the background, so it never blocks your shell. Run this
# once; after that, every fresh Cloud Shell session brings the IDE up on its own.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASHRC="$HOME/.bashrc"
BEGIN="# >>> cloud-ide autostart >>>"
END="# <<< cloud-ide autostart <<<"
touch "$BASHRC"

# Remove any previous block so re-running is clean
if grep -qF "$BEGIN" "$BASHRC"; then
  awk -v b="$BEGIN" -v e="$END" '
    $0==b {skip=1} skip && $0==e {skip=0; next} !skip' "$BASHRC" > "$BASHRC.cloudide.tmp"
  mv "$BASHRC.cloudide.tmp" "$BASHRC"
fi

cat >> "$BASHRC" <<EOF
$BEGIN
# Provision + start the cloud IDE once per boot, in the background.
if [ -n "\${PS1:-}" ] && [ -d "$ROOT" ]; then
  __cloudide_boot="\$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || date +%s)"
  __cloudide_mark="\$HOME/.cloud-ide/.booted-\$__cloudide_boot"
  if [ ! -f "\$__cloudide_mark" ]; then
    mkdir -p "\$HOME/.cloud-ide"; : > "\$__cloudide_mark"
    ( cd "$ROOT" && bash scripts/bootstrap.sh >>"\$HOME/.cloud-ide/bootstrap.log" 2>&1 & )
  fi
fi
$END
EOF

echo "Autostart enabled in $BASHRC."
echo "Test it by opening a new Cloud Shell session, or run: source ~/.bashrc"
