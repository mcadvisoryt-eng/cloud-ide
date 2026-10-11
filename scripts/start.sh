#!/usr/bin/env bash
#
# start.sh — start code-server in the background (idempotent).
#
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
PORT="${CODE_SERVER_PORT:-8080}"
PIDFILE="$HOME/.code-server.pid"
LOG="$HOME/.code-server.log"

if ! command -v code-server >/dev/null 2>&1; then
  echo "code-server is not installed yet — run ./scripts/setup.sh first." >&2
  exit 1
fi

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "code-server is already running (pid $(cat "$PIDFILE"))."
else
  nohup code-server >"$LOG" 2>&1 &
  echo $! > "$PIDFILE"
  sleep 2
  echo "Started code-server (pid $(cat "$PIDFILE"))."
  echo "Log: $LOG"
fi

cat <<EOF

Open it:
  * Google Cloud Shell:  click "Web Preview" -> "Change port" -> ${PORT}
  * Stable URL:          see docs/cloud-shell.md (Tailscale Funnel)

The password is in ~/.config/code-server/config.yaml
EOF
