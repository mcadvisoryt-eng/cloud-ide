#!/usr/bin/env bash
#
# install-extensions.sh — install every extension in the list, idempotently.
#
# Reads config/extensions.txt (or $CLOUDIDE_EXTENSIONS if set), skips anything
# already present, and is tolerant: a failed ID is reported and skipped, never
# fatal. Safe to run on every boot.
#
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="${CLOUDIDE_EXTENSIONS:-$ROOT/config/extensions.txt}"

if ! command -v code-server >/dev/null 2>&1; then
  echo "install-extensions: code-server is not installed yet." >&2
  exit 1
fi
if [ ! -f "$LIST" ]; then
  echo "install-extensions: no extension list at $LIST" >&2
  exit 0
fi

# Current set, lower-cased for case-insensitive comparison.
installed="$(code-server --list-extensions 2>/dev/null | tr 'A-Z' 'a-z')"

ok=0; skip=0; fail=0; failed=""
while IFS= read -r raw; do
  id="${raw%%#*}"                          # strip trailing comment
  id="$(printf '%s' "$id" | tr -d '[:space:]')"
  [ -z "$id" ] && continue
  lid="$(printf '%s' "$id" | tr 'A-Z' 'a-z')"

  if printf '%s\n' "$installed" | grep -qx "$lid"; then
    skip=$((skip + 1))
    continue
  fi
  if code-server --install-extension "$id" --force >/dev/null 2>&1; then
    echo "  + $id"
    ok=$((ok + 1))
  else
    echo "  ! $id (failed — not on Open VSX, or offline)"
    fail=$((fail + 1))
    failed="$failed $id"
  fi
done < "$LIST"

echo "install-extensions: $ok installed, $skip already present, $fail failed"
[ -n "$failed" ] && echo "install-extensions: failed:$failed"
exit 0
