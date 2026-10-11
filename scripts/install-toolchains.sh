#!/usr/bin/env bash
#
# install-toolchains.sh — OPTIONAL: install extra language toolchains into $HOME.
#
# Uses mise (https://mise.jdx.dev), which manages many languages under $HOME so
# they persist on hosts where only $HOME survives. Google Cloud Shell already
# ships Python, Node, Go, Java and more, so you rarely need this there - it is
# for a bare host, or to pin specific versions.
#
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="${CLOUDIDE_TOOLCHAINS:-$ROOT/config/toolchains.txt}"

if ! command -v mise >/dev/null 2>&1; then
  echo "Installing mise..."
  curl -fsSL https://mise.run | sh || { echo "! mise install failed"; exit 1; }
  export PATH="$HOME/.local/bin:$PATH"
fi

[ -f "$LIST" ] || { echo "No toolchain list at $LIST"; exit 0; }

while IFS= read -r raw; do
  t="${raw%%#*}"
  t="$(printf '%s' "$t" | tr -d '[:space:]')"
  [ -z "$t" ] && continue
  echo "  mise use -g $t"
  mise use -g "$t" >/dev/null 2>&1 || echo "  ! failed: $t"
done < "$LIST"

echo 'Toolchains done. Activate with: eval "$(mise activate bash)"'
exit 0
