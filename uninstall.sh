#!/usr/bin/env bash
#
# uninstall.sh — remove the scan command and Scan.app installed by install.sh.
# SANE (sane-backends) and your scans are left untouched.
#
set -euo pipefail

PREFIX="${PREFIX:-}"
APP_DIR="${APP_DIR:-}"

removed=0

usage() {
  cat <<'EOF'
Usage: uninstall.sh [options]

Options:
  --prefix DIR    Directory the `scan` command was installed into
                  (default: your Homebrew prefix, plus ~/.local/bin)
  --app-dir DIR   Directory Scan.app was installed into
                  (default: /Applications and ~/Applications)
  -h, --help      Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)  PREFIX="${2:?--prefix needs a directory}"; shift 2 ;;
    --app-dir) APP_DIR="${2:?--app-dir needs a directory}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1 (see --help)" >&2; exit 2 ;;
  esac
done

if [ -z "$PREFIX" ]; then
  if command -v brew >/dev/null 2>&1; then
    PREFIX="$(brew --prefix)"
  else
    PREFIX="/usr/local"
  fi
fi

for f in "$PREFIX/bin/scan" "$HOME/.local/bin/scan"; do
  if [ -f "$f" ]; then
    rm -f "$f"
    echo "removed $f"
    removed=1
  fi
done

if [ -n "$APP_DIR" ]; then
  apps=("$APP_DIR/Scan.app")
else
  apps=("/Applications/Scan.app" "$HOME/Applications/Scan.app")
fi

for app in "${apps[@]}"; do
  if [ -d "$app" ]; then
    rm -rf "$app"
    echo "removed $app"
    removed=1
  fi
done

if [ "$removed" -eq 0 ]; then
  echo "Nothing to remove."
fi

echo
echo "SANE is still installed (remove with: brew uninstall sane-backends)."
echo "Your scans in ~/Documents/Scans were not touched."
