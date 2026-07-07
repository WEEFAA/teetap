#!/bin/sh
# teetap installer: downloads the pinned release script to ~/.local/bin.
#   curl -fsSL https://raw.githubusercontent.com/OWNER/teetap/main/install.sh | sh
#   TEETAP_VERSION=v0.1.0 sh install.sh   # pin a specific release
set -eu

REPO="${TEETAP_REPO:-weefaa/teetap}"
BIN_DIR="${TEETAP_BIN_DIR:-$HOME/.local/bin}"

version="${TEETAP_VERSION:-}"
if [ -z "$version" ]; then
    version=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | awk -F'"' '/"tag_name"/{print $4; exit}')
fi
[ -n "$version" ] || { echo 'teetap install: could not resolve latest release' >&2; exit 1; }

mkdir -p "$BIN_DIR"
curl -fsSL "https://raw.githubusercontent.com/$REPO/$version/teetap" -o "$BIN_DIR/teetap"
chmod +x "$BIN_DIR/teetap"

printf 'teetap %s installed to %s\n' "$version" "$BIN_DIR/teetap"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) printf 'note: %s is not on your PATH\n' "$BIN_DIR" >&2 ;;
esac
printf 'next: teetap skill install   # give your coding agents the /teetap skill\n'
