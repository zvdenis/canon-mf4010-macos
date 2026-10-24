#!/usr/bin/env bash
#
# install.sh — set up Canon MF4010 scanning on macOS.
#
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/zvdenis/canon-mf4010-macos/main/install.sh | bash
#
# Options:
#   --prefix DIR    Install the `scan` command into DIR/bin (default: Homebrew prefix)
#   --app-dir DIR   Install Scan.app into DIR (default: /Applications)
#   --no-app        Skip the Spotlight app
#   --no-brew       Never run `brew install`
#   -h, --help      Show this help
#
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-zvdenis/canon-mf4010-macos}"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/${REPO_SLUG}/main}"

PREFIX="${PREFIX:-}"
APP_DIR="${APP_DIR:-}"
INSTALL_APP=1
ALLOW_BREW=1

say()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Installs the `scan` command and a Spotlight-friendly Scan.app for the
Canon imageCLASS MF4010 on macOS.

Options:
  --prefix DIR    Install the `scan` command into DIR/bin
                  (default: your Homebrew prefix, e.g. /opt/homebrew)
  --app-dir DIR   Install Scan.app into DIR (default: /Applications)
  --no-app        Do not build or install Scan.app
  --no-brew       Never run `brew install` (fail if SANE is missing)
  -h, --help      Show this help

Environment:
  PREFIX, APP_DIR, REPO_SLUG, RAW_BASE
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)  PREFIX="${2:?--prefix needs a directory}"; shift 2 ;;
    --app-dir) APP_DIR="${2:?--app-dir needs a directory}"; shift 2 ;;
    --no-app)  INSTALL_APP=0; shift ;;
    --no-brew) ALLOW_BREW=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || die "this installer only supports macOS"

# Make Homebrew's bin reachable in this shell, even if the user's profile
# hasn't been sourced yet.
if command -v brew >/dev/null 2>&1; then
  brew_bin="$(brew --prefix)/bin"
  case ":$PATH:" in
    *":$brew_bin:"*) ;;
    *) PATH="$brew_bin:$PATH"; export PATH ;;
  esac
fi

# ---------------------------------------------------------------------------
# Locate the payload: a local checkout when run as ./install.sh, otherwise
# download it (this is what makes `curl ... | bash` work).
# ---------------------------------------------------------------------------
src_dir=""
self="${BASH_SOURCE[0]:-}"
if [ -n "$self" ] && [ -f "$self" ]; then
  here="$(cd "$(dirname "$self")" && pwd)"
  if [ -f "$here/scan" ] && [ -f "$here/Scan.applescript" ]; then
    src_dir="$here"
  fi
fi

tmp_src=""
if [ -z "$src_dir" ]; then
  tmp_src="$(mktemp -d -t mf4010-scan)"
  trap 'rm -rf "$tmp_src"' EXIT
  src_dir="$tmp_src"
  say "Downloading scan and Scan.applescript ..."
  curl -fsSL "$RAW_BASE/scan" -o "$src_dir/scan" \
    || die "could not download $RAW_BASE/scan"
  curl -fsSL "$RAW_BASE/Scan.applescript" -o "$src_dir/Scan.applescript" \
    || die "could not download $RAW_BASE/Scan.applescript"
fi

# ---------------------------------------------------------------------------
# SANE: the actual driver for the scanner.
# ---------------------------------------------------------------------------
if ! command -v scanimage >/dev/null 2>&1; then
  if [ "$ALLOW_BREW" -eq 1 ] && command -v brew >/dev/null 2>&1; then
    say "Installing SANE (sane-backends) with Homebrew ..."
    brew install sane-backends
  else
    die "scanimage is missing. Install it with: brew install sane-backends"
  fi
fi

# ---------------------------------------------------------------------------
# The scan command.
# ---------------------------------------------------------------------------
if [ -z "$PREFIX" ]; then
  if command -v brew >/dev/null 2>&1; then
    PREFIX="$(brew --prefix)"
  else
    PREFIX="/usr/local"
  fi
fi
bin_dir="$PREFIX/bin"

if [ ! -d "$bin_dir" ]; then
  mkdir -p "$bin_dir" 2>/dev/null || die "cannot create $bin_dir"
fi

path_note=""
if [ ! -w "$bin_dir" ]; then
  warn "$bin_dir is not writable — installing to $HOME/.local/bin instead"
  bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *) path_note="export PATH=\"$bin_dir:\$PATH\"" ;;
  esac
fi

install -m 0755 "$src_dir/scan" "$bin_dir/scan"
say "installed  $bin_dir/scan"

# ---------------------------------------------------------------------------
# The Spotlight app.
# ---------------------------------------------------------------------------
if [ "$INSTALL_APP" -eq 1 ]; then
  if [ -z "$APP_DIR" ]; then
    if [ -w /Applications ]; then
      APP_DIR="/Applications"
    else
      APP_DIR="$HOME/Applications"
    fi
  fi
  mkdir -p "$APP_DIR"
  build_dir="$(mktemp -d -t mf4010-app)"
  if osacompile -o "$build_dir/Scan.app" "$src_dir/Scan.applescript" 2>/dev/null; then
    rm -rf "$APP_DIR/Scan.app"
    ditto "$build_dir/Scan.app" "$APP_DIR/Scan.app"
    say "installed  $APP_DIR/Scan.app"
  else
    warn "could not build Scan.app — the Spotlight app was skipped"
  fi
  rm -rf "$build_dir"
fi

# ---------------------------------------------------------------------------
# Verify.
# ---------------------------------------------------------------------------
list_out="$("$bin_dir/scan" --list 2>/dev/null || true)"
if printf '%s' "$list_out" | grep -q 'pixma:'; then
  say ""
  say "Scanner detected:"
  printf '%s\n' "$list_out" | sed 's/^/  /'
else
  warn "no scanner detected. Check the USB cable and that the printer is on, then run: scan --list"
fi

say ""
say "Try it:    scan"
if [ "$INSTALL_APP" -eq 1 ]; then
  say "Spotlight: press Cmd-Space, type \"Scan\", press Return"
fi
if [ -n "$path_note" ]; then
  say ""
  say "Add $bin_dir to your PATH:  $path_note"
fi
say "Docs:      https://github.com/$REPO_SLUG"
