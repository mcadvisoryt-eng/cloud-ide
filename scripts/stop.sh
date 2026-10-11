#!/usr/bin/env bash
#
# stop.sh — stop a code-server started by start.sh.
#
set -euo pipefail

PIDFILE="$HOME/.code-server.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  kill "$(cat "$PIDFILE")" && echo "Stopped code-server (pid $(cat "$PIDFILE"))."
else
  if pkill -f 'code-server' 2>/dev/null; then
    echo "Stopped code-server (found by name)."
  else
    echo "code-server is not running."
  fi
fi
rm -f "$PIDFILE"
